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
    """Minimal WebSocket server (stdlib only). Broadcasts frames out;
    incoming text frames are passed to on_message (used for live config)."""

    def __init__(self, host, port, on_message=None):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind((host, port))
        self.sock.listen(4)
        self.clients = []
        self.lock = threading.Lock()
        self.last_client_seen = time.monotonic()
        self.on_message = on_message
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
            self._read_loop(conn)
        except (OSError, ConnectionError):
            with self.lock:
                if conn in self.clients:
                    self.clients.remove(conn)
            conn.close()

    def _read_loop(self, conn):
        """Parse incoming client frames: text -> on_message, ping -> pong."""
        buf = b""
        while True:
            chunk = conn.recv(4096)
            if not chunk:
                raise ConnectionError
            buf += chunk
            while len(buf) >= 2:
                opcode = buf[0] & 0x0F
                masked = buf[1] & 0x80
                length = buf[1] & 0x7F
                offset = 2
                if length == 126:
                    if len(buf) < 4:
                        break
                    length = int.from_bytes(buf[2:4], "big")
                    offset = 4
                if masked:
                    if len(buf) < offset + 4 + length:
                        break
                    mask = buf[offset:offset + 4]
                    payload = bytes(
                        b ^ mask[i % 4]
                        for i, b in enumerate(buf[offset + 4:offset + 4 + length])
                    )
                    buf = buf[offset + 4 + length:]
                else:
                    if len(buf) < offset + length:
                        break
                    payload = buf[offset:offset + length]
                    buf = buf[offset + length:]
                if opcode == 0x8:  # close
                    raise ConnectionError
                if opcode == 0x9:  # ping -> pong
                    conn.sendall(struct.pack("!BB", 0x8A, len(payload)) + payload)
                elif opcode == 0x1 and self.on_message:
                    try:
                        self.on_message(payload.decode())
                    except Exception:
                        pass

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
    """FFT -> log-spaced bands -> mirrored bell layout with gaussian envelope.

    Tunable at runtime via set_params() (driven by the plasmoid config UI):
      bellWidth  - gaussian sigma as fraction of bar count (wider = flatter bell)
      bellFloor  - envelope floor, how much the edge bars still react (0..1)
      reactivity - 0 floaty .. 1 snappy (controls release speed)
      gamma      - response curve; <1 boosts quiet detail (punchier)
    """

    DEFAULTS = {"bellWidth": 0.45, "bellFloor": 0.3, "reactivity": 0.65, "gamma": 0.8}

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
        # treble tilt: raw spectra are bass-heavy; lift the high bands so the
        # outer bars get visible motion
        self.tilt = (np.arange(self.half) + 1.0) ** 0.3
        # bar index -> band index by distance from center (bass in middle)
        center = (bar_count - 1) / 2.0
        self.dist = np.abs(np.arange(bar_count) - center)
        self.band_of_bar = np.minimum(self.dist.astype(int), self.half - 1)
        self.peak = 1e-6
        self.smoothed = np.zeros(self.half)
        self.slow_avg = np.zeros(self.half)
        self.lock = threading.Lock()
        self.params = dict(self.DEFAULTS)
        self._rebuild_envelope()

    def _rebuild_envelope(self):
        sigma = max(self.bar_count * self.params["bellWidth"], 1e-3)
        gauss = np.exp(-0.5 * (self.dist / sigma) ** 2)
        floor = min(max(self.params["bellFloor"], 0.0), 1.0)
        self.envelope = floor + (1.0 - floor) * gauss

    def set_params(self, updates):
        with self.lock:
            for key in self.DEFAULTS:
                if key in updates:
                    self.params[key] = float(updates[key])
            self._rebuild_envelope()

    def process(self, samples):
        with self.lock:
            params = dict(self.params)
            envelope = self.envelope

        rms = float(np.sqrt(np.mean(samples**2)))
        if rms < 1e-5:  # silence
            self.smoothed *= 0.8
        else:
            spectrum = np.abs(np.fft.rfft(samples * self.window))
            vals = np.array([spectrum[idx].mean() for idx in self.bands])
            vals = np.sqrt(vals) * self.tilt  # compress range, lift highs
            # automatic gain: rolling peak, fast enough to track song dynamics
            self.peak = max(self.peak * 0.995, float(vals.max()), 1e-6)
            vals = vals / self.peak
            # onset emphasis: sustained energy normalizes high and flattens
            # the curve, so reward the *rise* above each band's short-term
            # average — kicks spike to full while steady rumble settles mid
            self.slow_avg = self.slow_avg * 0.92 + vals * 0.08
            flux = np.clip((vals - self.slow_avg) * 2.5, 0.0, 1.0)
            vals = 0.55 * vals + 0.45 * flux
            # fast attack, tunable release
            release = 0.97 - 0.17 * min(max(params["reactivity"], 0.0), 1.0)
            rising = vals > self.smoothed
            self.smoothed[rising] = self.smoothed[rising] * 0.3 + vals[rising] * 0.7
            self.smoothed[~rising] = np.maximum(
                self.smoothed[~rising] * release, vals[~rising]
            )
        shaped = np.clip(self.smoothed, 0.0, 1.0) ** max(params["gamma"], 0.05)
        bars = shaped[self.band_of_bar] * envelope
        return np.clip(bars, 0.0, 1.0)


def capture_loop(server, spectrum):
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

    spectrum = BellSpectrum(args.bars)

    def on_message(text):
        spectrum.set_params(json.loads(text))

    try:
        server = WSServer("127.0.0.1", args.port, on_message=on_message)
    except OSError:
        sys.exit(0)  # already running

    capture_loop(server, spectrum)


if __name__ == "__main__":
    main()
