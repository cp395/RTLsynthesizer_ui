`timescale 1ns / 1ps
//
// Pixel Renderer - 完整实现
// 实例化所有控件渲染器
//

module pixel_renderer (
    input wire clk,
    input wire rst_n,
    input wire [10:0] pixel_x,
    input wire [9:0] pixel_y,

    // UI State - flattened arrays
    input wire [1023:0] fft_bins_flat,    // 128 * 8 bits
    input wire [511:0] ui_state_flat,     // 32 * 16 bits
    input wire [2047:0] pcm_buffer_flat,  // 128 * signed 16 bits
    input wire [87:0] key_states,         // 88 keys

    // RGB Output
    output reg [7:0] rgb_r,
    output reg [7:0] rgb_g,
    output reg [7:0] rgb_b
);

    // ========================================
    // 背景面板
    // ========================================
    wire panel_bg_active;
    wire [23:0] panel_bg_color;
    panel_renderer #(
        .X_START(0),
        .Y_START(0),
        .WIDTH(1280),
        .HEIGHT(720),
        .BG_COLOR(24'h0A0D12)
    ) panel_bg (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .active(panel_bg_active),
        .color(panel_bg_color)
    );

    // ========================================
    // 频谱分析器
    // ========================================
    wire spectrum_active;
    wire [23:0] spectrum_color;
    spectrum_renderer #(
        .X_START(50),
        .Y_START(100),
        .WIDTH(600),
        .HEIGHT(200),
        .NUM_BARS(64),
        .BAR_COLOR(24'h38BDF8),
        .BG_COLOR(24'h0F131C)
    ) spectrum (
        .clk(clk),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .fft_bins_flat(fft_bins_flat),
        .active(spectrum_active),
        .color(spectrum_color)
    );

    // ========================================
    // 波形显示
    // ========================================
    wire waveform_active;
    wire [23:0] waveform_color;
    waveform_renderer #(
        .X_START(50),
        .Y_START(350),
        .WIDTH(600),
        .HEIGHT(150),
        .SAMPLES(128),
        .LINE_COLOR(24'h6EE7B7),
        .BG_COLOR(24'h0F131C)
    ) waveform (
        .clk(clk),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .pcm_buffer_flat(pcm_buffer_flat),
        .active(waveform_active),
        .color(waveform_color)
    );

    // ========================================
    // 键盘
    // ========================================
    wire keyboard_active;
    wire [23:0] keyboard_color;
    keyboard_renderer #(
        .X_START(50),
        .Y_START(550),
        .WIDTH(700),
        .HEIGHT(120),
        .START_NOTE(48),
        .NUM_KEYS(25),
        .WHITE_KEY_COLOR(24'hF0F0F5),
        .BLACK_KEY_COLOR(24'h141923),
        .PRESSED_COLOR(24'h38BDF8)
    ) keyboard (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .key_states(key_states[24:0]),
        .active(keyboard_active),
        .color(keyboard_color)
    );

    // ========================================
    // 进度条示例 (使用 ui_state[0])
    // ========================================
    wire [15:0] bar_value;
    assign bar_value = ui_state_flat[15:0];

    wire bar_active;
    wire [23:0] bar_color;
    bar_renderer #(
        .X_START(700),
        .Y_START(100),
        .WIDTH(300),
        .HEIGHT(20),
        .FG_COLOR(24'h38BDF8),
        .BG_COLOR(24'h1E283C)
    ) bar_0 (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .value(bar_value),
        .active(bar_active),
        .color(bar_color)
    );

    // ========================================
    // 旋钮示例 (使用 ui_state[1])
    // ========================================
    wire [15:0] knob_value;
    assign knob_value = ui_state_flat[31:16];

    wire knob_active;
    wire [23:0] knob_color;
    knob_renderer #(
        .X_START(800),
        .Y_START(150),
        .SIZE(80),
        .MIN_VALUE(0),
        .MAX_VALUE(127),
        .FG_COLOR(24'h38BDF8),
        .BG_COLOR(24'h1E2836)
    ) knob_0 (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .value(knob_value),  // 传入完整的 16 位值
        .active(knob_active),
        .color(knob_color)
    );

    // ========================================
    // 合成渲染 (后到前 layer 顺序)
    // ========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_r <= 8'd0;
            rgb_g <= 8'd0;
            rgb_b <= 8'd0;
        end else begin
            // 默认背景色
            rgb_r <= 8'd5;
            rgb_g <= 8'd7;
            rgb_b <= 8'd12;

            // Layer 0: 背景面板
            if (panel_bg_active) begin
                rgb_r <= panel_bg_color[23:16];
                rgb_g <= panel_bg_color[15:8];
                rgb_b <= panel_bg_color[7:0];
            end

            // Layer 1: 频谱
            if (spectrum_active) begin
                rgb_r <= spectrum_color[23:16];
                rgb_g <= spectrum_color[15:8];
                rgb_b <= spectrum_color[7:0];
            end

            // Layer 2: 波形
            if (waveform_active) begin
                rgb_r <= waveform_color[23:16];
                rgb_g <= waveform_color[15:8];
                rgb_b <= waveform_color[7:0];
            end

            // Layer 3: 键盘
            if (keyboard_active) begin
                rgb_r <= keyboard_color[23:16];
                rgb_g <= keyboard_color[15:8];
                rgb_b <= keyboard_color[7:0];
            end

            // Layer 4: 进度条
            if (bar_active) begin
                rgb_r <= bar_color[23:16];
                rgb_g <= bar_color[15:8];
                rgb_b <= bar_color[7:0];
            end

            // Layer 5: 旋钮
            if (knob_active) begin
                rgb_r <= knob_color[23:16];
                rgb_g <= knob_color[15:8];
                rgb_b <= knob_color[7:0];
            end
        end
    end

endmodule
