#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""最小 Qt 测试"""

import sys
from PySide6.QtWidgets import QApplication, QDialog, QLabel, QVBoxLayout

def test_minimal_qt():
    """测试最基本的 Qt 窗口"""
    print("Step 1: Create QApplication...")
    app = QApplication(sys.argv)
    print("OK - QApplication created")

    print("Step 2: Create dialog...")
    dialog = QDialog()
    dialog.setWindowTitle("Test")
    dialog.resize(400, 300)
    print("OK - Dialog created")

    print("Step 3: Add layout...")
    layout = QVBoxLayout()
    label = QLabel("Test Label")
    layout.addWidget(label)
    dialog.setLayout(layout)
    print("OK - Layout added")

    print("Step 4: Show dialog...")
    dialog.show()
    print("OK - Dialog shown")

    print("Step 5: Starting event loop (close window to exit)...")
    return app.exec()

if __name__ == "__main__":
    sys.exit(test_minimal_qt())
