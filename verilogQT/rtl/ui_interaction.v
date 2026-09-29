`timescale 1ns / 1ps
// Generated interaction/state module.
// All actions update next-state temporaries in source order.
module ui_interaction (
    input wire clk,
    input wire rst_n,
    input wire event_valid,
    input wire [3:0] event_type,
    input wire [7:0] event_id,
    input wire [15:0] event_value,
    output reg [511:0] ui_state_flat,
    output reg [87:0] key_states
);
    localparam [3:0] EVENT_CHANGE = 4'd4;
    localparam [3:0] EVENT_KEY_DOWN = 4'd5;
    localparam [3:0] EVENT_KEY_UP = 4'd6;
    reg [511:0] ui_next;
    reg [87:0] key_next;

    function [15:0] sat_add_u16;
        input [15:0] current;
        input signed [31:0] delta;
        reg signed [32:0] total;
        begin
            total = $signed({1'b0, current}) + delta;
            if (total < 0) sat_add_u16 = 16'd0;
            else if (total > 65535) sat_add_u16 = 16'hFFFF;
            else sat_add_u16 = total[15:0];
        end
    endfunction

    function key_add_bool;
        input current;
        input signed [31:0] delta;
        reg signed [32:0] total;
        begin
            total = $signed({1'b0, current}) + delta;
            key_add_bool = (total != 0);
        end
    endfunction

    function [87:0] set_key_index;
        input [87:0] current;
        input [7:0] index;
        input value;
        begin
            set_key_index = current;
            case (index)
                8'd0: set_key_index[0] = value;
                8'd1: set_key_index[1] = value;
                8'd2: set_key_index[2] = value;
                8'd3: set_key_index[3] = value;
                8'd4: set_key_index[4] = value;
                8'd5: set_key_index[5] = value;
                8'd6: set_key_index[6] = value;
                8'd7: set_key_index[7] = value;
                8'd8: set_key_index[8] = value;
                8'd9: set_key_index[9] = value;
                8'd10: set_key_index[10] = value;
                8'd11: set_key_index[11] = value;
                8'd12: set_key_index[12] = value;
                8'd13: set_key_index[13] = value;
                8'd14: set_key_index[14] = value;
                8'd15: set_key_index[15] = value;
                8'd16: set_key_index[16] = value;
                8'd17: set_key_index[17] = value;
                8'd18: set_key_index[18] = value;
                8'd19: set_key_index[19] = value;
                8'd20: set_key_index[20] = value;
                8'd21: set_key_index[21] = value;
                8'd22: set_key_index[22] = value;
                8'd23: set_key_index[23] = value;
                8'd24: set_key_index[24] = value;
                8'd25: set_key_index[25] = value;
                8'd26: set_key_index[26] = value;
                8'd27: set_key_index[27] = value;
                8'd28: set_key_index[28] = value;
                8'd29: set_key_index[29] = value;
                8'd30: set_key_index[30] = value;
                8'd31: set_key_index[31] = value;
                8'd32: set_key_index[32] = value;
                8'd33: set_key_index[33] = value;
                8'd34: set_key_index[34] = value;
                8'd35: set_key_index[35] = value;
                8'd36: set_key_index[36] = value;
                8'd37: set_key_index[37] = value;
                8'd38: set_key_index[38] = value;
                8'd39: set_key_index[39] = value;
                8'd40: set_key_index[40] = value;
                8'd41: set_key_index[41] = value;
                8'd42: set_key_index[42] = value;
                8'd43: set_key_index[43] = value;
                8'd44: set_key_index[44] = value;
                8'd45: set_key_index[45] = value;
                8'd46: set_key_index[46] = value;
                8'd47: set_key_index[47] = value;
                8'd48: set_key_index[48] = value;
                8'd49: set_key_index[49] = value;
                8'd50: set_key_index[50] = value;
                8'd51: set_key_index[51] = value;
                8'd52: set_key_index[52] = value;
                8'd53: set_key_index[53] = value;
                8'd54: set_key_index[54] = value;
                8'd55: set_key_index[55] = value;
                8'd56: set_key_index[56] = value;
                8'd57: set_key_index[57] = value;
                8'd58: set_key_index[58] = value;
                8'd59: set_key_index[59] = value;
                8'd60: set_key_index[60] = value;
                8'd61: set_key_index[61] = value;
                8'd62: set_key_index[62] = value;
                8'd63: set_key_index[63] = value;
                8'd64: set_key_index[64] = value;
                8'd65: set_key_index[65] = value;
                8'd66: set_key_index[66] = value;
                8'd67: set_key_index[67] = value;
                8'd68: set_key_index[68] = value;
                8'd69: set_key_index[69] = value;
                8'd70: set_key_index[70] = value;
                8'd71: set_key_index[71] = value;
                8'd72: set_key_index[72] = value;
                8'd73: set_key_index[73] = value;
                8'd74: set_key_index[74] = value;
                8'd75: set_key_index[75] = value;
                8'd76: set_key_index[76] = value;
                8'd77: set_key_index[77] = value;
                8'd78: set_key_index[78] = value;
                8'd79: set_key_index[79] = value;
                8'd80: set_key_index[80] = value;
                8'd81: set_key_index[81] = value;
                8'd82: set_key_index[82] = value;
                8'd83: set_key_index[83] = value;
                8'd84: set_key_index[84] = value;
                8'd85: set_key_index[85] = value;
                8'd86: set_key_index[86] = value;
                8'd87: set_key_index[87] = value;
                default: begin end
            endcase
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ui_state_flat <= 512'd0;
            key_states <= 88'd0;
        end else begin
            ui_next = ui_state_flat;
            key_next = key_states;
            if (event_valid) begin
                // Direct operations use fixed case decoders rather than
                // variable part-selects, keeping the generated logic bounded.
                case (event_type)
                    4'd8: begin
                        case (event_id)
                            8'd0: ui_next[0 +: 16] = event_value;
                            8'd1: ui_next[16 +: 16] = event_value;
                            8'd2: ui_next[32 +: 16] = event_value;
                            8'd3: ui_next[48 +: 16] = event_value;
                            8'd4: ui_next[64 +: 16] = event_value;
                            8'd5: ui_next[80 +: 16] = event_value;
                            8'd6: ui_next[96 +: 16] = event_value;
                            8'd7: ui_next[112 +: 16] = event_value;
                            8'd8: ui_next[128 +: 16] = event_value;
                            8'd9: ui_next[144 +: 16] = event_value;
                            8'd10: ui_next[160 +: 16] = event_value;
                            8'd11: ui_next[176 +: 16] = event_value;
                            8'd12: ui_next[192 +: 16] = event_value;
                            8'd13: ui_next[208 +: 16] = event_value;
                            8'd14: ui_next[224 +: 16] = event_value;
                            8'd15: ui_next[240 +: 16] = event_value;
                            8'd16: ui_next[256 +: 16] = event_value;
                            8'd17: ui_next[272 +: 16] = event_value;
                            8'd18: ui_next[288 +: 16] = event_value;
                            8'd19: ui_next[304 +: 16] = event_value;
                            8'd20: ui_next[320 +: 16] = event_value;
                            8'd21: ui_next[336 +: 16] = event_value;
                            8'd22: ui_next[352 +: 16] = event_value;
                            8'd23: ui_next[368 +: 16] = event_value;
                            8'd24: ui_next[384 +: 16] = event_value;
                            8'd25: ui_next[400 +: 16] = event_value;
                            8'd26: ui_next[416 +: 16] = event_value;
                            8'd27: ui_next[432 +: 16] = event_value;
                            8'd28: ui_next[448 +: 16] = event_value;
                            8'd29: ui_next[464 +: 16] = event_value;
                            8'd30: ui_next[480 +: 16] = event_value;
                            8'd31: ui_next[496 +: 16] = event_value;
                            default: begin end
                        endcase
                    end
                    4'd9: begin
                        case (event_id)
                            8'd0: begin
                                if (ui_next[0 +: 16] > (16'hFFFF - event_value)) ui_next[0 +: 16] = 16'hFFFF;
                                else ui_next[0 +: 16] = ui_next[0 +: 16] + event_value;
                            end
                            8'd1: begin
                                if (ui_next[16 +: 16] > (16'hFFFF - event_value)) ui_next[16 +: 16] = 16'hFFFF;
                                else ui_next[16 +: 16] = ui_next[16 +: 16] + event_value;
                            end
                            8'd2: begin
                                if (ui_next[32 +: 16] > (16'hFFFF - event_value)) ui_next[32 +: 16] = 16'hFFFF;
                                else ui_next[32 +: 16] = ui_next[32 +: 16] + event_value;
                            end
                            8'd3: begin
                                if (ui_next[48 +: 16] > (16'hFFFF - event_value)) ui_next[48 +: 16] = 16'hFFFF;
                                else ui_next[48 +: 16] = ui_next[48 +: 16] + event_value;
                            end
                            8'd4: begin
                                if (ui_next[64 +: 16] > (16'hFFFF - event_value)) ui_next[64 +: 16] = 16'hFFFF;
                                else ui_next[64 +: 16] = ui_next[64 +: 16] + event_value;
                            end
                            8'd5: begin
                                if (ui_next[80 +: 16] > (16'hFFFF - event_value)) ui_next[80 +: 16] = 16'hFFFF;
                                else ui_next[80 +: 16] = ui_next[80 +: 16] + event_value;
                            end
                            8'd6: begin
                                if (ui_next[96 +: 16] > (16'hFFFF - event_value)) ui_next[96 +: 16] = 16'hFFFF;
                                else ui_next[96 +: 16] = ui_next[96 +: 16] + event_value;
                            end
                            8'd7: begin
                                if (ui_next[112 +: 16] > (16'hFFFF - event_value)) ui_next[112 +: 16] = 16'hFFFF;
                                else ui_next[112 +: 16] = ui_next[112 +: 16] + event_value;
                            end
                            8'd8: begin
                                if (ui_next[128 +: 16] > (16'hFFFF - event_value)) ui_next[128 +: 16] = 16'hFFFF;
                                else ui_next[128 +: 16] = ui_next[128 +: 16] + event_value;
                            end
                            8'd9: begin
                                if (ui_next[144 +: 16] > (16'hFFFF - event_value)) ui_next[144 +: 16] = 16'hFFFF;
                                else ui_next[144 +: 16] = ui_next[144 +: 16] + event_value;
                            end
                            8'd10: begin
                                if (ui_next[160 +: 16] > (16'hFFFF - event_value)) ui_next[160 +: 16] = 16'hFFFF;
                                else ui_next[160 +: 16] = ui_next[160 +: 16] + event_value;
                            end
                            8'd11: begin
                                if (ui_next[176 +: 16] > (16'hFFFF - event_value)) ui_next[176 +: 16] = 16'hFFFF;
                                else ui_next[176 +: 16] = ui_next[176 +: 16] + event_value;
                            end
                            8'd12: begin
                                if (ui_next[192 +: 16] > (16'hFFFF - event_value)) ui_next[192 +: 16] = 16'hFFFF;
                                else ui_next[192 +: 16] = ui_next[192 +: 16] + event_value;
                            end
                            8'd13: begin
                                if (ui_next[208 +: 16] > (16'hFFFF - event_value)) ui_next[208 +: 16] = 16'hFFFF;
                                else ui_next[208 +: 16] = ui_next[208 +: 16] + event_value;
                            end
                            8'd14: begin
                                if (ui_next[224 +: 16] > (16'hFFFF - event_value)) ui_next[224 +: 16] = 16'hFFFF;
                                else ui_next[224 +: 16] = ui_next[224 +: 16] + event_value;
                            end
                            8'd15: begin
                                if (ui_next[240 +: 16] > (16'hFFFF - event_value)) ui_next[240 +: 16] = 16'hFFFF;
                                else ui_next[240 +: 16] = ui_next[240 +: 16] + event_value;
                            end
                            8'd16: begin
                                if (ui_next[256 +: 16] > (16'hFFFF - event_value)) ui_next[256 +: 16] = 16'hFFFF;
                                else ui_next[256 +: 16] = ui_next[256 +: 16] + event_value;
                            end
                            8'd17: begin
                                if (ui_next[272 +: 16] > (16'hFFFF - event_value)) ui_next[272 +: 16] = 16'hFFFF;
                                else ui_next[272 +: 16] = ui_next[272 +: 16] + event_value;
                            end
                            8'd18: begin
                                if (ui_next[288 +: 16] > (16'hFFFF - event_value)) ui_next[288 +: 16] = 16'hFFFF;
                                else ui_next[288 +: 16] = ui_next[288 +: 16] + event_value;
                            end
                            8'd19: begin
                                if (ui_next[304 +: 16] > (16'hFFFF - event_value)) ui_next[304 +: 16] = 16'hFFFF;
                                else ui_next[304 +: 16] = ui_next[304 +: 16] + event_value;
                            end
                            8'd20: begin
                                if (ui_next[320 +: 16] > (16'hFFFF - event_value)) ui_next[320 +: 16] = 16'hFFFF;
                                else ui_next[320 +: 16] = ui_next[320 +: 16] + event_value;
                            end
                            8'd21: begin
                                if (ui_next[336 +: 16] > (16'hFFFF - event_value)) ui_next[336 +: 16] = 16'hFFFF;
                                else ui_next[336 +: 16] = ui_next[336 +: 16] + event_value;
                            end
                            8'd22: begin
                                if (ui_next[352 +: 16] > (16'hFFFF - event_value)) ui_next[352 +: 16] = 16'hFFFF;
                                else ui_next[352 +: 16] = ui_next[352 +: 16] + event_value;
                            end
                            8'd23: begin
                                if (ui_next[368 +: 16] > (16'hFFFF - event_value)) ui_next[368 +: 16] = 16'hFFFF;
                                else ui_next[368 +: 16] = ui_next[368 +: 16] + event_value;
                            end
                            8'd24: begin
                                if (ui_next[384 +: 16] > (16'hFFFF - event_value)) ui_next[384 +: 16] = 16'hFFFF;
                                else ui_next[384 +: 16] = ui_next[384 +: 16] + event_value;
                            end
                            8'd25: begin
                                if (ui_next[400 +: 16] > (16'hFFFF - event_value)) ui_next[400 +: 16] = 16'hFFFF;
                                else ui_next[400 +: 16] = ui_next[400 +: 16] + event_value;
                            end
                            8'd26: begin
                                if (ui_next[416 +: 16] > (16'hFFFF - event_value)) ui_next[416 +: 16] = 16'hFFFF;
                                else ui_next[416 +: 16] = ui_next[416 +: 16] + event_value;
                            end
                            8'd27: begin
                                if (ui_next[432 +: 16] > (16'hFFFF - event_value)) ui_next[432 +: 16] = 16'hFFFF;
                                else ui_next[432 +: 16] = ui_next[432 +: 16] + event_value;
                            end
                            8'd28: begin
                                if (ui_next[448 +: 16] > (16'hFFFF - event_value)) ui_next[448 +: 16] = 16'hFFFF;
                                else ui_next[448 +: 16] = ui_next[448 +: 16] + event_value;
                            end
                            8'd29: begin
                                if (ui_next[464 +: 16] > (16'hFFFF - event_value)) ui_next[464 +: 16] = 16'hFFFF;
                                else ui_next[464 +: 16] = ui_next[464 +: 16] + event_value;
                            end
                            8'd30: begin
                                if (ui_next[480 +: 16] > (16'hFFFF - event_value)) ui_next[480 +: 16] = 16'hFFFF;
                                else ui_next[480 +: 16] = ui_next[480 +: 16] + event_value;
                            end
                            8'd31: begin
                                if (ui_next[496 +: 16] > (16'hFFFF - event_value)) ui_next[496 +: 16] = 16'hFFFF;
                                else ui_next[496 +: 16] = ui_next[496 +: 16] + event_value;
                            end
                            default: begin end
                        endcase
                    end
                    4'd10: begin
                        case (event_id)
                            8'd0: ui_next[0 +: 16] = (ui_next[0 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd1: ui_next[16 +: 16] = (ui_next[16 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd2: ui_next[32 +: 16] = (ui_next[32 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd3: ui_next[48 +: 16] = (ui_next[48 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd4: ui_next[64 +: 16] = (ui_next[64 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd5: ui_next[80 +: 16] = (ui_next[80 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd6: ui_next[96 +: 16] = (ui_next[96 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd7: ui_next[112 +: 16] = (ui_next[112 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd8: ui_next[128 +: 16] = (ui_next[128 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd9: ui_next[144 +: 16] = (ui_next[144 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd10: ui_next[160 +: 16] = (ui_next[160 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd11: ui_next[176 +: 16] = (ui_next[176 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd12: ui_next[192 +: 16] = (ui_next[192 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd13: ui_next[208 +: 16] = (ui_next[208 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd14: ui_next[224 +: 16] = (ui_next[224 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd15: ui_next[240 +: 16] = (ui_next[240 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd16: ui_next[256 +: 16] = (ui_next[256 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd17: ui_next[272 +: 16] = (ui_next[272 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd18: ui_next[288 +: 16] = (ui_next[288 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd19: ui_next[304 +: 16] = (ui_next[304 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd20: ui_next[320 +: 16] = (ui_next[320 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd21: ui_next[336 +: 16] = (ui_next[336 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd22: ui_next[352 +: 16] = (ui_next[352 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd23: ui_next[368 +: 16] = (ui_next[368 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd24: ui_next[384 +: 16] = (ui_next[384 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd25: ui_next[400 +: 16] = (ui_next[400 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd26: ui_next[416 +: 16] = (ui_next[416 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd27: ui_next[432 +: 16] = (ui_next[432 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd28: ui_next[448 +: 16] = (ui_next[448 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd29: ui_next[464 +: 16] = (ui_next[464 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd30: ui_next[480 +: 16] = (ui_next[480 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            8'd31: ui_next[496 +: 16] = (ui_next[496 +: 16] == 16'd0) ? 16'd1 : 16'd0;
                            default: begin end
                        endcase
                    end
                    4'd11: key_next = set_key_index(key_next, event_id, 1'b1);
                    4'd12: key_next = set_key_index(key_next, event_id, 1'b0);
                    default: begin end
                endcase
                if (event_type == EVENT_KEY_DOWN && event_value < 16'd88) key_next = set_key_index(key_next, event_value[7:0], 1'b1);
                if (event_type == EVENT_KEY_UP && event_value < 16'd88) key_next = set_key_index(key_next, event_value[7:0], 1'b0);
            end
            ui_state_flat <= ui_next;
            key_states <= key_next;
        end
    end
endmodule
