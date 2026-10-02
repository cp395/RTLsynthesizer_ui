"""Framing and scene-transfer protocol for the PC-to-FPGA UART link.

The UART itself is intentionally not opened here.  This module only defines
the deterministic byte contract used by a serial adapter, which keeps the
protocol testable without a COM port and lets Qt, asyncio, or a bare pyserial
loop use the same encoder/decoder.

Frame format (little-endian multi-byte fields)::

    SOF(1) | version(1) | message_type(1) | sequence(1) |
    payload_length(2) | payload(N) | CRC16(2)

CRC16-CCITT-FALSE (polynomial 0x1021, initial value 0xFFFF) covers
``version`` through the final payload byte.  The SOF byte is excluded.  The
CRC is transmitted little-endian so all multi-byte fields have one ordering.
"""

from __future__ import annotations

import hashlib
import json
import struct
from dataclasses import dataclass
from enum import IntEnum
from pathlib import Path
from typing import Any, Mapping, Optional, Union


SOF = 0xA5
PROTOCOL_VERSION = 1
MAX_PAYLOAD = 0xFFFF
FRAME_OVERHEAD = 1 + 1 + 1 + 1 + 2 + 2
EVENT_PAYLOAD_SIZE = 4
SCENE_CHUNK_SIZE = 512
MAX_SCENE_BYTES = 1024 * 1024

_HEADER = struct.Struct("<BBBH")
_CRC = struct.Struct("<H")
_EVENT = struct.Struct("<BBH")
_SCENE_BEGIN = struct.Struct("<II32s")
_SCENE_CHUNK_PREFIX = struct.Struct("<I")
_SCENE_COMMIT = struct.Struct("<I32s")


class ProtocolError(ValueError):
    """Raised when a frame or scene transfer violates the wire contract."""


class MessageType(IntEnum):
    """Messages understood by the PC adapter and the FPGA UART endpoint."""

    PING = 0x01
    PONG = 0x02
    EVENT = 0x10
    SCENE_BEGIN = 0x20
    SCENE_CHUNK = 0x21
    SCENE_COMMIT = 0x22
    ACK = 0x80
    NACK = 0x81


@dataclass(frozen=True)
class Frame:
    """Decoded transport frame without SOF or CRC bytes."""

    message_type: int
    sequence: int
    payload: bytes
    version: int = PROTOCOL_VERSION

    def __post_init__(self) -> None:
        if not 0 <= int(self.version) <= 0xFF:
            raise ProtocolError("version must fit in one byte")
        if not 0 <= int(self.message_type) <= 0xFF:
            raise ProtocolError("message_type must fit in one byte")
        if not 0 <= int(self.sequence) <= 0xFF:
            raise ProtocolError("sequence must fit in one byte")
        if not isinstance(self.payload, bytes):
            raise TypeError("payload must be bytes")
        if len(self.payload) > MAX_PAYLOAD:
            raise ProtocolError("payload exceeds the 16-bit frame length")


@dataclass(frozen=True)
class EventMessage:
    """One event matching ``ui_event_cdc``'s source-side event bus."""

    event_type: int
    event_id: int
    event_value: int

    def __post_init__(self) -> None:
        if not 0 <= int(self.event_type) <= 0x0F:
            raise ProtocolError("event_type must fit the FPGA 4-bit field")
        if not 0 <= int(self.event_id) <= 0xFF:
            raise ProtocolError("event_id must fit the FPGA 8-bit field")
        if not 0 <= int(self.event_value) <= 0xFFFF:
            raise ProtocolError("event_value must fit the FPGA 16-bit field")


def crc16_ccitt(data: bytes, initial: int = 0xFFFF) -> int:
    """Return CRC16-CCITT-FALSE for *data*."""

    crc = int(initial) & 0xFFFF
    for byte in data:
        crc ^= byte << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) & 0xFFFF if crc & 0x8000 else (crc << 1) & 0xFFFF
    return crc


def encode_frame(
    message_type: Union[int, MessageType],
    sequence: int,
    payload: bytes = b"",
    *,
    version: int = PROTOCOL_VERSION,
) -> bytes:
    """Encode one frame, including SOF and CRC."""

    if not isinstance(payload, (bytes, bytearray, memoryview)):
        raise TypeError("payload must be a bytes-like object")
    payload_bytes = bytes(payload)
    frame = Frame(int(message_type), int(sequence), payload_bytes, int(version))
    body = _HEADER.pack(frame.version, frame.message_type, frame.sequence, len(frame.payload))
    body += frame.payload
    return bytes((SOF,)) + body + _CRC.pack(crc16_ccitt(body))


def decode_frame(
    encoded: bytes,
    *,
    expected_version: Optional[int] = PROTOCOL_VERSION,
    max_payload: int = MAX_PAYLOAD,
) -> Frame:
    """Decode exactly one frame and validate length, version, and CRC."""

    if not isinstance(encoded, (bytes, bytearray, memoryview)):
        raise TypeError("encoded frame must be bytes-like")
    raw = bytes(encoded)
    if len(raw) < FRAME_OVERHEAD:
        raise ProtocolError("frame is shorter than the fixed overhead")
    if raw[0] != SOF:
        raise ProtocolError(f"invalid SOF 0x{raw[0]:02X}")
    version, message_type, sequence, payload_length = _HEADER.unpack(raw[1:6])
    if payload_length > int(max_payload):
        raise ProtocolError("payload exceeds decoder limit")
    expected_length = FRAME_OVERHEAD + payload_length
    if len(raw) != expected_length:
        raise ProtocolError(
            f"frame length mismatch: expected {expected_length}, got {len(raw)}"
        )
    if expected_version is not None and version != int(expected_version):
        raise ProtocolError(f"unsupported protocol version {version}")
    body = raw[1:-2]
    received_crc = _CRC.unpack(raw[-2:])[0]
    calculated_crc = crc16_ccitt(body)
    if received_crc != calculated_crc:
        raise ProtocolError(
            f"CRC mismatch: received 0x{received_crc:04X}, calculated 0x{calculated_crc:04X}"
        )
    return Frame(message_type, sequence, raw[6:-2], version)


class FrameParser:
    """Incremental parser that resynchronizes after noise or a bad frame."""

    def __init__(
        self,
        *,
        expected_version: Optional[int] = PROTOCOL_VERSION,
        max_payload: int = MAX_PAYLOAD,
    ) -> None:
        if not 0 <= int(max_payload) <= MAX_PAYLOAD:
            raise ValueError("max_payload must fit in the 16-bit length field")
        self.expected_version = expected_version
        self.max_payload = int(max_payload)
        self._buffer = bytearray()

    @property
    def buffered_bytes(self) -> int:
        """Number of bytes currently held while waiting for a complete frame."""

        return len(self._buffer)

    def reset(self) -> None:
        self._buffer.clear()

    def feed(self, data: bytes) -> list[Frame]:
        """Consume arbitrary serial bytes and return all complete frames."""

        if not isinstance(data, (bytes, bytearray, memoryview)):
            raise TypeError("data must be bytes-like")
        self._buffer.extend(data)
        frames: list[Frame] = []
        while True:
            try:
                sof_index = self._buffer.index(SOF)
            except ValueError:
                self._buffer.clear()
                break
            if sof_index:
                del self._buffer[:sof_index]
            if len(self._buffer) < 6:
                break
            payload_length = _HEADER.unpack(self._buffer[1:6])[3]
            if payload_length > self.max_payload:
                # Drop this SOF and search for the next candidate.
                del self._buffer[0]
                continue
            total_length = FRAME_OVERHEAD + payload_length
            if len(self._buffer) < total_length:
                break
            candidate = bytes(self._buffer[:total_length])
            try:
                frame = decode_frame(
                    candidate,
                    expected_version=self.expected_version,
                    max_payload=self.max_payload,
                )
            except ProtocolError:
                # A corrupted candidate must not block later valid frames.
                del self._buffer[0]
                continue
            del self._buffer[:total_length]
            frames.append(frame)
        return frames


def encode_event(
    event_type: int,
    event_id: int,
    event_value: int,
    sequence: int,
) -> bytes:
    """Encode an event for direct connection to the existing event bus."""

    event = EventMessage(int(event_type), int(event_id), int(event_value))
    return encode_frame(
        MessageType.EVENT,
        sequence,
        _EVENT.pack(event.event_type, event.event_id, event.event_value),
    )


def decode_event(frame: Union[Frame, bytes, bytearray, memoryview]) -> EventMessage:
    """Decode an EVENT frame into its type/id/value tuple."""

    decoded = decode_frame(frame) if not isinstance(frame, Frame) else frame
    if decoded.message_type != MessageType.EVENT:
        raise ProtocolError("frame is not an EVENT message")
    if len(decoded.payload) != EVENT_PAYLOAD_SIZE:
        raise ProtocolError("EVENT payload must be exactly 4 bytes")
    return EventMessage(*_EVENT.unpack(decoded.payload))


def scene_to_json(scene: Any) -> bytes:
    """Serialize a UIScene or mapping into deterministic UTF-8 JSON bytes."""

    if hasattr(scene, "to_dict"):
        scene = scene.to_dict()
    if not isinstance(scene, Mapping):
        raise TypeError("scene must be a mapping or expose to_dict()")
    try:
        text = json.dumps(scene, ensure_ascii=True, sort_keys=True, separators=(",", ":"))
    except (TypeError, ValueError) as exc:
        raise ProtocolError(f"scene is not JSON serializable: {exc}") from exc
    return text.encode("utf-8")


def decode_scene_json(data: bytes) -> dict[str, Any]:
    """Decode scene JSON bytes and require a JSON object at the root."""

    try:
        value = json.loads(bytes(data).decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError, TypeError) as exc:
        raise ProtocolError(f"invalid scene JSON: {exc}") from exc
    if not isinstance(value, dict):
        raise ProtocolError("scene JSON root must be an object")
    return value


def _scene_input_bytes(scene: Any) -> bytes:
    if isinstance(scene, (str, Path)):
        return Path(scene).read_bytes()
    return scene_to_json(scene)


def encode_scene_frames(
    scene: Any,
    *,
    revision: int = 0,
    sequence_start: int = 0,
    chunk_size: int = SCENE_CHUNK_SIZE,
) -> list[bytes]:
    """Encode a scene file as BEGIN, CHUNK*, COMMIT frames.

    ``scene`` may be a UIScene, a mapping, or a path to a JSON file.  The JSON
    bytes are sent exactly as loaded for a path, while in-memory scenes use the
    deterministic serializer above.  Chunks are contiguous and carry an
    absolute byte offset, so the FPGA endpoint can write them to a staging
    buffer before validating the final digest.
    """

    raw = _scene_input_bytes(scene)
    if not raw or len(raw) > MAX_SCENE_BYTES:
        raise ProtocolError("scene size must be between 1 byte and 1 MiB")
    # Validate before framing so a malformed UI_new.json never reaches the
    # serial writer.  Keep the original bytes for path inputs so the digest
    # covers exactly what the receiver will stage.
    decode_scene_json(raw)
    if not 0 <= int(revision) <= 0xFFFFFFFF:
        raise ProtocolError("revision must fit in 32 bits")
    if not 1 <= int(chunk_size) <= MAX_PAYLOAD - _SCENE_CHUNK_PREFIX.size:
        raise ValueError("chunk_size is outside the frame payload limit")
    sequence = int(sequence_start) & 0xFF
    digest = hashlib.sha256(raw).digest()
    frames = [
        encode_frame(
            MessageType.SCENE_BEGIN,
            sequence,
            _SCENE_BEGIN.pack(int(revision), len(raw), digest),
        )
    ]
    sequence = (sequence + 1) & 0xFF
    for offset in range(0, len(raw), int(chunk_size)):
        chunk = raw[offset : offset + int(chunk_size)]
        frames.append(
            encode_frame(
                MessageType.SCENE_CHUNK,
                sequence,
                _SCENE_CHUNK_PREFIX.pack(offset) + chunk,
            )
        )
        sequence = (sequence + 1) & 0xFF
    frames.append(
        encode_frame(
            MessageType.SCENE_COMMIT,
            sequence,
            _SCENE_COMMIT.pack(int(revision), digest),
        )
    )
    return frames


class SceneAssembler:
    """Validate and assemble a streamed scene transfer on the PC side."""

    def __init__(self, *, max_scene_bytes: int = MAX_SCENE_BYTES) -> None:
        if not 1 <= int(max_scene_bytes) <= 0xFFFFFFFF:
            raise ValueError("max_scene_bytes must be positive and fit in 32 bits")
        self.max_scene_bytes = int(max_scene_bytes)
        self.reset()

    def reset(self) -> None:
        self.revision: Optional[int] = None
        self.total_length = 0
        self.digest: Optional[bytes] = None
        self._data = bytearray()
        self._received = bytearray()

    @property
    def complete(self) -> bool:
        return bool(self._data) and all(self._received)

    def accept(self, frame: Frame) -> Optional[dict[str, Any]]:
        """Consume a scene frame; return the decoded scene on COMMIT."""

        if frame.message_type == MessageType.SCENE_BEGIN:
            self._accept_begin(frame.payload)
            return None
        if frame.message_type == MessageType.SCENE_CHUNK:
            self._accept_chunk(frame.payload)
            return None
        if frame.message_type == MessageType.SCENE_COMMIT:
            return self._accept_commit(frame.payload)
        raise ProtocolError("frame is not a scene transfer message")

    def _accept_begin(self, payload: bytes) -> None:
        if len(payload) != _SCENE_BEGIN.size:
            raise ProtocolError("SCENE_BEGIN payload has an invalid length")
        revision, total_length, digest = _SCENE_BEGIN.unpack(payload)
        if not 1 <= total_length <= self.max_scene_bytes:
            raise ProtocolError("scene length is outside the configured limit")
        self.revision = revision
        self.total_length = total_length
        self.digest = digest
        self._data = bytearray(total_length)
        self._received = bytearray(total_length)

    def _accept_chunk(self, payload: bytes) -> None:
        if self.digest is None:
            raise ProtocolError("SCENE_CHUNK received before SCENE_BEGIN")
        if len(payload) < _SCENE_CHUNK_PREFIX.size:
            raise ProtocolError("SCENE_CHUNK payload is missing its offset")
        offset = _SCENE_CHUNK_PREFIX.unpack(payload[:4])[0]
        chunk = payload[4:]
        end = offset + len(chunk)
        if not chunk or end > self.total_length:
            raise ProtocolError("SCENE_CHUNK range is outside the announced scene")
        self._data[offset:end] = chunk
        self._received[offset:end] = b"\x01" * len(chunk)

    def _accept_commit(self, payload: bytes) -> dict[str, Any]:
        if self.digest is None:
            raise ProtocolError("SCENE_COMMIT received before SCENE_BEGIN")
        if len(payload) != _SCENE_COMMIT.size:
            raise ProtocolError("SCENE_COMMIT payload has an invalid length")
        revision, digest = _SCENE_COMMIT.unpack(payload)
        if revision != self.revision or digest != self.digest:
            raise ProtocolError("SCENE_COMMIT does not match SCENE_BEGIN")
        if not self.complete:
            raise ProtocolError("SCENE_COMMIT arrived before all chunks")
        actual_digest = hashlib.sha256(self._data).digest()
        if actual_digest != self.digest:
            raise ProtocolError("scene SHA-256 digest mismatch")
        scene = decode_scene_json(bytes(self._data))
        self.reset()
        return scene


__all__ = [
    "EVENT_PAYLOAD_SIZE",
    "FRAME_OVERHEAD",
    "MAX_PAYLOAD",
    "PROTOCOL_VERSION",
    "SOF",
    "EventMessage",
    "Frame",
    "FrameParser",
    "MessageType",
    "ProtocolError",
    "SceneAssembler",
    "crc16_ccitt",
    "decode_event",
    "decode_frame",
    "decode_scene_json",
    "encode_event",
    "encode_frame",
    "encode_scene_frames",
    "scene_to_json",
]
