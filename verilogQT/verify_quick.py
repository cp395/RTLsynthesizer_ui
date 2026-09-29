#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FPGA UI Designer - 快速验证脚本
"""

import sys
import subprocess
from pathlib import Path

# 强制 UTF-8 输出
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def main():
    print("=" * 60)
    print("FPGA UI Designer - 项目验证")
    print("=" * 60)
    print()

    base_dir = Path(__file__).parent
    passed = 0
    total = 0

    # 1. 关键文件检查
    print("【关键文件】")
    files = [
        "rtl/top_hdmi_tang_mega_60k.v",
        "rtl/ui_top.v",
        "rtl/pixel_renderer.v",
        "rtl/hdmi_timing.v",
        "rtl/Gowin_rPLL.v",
        "rtl/waveform_renderer.v",
        "rtl/keyboard_renderer.v",
        "rtl/knob_renderer.v",
        "rtl/ui_interaction.v",
        "rtl/ui_event_cdc.v",
        "testbench/tb_ui_event_cdc.v",
        "constraints/tang_mega_60k_hdmi.cst",
        "tang_mega_60k_hdmi.gprj",
        "build.tcl"
    ]

    for f in files:
        total += 1
        if (base_dir / f).exists():
            passed += 1
        else:
            print(f"  ❌ 缺失: {f}")

    print(f"  ✅ {passed}/{total} 文件存在")
    print()

    # 2. Python 工具链
    print("【Python 工具链】")
    try:
        sys.path.insert(0, str(base_dir / "designer"))
        from ui_schema import UIScene, ColorRGB
        scene = UIScene(name="test", width=1280, height=720)
        data = scene.to_dict()
        UIScene.from_dict(data)
        ColorRGB(255, 0, 0)
        print("  ✅ Schema 导入和序列化正常")
        passed += 1
    except Exception as e:
        print(f"  ❌ Python 错误: {e}")
    total += 1
    print()

    # 3. 配置一致性
    print("【配置一致性】")

    # 检查器件配置
    gprj = (base_dir / "tang_mega_60k_hdmi.gprj").read_text(encoding='utf-8')
    build_tcl = (base_dir / "build.tcl").read_text(encoding='utf-8')
    cst = (base_dir / "constraints/tang_mega_60k_hdmi.cst").read_text(encoding='utf-8')

    board_config = (base_dir / "board_config.tcl").read_text(encoding='utf-8')
    checks = [
        ('GW5AT-60' in gprj, "gprj 候选器件记录"),
        ('board_config.tcl' in build_tcl and 'require_board_config' in build_tcl,
         "build.tcl 使用硬件配置门禁"),
        ('clk_50mhz' in cst, "约束文件时钟"),
        ('sysv2017' in build_tcl, "SystemVerilog 2017 模式"),
        ('BOARD_CONFIG_CONFIRMED 0' in board_config, "默认禁止未确认硬件构建"),
    ]

    for check, desc in checks:
        total += 1
        if check:
            print(f"  ✅ {desc}")
            passed += 1
        else:
            print(f"  ❌ {desc}")

    print()

    # 总结
    print("=" * 60)
    print(f"静态检查结果: {passed}/{total} 通过")
    print("=" * 60)
    print()

    if passed == total:
        print("✅ 所有静态检查通过（不等于 RTL 综合、时序或硬件验证通过）。")
        print()
        print("【下一步】")
        print("1. 使用 Gowin EDA 打开 tang_mega_60k_hdmi.gprj")
        print("2. 运行综合 (Synthesize)")
        print("3. 运行布局布线 (Place & Route)")
        print("4. 生成 bitstream (.fs 文件)")
        print("5. 使用 Gowin Programmer 烧录到 Tang Mega 60K")
        print()
        print("⚠️  注意: board_config.tcl 默认未确认，约束文件中的 HDMI 管脚仍是示例值")
        print("   请根据 Tang Mega 60K 实际原理图确认管脚分配")
        return 0
    else:
        print(f"❌ {total - passed} 个检查失败")
        return 1

if __name__ == "__main__":
    sys.exit(main())
