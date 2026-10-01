# Gowin EDA Build Script for Tang Mega 60K HDMI UI Project
# Usage: gw_sh build.tcl

# Load the single board configuration. It defaults to unconfirmed and
# intentionally stops the build until the real schematic/device is entered.
source [file join [file dirname [info script]] board_config.tcl]
require_board_config
set_device -name $FPGA_DEVICE_NAME $FPGA_PART -device_version $FPGA_DEVICE_VERSION

# Add design files
add_file -type verilog rtl/top_hdmi_tang_mega_60k.v
add_file -type verilog rtl/audio_synth_48k.v
add_file -type verilog [file join $BOARD_CONFIG_DIR $PLL_SOURCE_FILE]
add_file -type verilog rtl/ui_top.v
add_file -type verilog rtl/pixel_renderer.v
add_file -type verilog rtl/hdmi_timing.v
add_file -type verilog rtl/panel_renderer.v
add_file -type verilog rtl/bar_renderer.v
add_file -type verilog rtl/spectrum_renderer.v
add_file -type verilog rtl/waveform_renderer.v
add_file -type verilog rtl/keyboard_renderer.v
add_file -type verilog rtl/knob_renderer.v
add_file -type verilog rtl/adv7513_controller.v
add_file -type verilog rtl/ui_event_cdc.v
add_file -type verilog rtl/ui_interaction.v

# Add constraint file
add_file -type cst [file join $BOARD_CONFIG_DIR $HDMI_CONSTRAINT_FILE]

# Set top module
set_option -top_module top_hdmi_tang_mega_60k

# Set output directory
set_option -output_base_name fpga_ui_60k
set_option -output_path impl

# Synthesis options - use SystemVerilog 2012 for array slicing
set_option -verilog_std sysv2017
set_option -vhdl_std vhd2008

# Place and Route options
set_option -use_mspi_as_gpio 1
set_option -use_sspi_as_gpio 1
set_option -use_ready_as_gpio 1
set_option -use_done_as_gpio 1

# Run synthesis
run syn

# Run place and route
run pnr

# Generate bitstream
run bit
