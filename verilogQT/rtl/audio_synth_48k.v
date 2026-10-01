`timescale 1ns / 1ps
//
// Internal 48 kHz audio source and lightweight 128-point spectrum analyzer.
// The sample-rate clock enable is generated from the 74.25 MHz pixel clock;
// the audio source never depends on a board audio peripheral.
//

module audio_synth_48k #(
    parameter integer ANALYSIS_BINS = 32
) (
    input wire clk,
    input wire rst_n,
    output wire sample_tick,
    output wire [1023:0] fft_bins_flat,
    output wire [2047:0] pcm_buffer_flat
);

    // 48,000 / 74,250,000 in Q0.32. The resulting rate error is below 0.01 Hz.
    localparam [31:0] SAMPLE_PHASE_INC = 32'd2776545;
    // Tone phase increments are expressed per 48 kHz sample.
    localparam [31:0] TONE_A_INC = 32'd39370534;   // 440 Hz
    localparam [31:0] TONE_B_LOW_INC = 32'd59055801;  // 660 Hz
    localparam [31:0] TONE_B_HIGH_INC = 32'd78741067; // 880 Hz
    localparam [31:0] LFO_INC = 32'd89478;          // 1 Hz mode switch

    reg [31:0] sample_phase;
    reg [31:0] tone_a_phase;
    reg [31:0] tone_b_phase;
    reg [31:0] lfo_phase;

    wire [32:0] sample_phase_sum = {1'b0, sample_phase} +
                                    {1'b0, SAMPLE_PHASE_INC};
    assign sample_tick = sample_phase_sum[32];

    // A triangle wave is sufficient for a deterministic on-chip test source
    // and avoids a large sine ROM.
    function signed [15:0] triangle_wave;
        input [31:0] phase;
        reg [7:0] p;
        reg signed [16:0] value;
        begin
            p = phase[31:24];
            if (p < 8'd64)
                value = $signed({1'b0, p}) <<< 9;
            else if (p < 8'd192)
                value = 17'sd32767 - ($signed({1'b0, p - 8'd64}) <<< 9);
            else
                value = -17'sd32768 + ($signed({1'b0, p - 8'd192}) <<< 9);
            triangle_wave = value[15:0];
        end
    endfunction

    wire signed [15:0] tone_a = triangle_wave(tone_a_phase);
    wire signed [15:0] tone_b = triangle_wave(tone_b_phase);
    wire signed [17:0] mixed_sample =
        (tone_a >>> 1) + (tone_a >>> 2) +
        (lfo_phase[31] ? (tone_b >>> 2) : (tone_b >>> 3));
    wire signed [15:0] generated_sample = mixed_sample[15:0];

    // Two banks let the sample writer fill one window while the analyzer reads
    // the previous one. The completed bank is the one shown on screen.
    reg signed [15:0] sample_mem [0:1][0:127];
    reg write_bank;
    reg [6:0] write_index;
    reg analysis_bank;

    wire display_bank = ~write_bank;
    genvar p;
    generate
        for (p = 0; p < 128; p = p + 1) begin : gen_pcm_output
            assign pcm_buffer_flat[p*16 +: 16] = sample_mem[display_bank][p];
        end
        for (p = 0; p < 128; p = p + 1) begin : gen_fft_output
            assign fft_bins_flat[p*8 +: 8] = fft_bins[p];
        end
    endgenerate

    reg [7:0] fft_bins [0:127];

    // A compact cosine table for 128-point DFT twiddle factors. Values are Q15.
    // Keep the quarter-wave table as a separate non-recursive function; some
    // Icarus versions crash while elaborating recursive constant functions.
    function signed [15:0] twiddle_quarter;
        input [6:0] index;
        begin
            case (index)
                7'd0: twiddle_quarter = 16'sd32767;
                7'd1: twiddle_quarter = 16'sd32728;
                7'd2: twiddle_quarter = 16'sd32609;
                7'd3: twiddle_quarter = 16'sd32412;
                7'd4: twiddle_quarter = 16'sd32137;
                7'd5: twiddle_quarter = 16'sd31785;
                7'd6: twiddle_quarter = 16'sd31356;
                7'd7: twiddle_quarter = 16'sd30852;
                7'd8: twiddle_quarter = 16'sd30273;
                7'd9: twiddle_quarter = 16'sd29621;
                7'd10: twiddle_quarter = 16'sd28898;
                7'd11: twiddle_quarter = 16'sd28105;
                7'd12: twiddle_quarter = 16'sd27245;
                7'd13: twiddle_quarter = 16'sd26319;
                7'd14: twiddle_quarter = 16'sd25329;
                7'd15: twiddle_quarter = 16'sd24279;
                7'd16: twiddle_quarter = 16'sd23170;
                7'd17: twiddle_quarter = 16'sd22005;
                7'd18: twiddle_quarter = 16'sd20787;
                7'd19: twiddle_quarter = 16'sd19519;
                7'd20: twiddle_quarter = 16'sd18204;
                7'd21: twiddle_quarter = 16'sd16846;
                7'd22: twiddle_quarter = 16'sd15446;
                7'd23: twiddle_quarter = 16'sd14010;
                7'd24: twiddle_quarter = 16'sd12539;
                7'd25: twiddle_quarter = 16'sd11039;
                7'd26: twiddle_quarter = 16'sd9512;
                7'd27: twiddle_quarter = 16'sd7962;
                7'd28: twiddle_quarter = 16'sd6393;
                7'd29: twiddle_quarter = 16'sd4808;
                7'd30: twiddle_quarter = 16'sd3212;
                7'd31: twiddle_quarter = 16'sd1608;
                default: twiddle_quarter = 16'sd0;
            endcase
        end
    endfunction

    function signed [15:0] twiddle_cos;
        input [6:0] phase;
        reg [6:0] q;
        begin
            if (phase < 7'd32)
                twiddle_cos = twiddle_quarter(phase);
            else if (phase < 7'd64) begin
                q = 7'd64 - phase;
                twiddle_cos = -twiddle_quarter(q);
            end else if (phase < 7'd96) begin
                twiddle_cos = -twiddle_quarter(phase - 7'd64);
            end else begin
                q = phase - 7'd96;
                twiddle_cos = twiddle_quarter(7'd32 - q);
            end
        end
    endfunction

    function signed [15:0] twiddle_sin;
        input [6:0] phase;
        begin
            twiddle_sin = twiddle_cos(phase - 7'd32);
        end
    endfunction

    reg analysis_pending;
    reg analysis_active;
    reg [5:0] analysis_bin;
    reg [6:0] analysis_sample;
    reg [6:0] twiddle_phase;
    reg signed [39:0] real_acc;
    reg signed [39:0] imag_acc;

    wire signed [15:0] analysis_sample_value =
        sample_mem[analysis_bank][analysis_sample];
    wire signed [15:0] analysis_cos = twiddle_cos(twiddle_phase);
    wire signed [15:0] analysis_sin = twiddle_sin(twiddle_phase);
    wire signed [31:0] real_product = analysis_sample_value * analysis_cos;
    wire signed [31:0] imag_product = analysis_sample_value * analysis_sin;
    wire signed [39:0] real_product_scaled =
        {{8{real_product[31]}}, real_product} >>> 15;
    wire signed [39:0] imag_product_scaled =
        {{8{imag_product[31]}}, imag_product} >>> 15;
    wire signed [39:0] real_acc_next = real_acc + real_product_scaled;
    wire signed [39:0] imag_acc_next = imag_acc + imag_product_scaled;

    function [7:0] magnitude_byte;
        input signed [39:0] real_value;
        input signed [39:0] imag_value;
        reg [39:0] real_abs;
        reg [39:0] imag_abs;
        reg [40:0] magnitude_sum;
        reg [40:0] scaled;
        begin
            real_abs = real_value[39] ? (~real_value + 1'b1) : real_value;
            imag_abs = imag_value[39] ? (~imag_value + 1'b1) : imag_value;
            magnitude_sum = real_abs + imag_abs;
            scaled = magnitude_sum >> 13;
            magnitude_byte = (scaled > 41'd255) ? 8'hFF : scaled[7:0];
        end
    endfunction

    integer r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_phase <= 0;
            tone_a_phase <= 0;
            tone_b_phase <= 0;
            lfo_phase <= 0;
            write_bank <= 0;
            write_index <= 0;
            analysis_bank <= 0;
            analysis_pending <= 0;
            analysis_active <= 0;
            analysis_bin <= 0;
            analysis_sample <= 0;
            twiddle_phase <= 0;
            real_acc <= 0;
            imag_acc <= 0;
            for (r = 0; r < 128; r = r + 1) begin
                sample_mem[0][r] <= 0;
                sample_mem[1][r] <= 0;
                fft_bins[r] <= 0;
            end
        end else begin
            sample_phase <= sample_phase + SAMPLE_PHASE_INC;

            if (sample_tick) begin
                tone_a_phase <= tone_a_phase + TONE_A_INC;
                tone_b_phase <= tone_b_phase +
                                (lfo_phase[31] ? TONE_B_HIGH_INC : TONE_B_LOW_INC);
                lfo_phase <= lfo_phase + LFO_INC;
                sample_mem[write_bank][write_index] <= generated_sample;

                if (write_index == 7'd127) begin
                    analysis_bank <= write_bank;
                    analysis_pending <= 1'b1;
                    write_bank <= ~write_bank;
                    write_index <= 0;
                end else begin
                    write_index <= write_index + 1'b1;
                end
            end

            if (analysis_pending && !analysis_active) begin
                analysis_pending <= 1'b0;
                analysis_active <= 1'b1;
                analysis_bin <= 0;
                analysis_sample <= 0;
                twiddle_phase <= 0;
                real_acc <= 0;
                imag_acc <= 0;
            end else if (analysis_active) begin
                if (analysis_sample == 7'd127) begin
                    fft_bins[analysis_bin] <= magnitude_byte(real_acc_next, imag_acc_next);
                    if (analysis_bin == ANALYSIS_BINS - 1) begin
                        analysis_active <= 1'b0;
                        for (r = ANALYSIS_BINS; r < 128; r = r + 1)
                            fft_bins[r] <= 0;
                    end else begin
                        analysis_bin <= analysis_bin + 1'b1;
                        analysis_sample <= 0;
                        twiddle_phase <= 0;
                        real_acc <= 0;
                        imag_acc <= 0;
                    end
                end else begin
                    analysis_sample <= analysis_sample + 1'b1;
                    twiddle_phase <= twiddle_phase + analysis_bin;
                    real_acc <= real_acc_next;
                    imag_acc <= imag_acc_next;
                end
            end
        end
    end

endmodule
