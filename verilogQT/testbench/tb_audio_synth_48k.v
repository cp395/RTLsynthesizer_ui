`timescale 1ns / 1ps

module tb_audio_synth_48k;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire sample_tick;
    wire [1023:0] fft_bins_flat;
    wire [2047:0] pcm_buffer_flat;

    integer cycles = 0;
    integer ticks = 0;
    reg saw_spectrum = 1'b0;

    always #1 clk = ~clk;

    audio_synth_48k dut (
        .clk(clk),
        .rst_n(rst_n),
        .sample_tick(sample_tick),
        .fft_bins_flat(fft_bins_flat),
        .pcm_buffer_flat(pcm_buffer_flat)
    );

    always @(posedge clk) begin
        cycles = cycles + 1;
        if (sample_tick)
            ticks = ticks + 1;
        if (|fft_bins_flat[255:8])
            saw_spectrum = 1'b1;

        if (cycles == 350000) begin
            if (ticks < 220 || ticks > 235) begin
                $display("FAIL: expected about 226 sample ticks, got %0d", ticks);
                $finish(1);
            end
            if (!saw_spectrum) begin
                $display("FAIL: analyzer never produced a non-zero bin");
                $finish(1);
            end
            $display("PASS: 48 kHz ticks=%0d, dynamic spectrum observed", ticks);
            $finish(0);
        end
    end

    initial begin
        #10 rst_n = 1'b1;
    end
endmodule
