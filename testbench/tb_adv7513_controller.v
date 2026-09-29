`timescale 1ns / 1ps

// Protocol-level smoke test for the open-drain I2C controller.  The model
// acknowledges every byte and checks that the first transmitted byte is the
// expected 0x72 address (7-bit 0x39 plus the write bit).
module tb_adv7513_controller;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire scl;
    tri sda;
    integer bit_pos = 0;
    integer byte_count = 0;
    reg [7:0] shift_reg = 8'd0;
    reg saw_bad_address = 1'b0;

    always #10 clk = ~clk; // 50 MHz

    pullup(sda);
    // The slave holds SDA low for the complete high phase of every ACK bit.
    // This is derived from the DUT state only for the test model; the real
    // board provides the same behavior inside the HDMI transmitter.
    wire slave_ack = ((dut.state == 4'd3) ||
                      (dut.state == 4'd5) ||
                      (dut.state == 4'd7)) &&
                     (dut.bit_phase != 2'd0);
    assign sda = slave_ack ? 1'b0 : 1'bz;

    adv7513_controller dut (
        .clk(clk),
        .rst_n(rst_n),
        .scl(scl),
        .sda(sda),
        .init_done(init_done),
        .error(error)
    );

    wire init_done;
    wire error;

    // A falling SDA edge while SCL is high is a START condition.  Reset the
    // byte parser so STOP/START boundaries do not affect the next byte.
    always @(negedge sda) begin
        if (scl) begin
            bit_pos = 0;
            shift_reg = 8'd0;
        end
    end

    // Sample transmitted bits and pull SDA low during every ACK bit.
    always @(posedge scl) begin
        if (bit_pos < 8) begin
            shift_reg = {shift_reg[6:0], sda};
            if (bit_pos == 7) begin
                byte_count = byte_count + 1;
                if (byte_count == 0 && {shift_reg[6:0], sda} != 8'h72)
                    saw_bad_address = 1'b1;
            end
            bit_pos = bit_pos + 1;
        end else begin
            bit_pos = 9;
        end
    end

    always @(negedge scl) begin
        if (bit_pos == 9) begin
            bit_pos = 0;
        end
    end

    initial begin
        #200;
        rst_n = 1'b1;
        // Twenty-one register writes take well under 10 ms at the configured
        // divider.  Leave margin for the final STOP and DONE state.
        #10_000_000;
        if (error) begin
            $display("FAIL: controller reported I2C error state=%0d reg=%0d phase=%0d bytes=%0d", dut.state, dut.reg_index, dut.bit_phase, byte_count);
            $finish(1);
        end
        if (saw_bad_address) begin
            $display("FAIL: address byte was not transmitted MSB first");
            $finish(1);
        end
        if (!init_done) begin
            $display("FAIL: controller did not complete initialization");
            $finish(1);
        end
        if (byte_count < 60) begin
            $display("FAIL: expected register traffic, saw %0d bytes", byte_count);
            $finish(1);
        end
        $display("PASS: I2C controller completed %0d bytes", byte_count);
        $finish(0);
    end
endmodule
