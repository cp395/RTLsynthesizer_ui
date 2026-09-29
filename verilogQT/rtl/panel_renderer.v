`timescale 1ns / 1ps
//
// Panel (Rectangle) Renderer
//

module panel_renderer #(
    parameter X_START = 0,
    parameter Y_START = 0,
    parameter WIDTH = 100,
    parameter HEIGHT = 100,
    parameter BG_COLOR = 24'h0A0D12
) (
    input wire [10:0] pixel_x,
    input wire [9:0] pixel_y,
    output wire active,
    output wire [23:0] color
);

    wire in_x = (pixel_x >= X_START) && (pixel_x < X_START + WIDTH);
    wire in_y = (pixel_y >= Y_START) && (pixel_y < Y_START + HEIGHT);

    assign active = in_x && in_y;
    assign color = active ? BG_COLOR : 24'd0;

endmodule