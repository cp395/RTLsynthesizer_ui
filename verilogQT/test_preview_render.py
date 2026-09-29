#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""测试包含渲染器的预览"""

import sys
sys.path.insert(0, 'designer')
sys.path.insert(0, 'generator')

from PySide6.QtWidgets import QApplication, QDialog, QVBoxLayout, QLabel
from PySide6.QtGui import QImage, QPixmap
from designer.ui_schema import UIScene, PanelWidget, ColorRGB
from designer.pixel_renderer import PixelRenderer
from designer.interactive_state import InteractiveState

print("Step 1: Create QApplication...")
app = QApplication(sys.argv)
print("OK")

print("Step 2: Create scene with widget...")
scene = UIScene(
    name="test",
    width=800,
    height=600,
    bg_color=ColorRGB(10, 10, 10)
)
scene.widgets.append(PanelWidget(
    name="panel1",
    x=50, y=50, width=300, height=200,
    bg_color=ColorRGB(30, 40, 50),
    border_color=ColorRGB(100, 150, 200),
    border_width=2
))
print("OK")

print("Step 3: Create renderer...")
renderer = PixelRenderer(scene.width, scene.height)
print("OK")

print("Step 4: Create state...")
state = InteractiveState()
print("OK")

print("Step 5: Render frame...")
frame = renderer.render_scene(scene, state.to_dict())
print(f"OK - Frame shape: {frame.shape}")

print("Step 6: Convert to QImage...")
height, width, channels = frame.shape
bytes_per_line = channels * width
qimage = QImage(frame.data, width, height, bytes_per_line, QImage.Format_RGB888)
print("OK")

print("Step 7: Create dialog and show...")
dialog = QDialog()
dialog.setWindowTitle("Render Test")
dialog.resize(840, 680)

layout = QVBoxLayout()
canvas = QLabel()
pixmap = QPixmap.fromImage(qimage)
canvas.setPixmap(pixmap)
layout.addWidget(canvas)
dialog.setLayout(layout)

dialog.show()
print("OK - Dialog shown with rendered frame")

sys.exit(app.exec())
