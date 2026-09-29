`timescale 1ns / 1ps
//
// Legacy destination-clock event guard.
// The active top-level design uses ui_event_cdc.v instead. Keep this module
// only for compatibility with the historical standalone testbench; do not
// add it to a build that has an asynchronous event source.
//
// The public top-level event ports are intentionally unchanged. This module
// samples the event bus into the pixel-clock domain, then emits one event
// pulse for each rising edge of event_valid. It prevents a level-held valid
// signal from executing add/toggle actions on every pixel clock.
//
// This is not a full asynchronous FIFO: the source must hold event_valid and
// all payload bits stable for at least two destination-clock cycles and must
// provide a sampled-low cycle between events. Without an event clock or
// handshake, an arbitrarily short pulse or changing multi-bit payload cannot
// be transferred atomically.
module ui_event_guard (
    input wire clk,
    input wire rst_n,
    input wire event_valid_in,
    input wire [3:0] event_type_in,
    input wire [7:0] event_id_in,
    input wire [15:0] event_value_in,
    output wire event_valid_out,
    output wire [3:0] event_type_out,
    output wire [7:0] event_id_out,
    output wire [15:0] event_value_out
);
    reg valid_meta;
    reg valid_sync;
    reg valid_sync_d;
    reg [3:0] type_meta;
    reg [3:0] type_sync;
    reg [7:0] id_meta;
    reg [7:0] id_sync;
    reg [15:0] value_meta;
    reg [15:0] value_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_meta <= 1'b0;
            valid_sync <= 1'b0;
            valid_sync_d <= 1'b0;
            type_meta <= 4'd0;
            type_sync <= 4'd0;
            id_meta <= 8'd0;
            id_sync <= 8'd0;
            value_meta <= 16'd0;
            value_sync <= 16'd0;
        end else begin
            valid_meta <= event_valid_in;
            valid_sync <= valid_meta;
            valid_sync_d <= valid_sync;
            type_meta <= event_type_in;
            type_sync <= type_meta;
            id_meta <= event_id_in;
            id_sync <= id_meta;
            value_meta <= event_value_in;
            value_sync <= value_meta;
        end
    end

    // The synchronized payload is stable before this pulse is observed by a
    // consumer at the next rising edge of clk.
    assign event_valid_out = valid_sync && !valid_sync_d;
    assign event_type_out = type_sync;
    assign event_id_out = id_sync;
    assign event_value_out = value_sync;
endmodule
