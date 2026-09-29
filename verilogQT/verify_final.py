#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
最终验证总结
"""

import sys
import subprocess
from pathlib import Path

# 强制 UTF-8 输出
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def main():
    print("=" * 70)
    print("FPGA UI Designer - 最终验证总结")
    print("=" * 70)
    print()

    base_dir = Path(__file__).parent

    print("【已记录的代码修改（仍需综合验证）】")
    print("✅ 1. knob_renderer.v - 添加 rel_x, rel_y 变量声明")
    print("✅ 2. hdmi_timing.v - 修复 de 信号驱动（之前未连接）")
    print("✅ 3. pixel_renderer.v - 修复 knob 位宽不匹配（16位 vs 7位）")
    print("✅ 4. adv7513_controller.v - 更新为 50MHz 时钟和正确的 I2C 分频")
    print("✅ 5. adv7513_controller.v - 删除重复的代码块")
    print("✅ 6. test_features.py - 修复函数内 'import *' 语法错误")
    print("✅ 7. Gowin_rPLL.v - 添加 lock 输出端口")
    print()

    print("【配置统一】")
    print("✅ 器件: GW5AT-60K (build.tcl 和 gprj)")
    print("✅ 时钟: clk_50mhz (约束文件和顶层)")
    print("⚠️  PLL 目标：50MHz → 74.25MHz（参数和时序尚未由 Gowin EDA 验证）")
    print("✅ Verilog 标准: SystemVerilog 2017")
    print("✅ 构建脚本: 包含所有渲染器模块")
    print()

    print("【RTL 语法验证】")
    rtl_dir = base_dir / "rtl"
    try:
        # Reuse the real verifier in a subprocess so its console encoding
        # setup cannot replace this script's stdout stream.
        result = subprocess.run(
            [sys.executable, str(base_dir / "verify_real.py")],
            cwd=base_dir,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=45,
        )
        if result.returncode == 0:
            print("✅ RTL 结构检查通过（临时 rPLL stub）")
        else:
            print("❌ RTL 结构检查失败")
            print(result.stdout[-2000:])
            print(result.stderr[-2000:])
    except Exception as e:
        print(f"⚠️  语法检查异常: {e}")

    print()

    print("【已知限制】")
    print("⚠️  1. HDMI 管脚仍是示例值 - 需根据实际原理图确认")
    print("⚠️  2. PLL 参数可能需要微调 - 使用 Gowin PLL Wizard 生成精确配置")
    print("⚠️  3. Text 控件仅占位 - 需要字体 ROM 才能真正渲染文本")
    print("⚠️  4. RTL 生成器仅生成 ui_top.v 和 pixel_renderer.v")
    print()

    print("=" * 70)
    print("⚠️ 项目尚未证明可综合：需要 Gowin EDA、有效 License、正确 PLL 和真实管脚约束。")
    print("=" * 70)
    print()

    print("【下一步操作】")
    print()
    print("1. 打开 Gowin EDA")
    print("   - 加载工程: tang_mega_60k_hdmi.gprj")
    print()
    print("2. 运行综合")
    print("   - Synthesize (F5)")
    print("   - 检查是否有错误")
    print()
    print("3. 运行布局布线")
    print("   - Place & Route")
    print("   - 检查时序是否收敛")
    print()
    print("4. 生成 Bitstream")
    print("   - Program Device → Generate Bitstream")
    print("   - 生成 impl/pnr/fpga_ui_60k.fs")
    print()
    print("5. 烧录到板卡")
    print("   - 使用 Gowin Programmer")
    print("   - 连接 Tang Mega 60K")
    print("   - 加载 .fs 文件")
    print("   - Program")
    print()
    print("【重要提醒】")
    print("在烧录前，请确认约束文件中的 HDMI 管脚与您的板卡实际连接一致！")
    print()

if __name__ == "__main__":
    main()
