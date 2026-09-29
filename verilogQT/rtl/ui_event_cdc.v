`timescale 1ns / 1ps
// Clock-domain bridge for the UI event bus.
// The source must hold src_valid high until src_ready is asserted.  One
// accepted event is delivered as a one-cycle dst_valid pulse.
module ui_event_cdc (
    input wire src_clk,
    input wire src_rst_n,
    input wire src_valid,
    output wire src_ready,
    input wire [3:0] src_type,
    input wire [7:0] src_id,
    input wire [15:0] src_value,
    input wire dst_clk,
    input wire dst_rst_n,
    output reg dst_valid,
    output reg [3:0] dst_type,
    output reg [7:0] dst_id,
    output reg [15:0] dst_value
);
    reg request_toggle;
    reg acknowledge_toggle;
    reg [3:0] held_type;
    reg [7:0] held_id;
    reg [15:0] held_value;

    reg ack_sync_1;
    reg ack_sync_2;
    reg request_sync_1;
    reg request_sync_2;

    assign src_ready = (request_toggle == ack_sync_2);

    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            request_toggle <= 1'b0;
            held_type <= 4'd0;
            held_id <= 8'd0;
            held_value <= 16'd0;
            ack_sync_1 <= 1'b0;
            ack_sync_2 <= 1'b0;
        end else begin
            ack_sync_1 <= acknowledge_toggle;
            ack_sync_2 <= ack_sync_1;
            if (src_valid && src_ready) begin
                held_type <= src_type;
                held_id <= src_id;
                held_value <= src_value;
                request_toggle <= ~request_toggle;
            end
        end
    end

    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            request_sync_1 <= 1'b0;
            request_sync_2 <= 1'b0;
            acknowledge_toggle <= 1'b0;
            dst_valid <= 1'b0;
            dst_type <= 4'd0;
            dst_id <= 8'd0;
            dst_value <= 16'd0;
        end else begin
            request_sync_1 <= request_toggle;
            request_sync_2 <= request_sync_1;
            dst_valid <= 1'b0;
            if (request_sync_2 != acknowledge_toggle) begin
                // The source holds the payload until the acknowledge returns.
                dst_type <= held_type;
                dst_id <= held_id;
                dst_value <= held_value;
                dst_valid <= 1'b1;
                acknowledge_toggle <= request_sync_2;
            end
        end
    end
endmodule
