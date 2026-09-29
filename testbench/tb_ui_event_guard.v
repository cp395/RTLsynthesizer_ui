`timescale 1ns / 1ps
module tb_ui_event_guard;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg event_valid_in = 1'b0;
    reg [3:0] event_type_in = 4'd0;
    reg [7:0] event_id_in = 8'd0;
    reg [15:0] event_value_in = 16'd0;
    wire event_valid_out;
    wire [3:0] event_type_out;
    wire [7:0] event_id_out;
    wire [15:0] event_value_out;
    integer pulse_count = 0;

    ui_event_guard dut (
        .clk(clk), .rst_n(rst_n),
        .event_valid_in(event_valid_in),
        .event_type_in(event_type_in),
        .event_id_in(event_id_in),
        .event_value_in(event_value_in),
        .event_valid_out(event_valid_out),
        .event_type_out(event_type_out),
        .event_id_out(event_id_out),
        .event_value_out(event_value_out)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (event_valid_out) begin
            pulse_count = pulse_count + 1;
            if (pulse_count == 1) begin
                if (event_type_out !== 4'd4 || event_id_out !== 8'd9 ||
                    event_value_out !== 16'h1234)
                    $fatal(1, "first payload changed during guarded event");
            end else if (pulse_count == 2) begin
                if (event_type_out !== 4'd5 || event_id_out !== 8'd28 ||
                    event_value_out !== 16'd7)
                    $fatal(1, "second payload changed during guarded event");
            end
        end
    end

    initial begin
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        // A level-held event must be consumed once, not once per clock.
        @(negedge clk);
        event_type_in = 4'd4;
        event_id_in = 8'd9;
        event_value_in = 16'h1234;
        event_valid_in = 1'b1;
        repeat (6) @(posedge clk);
        if (pulse_count !== 1) $fatal(1, "held valid was consumed more than once");

        // A sampled-low gap permits the next event.
        @(negedge clk);
        event_valid_in = 1'b0;
        repeat (3) @(posedge clk);
        @(negedge clk);
        event_type_in = 4'd5;
        event_id_in = 8'd28;
        event_value_in = 16'd7;
        event_valid_in = 1'b1;
        repeat (4) @(posedge clk);
        if (pulse_count !== 2) $fatal(1, "second guarded event was not emitted");

        $display("PASS: event guard de-duplicates held valid");
        $finish;
    end
endmodule
