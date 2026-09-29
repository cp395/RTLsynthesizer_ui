#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试预览功能
"""

import sys
import numpy as np
from pathlib import Path

# 添加模块路径
sys.path.insert(0, str(Path(__file__).parent / 'designer'))
sys.path.insert(0, str(Path(__file__).parent / 'generator'))

from designer.ui_schema import *
from designer.pixel_renderer import PixelRenderer

def test_basic_preview():
    """测试基本预览功能"""
    print("创建测试场景...")

    # 创建场景
    scene = UIScene(
        name="test_scene",
        width=1280,
        height=720,
        bg_color=ColorRGB(5, 7, 12)
    )

    # 添加面板
    panel = PanelWidget(
        type="panel",
        name="main_panel",
        x=50, y=50, width=400, height=300,
        bg_color=ColorRGB(15, 19, 28),
        border_color=ColorRGB(50, 70, 100),
        border_width=2
    )
    scene.widgets.append(panel)

    # 添加文本
    text = TextWidget(
        type="text",
        name="title",
        x=100, y=100, width=200, height=30,
        text="Hello FPGA!",
        font_size=24,
        color=ColorRGB(200, 210, 230)
    )
    scene.widgets.append(text)

    # 添加进度条
    bar = BarWidget(
        type="bar",
        name="level_bar",
        x=100, y=150, width=300, height=20,
        source="ui_state[0]",
        max_value=65535,
        fg_color=ColorRGB(56, 189, 248),
        bg_color=ColorRGB(30, 40, 60)
    )
    scene.widgets.append(bar)

    # 添加频谱
    spectrum = SpectrumWidget(
        type="spectrum",
        name="audio_spectrum",
        x=100, y=200, width=300, height=120,
        source="fft_bins",
        bars=32,
        bg_color=ColorRGB(10, 12, 18),
        bar_color=ColorRGB(56, 189, 248)
    )
    scene.widgets.append(spectrum)

    print("创建渲染器...")
    renderer = PixelRenderer()

    # 创建测试状态
    ui_state = {
        "ui_state": [40000] + [32768] * 31,  # 第一个条 ~60%
        "fft_bins": [int(100 + 80 * np.sin(i * 0.2)) for i in range(128)],
        "pcm_buffer": [0] * 1024,
        "key_states": [0] * 88
    }

    print("渲染场景...")
    frame = renderer.render_scene(scene, ui_state)

    print(f"✓ 渲染完成: {frame.shape}")
    print(f"  - 分辨率: {frame.shape[1]}x{frame.shape[0]}")
    print(f"  - 通道数: {frame.shape[2]}")
    print(f"  - 数据类型: {frame.dtype}")

    # 保存为 PNG
    try:
        from PIL import Image
        img = Image.fromarray(frame)
        output_path = Path(__file__).parent / "test_preview.png"
        img.save(output_path)
        print(f"✓ 预览图已保存: {output_path}")
    except ImportError:
        print("⚠ PIL 未安装，跳过保存图片")

    return True

if __name__ == "__main__":
    try:
        test_basic_preview()
        print("\n✓ 测试通过！预览功能正常工作。")
    except Exception as e:
        print(f"\n✗ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
