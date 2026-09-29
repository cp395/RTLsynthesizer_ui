`timescale 1ns / 1ps
//
// ADV7513 I2C Configuration Controller
// Properly implements I2C open-drain with ACK detection
//

module adv7513_controller (
    input wire clk,              // System clock (50 MHz)
    input wire rst_n,            // Reset

    // I2C Interface
    output reg scl,              // I2C clock
    inout wire sda,              // I2C data (bidirectional)

    // Status outputs
    output reg init_done,        // Initialization complete
    output reg error             // Error flag
);

    // ADV7513 I2C address (7-bit)
    localparam I2C_ADDR = 7'h39;  // 0x72 >> 1, adjust based on hardware

    // State machine
    localparam IDLE       = 4'd0;
    localparam START      = 4'd1;
    localparam ADDR       = 4'd2;
    localparam ADDR_ACK   = 4'd3;
    localparam REG_ADDR   = 4'd4;
    localparam REG_ACK    = 4'd5;
    localparam REG_DATA   = 4'd6;
    localparam DATA_ACK   = 4'd7;
    localparam STOP       = 4'd8;
    localparam NEXT_REG   = 4'd9;
    localparam DONE       = 4'd10;
    localparam ERROR      = 4'd11;

    reg [3:0] state;
    reg [3:0] bit_count;
    reg [7:0] reg_index;
    reg [15:0] timeout_counter;
    // Three phases are used for each I2C bit: drive while SCL is low,
    // raise SCL, then lower SCL and advance/sample.  Keeping the phase
    // explicit avoids relying on the old value of SCL after a nonblocking
    // assignment.
    reg [1:0] bit_phase;

    // I2C clock divider.  Each transmitted bit uses three state-machine ticks
    // and the divider gives a 5 us tick at 50 MHz, so SCL is about 66.7 kHz
    // (well within standard-mode I2C timing, with a 5 us high phase).
    reg [7:0] clk_div;
    reg i2c_clk_tick;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div <= 0;
            i2c_clk_tick <= 0;
        end else begin
            if (clk_div >= 249) begin  // 250 分频
                clk_div <= 0;
                i2c_clk_tick <= 1;
            end else begin
                clk_div <= clk_div + 1;
                i2c_clk_tick <= 0;
            end
        end
    end

    // ADV7513 initialization registers
    // Based on ADV7513 Programming Guide for 720p60
    reg [15:0] init_regs [0:31];

    initial begin
        // Register address : Data
        init_regs[0]  = 16'h4110; // Power up
        init_regs[1]  = 16'h9803; // Fixed register
        init_regs[2]  = 16'h9AE0; // Fixed register
        init_regs[3]  = 16'h9C30; // Fixed register
        init_regs[4]  = 16'h9D61; // Fixed register
        init_regs[5]  = 16'hA2A4; // Fixed register
        init_regs[6]  = 16'hA3A4; // Fixed register
        init_regs[7]  = 16'hE0D0; // Fixed register
        init_regs[8]  = 16'hF900; // Fixed register

        // Input format configuration
        init_regs[9]  = 16'h1500; // Input ID = 0
        init_regs[10] = 16'h1630; // RGB 4:4:4, 8-bit
        init_regs[11] = 16'h1846; // CSC disabled
        init_regs[12] = 16'h4080; // GC packet enable
        init_regs[13] = 16'h4810; // Right justified

        // Output format
        init_regs[14] = 16'hAF06; // HDMI mode (not DVI)

        // 720p@60Hz configuration
        init_regs[15] = 16'h1700; // Aspect ratio 16:9

        // Audio disabled (video only)
        init_regs[16] = 16'h0A00; // Audio disabled
        init_regs[17] = 16'h0C00; // Audio disabled

        // Other fixed registers
        init_regs[18] = 16'hD0C0; // Power up
        init_regs[19] = 16'hBA60; // Clock delay
        init_regs[20] = 16'hDE10; // Fixed

        // End marker
        init_regs[21] = 16'hFFFF;
        init_regs[22] = 16'hFFFF;
        init_regs[23] = 16'hFFFF;
        init_regs[24] = 16'hFFFF;
        init_regs[25] = 16'hFFFF;
        init_regs[26] = 16'hFFFF;
        init_regs[27] = 16'hFFFF;
        init_regs[28] = 16'hFFFF;
        init_regs[29] = 16'hFFFF;
        init_regs[30] = 16'hFFFF;
        init_regs[31] = 16'hFFFF;
    end

    // I2C SDA control - proper open-drain implementation
    reg sda_out;
    reg sda_oe;  // Output enable: 1 = drive low, 0 = high-Z

    // Only drive SDA low, never high (open-drain)
    assign sda = sda_oe ? 1'b0 : 1'bz;

    // Read SDA input
    wire sda_in = sda;

    // Current register data
    wire [7:0] current_reg_addr = init_regs[reg_index][15:8];
    wire [7:0] current_reg_data = init_regs[reg_index][7:0];

    wire [7:0] tx_byte =
        (state == ADDR)     ? {I2C_ADDR, 1'b0} :
        (state == REG_ADDR) ? current_reg_addr :
        (state == REG_DATA) ? current_reg_data : 8'h00;

    // I2C state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            scl <= 1;
            sda_oe <= 0;
            init_done <= 0;
            error <= 0;
            reg_index <= 0;
            bit_count <= 0;
            bit_phase <= 0;
            timeout_counter <= 0;
        end else if (i2c_clk_tick) begin
            // Timeout detection
            if (state != IDLE && state != DONE && state != ERROR) begin
                if (timeout_counter >= 16'd10000) begin
                    state <= ERROR;
                    error <= 1;
                end else begin
                    timeout_counter <= timeout_counter + 1;
                end
            end

            case (state)
                IDLE: begin
                    scl <= 1;
                    sda_oe <= 0;
                    timeout_counter <= 0;

                    if (!init_done && !error) begin
                        state <= START;
                        reg_index <= 0;
                        bit_phase <= 0;
                    end
                end

                START: begin
                    // I2C START condition: SDA falls while SCL is high
                    scl <= 1;
                    sda_oe <= 1;  // Pull SDA low
                    state <= ADDR;
                    bit_count <= 7;
                    bit_phase <= 0;
                end

                ADDR, REG_ADDR, REG_DATA: begin
                    // Send one byte, MSB first.  Data changes only while SCL
                    // is low and remains stable for the complete high phase.
                    case (bit_phase)
                        2'd0: begin
                            scl <= 0;
                            sda_oe <= ~tx_byte[bit_count];
                            bit_phase <= 1;
                        end
                        2'd1: begin
                            scl <= 1;
                            bit_phase <= 2;
                        end
                        default: begin
                            scl <= 0;
                            if (bit_count == 0) begin
                                sda_oe <= 0;  // Release for ACK
                                bit_phase <= 0;
                                if (state == ADDR)
                                    state <= ADDR_ACK;
                                else if (state == REG_ADDR)
                                    state <= REG_ACK;
                                else
                                    state <= DATA_ACK;
                            end else begin
                                bit_count <= bit_count - 1'b1;
                                bit_phase <= 0;
                            end
                        end
                    endcase
                end

                ADDR_ACK, REG_ACK, DATA_ACK: begin
                    // Release SDA, clock the ACK bit, and sample it while SCL
                    // is high.  A low SDA is the slave ACK.
                    case (bit_phase)
                        2'd0: begin
                            scl <= 0;
                            sda_oe <= 0;
                            bit_phase <= 1;
                        end
                        2'd1: begin
                            scl <= 1;
                            bit_phase <= 2;
                        end
                        default: begin
                            scl <= 0;
                            bit_phase <= 0;
                            if (sda_in == 1'b0) begin
                                if (state == ADDR_ACK) begin
                                    state <= REG_ADDR;
                                    bit_count <= 7;
                                end else if (state == REG_ACK) begin
                                    state <= REG_DATA;
                                    bit_count <= 7;
                                end else begin
                                    state <= STOP;
                                end
                            end else begin
                                state <= ERROR;
                                error <= 1;
                            end
                        end
                    endcase
                end

                STOP: begin
                    // I2C STOP condition: drive SDA low while SCL is low,
                    // raise SCL, then release SDA while SCL is high.
                    case (bit_phase)
                        2'd0: begin
                            scl <= 0;
                            sda_oe <= 1;
                            bit_phase <= 1;
                        end
                        2'd1: begin
                            scl <= 1;
                            bit_phase <= 2;
                        end
                        default: begin
                            sda_oe <= 0;
                            bit_phase <= 0;
                            state <= NEXT_REG;
                            timeout_counter <= 0;
                        end
                    endcase
                end

                NEXT_REG: begin
                    // Check if more registers to configure
                    if (init_regs[reg_index + 1] == 16'hFFFF) begin
                        state <= DONE;
                    end else begin
                        reg_index <= reg_index + 1;
                        state <= START;
                        bit_phase <= 0;
                    end
                end

                DONE: begin
                    init_done <= 1;
                    scl <= 1;
                    sda_oe <= 0;
                end

                ERROR: begin
                    error <= 1;
                    scl <= 1;
                    sda_oe <= 0;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
