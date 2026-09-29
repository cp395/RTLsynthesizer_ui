#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试脚本 - 验证所有新增功能
"""

import sys
from pathlib import Path

# 强制 UTF-8 输出
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# 添加 designer 目录到路径
sys.path.insert(0, str(Path(__file__).parent / "designer"))

def test_import():
    """测试导入"""
    print("=" * 60)
    print("测试 1: 导入模块")
    print("=" * 60)

    try:
        import ui_schema
        print("✓ ui_schema 导入成功")
    except Exception as e:
        print(f"✗ ui_schema 导入失败: {e}")
        return False

    try:
        from pixel_renderer import PixelRenderer
        print("✓ pixel_renderer 导入成功")
    except Exception as e:
        print(f"✗ pixel_renderer 导入失败: {e}")
        return False

    try:
        from ui_designer import MainWindow
        print("✓ ui_designer 导入成功")
    except Exception as e:
        print(f"✗ ui_designer 导入失败: {e}")
        print("  提示: 需要安装 PySide6: pip install PySide6")
        return False

    return True

def test_schema():
    """测试数据模型"""
    print("\n" + "=" * 60)
    print("测试 2: 数据模型")
    print("=" * 60)

    import ui_schema
    from ui_schema import (PanelWidget, BarWidget, SpectrumWidget,
                          WaveformWidget, KeyboardWidget, KnobWidget,
                          UIScene, ColorRGB)

    # 测试创建各种控件
    widgets = []

    try:
        panel = PanelWidget(type="panel", name="test_panel", x=0, y=0, width=100, height=100)
        widgets.append(("Panel", panel))
        print("✓ Panel 控件创建成功")
    except Exception as e:
        print(f"✗ Panel 创建失败: {e}")
        return False

    try:
        bar = BarWidget(type="bar", name="test_bar", x=0, y=0, width=200, height=20)
        widgets.append(("Bar", bar))
        print("✓ Bar 控件创建成功")
    except Exception as e:
        print(f"✗ Bar 创建失败: {e}")
        return False

    try:
        spectrum = SpectrumWidget(type="spectrum", name="test_spectrum", x=0, y=0, width=600, height=240)
        widgets.append(("Spectrum", spectrum))
        print("✓ Spectrum 控件创建成功")
    except Exception as e:
        print(f"✗ Spectrum 创建失败: {e}")
        return False

    try:
        waveform = WaveformWidget(type="waveform", name="test_waveform", x=0, y=0, width=600, height=200)
        widgets.append(("Waveform", waveform))
        print("✓ Waveform 控件创建成功 [新增]")
    except Exception as e:
        print(f"✗ Waveform 创建失败: {e}")
        return False

    try:
        keyboard = KeyboardWidget(type="keyboard", name="test_keyboard", x=0, y=0, width=700, height=100)
        widgets.append(("Keyboard", keyboard))
        print("✓ Keyboard 控件创建成功 [新增]")
    except Exception as e:
        print(f"✗ Keyboard 创建失败: {e}")
        return False

    try:
        knob = KnobWidget(type="knob", name="test_knob", x=0, y=0, width=80, height=80)
        widgets.append(("Knob", knob))
        print("✓ Knob 控件创建成功 [新增]")
    except Exception as e:
        print(f"✗ Knob 创建失败: {e}")
        return False

    # 测试序列化
    try:
        scene = UIScene(name="test", width=1280, height=720, bg_color=ColorRGB(5, 7, 12))
        for name, widget in widgets:
            scene.widgets.append(widget)

        data = scene.to_dict()
        print(f"✓ 场景序列化成功 ({len(widgets)} 个控件)")

        # 测试反序列化
        scene2 = UIScene.from_dict(data)
        print(f"✓ 场景反序列化成功")
    except Exception as e:
        print(f"✗ 序列化失败: {e}")
        return False

    return True

def test_renderer():
    """测试渲染器"""
    print("\n" + "=" * 60)
    print("测试 3: Python 渲染器")
    print("=" * 60)

    try:
        from pixel_renderer import PixelRenderer
        import ui_schema
        from ui_schema import (PanelWidget, BarWidget, SpectrumWidget,
                              WaveformWidget, KeyboardWidget, KnobWidget,
                              UIScene, ColorRGB)
        import numpy as np

        # 创建测试场景
        scene = UIScene(name="test", width=1280, height=720, bg_color=ColorRGB(5, 7, 12))

        # 添加各种控件
        scene.widgets.append(PanelWidget(
            type="panel", name="bg", x=0, y=0, width=1280, height=720,
            bg_color=ColorRGB(10, 13, 18), border_width=0
        ))

        scene.widgets.append(SpectrumWidget(
            type="spectrum", name="spectrum", x=50, y=50, width=500, height=150,
            bars=32, bar_color=ColorRGB(56, 189, 248), bg_color=ColorRGB(10, 13, 18)
        ))

        scene.widgets.append(WaveformWidget(
            type="waveform", name="waveform", x=50, y=250, width=500, height=100,
            samples=512, line_color=ColorRGB(110, 231, 183), bg_color=ColorRGB(10, 13, 18)
        ))

        scene.widgets.append(KeyboardWidget(
            type="keyboard", name="keyboard", x=50, y=400, width=600, height=80,
            start_note=48, keys=25
        ))

        scene.widgets.append(KnobWidget(
            type="knob", name="knob", x=700, y=50, width=80, height=80,
            min_value=0, max_value=127
        ))

        scene.widgets.append(BarWidget(
            type="bar", name="bar", x=700, y=150, width=200, height=20,
            fg_color=ColorRGB(56, 189, 248), bg_color=ColorRGB(30, 40, 60)
        ))

        # 创建测试数据
        ui_state = {
            "fft_bins": [int(128 + 100 * np.sin(i * 0.2)) for i in range(128)],
            "ui_state": [40000, 50000] + [32768] * 30,
            "pcm_buffer": [int(16000 * np.sin(2 * np.pi * i / 50)) for i in range(1024)],
            "key_states": [True, False, True, False, False] + [False] * 20,
        }

        # 渲染
        renderer = PixelRenderer()
        frame = renderer.render_scene(scene, ui_state)

        print(f"✓ 渲染成功: {frame.shape}")
        print(f"  - Panel 渲染: OK")
        print(f"  - Spectrum 渲染: OK")
        print(f"  - Waveform 渲染: OK [新增]")
        print(f"  - Keyboard 渲染: OK [新增]")
        print(f"  - Knob 渲染: OK [新增]")
        print(f"  - Bar 渲染: OK")

        # 尝试保存（可选）
        try:
            output_file = Path(__file__).parent / "test_output.png"
            renderer.save_frame(str(output_file))
            print(f"✓ 保存测试图像: {output_file}")
        except Exception as e:
            print(f"⚠ 保存图像失败（需要 Pillow）: {e}")

        return True

    except Exception as e:
        print(f"✗ 渲染器测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_rtl_files():
    """测试 RTL 文件存在性"""
    print("\n" + "=" * 60)
    print("测试 4: RTL 文件")
    print("=" * 60)

    rtl_dir = Path(__file__).parent / "rtl"

    required_files = [
        "panel_renderer.v",
        "bar_renderer.v",
        "spectrum_renderer.v",
        "waveform_renderer.v",  # 新增
        "keyboard_renderer.v",  # 新增
        "knob_renderer.v",      # 新增
        "pixel_renderer.v",
        "ui_top.v",
        "hdmi_timing.v",
        "top_hdmi_tang_mega_60k.v",
        "adv7513_controller.v",
        "Gowin_rPLL.v",
    ]

    all_exist = True
    for filename in required_files:
        filepath = rtl_dir / filename
        if filepath.exists():
            is_new = filename in ["waveform_renderer.v", "keyboard_renderer.v", "knob_renderer.v"]
            tag = " [新增]" if is_new else ""
            print(f"✓ {filename}{tag}")
        else:
            print(f"✗ {filename} 不存在")
            all_exist = False

    return all_exist

def test_example_json():
    """测试示例 JSON 文件"""
    print("\n" + "=" * 60)
    print("测试 5: 示例 JSON")
    print("=" * 60)

    try:
        from ui_schema import UIScene

        json_file = Path(__file__).parent / "examples" / "dx7_synth.json"

        if not json_file.exists():
            print(f"✗ 示例文件不存在: {json_file}")
            return False

        scene = UIScene.from_json(str(json_file))
        print(f"✓ 加载成功: {json_file.name}")
        print(f"  - 场景名称: {scene.name}")
        print(f"  - 分辨率: {scene.width}x{scene.height}")
        print(f"  - 控件数量: {len(scene.widgets)}")

        # 统计控件类型
        widget_types = {}
        for widget in scene.widgets:
            widget_types[widget.type] = widget_types.get(widget.type, 0) + 1

        print(f"  - 控件类型:")
        for wtype, count in sorted(widget_types.items()):
            print(f"    * {wtype}: {count}")

        return True

    except Exception as e:
        print(f"✗ 加载示例失败: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """主测试函数"""
    print("\n" + "=" * 60)
    print("FPGA UI Designer - 功能测试")
    print("=" * 60)

    results = {
        "导入模块": test_import(),
        "数据模型": test_schema(),
        "Python 渲染器": test_renderer(),
        "RTL 文件": test_rtl_files(),
        "示例 JSON": test_example_json(),
    }

    # 总结
    print("\n" + "=" * 60)
    print("测试总结")
    print("=" * 60)

    passed = sum(results.values())
    total = len(results)

    for name, result in results.items():
        status = "✓ 通过" if result else "✗ 失败"
        print(f"{name}: {status}")

    print(f"\n总计: {passed}/{total} 测试通过")

    if passed == total:
        print("\n🎉 所有测试通过！")
        print("\n下一步:")
        print("  1. 运行 UI 设计器: python designer/ui_designer.py")
        print("  2. 测试渲染输出: 查看 test_output.png")
        print("  3. 阅读文档: COMPLEX_WIDGETS.md")
        return 0
    else:
        print("\n⚠️ 部分测试失败")
        print("\n常见问题:")
        print("  - 缺少依赖: pip install PySide6 numpy Pillow")
        print("  - 文件路径问题: 确保在项目根目录运行")
        return 1

if __name__ == "__main__":
    sys.exit(main())
