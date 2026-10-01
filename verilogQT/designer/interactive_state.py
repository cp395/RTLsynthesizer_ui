#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
交互式状态管理器
管理可变的 UI 状态（旋钮、琴键、动画数据）
"""

import numpy as np
from typing import Dict, Any

try:
    from .ui_schema import (
        FFT_BIN_COUNT,
        FFT_BIN_MIN,
        FFT_BIN_MAX,
        PCM_SAMPLE_COUNT,
        PCM_SAMPLE_MIN,
        PCM_SAMPLE_MAX,
    )
except ImportError:
    from ui_schema import (
        FFT_BIN_COUNT,
        FFT_BIN_MIN,
        FFT_BIN_MAX,
        PCM_SAMPLE_COUNT,
        PCM_SAMPLE_MIN,
        PCM_SAMPLE_MAX,
    )


class InteractiveState:
    """管理可交互的 UI 状态"""

    def __init__(self):
        # 旋钮和滑块值 (0-65535，16位).  FPGA reset uses zero, so the PC
        # preview starts from the same state unless a scene supplies events.
        self.ui_values = [0] * 32
        self.source_indices: Dict[str, int] = {}

        # MIDI 音高状态 (0..127)。这不是物理键盘数量；控件只显示选定窗口。
        self.key_states = [0] * 128

        # 频谱数据（128 个 8 位 bins，用于 FFT 可视化）
        self.fft_bins = [0] * FFT_BIN_COUNT

        # 波形数据（128 个有符号 8 位采样点，用于示波器）
        self.pcm_buffer = [0] * PCM_SAMPLE_COUNT

        # 动画计数器
        self.frame_count = 0

    def set_knob_value(self, index: int, value: int):
        """设置旋钮值

        Args:
            index: 旋钮索引 (0-31)
            value: 值 (0-65535)
        """
        if 0 <= index < len(self.ui_values):
            self.ui_values[index] = max(0, min(65535, value))

    def get_knob_value(self, index: int) -> int:
        """获取旋钮值"""
        if 0 <= index < len(self.ui_values):
            return self.ui_values[index]
        return 0

    def bind_source(self, source: str, index: int):
        """Bind a scene data-source name to one of the flattened state words."""
        if isinstance(source, str) and source.strip() and 0 <= index < len(self.ui_values):
            self.source_indices[source] = index

    def set_source_value(self, source: str, value: int):
        index = self.source_indices.get(source)
        if index is not None:
            self.set_knob_value(index, value)

    def get_state_target(self, target: str) -> int:
        """Read a rule target such as ``ui_state[3]`` or ``key_states[4]``."""
        kind, index = self._parse_target(target)
        if kind == "ui_state":
            return self.ui_values[index]
        if kind == "key_states":
            return self.key_states[index]
        raise ValueError(f"unsupported interaction target: {target}")

    def set_state_target(self, target: str, value: int):
        """Write a rule target with clamping to the FPGA bus width."""
        kind, index = self._parse_target(target)
        if kind == "ui_state":
            self.set_knob_value(index, value)
        elif kind == "key_states":
            self.set_key_down(index, bool(value))
        else:
            raise ValueError(f"unsupported interaction target: {target}")

    def apply_action(self, action: Dict[str, Any], event_value: int = 0):
        """Apply one scene interaction action.

        Supported actions are ``set``, ``add``, ``toggle`` and ``set_key``.
        ``event_value`` is used by ``set_event_value`` when a rule wants the
        value supplied by a knob or keyboard event.
        """
        action_type = str(action.get("action", "set")).lower()
        target = action.get("target", "")
        if action_type == "set_event_key":
            if not 0 <= int(event_value) < len(self.key_states):
                return
            # Match RTL's integer-to-boolean conversion.  In particular,
            # the JSON string "0" must mean false rather than Python's
            # truthy string value.
            key_value = int(action.get("value", 1))
            self.set_key_down(int(event_value), key_value != 0)
            return
        if action_type == "set_event_value":
            value = event_value
        elif action_type == "add":
            value = self.get_state_target(target) + int(action.get("value", 0))
        elif action_type == "toggle":
            value = 0 if self.get_state_target(target) else 1
        elif action_type in ("set", "set_key"):
            value = int(action.get("value", 0))
        else:
            raise ValueError(f"unsupported interaction action: {action_type}")
        self.set_state_target(target, value)

    @staticmethod
    def _parse_target(target: str):
        import re
        match = re.fullmatch(r"\s*(ui_state|key_states)\s*\[\s*(\d+)\s*\]\s*", str(target or ""))
        if not match:
            raise ValueError(f"invalid interaction target: {target}")
        kind = match.group(1)
        index = int(match.group(2))
        limit = 32 if kind == "ui_state" else 128
        if not 0 <= index < limit:
            raise ValueError(f"interaction target index out of range: {target}")
        return kind, index

    def set_key_down(self, key_index: int, pressed: bool):
        """设置琴键状态

        Args:
            key_index: MIDI 音高编号 (0-127)
            pressed: True=按下, False=释放
        """
        if 0 <= key_index < len(self.key_states):
            self.key_states[key_index] = 1 if pressed else 0

    def is_key_pressed(self, key_index: int) -> bool:
        """检查琴键是否按下"""
        if 0 <= key_index < len(self.key_states):
            return self.key_states[key_index] == 1
        return False

    def update_animation(self):
        """更新动画数据（每帧调用）

        模拟动态的频谱和波形数据
        """
        self.frame_count += 1
        t = self.frame_count * 0.05

        # 模拟频谱动画（衰减的振荡）
        self.fft_bins = [
            max(FFT_BIN_MIN, min(FFT_BIN_MAX, int(
                50 + 80 * np.sin(i * 0.1 + t) * np.exp(-i * 0.01)
            )))
            for i in range(FFT_BIN_COUNT)
        ]

        # 模拟波形（正弦波 + 谐波）
        self.pcm_buffer = [
            max(PCM_SAMPLE_MIN, min(PCM_SAMPLE_MAX, int(
                96 * np.sin(i * 0.02 + t) +
                24 * np.sin(i * 0.06 + t * 1.5)
            )))
            for i in range(PCM_SAMPLE_COUNT)
        ]

    def to_dict(self) -> Dict[str, Any]:
        """转换为渲染器需要的格式

        Returns:
            包含所有状态数据的字典
        """
        result = {
            "ui_state": self.ui_values,
            "fft_bins": self.fft_bins,
            "pcm_buffer": self.pcm_buffer,
            "key_states": self.key_states
        }
        for source, index in self.source_indices.items():
            result[source] = self.ui_values[index]
        return result
