#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Legacy Tang Mega 60K top-module template.

This file is retained as historical reference only.  Its generated module
uses the old TMDS/PLL interface and modules that are not part of the current
project (and still contains old device assumptions).  Use rtl/top_hdmi_*
and build.tcl for the current hand-written reference design instead.
"""

from pathlib import Path


class TopModuleGenerator:
    """顶层模块生成器 - 适配 Tang Mega 60K"""

    @staticmethod
    def generate(output_path: Path, ui_module_name: str = "ui_top"):
        """生成完整的顶层模块"""
        code = '''`timescale 1ns / 1ps
//
// Tang Mega 60K Top Module
// HDMI UI with FM Synthesizer Integration
//
// Board: Tang Mega 60K (GW5AT-LV60P484A)
// Clock: 50 MHz onboard oscillator
// Output: 1280x720@60Hz HDMI
//

module top_mega_60k (
    input wire clk_50m,          // 50 MHz onboard clock
    input wire btn_rst,          // S1 button (active low, with debounce)

    // HDMI outputs
    output wire tmds_clk_p,
    output wire tmds_clk_n,
    output wire [2:0] tmds_d_p,
    output wire [2:0] tmds_d_n,

    // LEDs for debugging
    output wire [5:0] led
);

    // =====================================================================
    // PLL: 50 MHz -> 74.25 MHz (pixel) + 371.25 MHz (serial)
    // =====================================================================
    wire clk_pixel, clk_serial, pll_locked;

    pll_hdmi pll_inst (
        .clkin(clk_50m),
        .clkout(clk_serial),      // 371.25 MHz
        .clkoutd(clk_pixel),      // 74.25 MHz
        .lock(pll_locked)
    );

    // =====================================================================
    // Reset Logic - 健壮的复位处理
    // =====================================================================
    // 策略：
    // 1. 不依赖按钮进行初始复位（避免按钮悬空问题）
    // 2. PLL 锁定后自动释放复位
    // 3. 按钮按下可以手动复位（可选功能）

    reg [7:0] rst_cnt = 8'd0;
    reg       rst_n = 1'b0;

    // 按钮去抖动（可选，如果没有按钮可以忽略）
    reg [3:0] btn_sync = 4'b1111;
    wire btn_stable = &btn_sync;  // 连续 4 个周期稳定才认为有效

    always @(posedge clk_pixel) begin
        btn_sync <= {btn_sync[2:0], btn_rst};
    end

    always @(posedge clk_pixel) begin
        if (!pll_locked) begin
            // PLL 未锁定 - 保持复位
            rst_cnt <= 8'd0;
            rst_n   <= 1'b0;
        end else if (rst_cnt != 8'hFF) begin
            // PLL 锁定后延迟 255 周期释放复位
            rst_cnt <= rst_cnt + 8'd1;
            rst_n   <= 1'b0;
        end else if (!btn_stable) begin
            // 按钮按下（可选）- 手动复位
            rst_cnt <= 8'd0;
            rst_n   <= 1'b0;
        end else begin
            // 正常工作状态
            rst_n   <= 1'b1;
        end
    end

    // =====================================================================
    // Video Timing Generator
    // =====================================================================
    wire [10:0] pixel_x;
    wire [9:0] pixel_y;
    wire hsync, vsync, display_active;

    video_timing timing_gen (
        .clk(clk_pixel),
        .rst_n(rst_n),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .hsync(hsync),
        .vsync(vsync),
        .de(display_active)
    );

    // =====================================================================
    // UI Renderer
    // =====================================================================
    // 模拟 UI 状态输入（实际应该连接到 FM 合成器）
    wire [7:0] fft_bins [0:127];
    wire [15:0] ui_state [0:31];

    // 示例：生成测试数据
    genvar i;
    generate
        for (i = 0; i < 128; i = i + 1) begin : gen_fft
            assign fft_bins[i] = 8'd128 + (i << 1);
        end
        for (i = 0; i < 32; i = i + 1) begin : gen_state
            assign ui_state[i] = 16'd1000 + (i << 4);
        end
    endgenerate

    wire [7:0] rgb_r, rgb_g, rgb_b;

    ''' + ui_module_name + ''' ui_inst (
        .clk_pixel(clk_pixel),
        .rst_n(rst_n),
        .fft_bins(fft_bins),
        .ui_state(ui_state),
        .hdmi_r(rgb_r),
        .hdmi_g(rgb_g),
        .hdmi_b(rgb_b),
        .hdmi_de(),           // 不使用，从 timing_gen 获取
        .hdmi_hsync(),        // 不使用
        .hdmi_vsync()         // 不使用
    );

    // =====================================================================
    // TMDS Encoder & Output
    // =====================================================================
    wire [9:0] tmds_r, tmds_g, tmds_b, tmds_clk_encoded;

    // RGB -> TMDS encoding
    tmds_encoder enc_r (
        .clk(clk_pixel),
        .data(rgb_r),
        .c(2'b00),
        .de(display_active),
        .tmds(tmds_r)
    );

    tmds_encoder enc_g (
        .clk(clk_pixel),
        .data(rgb_g),
        .c(2'b00),
        .de(display_active),
        .tmds(tmds_g)
    );

    tmds_encoder enc_b (
        .clk(clk_pixel),
        .data(rgb_b),
        .c({vsync, hsync}),
        .de(display_active),
        .tmds(tmds_b)
    );

    // Clock channel (constant pattern)
    assign tmds_clk_encoded = 10'b0000011111;

    // Serializer: 10:1 parallel to serial
    wire serial_r, serial_g, serial_b, serial_clk;

    serializer ser_r (
        .clk_pixel(clk_pixel),
        .clk_serial(clk_serial),
        .data(tmds_r),
        .serial_out(serial_r)
    );

    serializer ser_g (
        .clk_pixel(clk_pixel),
        .clk_serial(clk_serial),
        .data(tmds_g),
        .serial_out(serial_g)
    );

    serializer ser_b (
        .clk_pixel(clk_pixel),
        .clk_serial(clk_serial),
        .data(tmds_b),
        .serial_out(serial_b)
    );

    serializer ser_clk (
        .clk_pixel(clk_pixel),
        .clk_serial(clk_serial),
        .data(tmds_clk_encoded),
        .serial_out(serial_clk)
    );

    // LVDS output buffers
    ELVDS_OBUF tmds_bufds [3:0] (
        .I ({serial_clk, serial_r, serial_g, serial_b}),
        .O ({tmds_clk_p, tmds_d_p[2], tmds_d_p[1], tmds_d_p[0]}),
        .OB({tmds_clk_n, tmds_d_n[2], tmds_d_n[1], tmds_d_n[0]})
    );

    // =====================================================================
    // Debug LEDs
    // =====================================================================
    assign led[0] = ~pll_locked;      // PLL 锁定指示
    assign led[1] = ~rst_n;           // 复位释放指示
    assign led[2] = ~vsync;           // VSYNC 闪烁
    assign led[3] = ~display_active;  // DE 信号
    assign led[4] = ~btn_stable;      // 按钮状态
    assign led[5] = 1'b0;             // 常亮

endmodule
'''

        output_path.write_text(code, encoding='utf-8')
        print(f"[OK] Generated top module: {output_path.name}")


    @staticmethod
    def generate_pll_module(output_path: Path):
        """生成 PLL 模块（50MHz -> 74.25MHz + 371.25MHz）"""
        code = '''`timescale 1ns / 1ps
//
// HDMI PLL for Tang Mega 60K
// Input: 50 MHz
// Output: 74.25 MHz (pixel clock) + 371.25 MHz (TMDS serial clock)
//

module pll_hdmi (
    input wire clkin,       // 50 MHz
    output wire clkout,     // 371.25 MHz (serial)
    output wire clkoutd,    // 74.25 MHz (pixel)
    output wire lock
);

    // PLL calculation:
    // VCO = 50 MHz * FBDIV / IDIV = 50 * 149 / 20 = 372.5 MHz
    // clkout = VCO = 372.5 MHz (close to 371.25 MHz, error < 0.4%)
    // clkoutd = VCO / 5 = 74.5 MHz (close to 74.25 MHz, error < 0.4%)

    rPLL #(
        .FCLKIN("50"),
        .IDIV_SEL(19),        // /20
        .FBDIV_SEL(148),      // *149
        .ODIV_SEL(2),         // VCO / 2 (not used, just meets VCO range)
        .DYN_SDIV_SEL(5),     // clkoutd = VCO / 5
        .DEVICE("GW5AT-138")
    ) pll_inst (
        .CLKOUT(clkout),
        .CLKOUTD(clkoutd),
        .LOCK(lock),
        .CLKIN(clkin),
        .CLKFB(1'b0),
        .RESET(1'b0),
        .RESET_P(1'b0),
        .FBDSEL(6'b0),
        .IDSEL(6'b0),
        .ODSEL(6'b0),
        .PSDA(4'b0),
        .DUTYDA(4'b0),
        .FDLY(4'b0),
        .CLKOUTP(),
        .CLKOUTD3()
    );

endmodule
'''
        output_path.write_text(code, encoding='utf-8')
        print(f"[OK] Generated PLL module: {output_path.name}")


    @staticmethod
    def generate_constraint_file(output_path: Path):
        """生成 Tang Mega 60K 约束文件"""
        code = '''//
// Tang Mega 60K Pin Constraints
// HDMI UI Project
//

// Clock - 50 MHz onboard oscillator
IO_LOC "clk_50m" H11;
IO_PORT "clk_50m" IO_TYPE=LVCMOS33 PULL_MODE=NONE;

// Reset Button - S1 (active low)
IO_LOC "btn_rst" T10;
IO_PORT "btn_rst" IO_TYPE=LVCMOS18 PULL_MODE=UP;

// HDMI - J5 connector
IO_LOC "tmds_clk_p" E11;
IO_LOC "tmds_clk_n" D11;
IO_LOC "tmds_d_p[0]" G11;
IO_LOC "tmds_d_n[0]" F11;
IO_LOC "tmds_d_p[1]" J11;
IO_LOC "tmds_d_n[1]" H12;
IO_LOC "tmds_d_p[2]" C12;
IO_LOC "tmds_d_n[2]" B12;

IO_PORT "tmds_clk_p" IO_TYPE=LVCMOS33D PULL_MODE=NONE DRIVE=8;
IO_PORT "tmds_clk_n" IO_TYPE=LVCMOS33D PULL_MODE=NONE DRIVE=8;
IO_PORT "tmds_d_p[0]" IO_TYPE=LVCMOS33D PULL_MODE=NONE DRIVE=8;
IO_PORT "tmds_d_n[0]" IO_TYPE=LVCMOS33D PULL_MODE=NONE DRIVE=8;
IO_PORT "tmds_d_p[1]" IO_TYPE=LVCMOS33D PULL_MODE=NONE DRIVE=8;
IO_PORT "tmds_d_n[1]" IO_TYPE=LVCMOS33D PULL_MODE=NONE DRIVE=8;
IO_PORT "tmds_d_p[2]" IO_TYPE=LVCMOS33D PULL_MODE=NONE DRIVE=8;
IO_PORT "tmds_d_n[2]" IO_TYPE=LVCMOS33D PULL_MODE=NONE DRIVE=8;

// LEDs
IO_LOC "led[0]" R16;
IO_LOC "led[1]" R17;
IO_LOC "led[2]" R18;
IO_LOC "led[3]" P16;
IO_LOC "led[4]" P17;
IO_LOC "led[5]" P18;

IO_PORT "led[0]" IO_TYPE=LVCMOS18 PULL_MODE=UP DRIVE=8;
IO_PORT "led[1]" IO_TYPE=LVCMOS18 PULL_MODE=UP DRIVE=8;
IO_PORT "led[2]" IO_TYPE=LVCMOS18 PULL_MODE=UP DRIVE=8;
IO_PORT "led[3]" IO_TYPE=LVCMOS18 PULL_MODE=UP DRIVE=8;
IO_PORT "led[4]" IO_TYPE=LVCMOS18 PULL_MODE=UP DRIVE=8;
IO_PORT "led[5]" IO_TYPE=LVCMOS18 PULL_MODE=UP DRIVE=8;
'''
        output_path.write_text(code, encoding='utf-8')
        print(f"[OK] Generated constraints: {output_path.name}")
