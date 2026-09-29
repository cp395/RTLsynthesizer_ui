# Gowin EDA Build Script for a minimal electrical smoke test.
# This is not the generated UI/HDMI build.
# Usage: gw_sh build_simple.tcl

source [file join [file dirname [info script]] board_config.tcl]
require_board_config
set_device -name $FPGA_DEVICE_NAME $FPGA_PART -device_version $FPGA_DEVICE_VERSION

# Add design files
add_file -type verilog rtl/top_mega_60k_simple.v

# Add constraint file
add_file -type cst constraints/tang_mega_60k_simple.cst

# Set top module
set_option -top_module top_mega_60k_simple

# Set output name
set_option -output_base_name tang_mega_60k_hdmi

# Synthesis options
set_option -verilog_std v2001
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
