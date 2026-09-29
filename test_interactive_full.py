#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""测试完整的 InteractivePreviewDialog"""

import sys
sys.path.insert(0, 'designer')
sys.path.insert(0, 'generator')

from PySide6.QtWidgets import QApplication
from designer.ui_schema import UIScene, PanelWidget, BarWidget, KnobWidget, ColorRGB
from designer.interactive_preview import InteractivePreviewDialog

print("Step 1: Create QApplication...")
app = QApplication(sys.argv)
print("OK")

print("Step 2: Create scene with widgets...")
scene = UIScene(
    name="test_interactive",
    width=800,
    height=600,
    bg_color=ColorRGB(10, 10, 10)
)

# 添加面板
scene.widgets.append(PanelWidget(
    name="panel1",
    x=50, y=50, width=300, height=200,
    bg_color=ColorRGB(30, 40, 50),
    border_color=ColorRGB(100, 150, 200),
    border_width=2
))

# 添加条形图
scene.widgets.append(BarWidget(
    name="bar1",
    x=400, y=100, width=30, height=150,
    source="value",
    max_value=100,
    fg_color=ColorRGB(0, 200, 100),
    bg_color=ColorRGB(20, 20, 20)
))

# 添加旋钮
scene.widgets.append(KnobWidget(
    name="knob1",
    x=500, y=100, width=80, height=80,
    source="knob_value",
    min_value=0,
    max_value=127,
    fg_color=ColorRGB(100, 150, 200),
    bg_color=ColorRGB(30, 30, 30),
    pointer_color=ColorRGB(255, 100, 0)
))

print("OK")

print("Step 3: Create InteractivePreviewDialog...")
preview = InteractivePreviewDialog(scene)
print("OK")

print("Step 4: Show dialog...")
preview.show()
print("OK - Dialog shown, starting event loop...")

sys.exit(app.exec())
