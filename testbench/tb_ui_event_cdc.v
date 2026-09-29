`timescale 1ns / 1ps

// Asynchronous-clock smoke test for ui_event_cdc.
// The source side follows the ready/valid contract: payload and valid stay
// unchanged until the accepting source clock edge, then valid is released.
module tb_ui_event_cdc;
    reg src_clk = 1'b0;
    reg dst_clk = 1'b0;
    reg src_rst_n = 1'b0;
    reg dst_rst_n = 1'b0;
    reg src_valid = 1'b0;
    reg [3:0] src_type = 4'd0;
    reg [7:0] src_id = 8'd0;
    reg [15:0] src_value = 16'd0;
    wire src_ready;
    wire dst_valid;
    wire [3:0] dst_type;
    wire [7:0] dst_id;
    wire [15:0] dst_value;

    integer source_accepts = 0;
    integer destination_pulses = 0;
    reg previous_dst_valid = 1'b0;

    ui_event_cdc dut (
        .src_clk(src_clk),
        .src_rst_n(src_rst_n),
        .src_valid(src_valid),
        .src_ready(src_ready),
        .src_type(src_type),
        .src_id(src_id),
        .src_value(src_value),
        .dst_clk(dst_clk),
        .dst_rst_n(dst_rst_n),
        .dst_valid(dst_valid),
        .dst_type(dst_type),
        .dst_id(dst_id),
        .dst_value(dst_value)
    );

    // Deliberately unrelated periods (10 ns and 14 ns).
    always #5 src_clk = ~src_clk;
    always #7 dst_clk = ~dst_clk;

    always @(posedge src_clk) begin
        if (src_rst_n && src_valid && src_ready)
            source_accepts = source_accepts + 1;
    end

    always @(posedge dst_clk) begin
        if (dst_valid && previous_dst_valid)
            $fatal(1, "destination valid was wider than one destination cycle");
        previous_dst_valid = dst_valid;

        if (dst_valid) begin
            destination_pulses = destination_pulses + 1;
            case (destination_pulses)
                1: begin
                    if (dst_type !== 4'd1 || dst_id !== 8'h11 ||
                        dst_value !== 16'hCAFE)
                        $fatal(1, "first asynchronous payload was corrupted");
                end
                2: begin
                    if (dst_type !== 4'd6 || dst_id !== 8'hA5 ||
                        dst_value !== 16'h003C)
                        $fatal(1, "second asynchronous payload was corrupted");
                end
                3: begin
                    if (dst_type !== 4'd9 || dst_id !== 8'h20 ||
                        dst_value !== 16'h0001)
                        $fatal(1, "third asynchronous payload was corrupted");
                end
                default:
                    $fatal(1, "unexpected destination pulse %0d", destination_pulses);
            endcase
        end
    end

    // Submit exactly one event. The valid level is held through the accepting
    // source edge and released on the following half cycle.
    task automatic send_event;
        input [3:0] event_type;
        input [7:0] event_id;
        input [15:0] event_value;
        begin
            while (src_ready !== 1'b1)
                @(posedge src_clk);

            @(negedge src_clk);
            src_type = event_type;
            src_id = event_id;
            src_value = event_value;
            src_valid = 1'b1;

            // At this edge src_ready is sampled before the DUT toggles its
            // request bit. This avoids holding valid into the next handshake.
            forever begin
                @(posedge src_clk);
                if (src_ready === 1'b1) begin
                    @(negedge src_clk);
                    src_valid = 1'b0;
                    disable send_event;
                end
            end
        end
    endtask

    initial begin
        // Keep both domains in reset long enough to observe reset values.
        #23;
        if (src_ready !== 1'b1)
            $fatal(1, "source side was not ready after reset");
        src_rst_n = 1'b1;
        dst_rst_n = 1'b1;

        send_event(4'd1, 8'h11, 16'hCAFE);
        wait (destination_pulses == 1);
        repeat (4) @(posedge dst_clk);
        if (destination_pulses !== 1)
            $fatal(1, "one source transaction generated multiple destination pulses");

        send_event(4'd6, 8'hA5, 16'h003C);
        wait (destination_pulses == 2);
        repeat (3) @(posedge dst_clk);

        send_event(4'd9, 8'h20, 16'h0001);
        wait (destination_pulses == 3);
        repeat (4) @(posedge dst_clk);

        if (source_accepts !== 3)
            $fatal(1, "expected 3 source handshakes, got %0d", source_accepts);
        if (destination_pulses !== 3)
            $fatal(1, "expected 3 destination pulses, got %0d", destination_pulses);

        $display("PASS: ui_event_cdc asynchronous handshake and payload integrity");
        $finish;
    end
endmodule
