#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""逐步测试 InteractivePreviewDialog"""

import sys
sys.path.insert(0, 'designer')
sys.path.insert(0, 'generator')

from PySide6.QtWidgets import QApplication, QDialog, QVBoxLayout, QLabel
from designer.ui_schema import UIScene, ColorRGB

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
print("OK")

print("Step 3: Create dialog (no renderer yet)...")
dialog = QDialog()
dialog.setWindowTitle("Test Preview")
dialog.resize(840, 680)
print("OK")

print("Step 4: Add simple layout...")
layout = QVBoxLayout()
label = QLabel("Scene created successfully")
layout.addWidget(label)
dialog.setLayout(layout)
print("OK")

print("Step 5: Show dialog...")
dialog.show()
print("OK - Dialog shown, starting event loop...")

sys.exit(app.exec())
