#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""最小化测试 InteractivePreviewDialog - 不触发渲染"""

import sys
sys.path.insert(0, 'designer')
sys.path.insert(0, 'generator')

from PySide6.QtWidgets import QApplication, QDialog, QVBoxLayout, QLabel
from PySide6.QtCore import Qt
from designer.ui_schema import UIScene, PanelWidget, ColorRGB

print("Step 1: Create QApplication...")
app = QApplication(sys.argv)
print("OK")

print("Step 2: Create scene...")
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

print("Step 3: Create minimal dialog (without rendering)...")
class MinimalDialog(QDialog):
    def __init__(self, scene, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Minimal Test")
        self.resize(scene.width, scene.height)

        layout = QVBoxLayout()
        label = QLabel("If you see this, Qt initialization works")
        label.setAlignment(Qt.AlignCenter)
        layout.addWidget(label)
        self.setLayout(layout)

dialog = MinimalDialog(scene)
print("OK")

print("Step 4: Show dialog...")
dialog.show()
print("OK - Dialog shown")

sys.exit(app.exec())
