#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FPGA UI Designer - Pre-Build Verification Script
Check if project is ready to build
"""

import os
import re
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

def project_path(filepath):
    """Resolve project-relative paths independently of the current directory."""
    path = Path(filepath)
    return path if path.is_absolute() else BASE_DIR / path

def check_file_exists(filepath, description):
    """Check if file exists"""
    path = project_path(filepath)
    if path.exists():
        print(f"[OK] {description}: {filepath}")
        return True
    else:
        print(f"[FAIL] {description} not found: {filepath}")
        return False

def check_rtl_files():
    """Check RTL files"""
    print("\n" + "="*60)
    print("Checking RTL Files")
    print("="*60 + "\n")

    required_files = [
        ("rtl/top_hdmi_tang_mega_60k.v", "Top module"),
        ("rtl/ui_top.v", "UI top"),
        ("rtl/pixel_renderer.v", "Pixel renderer"),
        ("rtl/hdmi_timing.v", "HDMI timing"),
        ("rtl/panel_renderer.v", "Panel renderer"),
        ("rtl/bar_renderer.v", "Bar renderer"),
        ("rtl/spectrum_renderer.v", "Spectrum renderer"),
        ("rtl/adv7513_controller.v", "I2C controller"),
        ("rtl/ui_interaction.v", "UI interaction state module"),
        ("rtl/ui_event_cdc.v", "UI event clock-domain bridge"),
        ("rtl/Gowin_rPLL.v", "PLL module"),
        ("rtl/ui_config.vh", "UI config header"),
    ]

    all_ok = True
    for filepath, description in required_files:
        if not check_file_exists(filepath, description):
            all_ok = False

    return all_ok

def check_constraint_file():
    """Check constraint file"""
    print("\n" + "="*60)
    print("Checking Constraint File")
    print("="*60 + "\n")

    cst_file = "constraints/tang_mega_60k_hdmi.cst"

    if not check_file_exists(cst_file, "Constraint file"):
        return False

    with open(project_path(cst_file), 'r', encoding='utf-8') as f:
        content = f.read()

    upper_content = content.upper()
    valid = True
    if '???' in content or 'EXAMPLE' in upper_content:
        print("[BLOCKED] Constraint file still contains placeholder/example pins")
        print("          Verify every pin against the actual board schematic before PnR")
        valid = False
    else:
        print("[OK] No placeholder markers found in the constraint file")

    critical_signals = ['clk_50mhz', 'hdmi_clk', 'hdmi_d[', 'hdmi_scl', 'hdmi_sda']
    for signal in critical_signals:
        if signal in content:
            print(f"[OK] Found signal: {signal}")
        else:
            print(f"[WARN] Signal not found: {signal}")

    if not re.search(r'^\s*IO_LOC\s+"event_clk"', content, re.IGNORECASE | re.MULTILINE):
        print("[BLOCKED] event_clk/event_* has no board input adapter or pin constraint")
        valid = False

    return valid

def check_project_file():
    """Check project file"""
    print("\n" + "="*60)
    print("Checking Project File")
    print("="*60 + "\n")

    gprj_file = "tang_mega_60k_hdmi.gprj"

    if not check_file_exists(gprj_file, "Gowin project file"):
        return False

    with open(project_path(gprj_file), 'r', encoding='utf-8') as f:
        content = f.read()

    if 'GW5AT-60' in content or 'GW5AT-LV60' in content:
        print("[OK] GPRJ contains GW5AT-60 candidate (actual board/device unconfirmed)")
    elif 'GW1N-9C' in content:
        print("[FAIL] Wrong device: GW1N-9C (expected GW5AT-60 for this project)")
        return False
    else:
        print("[FAIL] Cannot determine the target device")
        return False

    return True

def check_build_script():
    """Check build script"""
    print("\n" + "="*60)
    print("Checking Build Script")
    print("="*60 + "\n")

    build_file = "build.tcl"

    if not check_file_exists(build_file, "Build script"):
        return False

    with open(project_path(build_file), 'r', encoding='utf-8') as f:
        content = f.read()

    # The build script resolves the PLL filename through board_config.tcl;
    # accept that indirection instead of requiring a stale literal filename.
    pll_is_configured = ('PLL_SOURCE_FILE' in content or 'Gowin_rPLL.v' in content)
    interaction_is_included = 'ui_interaction.v' in content
    if pll_is_configured and interaction_is_included and 'board_config.tcl' in content and 'require_board_config' in content:
        print("[OK] PLL file included and board_config preflight is enabled")
    else:
        print("[FAIL] Build script is missing configured PLL, interaction module, or board preflight")
        return False

    return True

def check_interface_consistency():
    """Check interface consistency"""
    print("\n" + "="*60)
    print("Checking Module Interface Consistency")
    print("="*60 + "\n")

    ui_top_file = "rtl/ui_top.v"
    if project_path(ui_top_file).exists():
        with open(project_path(ui_top_file), 'r', encoding='utf-8') as f:
            content = f.read()

        if 'fft_bins_flat' in content and 'ui_state_flat' in content:
            print("[OK] ui_top.v uses flattened interface")
        else:
            print("[WARN] ui_top.v interface may not be flattened")

    renderer_file = "rtl/pixel_renderer.v"
    if project_path(renderer_file).exists():
        with open(project_path(renderer_file), 'r', encoding='utf-8') as f:
            content = f.read()

        if 'fft_bins_flat' in content and 'ui_state_flat' in content:
            print("[OK] pixel_renderer.v uses flattened interface")
        else:
            print("[FAIL] pixel_renderer.v interface not flattened")
            return False

        if 'panel_renderer' in content:
            print("[OK] pixel_renderer.v instantiates Panel widgets")
        else:
            print("[WARN] pixel_renderer.v may not instantiate any widgets")

        if 'bar_renderer' in content:
            print("[OK] pixel_renderer.v instantiates Bar widgets")

        if 'spectrum_renderer' in content:
            print("[OK] pixel_renderer.v instantiates Spectrum widget")

    return True

def check_clock_configuration():
    """Check clock configuration"""
    print("\n" + "="*60)
    print("Checking Clock Configuration")
    print("="*60 + "\n")

    cst_file = "constraints/tang_mega_60k_hdmi.cst"
    if project_path(cst_file).exists():
        with open(project_path(cst_file), 'r', encoding='utf-8') as f:
            content = f.read()

        if 'period 20' in content or 'period 20.0' in content:
            print("[OK] CST contains a 20 ns clock constraint (50 MHz is an unconfirmed assumption)")
        elif 'period 37.037' in content:
            print("[FAIL] Clock constraint still targets 27 MHz")
            return False
        else:
            print("[FAIL] Cannot identify clock frequency configuration")
            return False

    pll_file = "rtl/Gowin_rPLL.v"
    if project_path(pll_file).exists():
        with open(project_path(pll_file), 'r', encoding='utf-8') as f:
            content = f.read()

        board_config = project_path("board_config.tcl").read_text(encoding='utf-8')
        if 'PLL_CONFIRMED 0' in board_config:
            print("[BLOCKED] PLL is intentionally unconfirmed; regenerate it with Gowin PLL Wizard")
        elif 'require_board_config' in project_path("build.tcl").read_text(encoding='utf-8'):
            print("[OK] PLL verification is gated by board_config.tcl")
        else:
            print("[FAIL] PLL preflight gate is missing")
            return False

    return True

def check_board_configuration():
    """Report whether the hardware-specific build gate has been cleared."""
    print("\n" + "="*60)
    print("Checking Board Configuration Gate")
    print("="*60 + "\n")

    config_path = project_path("board_config.tcl")
    if not config_path.exists():
        print("[FAIL] board_config.tcl not found")
        return False

    content = config_path.read_text(encoding='utf-8')
    match = re.search(r"set\s+BOARD_CONFIG_CONFIRMED\s+([01])", content)
    if not match or match.group(1) != "1":
        print("[BLOCKED] Hardware configuration is intentionally unconfirmed")
        print("          Fill the real FPGA/package, oscillator, HDMI chip, PLL and pins")
        print("          from the board schematic before setting BOARD_CONFIG_CONFIRMED 1")
        return False

    print("[OK] BOARD_CONFIG_CONFIRMED is enabled")
    return True

def check_documentation():
    """Check documentation"""
    print("\n" + "="*60)
    print("Checking Documentation")
    print("="*60 + "\n")

    docs = [
        ("README.md", "Project documentation"),
        ("QUICKSTART.md", "Quick start guide"),
        ("FIXES.md", "Fix summary"),
    ]

    all_ok = True
    for filepath, description in docs:
        if not check_file_exists(filepath, description):
            all_ok = False

    return all_ok

def print_summary(results):
    """Print summary"""
    print("\n" + "="*60)
    print("Verification Summary")
    print("="*60 + "\n")

    total = len(results)
    passed = sum(results.values())

    print(f"Total checks: {total}")
    print(f"Passed: {passed}")
    print(f"Failed: {total - passed}")

    if all(results.values()):
        print("\n[SUCCESS] All checks passed! Project is ready to build.\n")
        print("Next steps:")
        print("  1. Verify pin assignments in constraint file match your board")
        print("  2. Run build: gw_sh build.tcl")
        print("  3. Or use Gowin IDE to open tang_mega_60k_hdmi.gprj")
        print("\nSee QUICKSTART.md for detailed guide")
        return 0
    else:
        print("\n[ERROR] Issues found. Please fix before building.\n")
        print("Failed checks:")
        for name, passed in results.items():
            if not passed:
                print(f"  - {name}")
        print("\nPlease fix the issues listed above.")
        return 1

def main():
    """Main function"""
    print("\nFPGA UI Designer - Pre-Build Verification")
    print("Target: Tang Mega 60K (GW5AT-60)\n")

    if not project_path("tang_mega_60k_hdmi.gprj").exists():
        print("[FAIL] tang_mega_60k_hdmi.gprj not found")
        print("Please run this script from the project root directory!")
        return 1

    results = {
        "RTL Files": check_rtl_files(),
        "Constraint File": check_constraint_file(),
        "Project File": check_project_file(),
        "Build Script": check_build_script(),
        "Interface Consistency": check_interface_consistency(),
        "Clock Configuration": check_clock_configuration(),
        "Board Configuration": check_board_configuration(),
        "Documentation": check_documentation(),
    }

    return print_summary(results)

if __name__ == "__main__":
    sys.exit(main())
