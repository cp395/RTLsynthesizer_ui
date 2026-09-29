`timescale 1ns/1ps
module tb_ui_interaction;
    reg clk = 0;
    reg rst_n = 0;
    reg event_valid = 0;
    reg [3:0] event_type = 0;
    reg [7:0] event_id = 0;
    reg [15:0] event_value = 0;
    wire [511:0] ui_state_flat;
    wire [87:0] key_states;

    ui_interaction dut (
        .clk(clk), .rst_n(rst_n), .event_valid(event_valid),
        .event_type(event_type), .event_id(event_id),
        .event_value(event_value), .ui_state_flat(ui_state_flat),
        .key_states(key_states)
    );

    always #5 clk = ~clk;

    task send;
        input [3:0] t;
        input [7:0] i;
        input [15:0] v;
        begin
            @(negedge clk);
            event_type = t;
            event_id = i;
            event_value = v;
            event_valid = 1'b1;
            @(negedge clk);
            event_valid = 1'b0;
        end
    endtask

    initial begin
        #12 rst_n = 1'b1;
        send(4'd8, 8'd4, 16'd42);
        if (ui_state_flat[4*16 +: 16] !== 16'd42) $fatal(1, "direct set failed");
        send(4'd11, 8'd7, 16'd0);
        if (key_states[7] !== 1'b1) $fatal(1, "direct key set failed");
        send(4'd12, 8'd7, 16'd0);
        if (key_states[7] !== 1'b0) $fatal(1, "direct key clear failed");
        send(4'd1, 8'd0, 16'd0);
        if (ui_state_flat[0 +: 16] !== 16'd1234 || key_states[3] !== 1'b1 ||
            ui_state_flat[2*16 +: 16] !== 16'd0)
            $fatal(1, "scene click failed");
        send(4'd8, 8'd0, 16'hFFFF);
        send(4'd9, 8'd0, 16'd1);
        if (ui_state_flat[0 +: 16] !== 16'hFFFF) $fatal(1, "saturating add failed");
        send(4'd10, 8'd0, 16'd0);
        if (ui_state_flat[0 +: 16] !== 16'd0) $fatal(1, "logical toggle failed");
        send(4'd4, 8'd1, 16'd321);
        if (ui_state_flat[0 +: 16] !== 16'd321 ||
            ui_state_flat[16 +: 16] !== 16'd326) $fatal(1, "scene change failed");
        send(4'd5, 8'd2, 16'd7);
        if (key_states[7] !== 1'b1) $fatal(1, "scene key event failed");
        send(4'd2, 8'd0, 16'd2);
        if (key_states[4] !== 1'b1 || ui_state_flat[3*16 +: 16] !== 16'd0)
            $fatal(1, "event value boolean or signed add conversion failed");
        send(4'd3, 8'd0, 16'd0);
        if (ui_state_flat[2*16 +: 16] !== 16'hFFFF) $fatal(1, "ordered saturating actions failed");
        send(4'd5, 8'd2, 16'd255);
        if (key_states[0] !== 1'b0) $fatal(1, "out-of-range key event wrapped");
        $display("PASS: generated RTL event behavior");
        $finish;
    end
endmodule
