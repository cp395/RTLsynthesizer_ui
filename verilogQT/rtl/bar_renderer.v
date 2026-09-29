`timescale 1ns / 1ps
//
// Bar (Progress Bar) Renderer
//

module bar_renderer #(
    parameter X_START = 0,
    parameter Y_START = 0,
    parameter WIDTH = 200,
    parameter HEIGHT = 20,
    parameter MAX_VALUE = 65535,
    parameter FG_COLOR = 24'h38BDF8,
    parameter BG_COLOR = 24'h1E2836
) (
    input wire [10:0] pixel_x,
    input wire [9:0] pixel_y,
    input wire [15:0] value,        // 0~65535
    output wire active,
    output wire [23:0] color
);

    wire in_x = (pixel_x >= X_START) && (pixel_x < X_START + WIDTH);
    wire in_y = (pixel_y >= Y_START) && (pixel_y < Y_START + HEIGHT);

    // Scale against the widget's declared range.  The old implementation
    // always treated the input as Q16, which made a JSON bar with
    // max_value=100 disagree with the Python preview.
    localparam integer EFFECTIVE_MAX = (MAX_VALUE > 0) ? MAX_VALUE : 1;
    wire [31:0] clamped_value = (value > EFFECTIVE_MAX) ? EFFECTIVE_MAX : value;
    // EFFECTIVE_MAX and WIDTH are parameters.  Compute a fixed-point scale at
    // elaboration so the pixel path contains only a constant-coefficient
    // multiply and shift rather than a general divider.
    localparam integer VALUE_FRAC_BITS = 44;
    localparam [63:0] VALUE_STEP_Q = (EFFECTIVE_MAX > 0) ?
                                     ((((64'd1 << VALUE_FRAC_BITS) * WIDTH) + EFFECTIVE_MAX - 1) / EFFECTIVE_MAX) : 0;
    // Preserve the full fixed-point product for parameterized widths/ranges.
    wire [79:0] filled_width_fp = {48'd0, clamped_value} * {16'd0, VALUE_STEP_Q};
    wire [31:0] filled_width = filled_width_fp >> VALUE_FRAC_BITS;

    wire [10:0] local_x = pixel_x - X_START;
    wire is_filled = local_x < filled_width;

    assign active = in_x && in_y;
    assign color = active ? (is_filled ? FG_COLOR : BG_COLOR) : 24'd0;

endmodule
