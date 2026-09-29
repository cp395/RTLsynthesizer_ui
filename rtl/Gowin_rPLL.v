//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: PLL IP
// Device/clock values must be regenerated with Gowin PLL Wizard after the
// board configuration is confirmed.  The checked-in values are a 27 MHz
// reference template and must not be used with a 50 MHz oscillator.

module Gowin_rPLL (
    output clkout,
    output lock,
    input clkin
);

wire clkout0;
wire clkout0n;
wire clkout1;
wire clkout1n;
wire clkout2;
wire clkout2n;
wire clkout3;
wire clkout3n;
wire clkout4;
wire clkout5;
wire lock_int;
wire clkfbout;
wire clkfboutn;
wire gw_gnd;

assign gw_gnd = 1'b0;
assign clkout = clkout0;
assign lock = lock_int;

// PLLG instance for GW5AT
PLLG pllg_inst (
    .CLKOUT0(clkout0),
    .CLKOUT0N(clkout0n),
    .CLKOUT1(clkout1),
    .CLKOUT1N(clkout1n),
    .CLKOUT2(clkout2),
    .CLKOUT2N(clkout2n),
    .CLKOUT3(clkout3),
    .CLKOUT3N(clkout3n),
    .CLKOUT4(clkout4),
    .CLKOUT5(clkout5),
    .LOCK(lock_int),
    .CLKFBOUT(clkfbout),
    .CLKFBOUTN(clkfboutn),
    .CLKIN(clkin),
    .CLKFB(gw_gnd),
    .IDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FBDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FBODSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FBODSEL_FRAC({gw_gnd,gw_gnd,gw_gnd}),
    .ODSEL0({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .ODSEL0_FRAC({gw_gnd,gw_gnd,gw_gnd}),
    .ODSEL1({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .ODSEL2({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .ODSEL3({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .ODSEL4({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .ODSEL5({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .PSFB({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FPSFB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .PS0({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FPS0({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .DUTY0({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FDUTY0({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .PS1({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FPS1({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .DUTY1({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FDUTY1({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .PS2({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FPS2({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .DUTY2({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FDUTY2({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .PS3({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FPS3({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .DUTY3({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FDUTY3({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .PS4({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FPS4({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .DUTY4({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FDUTY4({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .PS5({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FPS5({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .DUTY5({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FDUTY5({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .RESET(gw_gnd),
    .PLLPWD(gw_gnd)
);

// Parameters for 27 MHz -> 74.25 MHz
// IDIV = 1, FBDIV = 11, ODIV = 4
// VCO = 27 * 11 = 297 MHz
// Out = 297 / 4 = 74.25 MHz
defparam pllg_inst.FCLKIN = "27";
defparam pllg_inst.IDIV_SEL = 0;      // divide by 1
defparam pllg_inst.FBDIV_SEL = 10;    // multiply by 11
defparam pllg_inst.ODIV0_SEL = 4;     // divide by 4
defparam pllg_inst.CLKFB_SEL = "internal";
defparam pllg_inst.DEVICE = "GW5AST-138C";

endmodule
