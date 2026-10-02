#!/usr/bin/env python3
"""Unit tests for the PC-side UART framing and scene transfer contract."""

from __future__ import annotations

import hashlib
import random
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from host.uart_protocol import (  # noqa: E402
    FrameParser,
    MessageType,
    ProtocolError,
    SceneAssembler,
    decode_event,
    decode_frame,
    encode_event,
    encode_frame,
    encode_scene_frames,
    scene_to_json,
)


def test_event_roundtrip() -> None:
    raw = encode_event(4, 0xA5, 0xBEEF, 255)
    frame = decode_frame(raw)
    assert frame.message_type == MessageType.EVENT
    assert frame.sequence == 255
    assert decode_event(frame).event_type == 4
    assert decode_event(frame).event_id == 0xA5
    assert decode_event(frame).event_value == 0xBEEF


def test_parser_handles_fragments_noise_and_bad_crc() -> None:
    first = encode_frame(MessageType.PING, 1, b"hello")
    second = encode_frame(MessageType.PONG, 2, b"world")
    bad = bytearray(encode_frame(MessageType.EVENT, 3, b"1234"))
    bad[-1] ^= 0xFF
    stream = b"\x00\x7f" + first + bytes(bad) + b"\x11" + second
    parser = FrameParser()
    frames = []
    rng = random.Random(7)
    while stream:
        count = min(len(stream), rng.randint(1, 5))
        frames.extend(parser.feed(stream[:count]))
        stream = stream[count:]
    assert [(f.message_type, f.sequence, f.payload) for f in frames] == [
        (MessageType.PING, 1, b"hello"),
        (MessageType.PONG, 2, b"world"),
    ]
    assert parser.buffered_bytes == 0


def test_decode_rejects_corruption_and_wrong_shape() -> None:
    raw = encode_event(1, 2, 3, 4)
    with_bad_crc = bytearray(raw)
    with_bad_crc[-2] ^= 1
    try:
        decode_frame(with_bad_crc)
    except ProtocolError as exc:
        assert "CRC" in str(exc)
    else:
        raise AssertionError("bad CRC was accepted")
    with_wrong_payload = encode_frame(MessageType.EVENT, 0, b"x")
    try:
        decode_event(with_wrong_payload)
    except ProtocolError as exc:
        assert "exactly 4" in str(exc)
    else:
        raise AssertionError("short EVENT payload was accepted")


def test_scene_frames_reassemble_with_wrapped_sequence() -> None:
    scene = {
        "name": "uart-demo",
        "width": 1280,
        "height": 720,
        "widgets": [{"type": "panel", "x": 0, "y": 0}],
        "interactions": [],
    }
    frames = [decode_frame(raw) for raw in encode_scene_frames(
        scene, revision=17, sequence_start=254, chunk_size=19
    )]
    assert frames[0].message_type == MessageType.SCENE_BEGIN
    assert frames[-1].message_type == MessageType.SCENE_COMMIT
    assert frames[0].sequence == 254
    assert frames[1].sequence == 255
    assert frames[2].sequence == 0
    assembler = SceneAssembler()
    result = None
    for frame in frames:
        result = assembler.accept(frame) or result
    assert result == scene
    assert assembler.digest is None


def test_scene_transfer_rejects_missing_chunk_and_bad_digest() -> None:
    scene = {"name": "x", "widgets": []}
    frames = [decode_frame(raw) for raw in encode_scene_frames(scene, chunk_size=2)]
    assembler = SceneAssembler()
    assembler.accept(frames[0])
    # Skip one middle chunk; COMMIT must not publish an incomplete scene.
    for frame in frames[1:-2]:
        assembler.accept(frame)
    try:
        assembler.accept(frames[-1])
    except ProtocolError as exc:
        assert "all chunks" in str(exc)
    else:
        raise AssertionError("incomplete scene was committed")

    assembler = SceneAssembler()
    assembler.accept(frames[0])
    for frame in frames[1:]:
        if frame.message_type == MessageType.SCENE_CHUNK:
            assembler.accept(frame)
    bad_commit = encode_frame(
        MessageType.SCENE_COMMIT,
        0,
        struct.pack("<I32s", assembler.revision, hashlib.sha256(b"bad").digest()),
    )
    try:
        assembler.accept(decode_frame(bad_commit))
    except ProtocolError as exc:
        assert "match" in str(exc)
    else:
        raise AssertionError("bad scene digest was accepted")


def test_scene_json_is_deterministic_and_utf8() -> None:
    first = scene_to_json({"b": "中文", "a": 1})
    second = scene_to_json({"a": 1, "b": "中文"})
    assert first == second
    assert first == b'{"a":1,"b":"\\u4e2d\\u6587"}'


if __name__ == "__main__":
    tests = [value for name, value in globals().items() if name.startswith("test_")]
    for test in tests:
        test()
    print(f"PASS: {len(tests)} UART protocol tests")
