`timescale 1ns / 1ps
//
// UI Top Module
// 连接 UI 渲染器和数据源
//

module ui_top (
    input wire clk,
    input wire rst_n,

    // 时序信号
    input wire [10:0] pixel_x,
    input wire [9:0] pixel_y,

    // 数据输入 - 扁平化接口
    input wire [1023:0] fft_bins_flat,    // 128 bins * 8 bits
    input wire [511:0] ui_state_flat,     // 32 registers * 16 bits
    input wire [16383:0] pcm_buffer_flat, // 1024 samples * 16 bits
    input wire [87:0] key_states,         // 88 keys max

    // RGB 输出
    output wire [7:0] rgb_r,
    output wire [7:0] rgb_g,
    output wire [7:0] rgb_b
);

    // 实例化像素渲染器
    pixel_renderer renderer (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .fft_bins_flat(fft_bins_flat),
        .ui_state_flat(ui_state_flat),
        .pcm_buffer_flat(pcm_buffer_flat),
        .key_states(key_states),
        .rgb_r(rgb_r),
        .rgb_g(rgb_g),
        .rgb_b(rgb_b)
    );

endmodule
