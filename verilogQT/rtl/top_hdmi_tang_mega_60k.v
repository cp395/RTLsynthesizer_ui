`timescale 1ns / 1ps
//
// Tang Mega 60K HDMI 顶层模块
// 完整实现：UI + ADV7513 控制
//

module top_hdmi_tang_mega_60k (
    // 板载晶振 50 MHz
    input wire clk_50mhz,

    // 复位按钮
    input wire key_reset_n,

    // UI event source. The adapter holds event_valid until event_ready.
    // event_clk may belong to a UART/USB/soft-core controller; ui_event_cdc
    // transfers accepted events into the pixel-clock domain.
    input wire event_clk,
    input wire event_valid,
    output wire event_ready,
    input wire [3:0] event_type,
    input wire [7:0] event_id,
    input wire [15:0] event_value,

    // LED 调试输出
    output wire [7:0] led,

    // HDMI 接口（到 ADV7513 芯片）
    output wire [23:0] hdmi_d,      // RGB 数据
    output wire hdmi_clk,           // 像素时钟
    output wire hdmi_vsync,         // 垂直同步
    output wire hdmi_hsync,         // 水平同步
    output wire hdmi_de,            // 数据使能

    // ADV7513 I2C 控制
    output wire hdmi_scl,           // I2C 时钟
    inout wire hdmi_sda             // I2C 数据
);

    // ========================================
    // PLL: 50 MHz → 74.25 MHz
    // ========================================
    wire clk_pixel;
    wire pll_lock;

    Gowin_rPLL pll_hdmi (
        .clkout(clk_pixel),         // 74.25 MHz
        .lock(pll_lock),
        .clkin(clk_50mhz)           // 50 MHz 输入
    );

    // ========================================
    // 复位同步
    // ========================================
    reg [3:0] reset_sync = 0;
    reg sys_rst_n = 0;

    always @(posedge clk_pixel or negedge key_reset_n) begin
        if (!key_reset_n || !pll_lock) begin
            reset_sync <= 0;
            sys_rst_n <= 0;
        end else begin
            reset_sync <= {reset_sync[2:0], 1'b1};
            sys_rst_n <= reset_sync[3];
        end
    end

    // sys_rst_n is generated in the pixel-clock domain.  Synchronize it
    // before using it as the reset for the 50 MHz I2C controller.
    reg [1:0] reset_50_sync = 0;
    wire sys_rst_n_50 = reset_50_sync[1];
    always @(posedge clk_50mhz or negedge key_reset_n) begin
        if (!key_reset_n) begin
            reset_50_sync <= 2'b00;
        end else begin
            reset_50_sync <= {reset_50_sync[0], sys_rst_n};
        end
    end

    // ========================================
    // ADV7513 初始化控制器
    // ========================================
    wire adv7513_init_done;
    wire adv7513_error;

    adv7513_controller adv7513_ctrl (
        .clk(clk_50mhz),            // 使用 50 MHz 时钟
        .rst_n(sys_rst_n_50),
        .scl(hdmi_scl),
        .sda(hdmi_sda),
        .init_done(adv7513_init_done),
        .error(adv7513_error)
    );

    // ========================================
    // FPGA 内部 48 kHz 音频源与频谱分析器
    // ========================================
    reg [31:0] frame_counter = 0;
    wire sample_tick_48k;
    wire [1023:0] fft_bins_flat;
    wire [2047:0] pcm_buffer_flat;
    wire [511:0] ui_state_flat;
    wire [87:0] key_states_reg;

    // Cross the event bus into the pixel-clock domain with a toggle handshake.
    wire event_valid_pixel;
    wire [3:0] event_type_pixel;
    wire [7:0] event_id_pixel;
    wire [15:0] event_value_pixel;

    ui_event_cdc event_bridge (
        .src_clk(event_clk),
        .src_rst_n(key_reset_n),
        .src_valid(event_valid),
        .src_ready(event_ready),
        .src_type(event_type),
        .src_id(event_id),
        .src_value(event_value),
        .dst_clk(clk_pixel),
        .dst_rst_n(sys_rst_n),
        .dst_valid(event_valid_pixel),
        .dst_type(event_type_pixel),
        .dst_id(event_id_pixel),
        .dst_value(event_value_pixel)
    );

    // Scene-specific generated interaction rules update these state buses.
    // The checked-in module provides the generic event API; generated scenes
    // replace it with their rule-specialized implementation.
    ui_interaction ui_state_ctrl (
        .clk(clk_pixel),
        .rst_n(sys_rst_n),
        .event_valid(event_valid_pixel),
        .event_type(event_type_pixel),
        .event_id(event_id_pixel),
        .event_value(event_value_pixel),
        .ui_state_flat(ui_state_flat),
        .key_states(key_states_reg)
    );

    // Synchronize the I2C controller's completion flag back to the pixel
    // clock for status indication. Audio generation is independent of HDMI
    // transmitter initialization, so the spectrum is available immediately.
    reg [1:0] adv_init_sync = 0;
    wire adv7513_init_done_pixel = adv_init_sync[1];
    always @(posedge clk_pixel or negedge sys_rst_n) begin
        if (!sys_rst_n)
            adv_init_sync <= 2'b00;
        else
            adv_init_sync <= {adv_init_sync[0], adv7513_init_done};
    end

    // 帧计数
    wire frame_tick;
    wire [10:0] pixel_x_internal;
    wire [9:0] pixel_y_internal;

    assign frame_tick = (pixel_x_internal == 0 && pixel_y_internal == 0);

    always @(posedge clk_pixel) begin
        if (!sys_rst_n) begin
            frame_counter <= 0;
        end else if (frame_tick) begin
            frame_counter <= frame_counter + 1;
        end
    end

    audio_synth_48k audio_source (
        .clk(clk_pixel),
        .rst_n(sys_rst_n),
        .sample_tick(sample_tick_48k),
        .fft_bins_flat(fft_bins_flat),
        .pcm_buffer_flat(pcm_buffer_flat)
    );

    // ========================================
    // UI 渲染模块
    // ========================================
    wire [7:0] ui_r, ui_g, ui_b;

    ui_top ui_renderer (
        .clk(clk_pixel),
        .rst_n(sys_rst_n),
        .pixel_x(pixel_x_internal),
        .pixel_y(pixel_y_internal),
        .fft_bins_flat(fft_bins_flat),
        .ui_state_flat(ui_state_flat),
        .pcm_buffer_flat(pcm_buffer_flat),
        .key_states(key_states_reg),
        .rgb_r(ui_r),
        .rgb_g(ui_g),
        .rgb_b(ui_b)
    );

    // ========================================
    // HDMI 时序生成器 (720p60)
    // ========================================
    wire ui_de, ui_hsync, ui_vsync;

    hdmi_timing hdmi_sync (
        .clk(clk_pixel),
        .rst_n(sys_rst_n),
        .pixel_x(pixel_x_internal),
        .pixel_y(pixel_y_internal),
        .hsync(ui_hsync),
        .vsync(ui_vsync),
        .de(ui_de)
    );

    // ========================================
    // HDMI 输出
    // ========================================
    assign hdmi_clk = clk_pixel;
    assign hdmi_de = ui_de;
    assign hdmi_hsync = ui_hsync;
    assign hdmi_vsync = ui_vsync;
    assign hdmi_d = {ui_r, ui_g, ui_b};

    // ========================================
    // LED 调试输出
    // ========================================
    assign led[0] = pll_lock;
    assign led[1] = sys_rst_n;
    assign led[2] = adv7513_init_done;
    assign led[3] = adv7513_error;
    assign led[4] = ui_de;
    assign led[5] = ui_hsync;
    assign led[6] = ui_vsync;
    assign led[7] = frame_counter[20];

endmodule
