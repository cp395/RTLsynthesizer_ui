#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
简单测试：验证模块导入
"""

import sys
import io

# Force UTF-8 encoding on Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

from pathlib import Path

# 添加模块路径
sys.path.insert(0, str(Path(__file__).parent / 'designer'))
sys.path.insert(0, str(Path(__file__).parent / 'generator'))

print("1. 测试基本导入...")
try:
    from designer.ui_schema import *
    print("   ✓ ui_schema 导入成功")
except Exception as e:
    print(f"   ✗ ui_schema 导入失败: {e}")
    sys.exit(1)

print("\n2. 测试 PySide6 导入...")
try:
    from PySide6.QtWidgets import QApplication
    print("   ✓ PySide6 导入成功")
except Exception as e:
    print(f"   ✗ PySide6 导入失败: {e}")
    sys.exit(1)

print("\n3. 测试 numpy 导入...")
try:
    import numpy as np
    print("   ✓ numpy 导入成功")
except Exception as e:
    print(f"   ✗ numpy 导入失败: {e}")
    sys.exit(1)

print("\n4. 测试 interactive_state 导入...")
try:
    from designer.interactive_state import InteractiveState
    print("   ✓ interactive_state 导入成功")
except Exception as e:
    print(f"   ✗ interactive_state 导入失败: {e}")
    sys.exit(1)

print("\n5. 测试 pixel_renderer 导入...")
try:
    from designer.pixel_renderer import PixelRenderer
    print("   ✓ pixel_renderer 导入成功")
except Exception as e:
    print(f"   ✗ pixel_renderer 导入失败: {e}")
    sys.exit(1)

print("\n6. 测试 interactive_preview 导入...")
try:
    from designer.interactive_preview import InteractivePreviewDialog
    print("   ✓ interactive_preview 导入成功")
except Exception as e:
    print(f"   ✗ interactive_preview 导入失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n7. 创建测试场景...")
try:
    scene = UIScene(
        name="test",
        width=800,
        height=600,
        bg_color=ColorRGB(10, 10, 10)
    )

    panel = PanelWidget(
        name="test_panel",
        x=100, y=100, width=200, height=200,
        bg_color=ColorRGB(30, 40, 50)
    )
    scene.widgets.append(panel)

    print(f"   ✓ 场景创建成功: {len(scene.widgets)} 个控件")
except Exception as e:
    print(f"   ✗ 场景创建失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n8. 测试渲染器...")
try:
    renderer = PixelRenderer(800, 600)
    state = InteractiveState()
    frame = renderer.render_scene(scene, state.to_dict())
    print(f"   ✓ 渲染成功: {frame.shape}")
except Exception as e:
    print(f"   ✗ 渲染失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n✓ 所有模块测试通过！")
print("\n现在尝试启动 GUI...")

try:
    app = QApplication(sys.argv)
    print("✓ QApplication 创建成功")

    dialog = InteractivePreviewDialog(scene)
    print("✓ InteractivePreviewDialog 创建成功")

    dialog.show()
    print("✓ 窗口显示成功")
    print("\n交互式预览窗口已打开。关闭窗口退出。")

    sys.exit(app.exec())
except Exception as e:
    print(f"✗ GUI 启动失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
