#!/usr/bin/env python3
"""MusiK visualizer backend.

Captures system audio from the default sink monitor (via parec, works on
PulseAudio and PipeWire), computes a Zune-style bell-curve spectrum (bass
in the center, fanning out to highs), and streams normalized bar heights
as JSON arrays over a minimal localhost WebSocket server.

Dependencies: numpy, libpulse (parec). No pip packages required beyond numpy.

Only one instance runs per port: if the port is already bound, the new
process exits silently. The process exits on its own when no client has
been connected for a while, so the plasmoid can (re)spawn it freely.
"""

import argparse
import base64
import hashlib
import json
import socket
import struct
import subprocess
import sys
import threading
import time

import numpy as np

WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

RATE = 44100
FFT_SIZE = 2048
HOP_SIZE = 1024          # ~43 frames/sec
F_MIN = 40.0
F_MAX = 15000.0
IDLE_EXIT_SECS = 180     # exit when no client connected for this long


class WSServer:
    """Minimal send-only WebSocket server (stdlib only)."""

    def __init__(self, host, port):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind((host, port))
        self.sock.listen(4)
        self.clients = []
        self.lock = threading.Lock()
        self.last_client_seen = time.monotonic()
        threading.Thread(target=self._accept_loop, daemon=True).start()

    def _accept_loop(self):
        while True:
            try:
                conn, _ = self.sock.accept()
                threading.Thread(target=self._handshake, args=(conn,), daemon=True).start()
            except OSError:
                return

    def _handshake(self, conn):
        try:
            conn.settimeout(5)
            request = b""
            while b"\r\n\r\n" not in request:
                chunk = conn.recv(4096)
                if not chunk:
                    raise ConnectionError
                request += chunk
            key = None
            for line in request.decode("latin1").split("\r\n"):
                if line.lower().startswith("sec-websocket-key:"):
                    key = line.split(":", 1)[1].strip()
            if key is None:
                raise ConnectionError
            accept = base64.b64encode(
                hashlib.sha1((key + WS_GUID).encode()).digest()
            ).decode()
            conn.sendall(
                (
                    "HTTP/1.1 101 Switching Protocols\r\n"
                    "Upgrade: websocket\r\n"
                    "Connection: Upgrade\r\n"
                    f"Sec-WebSocket-Accept: {accept}\r\n\r\n"
                ).encode()
            )
            conn.settimeout(None)
            with self.lock:
                self.clients.append(conn)
                self.last_client_seen = time.monotonic()
        except (OSError, ConnectionError):
            conn.close()

    def broadcast(self, text):
        payload = text.encode()
        if len(payload) < 126:
            frame = struct.pack("!BB", 0x81, len(payload)) + payload
        else:
            frame = struct.pack("!BBH", 0x81, 126, len(payload)) + payload
        with self.lock:
            dead = []
            for conn in self.clients:
                try:
                    conn.sendall(frame)
                except OSError:
                    dead.append(conn)
            for conn in dead:
                self.clients.remove(conn)
                conn.close()
            if self.clients:
                self.last_client_seen = time.monotonic()
            return len(self.clients)

    def idle_for(self):
        with self.lock:
            if self.clients:
                return 0.0
            return time.monotonic() - self.last_client_seen


class BellSpectrum:
    """FFT -> log-spaced bands -> mirrored bell layout with gaussian envelope."""

    def __init__(self, bar_count):
        self.bar_count = bar_count
        self.half = max(bar_count // 2, 1)
        self.window = np.hanning(FFT_SIZE)
        freqs = np.fft.rfftfreq(FFT_SIZE, 1.0 / RATE)
        edges = np.geomspace(F_MIN, F_MAX, self.half + 1)
        self.bands = []
        for i in range(self.half):
            idx = np.where((freqs >= edges[i]) & (freqs < edges[i + 1]))[0]
            if len(idx) == 0:
                idx = np.array([np.argmin(np.abs(freqs - edges[i]))])
            self.bands.append(idx)
        # bar index -> band index by distance from center (bass in middle)
        center = (bar_count - 1) / 2.0
        dist = np.abs(np.arange(bar_count) - center)
        self.band_of_bar = np.minimum(dist.astype(int), self.half - 1)
        sigma = bar_count * 0.27
        self.envelope = np.exp(-0.5 * (dist / sigma) ** 2)
        self.peak = 1e-6
        self.smoothed = np.zeros(self.half)

    def process(self, samples):
        rms = float(np.sqrt(np.mean(samples**2)))
        if rms < 1e-5:  # silence
            self.smoothed *= 0.8
            vals = self.smoothed
        else:
            spectrum = np.abs(np.fft.rfft(samples * self.window))
            vals = np.array([spectrum[idx].mean() for idx in self.bands])
            vals = np.sqrt(vals)  # compress dynamic range
            # automatic gain: rolling peak with slow decay
            self.peak = max(self.peak * 0.998, float(vals.max()), 1e-6)
            vals = vals / self.peak
            # temporal smoothing (backend-side, client smooths further)
            self.smoothed = self.smoothed * 0.55 + vals * 0.45
            vals = self.smoothed
        bars = vals[self.band_of_bar] * self.envelope
        return np.clip(bars, 0.0, 1.0)


def capture_loop(server, bar_count):
    spectrum = BellSpectrum(bar_count)
    ring = np.zeros(FFT_SIZE, dtype=np.float32)
    hop_bytes = HOP_SIZE * 4

    while True:
        if server.idle_for() > IDLE_EXIT_SECS:
            sys.exit(0)
        proc = subprocess.Popen(
            [
                "parec",
                "-d", "@DEFAULT_MONITOR@",
                "--format=float32le",
                f"--rate={RATE}",
                "--channels=1",
                "--latency-msec=50",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        try:
            while True:
                data = proc.stdout.read(hop_bytes)
                if not data or len(data) < hop_bytes:
                    break  # parec died (e.g. device change); respawn
                ring[:-HOP_SIZE] = ring[HOP_SIZE:]
                ring[-HOP_SIZE:] = np.frombuffer(data, dtype=np.float32)
                bars = spectrum.process(ring.astype(np.float64))
                server.broadcast(json.dumps([round(float(b), 3) for b in bars]))
                if server.idle_for() > IDLE_EXIT_SECS:
                    proc.kill()
                    sys.exit(0)
        finally:
            proc.kill()
            proc.wait()
        time.sleep(1)


def main():
    parser = argparse.ArgumentParser(description="MusiK visualizer backend")
    parser.add_argument("--port", type=int, default=13769)
    parser.add_argument("--bars", type=int, default=32)
    args = parser.parse_args()

    try:
        server = WSServer("127.0.0.1", args.port)
    except OSError:
        sys.exit(0)  # already running

    capture_loop(server, args.bars)


if __name__ == "__main__":
    main()
