//
// Font ROM - 8×16
// Characters: 73
//

module font_rom (
    input wire clk,
    input wire [7:0] char_code,
    input wire [3:0] row,
    output reg [7:0] pixels
);

    always @(posedge clk) begin
        case (char_code)
            8'd65: begin // 'A'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00010000;
                    4'd3: pixels = 8'b00110000;
                    4'd4: pixels = 8'b00101000;
                    4'd5: pixels = 8'b00001000;
                    4'd6: pixels = 8'b01111000;
                    4'd7: pixels = 8'b01000100;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b10000100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd66: begin // 'B'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01111000;
                    4'd3: pixels = 8'b01000100;
                    4'd4: pixels = 8'b01000100;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01111100;
                    4'd7: pixels = 8'b01000100;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b01111000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd67: begin // 'C'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00111000;
                    4'd3: pixels = 8'b01000100;
                    4'd4: pixels = 8'b10000100;
                    4'd5: pixels = 8'b10000000;
                    4'd6: pixels = 8'b10000000;
                    4'd7: pixels = 8'b10000100;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b00111000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd68: begin // 'D'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01111000;
                    4'd3: pixels = 8'b01000100;
                    4'd4: pixels = 8'b01000010;
                    4'd5: pixels = 8'b01000010;
                    4'd6: pixels = 8'b01000010;
                    4'd7: pixels = 8'b01000010;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b01111000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd69: begin // 'E'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01111000;
                    4'd3: pixels = 8'b01000000;
                    4'd4: pixels = 8'b01000000;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01111000;
                    4'd7: pixels = 8'b01000000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01111100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd70: begin // 'F'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01111000;
                    4'd3: pixels = 8'b01000000;
                    4'd4: pixels = 8'b01000000;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01111000;
                    4'd7: pixels = 8'b01000000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd71: begin // 'G'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00111000;
                    4'd3: pixels = 8'b01000100;
                    4'd4: pixels = 8'b10000100;
                    4'd5: pixels = 8'b10000000;
                    4'd6: pixels = 8'b10001100;
                    4'd7: pixels = 8'b10000100;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b01110100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd72: begin // 'H'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01000010;
                    4'd3: pixels = 8'b01000010;
                    4'd4: pixels = 8'b01000010;
                    4'd5: pixels = 8'b01000010;
                    4'd6: pixels = 8'b01111110;
                    4'd7: pixels = 8'b01000010;
                    4'd8: pixels = 8'b01000010;
                    4'd9: pixels = 8'b01000010;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd73: begin // 'I'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01000000;
                    4'd3: pixels = 8'b01000000;
                    4'd4: pixels = 8'b01000000;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01000000;
                    4'd7: pixels = 8'b01000000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd74: begin // 'J'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00001000;
                    4'd3: pixels = 8'b00001000;
                    4'd4: pixels = 8'b00001000;
                    4'd5: pixels = 8'b00001000;
                    4'd6: pixels = 8'b00001000;
                    4'd7: pixels = 8'b01001000;
                    4'd8: pixels = 8'b01001000;
                    4'd9: pixels = 8'b00110000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd75: begin // 'K'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01000100;
                    4'd3: pixels = 8'b01001000;
                    4'd4: pixels = 8'b01010000;
                    4'd5: pixels = 8'b01010000;
                    4'd6: pixels = 8'b01110000;
                    4'd7: pixels = 8'b01010000;
                    4'd8: pixels = 8'b01001000;
                    4'd9: pixels = 8'b01000100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd76: begin // 'L'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01000000;
                    4'd3: pixels = 8'b01000000;
                    4'd4: pixels = 8'b01000000;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01000000;
                    4'd7: pixels = 8'b01000000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01111100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd77: begin // 'M'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01100011;
                    4'd3: pixels = 8'b01100011;
                    4'd4: pixels = 8'b01100011;
                    4'd5: pixels = 8'b01000001;
                    4'd6: pixels = 8'b01010101;
                    4'd7: pixels = 8'b01010101;
                    4'd8: pixels = 8'b01001001;
                    4'd9: pixels = 8'b01001001;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd78: begin // 'N'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01100010;
                    4'd3: pixels = 8'b01100010;
                    4'd4: pixels = 8'b01010010;
                    4'd5: pixels = 8'b01010010;
                    4'd6: pixels = 8'b01001010;
                    4'd7: pixels = 8'b01001010;
                    4'd8: pixels = 8'b01000110;
                    4'd9: pixels = 8'b01000110;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd79: begin // 'O'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00111000;
                    4'd3: pixels = 8'b01000100;
                    4'd4: pixels = 8'b10000010;
                    4'd5: pixels = 8'b10000010;
                    4'd6: pixels = 8'b10000010;
                    4'd7: pixels = 8'b10000010;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b00111000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd80: begin // 'P'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01111000;
                    4'd3: pixels = 8'b01000100;
                    4'd4: pixels = 8'b01000100;
                    4'd5: pixels = 8'b01000100;
                    4'd6: pixels = 8'b01111000;
                    4'd7: pixels = 8'b01000000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd81: begin // 'Q'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00111000;
                    4'd3: pixels = 8'b01000100;
                    4'd4: pixels = 8'b10000010;
                    4'd5: pixels = 8'b10000010;
                    4'd6: pixels = 8'b10000010;
                    4'd7: pixels = 8'b10000010;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b00111100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd82: begin // 'R'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01111000;
                    4'd3: pixels = 8'b01000100;
                    4'd4: pixels = 8'b01000100;
                    4'd5: pixels = 8'b01000100;
                    4'd6: pixels = 8'b01111000;
                    4'd7: pixels = 8'b01000000;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b01000100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd83: begin // 'S'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00111000;
                    4'd3: pixels = 8'b01000100;
                    4'd4: pixels = 8'b01000000;
                    4'd5: pixels = 8'b00110000;
                    4'd6: pixels = 8'b00001000;
                    4'd7: pixels = 8'b00000100;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b00111000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd84: begin // 'T'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01111100;
                    4'd3: pixels = 8'b00010000;
                    4'd4: pixels = 8'b00010000;
                    4'd5: pixels = 8'b00010000;
                    4'd6: pixels = 8'b00010000;
                    4'd7: pixels = 8'b00010000;
                    4'd8: pixels = 8'b00010000;
                    4'd9: pixels = 8'b00010000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd85: begin // 'U'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01000100;
                    4'd3: pixels = 8'b01000100;
                    4'd4: pixels = 8'b01000100;
                    4'd5: pixels = 8'b01000100;
                    4'd6: pixels = 8'b01000100;
                    4'd7: pixels = 8'b01000100;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b00111000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd86: begin // 'V'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b10000100;
                    4'd3: pixels = 8'b01000100;
                    4'd4: pixels = 8'b01000100;
                    4'd5: pixels = 8'b01001000;
                    4'd6: pixels = 8'b00101000;
                    4'd7: pixels = 8'b00101000;
                    4'd8: pixels = 8'b00110000;
                    4'd9: pixels = 8'b00010000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd87: begin // 'W'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b10001100;
                    4'd3: pixels = 8'b01001100;
                    4'd4: pixels = 8'b01001100;
                    4'd5: pixels = 8'b01000100;
                    4'd6: pixels = 8'b01010000;
                    4'd7: pixels = 8'b00010011;
                    4'd8: pixels = 8'b00110011;
                    4'd9: pixels = 8'b00100011;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd88: begin // 'X'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01000100;
                    4'd3: pixels = 8'b01001000;
                    4'd4: pixels = 8'b00101000;
                    4'd5: pixels = 8'b00110000;
                    4'd6: pixels = 8'b00110000;
                    4'd7: pixels = 8'b00101000;
                    4'd8: pixels = 8'b01001000;
                    4'd9: pixels = 8'b01000100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd89: begin // 'Y'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01000100;
                    4'd3: pixels = 8'b01000100;
                    4'd4: pixels = 8'b00101000;
                    4'd5: pixels = 8'b00111000;
                    4'd6: pixels = 8'b00010000;
                    4'd7: pixels = 8'b00010000;
                    4'd8: pixels = 8'b00010000;
                    4'd9: pixels = 8'b00010000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd90: begin // 'Z'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01111100;
                    4'd3: pixels = 8'b00000100;
                    4'd4: pixels = 8'b00001000;
                    4'd5: pixels = 8'b00010000;
                    4'd6: pixels = 8'b00010000;
                    4'd7: pixels = 8'b00100000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01111100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd97: begin // 'a'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01100000;
                    4'd5: pixels = 8'b10010000;
                    4'd6: pixels = 8'b00110000;
                    4'd7: pixels = 8'b10010000;
                    4'd8: pixels = 8'b10010000;
                    4'd9: pixels = 8'b11110000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd98: begin // 'b'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01000000;
                    4'd3: pixels = 8'b01000000;
                    4'd4: pixels = 8'b01111000;
                    4'd5: pixels = 8'b01000100;
                    4'd6: pixels = 8'b01000100;
                    4'd7: pixels = 8'b01000100;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b01111000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd99: begin // 'c'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01110000;
                    4'd5: pixels = 8'b10001000;
                    4'd6: pixels = 8'b10000000;
                    4'd7: pixels = 8'b10000000;
                    4'd8: pixels = 8'b10001000;
                    4'd9: pixels = 8'b01110000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd100: begin // 'd'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00001000;
                    4'd3: pixels = 8'b00001000;
                    4'd4: pixels = 8'b01111000;
                    4'd5: pixels = 8'b10001000;
                    4'd6: pixels = 8'b10001000;
                    4'd7: pixels = 8'b10001000;
                    4'd8: pixels = 8'b10001000;
                    4'd9: pixels = 8'b01111000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd101: begin // 'e'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01110000;
                    4'd5: pixels = 8'b10001000;
                    4'd6: pixels = 8'b11111000;
                    4'd7: pixels = 8'b10000000;
                    4'd8: pixels = 8'b10001000;
                    4'd9: pixels = 8'b01110000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd102: begin // 'f'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01000000;
                    4'd3: pixels = 8'b01000000;
                    4'd4: pixels = 8'b01100000;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01000000;
                    4'd7: pixels = 8'b01000000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd103: begin // 'g'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01111000;
                    4'd5: pixels = 8'b10001000;
                    4'd6: pixels = 8'b10001000;
                    4'd7: pixels = 8'b10001000;
                    4'd8: pixels = 8'b10001000;
                    4'd9: pixels = 8'b01111000;
                    4'd10: pixels = 8'b10001000;
                    4'd11: pixels = 8'b01110000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd104: begin // 'h'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01000000;
                    4'd3: pixels = 8'b01000000;
                    4'd4: pixels = 8'b01111000;
                    4'd5: pixels = 8'b01000100;
                    4'd6: pixels = 8'b01000100;
                    4'd7: pixels = 8'b01000100;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b01000100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd105: begin // 'i'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01000000;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01000000;
                    4'd7: pixels = 8'b01000000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd106: begin // 'j'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01000000;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01000000;
                    4'd7: pixels = 8'b01000000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01000000;
                    4'd10: pixels = 8'b01000000;
                    4'd11: pixels = 8'b11000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd107: begin // 'k'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01000000;
                    4'd3: pixels = 8'b01000000;
                    4'd4: pixels = 8'b01001000;
                    4'd5: pixels = 8'b01010000;
                    4'd6: pixels = 8'b01100000;
                    4'd7: pixels = 8'b01110000;
                    4'd8: pixels = 8'b01010000;
                    4'd9: pixels = 8'b01001000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd108: begin // 'l'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01000000;
                    4'd3: pixels = 8'b01000000;
                    4'd4: pixels = 8'b01000000;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01000000;
                    4'd7: pixels = 8'b01000000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd109: begin // 'm'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01110110;
                    4'd5: pixels = 8'b01001001;
                    4'd6: pixels = 8'b01001001;
                    4'd7: pixels = 8'b01001001;
                    4'd8: pixels = 8'b01001001;
                    4'd9: pixels = 8'b01001001;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd110: begin // 'n'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01111000;
                    4'd5: pixels = 8'b01000100;
                    4'd6: pixels = 8'b01000100;
                    4'd7: pixels = 8'b01000100;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b01000100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd111: begin // 'o'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01110000;
                    4'd5: pixels = 8'b10001000;
                    4'd6: pixels = 8'b10001000;
                    4'd7: pixels = 8'b10001000;
                    4'd8: pixels = 8'b10001000;
                    4'd9: pixels = 8'b01110000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd112: begin // 'p'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01111000;
                    4'd5: pixels = 8'b01000100;
                    4'd6: pixels = 8'b01000100;
                    4'd7: pixels = 8'b01000100;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b01111000;
                    4'd10: pixels = 8'b01000000;
                    4'd11: pixels = 8'b01000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd113: begin // 'q'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01111000;
                    4'd5: pixels = 8'b10001000;
                    4'd6: pixels = 8'b10001000;
                    4'd7: pixels = 8'b10001000;
                    4'd8: pixels = 8'b10001000;
                    4'd9: pixels = 8'b01111000;
                    4'd10: pixels = 8'b00001000;
                    4'd11: pixels = 8'b00001000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd114: begin // 'r'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01100000;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01000000;
                    4'd7: pixels = 8'b01000000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd115: begin // 's'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01100000;
                    4'd5: pixels = 8'b10010000;
                    4'd6: pixels = 8'b11000000;
                    4'd7: pixels = 8'b00110000;
                    4'd8: pixels = 8'b10010000;
                    4'd9: pixels = 8'b01100000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd116: begin // 't'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b01000000;
                    4'd4: pixels = 8'b11100000;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01000000;
                    4'd7: pixels = 8'b01000000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01100000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd117: begin // 'u'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01000100;
                    4'd5: pixels = 8'b01000100;
                    4'd6: pixels = 8'b01000100;
                    4'd7: pixels = 8'b01000100;
                    4'd8: pixels = 8'b01000100;
                    4'd9: pixels = 8'b00111100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd118: begin // 'v'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b10001000;
                    4'd5: pixels = 8'b00001000;
                    4'd6: pixels = 8'b01010000;
                    4'd7: pixels = 8'b01010000;
                    4'd8: pixels = 8'b00110000;
                    4'd9: pixels = 8'b00100000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd119: begin // 'w'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b10011001;
                    4'd5: pixels = 8'b10011000;
                    4'd6: pixels = 8'b01011010;
                    4'd7: pixels = 8'b01001010;
                    4'd8: pixels = 8'b01100110;
                    4'd9: pixels = 8'b00100100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd120: begin // 'x'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b10010000;
                    4'd5: pixels = 8'b01010000;
                    4'd6: pixels = 8'b00100000;
                    4'd7: pixels = 8'b00100000;
                    4'd8: pixels = 8'b01010000;
                    4'd9: pixels = 8'b10010000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd121: begin // 'y'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b10001000;
                    4'd5: pixels = 8'b00001000;
                    4'd6: pixels = 8'b01010000;
                    4'd7: pixels = 8'b01010000;
                    4'd8: pixels = 8'b00100000;
                    4'd9: pixels = 8'b00100000;
                    4'd10: pixels = 8'b00100000;
                    4'd11: pixels = 8'b01000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd122: begin // 'z'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b01111000;
                    4'd5: pixels = 8'b00001000;
                    4'd6: pixels = 8'b00010000;
                    4'd7: pixels = 8'b00100000;
                    4'd8: pixels = 8'b00000000;
                    4'd9: pixels = 8'b01111000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd48: begin // '0'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01110000;
                    4'd3: pixels = 8'b10001000;
                    4'd4: pixels = 8'b10001000;
                    4'd5: pixels = 8'b10001000;
                    4'd6: pixels = 8'b10001000;
                    4'd7: pixels = 8'b10001000;
                    4'd8: pixels = 8'b10001000;
                    4'd9: pixels = 8'b01110000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd49: begin // '1'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00110000;
                    4'd3: pixels = 8'b01010000;
                    4'd4: pixels = 8'b00010000;
                    4'd5: pixels = 8'b00010000;
                    4'd6: pixels = 8'b00010000;
                    4'd7: pixels = 8'b00010000;
                    4'd8: pixels = 8'b00010000;
                    4'd9: pixels = 8'b00010000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd50: begin // '2'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00110000;
                    4'd3: pixels = 8'b01001000;
                    4'd4: pixels = 8'b00001000;
                    4'd5: pixels = 8'b00001000;
                    4'd6: pixels = 8'b00010000;
                    4'd7: pixels = 8'b00100000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01111000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd51: begin // '3'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01110000;
                    4'd3: pixels = 8'b00001000;
                    4'd4: pixels = 8'b00001000;
                    4'd5: pixels = 8'b00110000;
                    4'd6: pixels = 8'b00001000;
                    4'd7: pixels = 8'b10001000;
                    4'd8: pixels = 8'b10001000;
                    4'd9: pixels = 8'b01110000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd52: begin // '4'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00001000;
                    4'd3: pixels = 8'b00011000;
                    4'd4: pixels = 8'b00101000;
                    4'd5: pixels = 8'b00101000;
                    4'd6: pixels = 8'b01001000;
                    4'd7: pixels = 8'b01111100;
                    4'd8: pixels = 8'b00001000;
                    4'd9: pixels = 8'b00001000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd53: begin // '5'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01111000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b00000000;
                    4'd5: pixels = 8'b11110000;
                    4'd6: pixels = 8'b10001000;
                    4'd7: pixels = 8'b00001000;
                    4'd8: pixels = 8'b10001000;
                    4'd9: pixels = 8'b01110000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd54: begin // '6'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01110000;
                    4'd3: pixels = 8'b01001000;
                    4'd4: pixels = 8'b10000000;
                    4'd5: pixels = 8'b10110000;
                    4'd6: pixels = 8'b10001000;
                    4'd7: pixels = 8'b10001000;
                    4'd8: pixels = 8'b10001000;
                    4'd9: pixels = 8'b01110000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd55: begin // '7'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b11111000;
                    4'd3: pixels = 8'b00001000;
                    4'd4: pixels = 8'b00010000;
                    4'd5: pixels = 8'b00010000;
                    4'd6: pixels = 8'b00100000;
                    4'd7: pixels = 8'b00100000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd56: begin // '8'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01110000;
                    4'd3: pixels = 8'b10001000;
                    4'd4: pixels = 8'b10001000;
                    4'd5: pixels = 8'b01110000;
                    4'd6: pixels = 8'b10001000;
                    4'd7: pixels = 8'b10001000;
                    4'd8: pixels = 8'b10001000;
                    4'd9: pixels = 8'b01110000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd57: begin // '9'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01110000;
                    4'd3: pixels = 8'b10001000;
                    4'd4: pixels = 8'b10001000;
                    4'd5: pixels = 8'b10001000;
                    4'd6: pixels = 8'b01101000;
                    4'd7: pixels = 8'b00001000;
                    4'd8: pixels = 8'b10010000;
                    4'd9: pixels = 8'b01110000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd32: begin // ' '
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b00000000;
                    4'd5: pixels = 8'b00000000;
                    4'd6: pixels = 8'b00000000;
                    4'd7: pixels = 8'b00000000;
                    4'd8: pixels = 8'b00000000;
                    4'd9: pixels = 8'b00000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd46: begin // '.'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b00000000;
                    4'd5: pixels = 8'b00000000;
                    4'd6: pixels = 8'b00000000;
                    4'd7: pixels = 8'b00000000;
                    4'd8: pixels = 8'b00000000;
                    4'd9: pixels = 8'b10000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd44: begin // ','
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b00000000;
                    4'd5: pixels = 8'b00000000;
                    4'd6: pixels = 8'b00000000;
                    4'd7: pixels = 8'b00000000;
                    4'd8: pixels = 8'b00000000;
                    4'd9: pixels = 8'b10000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd58: begin // ':'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b10000000;
                    4'd5: pixels = 8'b00000000;
                    4'd6: pixels = 8'b00000000;
                    4'd7: pixels = 8'b00000000;
                    4'd8: pixels = 8'b00000000;
                    4'd9: pixels = 8'b10000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd45: begin // '-'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b00000000;
                    4'd5: pixels = 8'b00000000;
                    4'd6: pixels = 8'b11000000;
                    4'd7: pixels = 8'b00000000;
                    4'd8: pixels = 8'b00000000;
                    4'd9: pixels = 8'b00000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd43: begin // '+'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00000000;
                    4'd3: pixels = 8'b00000000;
                    4'd4: pixels = 8'b00010000;
                    4'd5: pixels = 8'b00010000;
                    4'd6: pixels = 8'b01111100;
                    4'd7: pixels = 8'b00010000;
                    4'd8: pixels = 8'b00010000;
                    4'd9: pixels = 8'b00000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd35: begin // '#'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00001000;
                    4'd3: pixels = 8'b00100000;
                    4'd4: pixels = 8'b00100000;
                    4'd5: pixels = 8'b01111000;
                    4'd6: pixels = 8'b00010000;
                    4'd7: pixels = 8'b01111000;
                    4'd8: pixels = 8'b01010000;
                    4'd9: pixels = 8'b01000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd37: begin // '%'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b01000100;
                    4'd3: pixels = 8'b10100000;
                    4'd4: pixels = 8'b10101000;
                    4'd5: pixels = 8'b01010000;
                    4'd6: pixels = 8'b00010100;
                    4'd7: pixels = 8'b00101010;
                    4'd8: pixels = 8'b00001010;
                    4'd9: pixels = 8'b01000100;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd47: begin // '/'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b00100000;
                    4'd3: pixels = 8'b00100000;
                    4'd4: pixels = 8'b00000000;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01000000;
                    4'd7: pixels = 8'b00000000;
                    4'd8: pixels = 8'b00000000;
                    4'd9: pixels = 8'b10000000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd92: begin // '\'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b00000000;
                    4'd2: pixels = 8'b10000000;
                    4'd3: pixels = 8'b10000000;
                    4'd4: pixels = 8'b00000000;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01000000;
                    4'd7: pixels = 8'b00000000;
                    4'd8: pixels = 8'b00000000;
                    4'd9: pixels = 8'b00100000;
                    4'd10: pixels = 8'b00000000;
                    4'd11: pixels = 8'b00000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            8'd124: begin // '|'
                case (row)
                    4'd0: pixels = 8'b00000000;
                    4'd1: pixels = 8'b01000000;
                    4'd2: pixels = 8'b01000000;
                    4'd3: pixels = 8'b01000000;
                    4'd4: pixels = 8'b01000000;
                    4'd5: pixels = 8'b01000000;
                    4'd6: pixels = 8'b01000000;
                    4'd7: pixels = 8'b01000000;
                    4'd8: pixels = 8'b01000000;
                    4'd9: pixels = 8'b01000000;
                    4'd10: pixels = 8'b01000000;
                    4'd11: pixels = 8'b01000000;
                    4'd12: pixels = 8'b00000000;
                    4'd13: pixels = 8'b00000000;
                    4'd14: pixels = 8'b00000000;
                    4'd15: pixels = 8'b00000000;
                    default: pixels = 8'd0;
                endcase
            end
            default: begin
                case (row)
                    4'd0: pixels = 8'd0;
                    4'd1: pixels = 8'd0;
                    4'd2: pixels = 8'd0;
                    4'd3: pixels = 8'd0;
                    4'd4: pixels = 8'd0;
                    4'd5: pixels = 8'd0;
                    4'd6: pixels = 8'd0;
                    4'd7: pixels = 8'd0;
                    4'd8: pixels = 8'd0;
                    4'd9: pixels = 8'd0;
                    4'd10: pixels = 8'd0;
                    4'd11: pixels = 8'd0;
                    4'd12: pixels = 8'd0;
                    4'd13: pixels = 8'd0;
                    4'd14: pixels = 8'd0;
                    4'd15: pixels = 8'd0;
                    default: pixels = 8'd0;
                endcase
            end
        endcase
    end

endmodule