`timescale 1ns / 1ps
//
// Waveform Renderer
// 显示 PCM 波形
//

module waveform_renderer #(
    parameter X_START = 0,
    parameter Y_START = 0,
    parameter WIDTH = 600,
    parameter HEIGHT = 200,
    parameter SAMPLES = 128,
    parameter LINE_COLOR = 24'h6EE7B7,
    parameter BG_COLOR = 24'h0A0D12
) (
    input wire clk,
    input wire [10:0] pixel_x,
    input wire [9:0] pixel_y,
    input wire [2047:0] pcm_buffer_flat,   // 128 samples * signed 16 bits
    output wire active,
    output wire [23:0] color
);

    // 解包 PCM buffer
    wire signed [15:0] pcm_samples [0:127];
    genvar i;
    generate
        for (i = 0; i < 128; i = i + 1) begin : gen_pcm
            assign pcm_samples[i] = pcm_buffer_flat[i*16 +: 16];
        end
    endgenerate

    wire in_x = (pixel_x >= X_START) && (pixel_x < X_START + WIDTH);
    wire in_y = (pixel_y >= Y_START) && (pixel_y < Y_START + HEIGHT);
    assign active = in_x && in_y;

    // 计算中心线
    localparam CENTER_Y = Y_START + (HEIGHT / 2);
    localparam HALF_HEIGHT = HEIGHT / 2;

    // 当前 X 位置对应的样本索引。128 点场景只需要 7 位左移；保留
    // 通用分支供其它采样数使用，避免在默认像素路径上生成宽乘法器。
    wire [10:0] local_x = pixel_x - X_START;
    wire [10:0] sample_idx;
    generate
        if (SAMPLES == 128) begin : gen_default_sample_index
            wire [17:0] sample_idx_scaled = {local_x, 7'd0};
            assign sample_idx = (WIDTH > 0) ? (sample_idx_scaled / WIDTH) : 11'd0;
        end else begin : gen_generic_sample_index
            assign sample_idx = (WIDTH > 0) ? ((local_x * SAMPLES) / WIDTH) : 11'd0;
        end
    endgenerate

    // 获取当前样本值
    wire signed [15:0] current_sample = (sample_idx < SAMPLES) ?
                                        pcm_samples[sample_idx] : 16'sd0;

    // 将样本值映射到 Y 坐标 (-32768..32767 -> -HALF_HEIGHT..HALF_HEIGHT)。
    // 32768 is 2^15, so use an arithmetic shift instead of a divider.
    wire signed [31:0] current_sample_ext = {{16{current_sample[15]}}, current_sample};
    wire signed [31:0] sample_scaled;
    generate
        if (HALF_HEIGHT == 75) begin : gen_default_sample_scale
            // 75 = 64 + 8 + 2 + 1; avoid a DSP for the default 150-pixel
            // waveform widget.
            assign sample_scaled = (current_sample_ext <<< 6) +
                                   (current_sample_ext <<< 3) +
                                   (current_sample_ext <<< 1) +
                                   current_sample_ext;
        end else if (HALF_HEIGHT == 100) begin : gen_200px_sample_scale
            assign sample_scaled = (current_sample_ext <<< 6) +
                                   (current_sample_ext <<< 5) +
                                   (current_sample_ext <<< 2);
        end else begin : gen_generic_sample_scale
            assign sample_scaled = current_sample * HALF_HEIGHT;
        end
    endgenerate
    wire signed [31:0] y_offset_calc =
        (sample_scaled + (sample_scaled[31] ? 32'sd32767 : 32'sd0)) >>> 15;
    wire signed [15:0] y_offset = y_offset_calc[15:0];
    wire [9:0] waveform_y = CENTER_Y - y_offset;

    // 检查当前像素是否在波形线上（±2 像素容差）
    wire [9:0] y_diff = (pixel_y > waveform_y) ?
                        (pixel_y - waveform_y) :
                        (waveform_y - pixel_y);
    wire on_waveform = (y_diff <= 2) && in_x && in_y;

    assign color = active ? (on_waveform ? LINE_COLOR : BG_COLOR) : 24'd0;

endmodule
