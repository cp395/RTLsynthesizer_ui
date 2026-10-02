"""PC-side UI host built on the shared UART framing contract.

This module intentionally does not define wire bytes.  All frames are created
by :mod:`host.uart_protocol`, so a future Qt, CLI, or asyncio client uses the
same SOF/CRC/scene-chunk format.  A serial port is optional at import time;
``validate`` and ``render`` therefore work on machines without pyserial.
"""

from __future__ import annotations

import argparse
import json
import time
from pathlib import Path
from typing import Any, Iterable, List, Optional, Sequence

from designer.interactive_state import InteractiveState
from designer.pixel_renderer import PixelRenderer
from designer.ui_schema import UIScene

from .uart_protocol import (
    Frame,
    FrameParser,
    MessageType,
    ProtocolError,
    SceneAssembler,
    decode_event,
    decode_scene_json,
    encode_event,
    encode_scene_frames,
)


class SerialTransport:
    """Small pyserial adapter; import pyserial only when a port is opened."""

    def __init__(self, port: str, baudrate: int = 115200, timeout: float = 0.1):
        try:
            import serial  # type: ignore
        except ImportError as exc:  # pragma: no cover - environment dependent
            raise RuntimeError("pyserial is required for a real UART port; install pyserial") from exc
        if baudrate <= 0:
            raise ValueError("baudrate must be positive")
        timeout = max(0.0, float(timeout))
        self.serial = serial.serial_for_url(
            port,
            baudrate=int(baudrate),
            timeout=timeout,
            write_timeout=timeout,
        )

    def write(self, data: bytes) -> int:
        return int(self.serial.write(data))

    def read(self, size: int = 4096) -> bytes:
        return bytes(self.serial.read(max(1, int(size))))

    @property
    def in_waiting(self) -> int:
        return int(getattr(self.serial, "in_waiting", 0))

    def close(self) -> None:
        self.serial.close()


class UIHost:
    """Load, render, and transfer a VerilogQT scene."""

    def __init__(self, scene: Optional[UIScene] = None, transport: Any = None):
        self.scene = scene or UIScene()
        self.state = InteractiveState()
        self.transport = transport
        self.parser = FrameParser()
        self.scene_assembler = SceneAssembler()
        self.sequence = 0
        self.revision = 0
        self.received_frames: List[Frame] = []
        self.last_remote_scene: Optional[dict[str, Any]] = None
        self.last_remote_event: Any = None
        self.last_error: Optional[str] = None

    @classmethod
    def from_json(cls, path: str | Path, transport: Any = None) -> "UIHost":
        host = cls(transport=transport)
        host.load_json(path)
        return host

    def load_json(self, path: str | Path) -> UIScene:
        source = Path(path)
        try:
            data = json.loads(source.read_text(encoding="utf-8"))
        except OSError as exc:
            raise ValueError(f"cannot read UI JSON {source}: {exc}") from exc
        except json.JSONDecodeError as exc:
            raise ValueError(f"invalid UI JSON {source}: {exc}") from exc
        if not isinstance(data, dict):
            raise ValueError("UI JSON root must be an object")
        self.scene = UIScene.from_dict(data)
        self._load_runtime_state(data.get("runtime_state", data.get("state")))
        return self.scene

    def save_json(self, path: str | Path) -> Path:
        target = Path(path)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(
            json.dumps(self.scene.to_dict(), ensure_ascii=True, indent=2) + "\n",
            encoding="utf-8",
        )
        return target

    def save_ui_new(self, path: str | Path) -> Path:
        """Save the current editor scene and dynamic PC state to UI_new.json."""

        target = Path(path)
        target.parent.mkdir(parents=True, exist_ok=True)
        data = self.scene.to_dict()
        data["runtime_state"] = self.state.to_dict()
        data["host_protocol"] = {"name": "VerilogQT UART", "version": 1}
        target.write_text(
            json.dumps(data, ensure_ascii=True, indent=2) + "\n",
            encoding="utf-8",
        )
        return target

    def render(self, output: Optional[str | Path] = None, state: Optional[dict[str, Any]] = None):
        """Render with the same Python reference renderer used by the preview."""

        values = state if state is not None else self.state.to_dict()
        frame = PixelRenderer(self.scene.width, self.scene.height).render_scene(self.scene, values)
        if output is not None:
            try:
                from PIL import Image
            except ImportError as exc:  # pragma: no cover - environment dependent
                raise RuntimeError("Pillow is required to save a rendered frame") from exc
            target = Path(output)
            target.parent.mkdir(parents=True, exist_ok=True)
            Image.fromarray(frame, "RGB").save(str(target))
        return frame

    def connect(self, port: str, baudrate: int = 115200, timeout: float = 0.1) -> SerialTransport:
        self.close()
        self.transport = SerialTransport(port, baudrate, timeout)
        return self.transport

    def close(self) -> None:
        if self.transport is not None and hasattr(self.transport, "close"):
            self.transport.close()
        self.transport = None

    def _next_sequence(self) -> int:
        value = self.sequence & 0xFF
        self.sequence = (self.sequence + 1) & 0xFF
        return value

    def _write(self, data: bytes) -> int:
        if self.transport is None:
            raise RuntimeError("UART transport is not connected")
        written = int(self.transport.write(data))
        if written != len(data):
            raise OSError(f"short UART write: {written}/{len(data)} bytes")
        return written

    def send_scene(self, scene: Optional[UIScene] = None, *, revision: Optional[int] = None,
                   chunk_size: int = 512) -> int:
        """Send a validated scene as BEGIN/CHUNK/COMMIT frames."""

        selected = scene or self.scene
        validated = UIScene.from_dict(selected.to_dict())
        revision = self.revision if revision is None else int(revision)
        frames = encode_scene_frames(
            validated,
            revision=revision,
            sequence_start=self.sequence,
            chunk_size=chunk_size,
        )
        for encoded in frames:
            self._write(encoded)
            self.sequence = (self.sequence + 1) & 0xFF
        self.revision = (revision + 1) & 0xFFFFFFFF
        return len(frames)

    def send_event(self, event_type: int, event_id: int, event_value: int) -> int:
        """Send one event matching the existing ``event_clk`` event bus."""

        encoded = encode_event(int(event_type), int(event_id), int(event_value), self._next_sequence())
        self._write(encoded)
        return self.sequence - 1 & 0xFF

    def receive(self, timeout: float = 0.0) -> List[Frame]:
        """Read available frames and update remote scene/event fields."""

        if self.transport is None:
            raise RuntimeError("UART transport is not connected")
        deadline = time.monotonic() + max(0.0, float(timeout))
        frames: List[Frame] = []
        while True:
            waiting = int(getattr(self.transport, "in_waiting", 0))
            chunk = self.transport.read(max(1, waiting or 4096))
            if chunk:
                frames.extend(self.parser.feed(chunk))
                if timeout <= 0:
                    break
            if time.monotonic() >= deadline:
                break
            time.sleep(min(0.01, max(0.0, deadline - time.monotonic())))
        for frame in frames:
            self._handle_frame(frame)
        self.received_frames.extend(frames)
        return frames

    def _handle_frame(self, frame: Frame) -> None:
        if frame.message_type in (MessageType.SCENE_BEGIN, MessageType.SCENE_CHUNK, MessageType.SCENE_COMMIT):
            scene = self.scene_assembler.accept(frame)
            if scene is not None:
                self.last_remote_scene = scene
        elif frame.message_type == MessageType.EVENT:
            self.last_remote_event = decode_event(frame)
        elif frame.message_type == MessageType.NACK:
            try:
                self.last_error = decode_scene_json(frame.payload).get("error", "remote NACK")
            except ProtocolError:
                self.last_error = frame.payload.decode("utf-8", errors="replace")

    def _load_runtime_state(self, values: Any) -> None:
        if not isinstance(values, dict):
            return
        for index, value in enumerate(list(values.get("ui_state", []))[:32]):
            self.state.set_knob_value(index, int(value))
        for index, value in enumerate(list(values.get("key_states", []))[:128]):
            self.state.set_key_down(index, bool(value))
        self.state.fft_bins = [max(0, min(255, int(value))) for value in list(values.get("fft_bins", []))[:128]]
        self.state.fft_bins += [0] * (128 - len(self.state.fft_bins))
        self.state.pcm_buffer = [max(-32768, min(32767, int(value))) for value in list(values.get("pcm_buffer", []))[:128]]
        self.state.pcm_buffer += [0] * (128 - len(self.state.pcm_buffer))


def _event_type(value: str) -> int:
    names = {"click": 1, "press": 2, "release": 3, "change": 4, "key_down": 5, "key_up": 6,
             "set": 8, "add": 9, "toggle": 10, "set_key": 11, "clear_key": 12}
    try:
        return int(value, 0)
    except ValueError:
        try:
            return names[value.lower()]
        except KeyError as exc:
            raise argparse.ArgumentTypeError(f"unknown event type: {value}") from exc


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="VerilogQT PC UI host and UART bridge")
    sub = parser.add_subparsers(dest="command", required=True)
    validate = sub.add_parser("validate", help="validate a UI JSON scene")
    validate.add_argument("scene")
    render = sub.add_parser("render", help="render UI JSON on the PC")
    render.add_argument("scene")
    render.add_argument("-o", "--output", required=True)
    send = sub.add_parser("send", help="send UI JSON as scene chunks")
    send.add_argument("scene")
    send.add_argument("--port", required=True)
    send.add_argument("--baud", type=int, default=115200)
    send.add_argument("--timeout", type=float, default=0.1)
    send.add_argument("--chunk-size", type=int, default=512)
    send.add_argument("--ui-new", help="also write a UI_new.json copy before transfer")
    event = sub.add_parser("event", help="send one FPGA UI event")
    event.add_argument("--port", required=True)
    event.add_argument("--baud", type=int, default=115200)
    event.add_argument("--type", required=True, type=_event_type)
    event.add_argument("--id", required=True, type=lambda value: int(value, 0))
    event.add_argument("--value", required=True, type=lambda value: int(value, 0))
    receive = sub.add_parser("receive", help="receive scene/event frames")
    receive.add_argument("--port", required=True)
    receive.add_argument("--baud", type=int, default=115200)
    receive.add_argument("--timeout", type=float, default=5.0)
    receive.add_argument("-o", "--output")
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = build_arg_parser().parse_args(argv)
    if args.command == "validate":
        host = UIHost.from_json(args.scene)
        print(f"OK: {args.scene} ({host.scene.width}x{host.scene.height}, {len(host.scene.widgets)} widgets)")
        return 0
    if args.command == "render":
        host = UIHost.from_json(args.scene)
        host.render(args.output)
        print(f"Rendered {args.scene} -> {args.output}")
        return 0
    host = UIHost.from_json(args.scene) if hasattr(args, "scene") else UIHost()
    try:
        host.connect(args.port, args.baud, min(getattr(args, "timeout", 0.1), 0.1))
        if args.command == "send":
            if args.ui_new:
                host.save_ui_new(args.ui_new)
            count = host.send_scene(chunk_size=args.chunk_size)
            print(f"Sent {count} scene frame(s) to {args.port}")
        elif args.command == "event":
            sequence = host.send_event(args.type, args.id, args.value)
            print(f"Sent event sequence={sequence} to {args.port}")
        else:
            frames = host.receive(args.timeout)
            if args.output and host.last_remote_scene is not None:
                Path(args.output).write_text(json.dumps(host.last_remote_scene, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
            print(f"Received {len(frames)} frame(s) from {args.port}")
    finally:
        host.close()
    return 0


__all__ = ["SerialTransport", "UIHost", "build_arg_parser", "main"]
