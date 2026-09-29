`timescale 1ns / 1ps
//
// HDMI Timing Generator for 1280x720 @ 60Hz
// Pixel clock: 74.25 MHz
//

module hdmi_timing (
    input wire clk,              // 74.25 MHz
    input wire rst_n,

    output reg [10:0] pixel_x,   // 0~1649
    output reg [9:0] pixel_y,    // 0~749
    output reg hsync,
    output reg vsync,
    output wire de               // 数据使能 (display enable)
);

    // 1280x720 @ 60Hz timing parameters
    localparam H_ACTIVE = 1280;
    localparam H_FRONT  = 110;
    localparam H_SYNC   = 40;
    localparam H_BACK   = 220;
    localparam H_TOTAL  = 1650;

    localparam V_ACTIVE = 720;
    localparam V_FRONT  = 5;
    localparam V_SYNC   = 5;
    localparam V_BACK   = 20;
    localparam V_TOTAL  = 750;

    // Horizontal counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_x <= 11'd0;
        end else begin
            if (pixel_x == H_TOTAL - 1)
                pixel_x <= 11'd0;
            else
                pixel_x <= pixel_x + 1'b1;
        end
    end

    // Vertical counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_y <= 10'd0;
        end else begin
            if (pixel_x == H_TOTAL - 1) begin
                if (pixel_y == V_TOTAL - 1)
                    pixel_y <= 10'd0;
                else
                    pixel_y <= pixel_y + 1'b1;
            end
        end
    end

    // Sync signals (active low for HDMI)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hsync <= 1'b0;
            vsync <= 1'b0;
        end else begin
            hsync <= (pixel_x >= H_ACTIVE + H_FRONT) &&
                     (pixel_x < H_ACTIVE + H_FRONT + H_SYNC) ? 1'b0 : 1'b1;
            vsync <= (pixel_y >= V_ACTIVE + V_FRONT) &&
                     (pixel_y < V_ACTIVE + V_FRONT + V_SYNC) ? 1'b0 : 1'b1;
        end
    end

    // Display active region (registered for timing alignment)
    reg de_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            de_reg <= 1'b0;
        else
            de_reg <= (pixel_x < H_ACTIVE) && (pixel_y < V_ACTIVE);
    end

    assign de = de_reg;

endmodule