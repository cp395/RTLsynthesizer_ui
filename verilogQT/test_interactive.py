#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试交互式预览功能
"""

import sys
from pathlib import Path

# 添加模块路径
sys.path.insert(0, str(Path(__file__).parent / 'designer'))
sys.path.insert(0, str(Path(__file__).parent / 'generator'))

from PySide6.QtWidgets import QApplication
from designer.ui_schema import *
from designer.interactive_preview import InteractivePreviewDialog

def create_test_scene():
    """创建测试场景"""
    scene = UIScene(
        name="interactive_test",
        width=1280,
        height=720,
        bg_color=ColorRGB(5, 7, 12)
    )

    # 背景面板
    main_panel = PanelWidget(
        name="main_bg",
        x=0, y=0, width=1280, height=720,
        bg_color=ColorRGB(11, 14, 20),
        border_width=0
    )
    scene.widgets.append(main_panel)

    # 标题面板
    title_panel = PanelWidget(
        name="title_panel",
        x=20, y=20, width=1240, height=60,
        bg_color=ColorRGB(15, 19, 28),
        border_color=ColorRGB(50, 70, 100),
        border_width=2
    )
    scene.widgets.append(title_panel)

    # 标题文本
    title = TextWidget(
        name="title",
        x=40, y=35, width=400, height=30,
        text="Interactive UI Preview",
        font_size=24,
        color=ColorRGB(248, 250, 252)
    )
    scene.widgets.append(title)

    # 旋钮区域
    knob_panel = PanelWidget(
        name="knob_panel",
        x=20, y=100, width=400, height=300,
        bg_color=ColorRGB(15, 19, 28),
        border_color=ColorRGB(50, 70, 100),
        border_width=2
    )
    scene.widgets.append(knob_panel)

    # 添加 6 个旋钮
    knob_positions = [
        (60, 150), (180, 150), (300, 150),
        (60, 280), (180, 280), (300, 280)
    ]
    knob_names = ["Volume", "Pitch", "Filter", "Attack", "Decay", "Release"]

    for i, (x, y) in enumerate(knob_positions):
        # 旋钮标签
        label = TextWidget(
            name=f"knob_label_{i}",
            x=x-30, y=y-30, width=100, height=20,
            text=knob_names[i],
            font_size=12,
            color=ColorRGB(160, 174, 192)
        )
        scene.widgets.append(label)

        # 旋钮
        knob = KnobWidget(
            name=f"knob_{i}",
            x=x, y=y, width=60, height=60,
            source=f"ui_state[{i}]",
            min_value=0,
            max_value=65535,
            fg_color=ColorRGB(56, 189, 248),
            pointer_color=ColorRGB(233, 165, 104),
            bg_color=ColorRGB(30, 41, 59)
        )
        scene.widgets.append(knob)

    # 频谱显示
    spectrum_panel = PanelWidget(
        name="spectrum_panel",
        x=440, y=100, width=400, height=180,
        bg_color=ColorRGB(15, 19, 28),
        border_color=ColorRGB(50, 70, 100),
        border_width=2
    )
    scene.widgets.append(spectrum_panel)

    spectrum_label = TextWidget(
        name="spectrum_label",
        x=460, y=115, width=200, height=20,
        text="Audio Spectrum",
        font_size=14,
        color=ColorRGB(160, 174, 192)
    )
    scene.widgets.append(spectrum_label)

    spectrum = SpectrumWidget(
        name="spectrum",
        x=460, y=145, width=360, height=120,
        source="fft_bins",
        bars=32,
        bg_color=ColorRGB(10, 12, 18),
        bar_color=ColorRGB(56, 189, 248),
        peak_color=ColorRGB(233, 165, 104)
    )
    scene.widgets.append(spectrum)

    # 波形显示
    waveform_panel = PanelWidget(
        name="waveform_panel",
        x=440, y=300, width=400, height=180,
        bg_color=ColorRGB(15, 19, 28),
        border_color=ColorRGB(50, 70, 100),
        border_width=2
    )
    scene.widgets.append(waveform_panel)

    waveform_label = TextWidget(
        name="waveform_label",
        x=460, y=315, width=200, height=20,
        text="Waveform",
        font_size=14,
        color=ColorRGB(160, 174, 192)
    )
    scene.widgets.append(waveform_label)

    waveform = WaveformWidget(
        name="waveform",
        x=460, y=345, width=360, height=120,
        source="pcm_buffer",
        samples=128,
        line_color=ColorRGB(110, 231, 183),
        bg_color=ColorRGB(10, 12, 18),
        line_width=2
    )
    scene.widgets.append(waveform)

    # 进度条区域
    bars_panel = PanelWidget(
        name="bars_panel",
        x=860, y=100, width=400, height=380,
        bg_color=ColorRGB(15, 19, 28),
        border_color=ColorRGB(50, 70, 100),
        border_width=2
    )
    scene.widgets.append(bars_panel)

    bars_label = TextWidget(
        name="bars_label",
        x=880, y=115, width=200, height=20,
        text="Level Meters",
        font_size=14,
        color=ColorRGB(160, 174, 192)
    )
    scene.widgets.append(bars_label)

    # 添加 6 个进度条（对应旋钮）
    for i in range(6):
        y = 150 + i * 55

        # 标签
        label = TextWidget(
            name=f"bar_label_{i}",
            x=880, y=y, width=80, height=20,
            text=knob_names[i],
            font_size=11,
            color=ColorRGB(160, 174, 192)
        )
        scene.widgets.append(label)

        # 进度条
        bar = BarWidget(
            name=f"bar_{i}",
            x=880, y=y+25, width=360, height=20,
            source=f"ui_state[{i}]",
            max_value=65535,
            fg_color=ColorRGB(56, 189, 248),
            bg_color=ColorRGB(30, 41, 59),
            corner_radius=10
        )
        scene.widgets.append(bar)

    # 钢琴键盘
    keyboard_panel = PanelWidget(
        name="keyboard_panel",
        x=20, y=500, width=1240, height=200,
        bg_color=ColorRGB(15, 19, 28),
        border_color=ColorRGB(50, 70, 100),
        border_width=2
    )
    scene.widgets.append(keyboard_panel)

    keyboard_label = TextWidget(
        name="keyboard_label",
        x=40, y=515, width=300, height=20,
        text="Piano Keyboard (click or use ASDFGHJK keys)",
        font_size=14,
        color=ColorRGB(160, 174, 192)
    )
    scene.widgets.append(keyboard_label)

    keyboard = KeyboardWidget(
        name="keyboard",
        x=40, y=545, width=1200, height=140,
        source="key_states",
        keys=88,
        white_key_color=ColorRGB(240, 242, 245),
        black_key_color=ColorRGB(30, 41, 59),
        pressed_color=ColorRGB(56, 189, 248)
    )
    scene.widgets.append(keyboard)

    return scene

if __name__ == "__main__":
    print("启动交互式预览测试...")

    app = QApplication(sys.argv)
    app.setStyle("Fusion")

    scene = create_test_scene()
    print(f"✓ 场景创建完成: {len(scene.widgets)} 个控件")

    dialog = InteractivePreviewDialog(scene)
    print("✓ 交互式预览窗口已打开")
    print("\n操作说明：")
    print("  - 拖动旋钮改变值（向上增加）")
    print("  - 点击钢琴键")
    print("  - 键盘按键: A S D F G H J K 对应琴键")
    print("  - 观察频谱和波形的实时动画")
    print("  - 进度条实时跟随旋钮变化\n")

    dialog.show()
    sys.exit(app.exec())
