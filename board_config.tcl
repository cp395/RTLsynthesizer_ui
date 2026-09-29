# Single source of truth for board-specific build parameters.
#
# This file intentionally ships unconfirmed. Fill every value from the board
# schematic/part marking, then set BOARD_CONFIG_CONFIRMED to 1. Build scripts
# refuse to run before that flag is enabled, so example pins and clocks cannot
# produce a bitstream by accident.

set BOARD_CONFIG_CONFIRMED 0
# Keep the script directory un-normalized.  Tcl on some Windows installations
# resolves a Desktop shell alias to the profile root during `file normalize`,
# which can make valid project-relative files appear missing.
set BOARD_CONFIG_DIR [file dirname [info script]]

# Board identity
set BOARD_NAME "Tang Mega 60K (confirm PCB revision)"
set FPGA_DEVICE_NAME ""
set FPGA_PART ""
set FPGA_DEVICE_VERSION "C"

# The PLL is a generated, device-specific IP.  Keep this separate from the
# board gate so a board entry cannot accidentally reuse a PLL generated for a
# different part or clock.  Fill these from the final Gowin PLL Wizard output.
set PLL_CONFIRMED 0
set PLL_INPUT_MHZ ""
set PLL_OUTPUT_MHZ ""
set PLL_DEVICE_NAME ""
set PLL_SOURCE_FILE "rtl/Gowin_rPLL.v"

# Input clock
set INPUT_CLOCK_MHZ ""
set INPUT_CLOCK_PORT ""

# The checked-in top only drives parallel RGB into an external HDMI transmitter
# (ADV7513-style).  Direct FPGA TMDS is not implemented by this project.
set VIDEO_ARCHITECTURE ""
set HDMI_CHIP ""
set VIDEO_MODE "1280x720@60"
set PIXEL_CLOCK_MHZ "74.25"

# Event transport is deliberately board-specific.  Fill these after adding a
# UART/USB/soft-core adapter and assigning event_clk/event_* pins.
set EVENT_INPUT_MODE ""
set EVENT_CLOCK_SOURCE ""

# Constraint file selected only after the pin map is verified.
set HDMI_CONSTRAINT_FILE "constraints/tang_mega_60k_hdmi.cst"

proc require_board_config {} {
    global BOARD_CONFIG_CONFIRMED BOARD_CONFIG_DIR BOARD_NAME FPGA_DEVICE_NAME FPGA_PART
    global PLL_CONFIRMED PLL_INPUT_MHZ PLL_OUTPUT_MHZ PLL_DEVICE_NAME PLL_SOURCE_FILE
    global INPUT_CLOCK_MHZ INPUT_CLOCK_PORT VIDEO_ARCHITECTURE HDMI_CHIP
    global VIDEO_MODE PIXEL_CLOCK_MHZ HDMI_CONSTRAINT_FILE
    global EVENT_INPUT_MODE EVENT_CLOCK_SOURCE

    if {$BOARD_CONFIG_CONFIRMED != 1} {
        error "board_config.tcl is unconfirmed: fill hardware parameters and set BOARD_CONFIG_CONFIRMED 1"
    }

    set required {
        BOARD_NAME FPGA_DEVICE_NAME FPGA_PART INPUT_CLOCK_MHZ INPUT_CLOCK_PORT
        VIDEO_ARCHITECTURE HDMI_CHIP VIDEO_MODE PIXEL_CLOCK_MHZ HDMI_CONSTRAINT_FILE
        EVENT_INPUT_MODE EVENT_CLOCK_SOURCE
    }
    foreach name $required {
        if {[string trim [set $name]] eq ""} {
            error "board_config.tcl: $name is required"
        }
    }

    if {$VIDEO_ARCHITECTURE ne "PARALLEL_RGB_EXTERNAL_TX"} {
        if {$VIDEO_ARCHITECTURE eq "DIRECT_TMDS"} {
            error "board_config.tcl: DIRECT_TMDS is unsupported by top_hdmi_tang_mega_60k; use the parallel-RGB external transmitter path or add a dedicated TMDS top"
        }
        error "board_config.tcl: VIDEO_ARCHITECTURE must be PARALLEL_RGB_EXTERNAL_TX for this top"
    }

    if {$INPUT_CLOCK_PORT ne "clk_50mhz"} {
        error "board_config.tcl: this top has a fixed clk_50mhz input; map the physical oscillator pin to that logical port"
    }

    if {![string match "ADV7513*" [string toupper [string trim $HDMI_CHIP]]]} {
        error "board_config.tcl: this top instantiates the ADV7513 controller; replace the controller/top before selecting another HDMI transmitter"
    }

    if {$PLL_CONFIRMED != 1} {
        error "board_config.tcl: PLL_CONFIRMED must be 1 only after regenerating/checking the PLL for the confirmed board"
    }

    foreach name {PLL_INPUT_MHZ PLL_OUTPUT_MHZ PLL_DEVICE_NAME PLL_SOURCE_FILE} {
        if {[string trim [set $name]] eq ""} {
            error "board_config.tcl: $name is required when PLL_CONFIRMED is 1"
        }
    }

    if {[string trim $PLL_INPUT_MHZ] ne [string trim $INPUT_CLOCK_MHZ]} {
        error "board_config.tcl: PLL_INPUT_MHZ must match INPUT_CLOCK_MHZ"
    }
    if {[string trim $PLL_OUTPUT_MHZ] ne [string trim $PIXEL_CLOCK_MHZ]} {
        error "board_config.tcl: PLL_OUTPUT_MHZ must match PIXEL_CLOCK_MHZ"
    }
    if {[string trim $PLL_DEVICE_NAME] ne [string trim $FPGA_DEVICE_NAME]} {
        error "board_config.tcl: PLL_DEVICE_NAME must match FPGA_DEVICE_NAME; regenerate the PLL for this device"
    }
    if {![file exists [file join $BOARD_CONFIG_DIR $PLL_SOURCE_FILE]]} {
        error "board_config.tcl: PLL source file not found: $PLL_SOURCE_FILE"
    }

    if {![file exists [file join $BOARD_CONFIG_DIR $HDMI_CONSTRAINT_FILE]]} {
        error "board_config.tcl: constraint file not found: $HDMI_CONSTRAINT_FILE"
    }
}
