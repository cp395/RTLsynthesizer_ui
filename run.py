#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FPGA UI Designer 启动脚本
Tang Mega 60K HDMI UI 设计工具
"""

import sys
import io

# Force UTF-8 encoding on Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')
import os

# 添加当前目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'designer'))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'generator'))

def check_dependencies():
    """检查依赖"""
    missing = []

    try:
        import PySide6
    except ImportError:
        missing.append('PySide6')

    try:
        import numpy
    except ImportError:
        missing.append('numpy')

    if missing:
        print("缺少依赖包，请运行：")
        print(f"  pip install {' '.join(missing)}")
        print("\n或安装所有依赖：")
        print("  pip install -r requirements.txt")
        return False

    return True

def main():
    import argparse

    parser = argparse.ArgumentParser(description='FPGA UI Designer - Tang Mega 60K HDMI UI 设计工具')
    parser.add_argument('--preview', action='store_true',
                        help='启动交互式预览窗口（测试用）')
    parser.add_argument('--scene', type=str, default=None,
                        help='指定场景文件路径（JSON格式）')

    args = parser.parse_args()

    if not check_dependencies():
        sys.exit(1)

    if args.preview:
        # 启动交互式预览
        print("启动交互式预览...")
        from designer.interactive_preview import InteractivePreviewDialog
        from designer.ui_schema import UIScene, PanelWidget, BarWidget, KnobWidget, ColorRGB
        from PySide6.QtWidgets import QApplication

        # 创建测试场景或加载指定场景
        if args.scene:
            print(f"加载场景: {args.scene}")
            import json
            with open(args.scene, 'r', encoding='utf-8') as f:
                scene_data = json.load(f)
            scene = UIScene.from_dict(scene_data)
        else:
            # 创建默认测试场景
            print("创建默认测试场景...")
            scene = UIScene(
                name="preview_test",
                width=800,
                height=600,
                bg_color=ColorRGB(10, 10, 10)
            )

            # 添加一些测试组件
            scene.widgets.append(PanelWidget(
                name="panel1",
                x=50, y=50, width=300, height=200,
                bg_color=ColorRGB(30, 40, 50),
                border_color=ColorRGB(100, 150, 200),
                border_width=2
            ))

            scene.widgets.append(BarWidget(
                name="bar1",
                x=400, y=50, width=40, height=200,
                source="ui_state[0]",
                bg_color=ColorRGB(20, 25, 30),
                fg_color=ColorRGB(56, 189, 248)
            ))

            scene.widgets.append(KnobWidget(
                name="knob1",
                x=500, y=100, width=80, height=80,
                source="ui_state[1]",
                min_value=0,
                max_value=65535,
                fg_color=ColorRGB(56, 189, 248),
                bg_color=ColorRGB(30, 40, 60),
                pointer_color=ColorRGB(220, 220, 240)
            ))

        # 启动预览窗口
        app = QApplication(sys.argv)
        preview = InteractivePreviewDialog(scene)
        preview.show()
        sys.exit(app.exec())
    else:
        # 导入并启动 UI Designer
        from ui_designer import main as ui_main
        ui_main()

if __name__ == "__main__":
    main()
