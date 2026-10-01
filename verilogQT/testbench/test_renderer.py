"""
Testbench for UI Renderer
仿真验证像素渲染器
"""

import sys
from pathlib import Path
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent.parent / "designer"))
sys.path.insert(0, str(Path(__file__).parent.parent / "examples"))

from ui_schema import *
from pixel_renderer import PixelRenderer
from generate_dx7_rtl import load_scene_from_json


def generate_test_frame():
    """生成测试帧"""
    # 加载场景
    json_path = Path(__file__).parent.parent / "examples" / "dx7_synth.json"
    scene = load_scene_from_json(json_path)

    # 创建渲染器
    renderer = PixelRenderer(scene.width, scene.height)

    # 模拟 UI 状态
    ui_state = {
        # FFT bins - 模拟频谱数据
        "fft_bins": [
            int(128 + 100 * np.sin(i * 0.15) * np.exp(-i * 0.01))
            for i in range(128)
        ],

        # Operator levels (0~100)
        "op1_level": 82,
        "op2_level": 55,
        "op3_level": 32,
        "op4_level": 67,
        "op5_level": 16,
        "op6_level": 75,

        # PCM waveform - 模拟正弦波
        "pcm_buffer": [
            int(100 * np.sin(i * 0.02)) for i in range(128)
        ],

        # Keyboard states - 假设按下 C4, E4, G4
        "key_states": [0] * 128
    }
    ui_state["key_states"][60] = 1  # C4
    ui_state["key_states"][64] = 1  # E4
    ui_state["key_states"][67] = 1  # G4

    # 渲染
    print("Rendering frame...")
    frame = renderer.render_scene(scene, ui_state)

    # 保存为 PNG
    output_path = Path(__file__).parent / "reference_frame.png"
    img = Image.fromarray(frame, mode='RGB')
    img.save(output_path)

    print(f"[OK] Saved reference frame to {output_path}")
    print(f"  Resolution: {scene.width}x{scene.height}")
    print(f"  Widgets: {len(scene.widgets)}")

    return frame, scene, ui_state


def compare_with_rtl_simulation():
    """
    TODO: 与 RTL 仿真结果比较
    需要 Verilog 仿真器 (iverilog/ModelSim/Verilator)
    """
    print("\nRTL comparison:")
    print("  To compare with RTL simulation:")
    print("  1. Run Verilog testbench (tb_pixel_renderer.v)")
    print("  2. Dump RGB values to file")
    print("  3. Compare pixel-by-pixel with reference_frame.png")
    print("  4. Report any mismatches")


def generate_test_patterns():
    """生成多种测试图案"""
    test_scenes = {
        "bars_only": UIScene(name="bars_test", width=1280, height=720),
        "spectrum_only": UIScene(name="spectrum_test", width=1280, height=720),
    }

    # Bars test
    scene = test_scenes["bars_only"]
    for i in range(6):
        scene.widgets.append(BarWidget(
            x=100,
            y=100 + i * 40,
            width=400,
            height=20,
            source=f"bar_{i}",
            name=f"bar_{i}"
        ))

    # Spectrum test
    scene = test_scenes["spectrum_only"]
    scene.widgets.append(SpectrumWidget(
        x=100, y=100, width=800, height=400,
        bars=64,
        name="spectrum"
    ))

    return test_scenes


def main():
    print("=" * 60)
    print("FPGA UI Designer - Reference Renderer Test")
    print("=" * 60)
    print()

    # 生成参考帧
    frame, scene, ui_state = generate_test_frame()

    # 统计信息
    print("\nScene statistics:")
    print(f"  Background: RGB({scene.bg_color.r}, {scene.bg_color.g}, {scene.bg_color.b})")

    widget_counts = {}
    for w in scene.widgets:
        widget_counts[w.type] = widget_counts.get(w.type, 0) + 1

    print(f"  Widget types:")
    for wtype, count in widget_counts.items():
        print(f"    - {wtype}: {count}")

    # RTL 比较提示
    compare_with_rtl_simulation()

    print("\n" + "=" * 60)
    print("Test complete!")


if __name__ == "__main__":
    main()
