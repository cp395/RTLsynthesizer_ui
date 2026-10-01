`timescale 1ns / 1ps
//
// Spectrum Analyzer Renderer
//

module spectrum_renderer #(
    parameter X_START = 0,
    parameter Y_START = 0,
    parameter WIDTH = 600,
    parameter HEIGHT = 240,
    parameter NUM_BARS = 64,
    parameter BAR_COLOR = 24'h38BDF8,
    parameter BG_COLOR = 24'h0F131C
) (
    input wire clk,
    input wire [10:0] pixel_x,
    input wire [9:0] pixel_y,
    input wire [1023:0] fft_bins_flat,  // 128 * 8 bits flattened
    output wire active,
    output wire [23:0] color
);

    // Unpack flattened FFT bins
    wire [7:0] fft_bins [0:127];
    genvar i;
    generate
        for (i = 0; i < 128; i = i + 1) begin : gen_fft
            assign fft_bins[i] = fft_bins_flat[i*8 +: 8];
        end
    endgenerate

    localparam BAR_WIDTH = WIDTH / NUM_BARS;
    localparam GAP = BAR_WIDTH >> 3;  // 1/8 of bar width
    localparam ACTUAL_BAR_WIDTH = BAR_WIDTH - GAP;

    wire in_x = (pixel_x >= X_START) && (pixel_x < X_START + WIDTH);
    wire in_y = (pixel_y >= Y_START) && (pixel_y < Y_START + HEIGHT);

    // Determine which bar. The default 64-bar scene has nine-pixel bars;
    // a small constant divider is considerably cheaper than a wide fixed-
    // point multiplier chain.
    wire [10:0] local_x = pixel_x - X_START;
    wire [9:0] local_y = pixel_y - Y_START;
    wire [7:0] bar_index = (BAR_WIDTH > 0) ? (local_x / BAR_WIDTH) : 8'd0;

    // Get bar height from FFT bins
    wire [7:0] bin_value = (bar_index < NUM_BARS) ? fft_bins[bar_index] : 8'd0;

    // Scale to screen height: bar_height = (bin_value * HEIGHT) >> 8.
    // Keep the full product so custom widgets taller than 257 pixels do not
    // wrap when the intermediate value exceeds 16 bits.
    wire [31:0] mult;
    generate
        if (HEIGHT == 200) begin : gen_default_height_scale
            // 200 = 128 + 64 + 8; avoid a DSP for the default scene.
            assign mult = ({24'd0, bin_value} << 7) +
                          ({24'd0, bin_value} << 6) +
                          ({24'd0, bin_value} << 3);
        end else if (HEIGHT == 240) begin : gen_240px_height_scale
            assign mult = ({24'd0, bin_value} << 8) -
                          ({24'd0, bin_value} << 4);
        end else begin : gen_generic_height_scale
            assign mult = {24'd0, bin_value} * HEIGHT;
        end
    endgenerate
    wire [15:0] bar_height_scaled = mult >> 8;
    wire [15:0] bar_height = (bar_height_scaled > HEIGHT) ? HEIGHT : bar_height_scaled;

    // Check if in bar or gap
    wire [10:0] bar_offset;
    generate
        if (BAR_WIDTH == 9) begin : gen_default_bar_offset
            assign bar_offset = (bar_index << 3) + bar_index;
        end else begin : gen_generic_bar_offset
            assign bar_offset = bar_index * BAR_WIDTH;
        end
    endgenerate
    wire [10:0] bar_local_x = local_x - bar_offset;
    wire in_bar = bar_local_x < ACTUAL_BAR_WIDTH;

    // Check if pixel is in filled region
    wire [15:0] threshold_y = HEIGHT - bar_height;
    wire is_filled = local_y >= threshold_y;

    assign active = in_x && in_y;
    assign color = active ? (in_bar && is_filled ? BAR_COLOR : BG_COLOR) : 24'd0;

endmodule
