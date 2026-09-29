// Tang Mega 60K LED 测试
// 最简单的测试 - 让 LED 闪烁证明 FPGA 工作

module top_led_test (
    input  wire       clk_27mhz,
    input  wire       key_reset_n,
    output wire [5:0] led
);

    // 复位同步
    reg [1:0] rst_sync;
    wire rst_n = rst_sync[1];

    always @(posedge clk_27mhz or negedge key_reset_n) begin
        if (!key_reset_n)
            rst_sync <= 2'b00;
        else
            rst_sync <= {rst_sync[0], 1'b1};
    end

    // 计数器
    reg [25:0] counter;

    always @(posedge clk_27mhz or negedge rst_n) begin
        if (!rst_n)
            counter <= 26'd0;
        else
            counter <= counter + 1'd1;
    end

    // LED 输出 (active low)
    assign led[0] = ~counter[23];  // 约 3.2 Hz
    assign led[1] = ~counter[22];  // 约 6.4 Hz
    assign led[2] = ~counter[21];  // 约 12.8 Hz
    assign led[3] = ~counter[20];  // 约 25.6 Hz
    assign led[4] = ~counter[24];  // 约 1.6 Hz
    assign led[5] = ~rst_n;        // 复位指示

endmodule
