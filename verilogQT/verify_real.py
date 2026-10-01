#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Local structural verification script
Check project integrity and report syntax/elaboration status without claiming
Gowin synthesis or hardware validation.
"""

import sys
import subprocess
import tempfile
import re
from pathlib import Path

# Prefer UTF-8 without replacing the process streams.  Re-wrapping an
# existing TextIOWrapper can close the original stream while it is still in
# use by a test runner or IDE.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

def check_file(path: Path, description: str) -> bool:
    """检查文件是否存在"""
    if not path.exists():
        print(f"❌ {description}: {path} 不存在")
        return False
    print(f"✅ {description}: {path}")
    return True

PLLG_STUB = r'''
// Simulation-only replacement for the Gowin PLLG primitive.  It deliberately
// models lock and clock forwarding only; it does not validate PLL settings.
module PLLG #(
    parameter FCLKIN = "50",
    parameter IDIV_SEL = 0,
    parameter FBDIV_SEL = 0,
    parameter ODIV0_SEL = 0,
    parameter CLKFB_SEL = "internal",
    parameter DEVICE = "GW5AT-60"
) (
    output wire CLKOUT0,
    output wire CLKOUT0N,
    output wire CLKOUT1,
    output wire CLKOUT1N,
    output wire CLKOUT2,
    output wire CLKOUT2N,
    output wire CLKOUT3,
    output wire CLKOUT3N,
    output wire CLKOUT4,
    output wire CLKOUT5,
    output wire LOCK,
    output wire CLKFBOUT,
    output wire CLKFBOUTN,
    input wire CLKIN,
    input wire CLKFB,
    input wire [5:0] IDSEL,
    input wire [5:0] FBDSEL,
    input wire [5:0] FBODSEL,
    input wire [2:0] FBODSEL_FRAC,
    input wire [5:0] ODSEL0,
    input wire [2:0] ODSEL0_FRAC,
    input wire [5:0] ODSEL1,
    input wire [5:0] ODSEL2,
    input wire [5:0] ODSEL3,
    input wire [5:0] ODSEL4,
    input wire [5:0] ODSEL5,
    input wire [3:0] PSFB,
    input wire [7:0] FPSFB,
    input wire [3:0] PS0,
    input wire [7:0] FPS0,
    input wire [3:0] DUTY0,
    input wire [7:0] FDUTY0,
    input wire [3:0] PS1,
    input wire [7:0] FPS1,
    input wire [3:0] DUTY1,
    input wire [7:0] FDUTY1,
    input wire [3:0] PS2,
    input wire [7:0] FPS2,
    input wire [3:0] DUTY2,
    input wire [7:0] FDUTY2,
    input wire [3:0] PS3,
    input wire [7:0] FPS3,
    input wire [3:0] DUTY3,
    input wire [7:0] FDUTY3,
    input wire [3:0] PS4,
    input wire [7:0] FPS4,
    input wire [3:0] DUTY4,
    input wire [7:0] FDUTY4,
    input wire [3:0] PS5,
    input wire [7:0] FPS5,
    input wire [3:0] DUTY5,
    input wire [7:0] FDUTY5,
    input wire RESET,
    input wire PLLPWD
);
    assign CLKOUT0 = CLKIN;
    assign CLKOUT0N = 1'b0;
    assign CLKOUT1 = CLKIN;
    assign CLKOUT1N = 1'b0;
    assign CLKOUT2 = CLKIN;
    assign CLKOUT2N = 1'b0;
    assign CLKOUT3 = CLKIN;
    assign CLKOUT3N = 1'b0;
    assign CLKOUT4 = CLKIN;
    assign CLKOUT5 = CLKIN;
    assign LOCK = 1'b1;
    assign CLKFBOUT = CLKIN;
    assign CLKFBOUTN = 1'b0;
endmodule
'''


def check_verilog_syntax(file: Path) -> bool:
    """Check RTL syntax/elaboration with a temporary PLLG primitive stub."""
    try:
        rtl_dir = file.parent
        all_rtl = list(rtl_dir.glob("*.v"))
        with tempfile.TemporaryDirectory(prefix="fpga_ui_pllg_") as temp_dir:
            stub = Path(temp_dir) / "pllg_stub.v"
            stub.write_text(PLLG_STUB, encoding="ascii")
            result = subprocess.run(
                ["iverilog", "-t", "null", "-g2012", "-s", "top_hdmi_tang_mega_60k"]
                + [str(f) for f in all_rtl] + [str(stub)],
                capture_output=True,
                text=True,
                timeout=30
            )
        if result.returncode == 0:
            print("✅ RTL syntax/elaboration passed with a temporary PLLG stub")
            print("   This does not validate Gowin primitive parameters or timing.")
            return True

        print("❌ RTL syntax/elaboration failed:")
        print(result.stderr)
        return False
    except FileNotFoundError:
        print("⚠️  Verilog 检查未执行 (iverilog 未安装)")
        return False
    except Exception as e:
        print(f"❌ 语法检查异常: {e}")
        return False


def check_i2c_protocol(base_dir: Path) -> bool:
    """Run the open-drain I2C controller smoke test with an ACKing slave."""
    tb = base_dir / "testbench/tb_adv7513_controller.v"
    dut = base_dir / "rtl/adv7513_controller.v"
    if not tb.exists() or not dut.exists():
        print("❌ I2C protocol testbench or DUT is missing")
        return False

    try:
        with tempfile.TemporaryDirectory(prefix="fpga_ui_i2c_") as temp_dir:
            output = Path(temp_dir) / "tb_i2c.out"
            compile_result = subprocess.run(
                ["iverilog", "-g2012", "-s", "tb_adv7513_controller",
                 "-o", str(output), str(tb), str(dut)],
                capture_output=True,
                text=True,
                timeout=30,
            )
            if compile_result.returncode != 0:
                print("❌ I2C protocol test compile failed:")
                print(compile_result.stderr)
                return False

            run_result = subprocess.run(
                ["vvp", str(output)],
                capture_output=True,
                text=True,
                timeout=30,
            )
            if run_result.returncode != 0 or "PASS: I2C controller" not in run_result.stdout:
                print("❌ I2C protocol test failed:")
                print(run_result.stdout)
                print(run_result.stderr)
                return False

        print("✅ I2C protocol smoke test passed (address, ACKs, register writes, STOP)")
        return True
    except FileNotFoundError:
        print("⚠️  I2C protocol test not executed (iverilog/vvp unavailable)")
        return False
    except Exception as e:
        print(f"❌ I2C protocol test exception: {e}")
        return False


def check_event_cdc(base_dir: Path) -> bool:
    """Run the asynchronous UI event clock-domain bridge testbench."""
    tb = base_dir / "testbench/tb_ui_event_cdc.v"
    dut = base_dir / "rtl/ui_event_cdc.v"
    if not tb.exists() or not dut.exists():
        print("❌ UI event CDC testbench or DUT is missing")
        return False

    try:
        with tempfile.TemporaryDirectory(prefix="fpga_ui_cdc_") as temp_dir:
            output = Path(temp_dir) / "tb_ui_event_cdc.out"
            compile_result = subprocess.run(
                ["iverilog", "-g2012", "-s", "tb_ui_event_cdc",
                 "-o", str(output), str(tb), str(dut)],
                capture_output=True,
                text=True,
                timeout=30,
            )
            if compile_result.returncode != 0:
                print("❌ UI event CDC test compile failed:")
                print(compile_result.stderr)
                return False

            run_result = subprocess.run(
                ["vvp", str(output)],
                capture_output=True,
                text=True,
                timeout=30,
            )
            if (run_result.returncode != 0 or
                    "PASS: ui_event_cdc" not in run_result.stdout):
                print("❌ UI event CDC test failed:")
                print(run_result.stdout)
                print(run_result.stderr)
                return False

        print("✅ UI event CDC test passed (async clocks, ready/valid, one-cycle pulses)")
        return True
    except FileNotFoundError:
        print("⚠️ UI event CDC test not executed (iverilog/vvp unavailable)")
        return False
    except Exception as e:
        print(f"❌ UI event CDC test exception: {e}")
        return False

def check_python_imports() -> bool:
    """检查 Python 模块导入"""
    try:
        sys.path.insert(0, str(Path(__file__).parent / "designer"))
        from ui_schema import UIScene, Color, ColorRGB
        print("✅ Python Schema 导入成功")

        # 测试序列化
        scene = UIScene(name="test", width=1280, height=720)
        data = scene.to_dict()
        scene2 = UIScene.from_dict(data)
        print("✅ UIScene 序列化/反序列化正常")

        # 测试 ColorRGB 别名
        c = ColorRGB(255, 0, 0)
        print(f"✅ ColorRGB 别名正常: {c}")

        return True
    except Exception as e:
        print(f"❌ Python 导入错误: {e}")
        return False

def main():
    print("=" * 60)
    print("FPGA UI Designer - 本地结构验证")
    print("=" * 60)
    print()

    base_dir = Path(__file__).parent
    results = []

    # 1. 检查关键文件
    print("--- 检查关键文件 ---")
    files_to_check = [
        (base_dir / "rtl/top_hdmi_tang_mega_60k.v", "顶层模块"),
        (base_dir / "rtl/audio_synth_48k.v", "48 kHz 内部音频源"),
        (base_dir / "rtl/ui_top.v", "UI 顶层"),
        (base_dir / "rtl/pixel_renderer.v", "像素渲染器"),
        (base_dir / "rtl/hdmi_timing.v", "HDMI 时序"),
        (base_dir / "rtl/Gowin_rPLL.v", "PLL"),
        (base_dir / "rtl/panel_renderer.v", "面板渲染器"),
        (base_dir / "rtl/bar_renderer.v", "进度条渲染器"),
        (base_dir / "rtl/spectrum_renderer.v", "频谱渲染器"),
        (base_dir / "rtl/waveform_renderer.v", "波形渲染器"),
        (base_dir / "rtl/keyboard_renderer.v", "键盘渲染器"),
        (base_dir / "rtl/knob_renderer.v", "旋钮渲染器"),
        (base_dir / "rtl/ui_interaction.v", "交互状态模块"),
        (base_dir / "rtl/ui_event_cdc.v", "事件时钟域桥接模块"),
        (base_dir / "testbench/tb_ui_event_cdc.v", "事件时钟域测试台"),
        (base_dir / "testbench/tb_adv7513_controller.v", "I2C 协议测试台"),
        (base_dir / "constraints/tang_mega_60k_hdmi.cst", "约束文件"),
        (base_dir / "tang_mega_60k_hdmi.gprj", "工程文件"),
        (base_dir / "build.tcl", "构建脚本"),
    ]

    for path, desc in files_to_check:
        results.append(check_file(path, desc))

    print()

    # 2. 检查 Python 工具链
    print("--- 检查 Python 工具链 ---")
    results.append(check_python_imports())
    print()

    # 3. 检查 Verilog 语法（如果 iverilog 可用）
    print("--- 检查 Verilog 语法（临时 PLLG stub；不含厂商时序模型） ---")
    verilog_files = [
        base_dir / "rtl/top_hdmi_tang_mega_60k.v",
        base_dir / "rtl/ui_top.v",
        base_dir / "rtl/pixel_renderer.v",
        base_dir / "rtl/hdmi_timing.v",
    ]

    existing_verilog = [vfile for vfile in verilog_files if vfile.exists()]
    if existing_verilog:
        # One full-project compile is enough; running it once per source file
        # only repeats the same result and obscures the failure cause.
        results.append(check_verilog_syntax(existing_verilog[0]))

    print()

    # 4. Exercise the I2C state machine with an ACKing open-drain slave model.
    print("--- 检查 I2C 协议状态机 ---")
    results.append(check_i2c_protocol(base_dir))

    print()

    # 5. Exercise the asynchronous event clock-domain bridge.
    print("--- 检查 UI 事件时钟域桥接 ---")
    results.append(check_event_cdc(base_dir))

    print()

    # 6. 检查配置一致性
    print("--- 检查配置一致性 ---")

    # 检查 gprj 文件
    gprj_path = base_dir / "tang_mega_60k_hdmi.gprj"
    if gprj_path.exists():
        gprj_content = gprj_path.read_text(encoding='utf-8')
        if 'GW5AT-60' in gprj_content:
            print("✅ gprj 含 GW5AT-60 候选字段（不代表实际板卡已确认）")
            results.append(True)
        else:
            print("❌ gprj 文件器件配置错误")
            results.append(False)

    # 检查 build.tcl
    build_tcl_path = base_dir / "build.tcl"
    if build_tcl_path.exists():
        build_content = build_tcl_path.read_text(encoding='utf-8')
        if 'board_config.tcl' in build_content and 'require_board_config' in build_content:
            print("✅ build.tcl 使用 board_config.tcl 和硬件门禁")
            results.append(True)
        else:
            print("❌ build.tcl 未使用 board_config.tcl 硬件门禁")
            results.append(False)

    # 检查约束文件
    cst_path = base_dir / "constraints/tang_mega_60k_hdmi.cst"
    if cst_path.exists():
        cst_content = cst_path.read_text(encoding='utf-8')
        if 'clk_50mhz' in cst_content:
            print("✅ 约束文件含 clk_50mhz 逻辑时钟（实际频率仍待板卡确认）")
            results.append(True)
        else:
            print("❌ 约束文件时钟信号错误")
            results.append(False)

    # Local syntax/protocol checks do not establish board readiness. Keep the
    # hardware blockers visible without conflating them with simulator errors.
    print("--- 硬件交付门禁状态 ---")
    board_config_path = base_dir / "board_config.tcl"
    constraint_path = base_dir / "constraints/tang_mega_60k_hdmi.cst"
    hardware_blockers = []
    if not board_config_path.exists():
        hardware_blockers.append("缺少 board_config.tcl")
    else:
        board_config = board_config_path.read_text(encoding="utf-8")
        if "set BOARD_CONFIG_CONFIRMED 0" in board_config:
            hardware_blockers.append("FPGA/封装、晶振、HDMI 芯片和板卡参数未确认")
        if "set PLL_CONFIRMED 0" in board_config:
            hardware_blockers.append("PLL 未按已确认器件和输入时钟重新生成")
    if constraint_path.exists():
        constraint_content = constraint_path.read_text(encoding="utf-8").upper()
        if "EXAMPLE" in constraint_content or "EXAMPLE ONLY" in constraint_content:
            hardware_blockers.append("管脚约束仍为示例，尚未按实际原理图核对")
        if not re.search(r"^\s*IO_LOC\s+\"event_clk\"", constraint_content, re.MULTILINE | re.IGNORECASE):
            hardware_blockers.append(
                "event_clk/event_* 尚无板级输入适配器和管脚约束"
            )

    if hardware_blockers:
        print("🚫 BLOCKED: 本地仿真通过不代表硬件可构建")
        for blocker in hardware_blockers:
            print(f"   - {blocker}")
        print("   还需 Gowin 综合、布局布线、时序分析、bitstream 和实板验证。")
    else:
        print("⚠️ 配置门禁已清除；仍需 Gowin 综合、布局布线和实板验证。")

    print()

    # 5. 总结
    print("=" * 60)
    passed = sum(results)
    total = len(results)
    print(f"验证结果: {passed}/{total} 通过")

    if passed == total:
        print("✅ 所有本地结构、语法和协议检查通过。")
        print("⚠️ 这不表示 Gowin 综合、时序或实板显示验证通过。")
        return 0
    else:
        print("❌ 部分检查失败或未完成，请查看上述输出；不能据此生成 bitstream。")
        return 1

if __name__ == "__main__":
    sys.exit(main())
