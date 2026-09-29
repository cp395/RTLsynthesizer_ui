`timescale 1ns / 1ps
//
// Keyboard Renderer
// 显示钢琴键盘
//

module keyboard_renderer #(
    parameter X_START = 0,
    parameter Y_START = 0,
    parameter WIDTH = 700,
    parameter HEIGHT = 100,
    parameter START_NOTE = 48,    // MIDI note number (C3)
    parameter NUM_KEYS = 25,
    parameter WHITE_KEY_COLOR = 24'hF0F0F5,
    parameter BLACK_KEY_COLOR = 24'h141923,
    parameter PRESSED_COLOR = 24'h38BDF8
) (
    input wire [10:0] pixel_x,
    input wire [9:0] pixel_y,
    input wire [NUM_KEYS-1:0] key_states,  // 按键状态位向量
    output wire active,
    output wire [23:0] color
);

    wire in_x = (pixel_x >= X_START) && (pixel_x < X_START + WIDTH);
    wire in_y = (pixel_y >= Y_START) && (pixel_y < Y_START + HEIGHT);
    assign active = in_x && in_y;

    wire [10:0] local_x = pixel_x - X_START;
    wire [9:0] local_y = pixel_y - Y_START;

    // 键盘模式：12 音符，0=C, 1=C#, 2=D, ...
    // 黑键：1(C#), 3(D#), 6(F#), 8(G#), 10(A#)
    function [0:0] is_black_key;
        input [3:0] note;
        begin
            is_black_key = (note == 1) || (note == 3) || (note == 6) ||
                          (note == 8) || (note == 10);
        end
    endfunction

    // Count the actual white notes in the configured range.  A simple
    // NUM_KEYS*7/12 approximation is wrong for partial octaves (25 keys
    // starting at C contain 15 white keys, not 14).
    function integer count_white_keys;
        integer n;
        begin
            count_white_keys = 0;
            for (n = 0; n < NUM_KEYS; n = n + 1) begin
                if (!is_black_key((START_NOTE + n) % 12))
                    count_white_keys = count_white_keys + 1;
            end
        end
    endfunction

    localparam NUM_WHITE_KEYS = count_white_keys();
    localparam SAFE_NUM_WHITE_KEYS = (NUM_WHITE_KEYS > 0) ? NUM_WHITE_KEYS : 1;
    localparam WHITE_KEY_WIDTH = (NUM_WHITE_KEYS > 0) ? (WIDTH / NUM_WHITE_KEYS) : WIDTH;

    // 黑键参数
    localparam BLACK_KEY_HEIGHT = (HEIGHT * 3) / 5;  // 60% 高度
    localparam BLACK_KEY_WIDTH = (NUM_WHITE_KEYS > 0) ?
                                 ((WIDTH * 3) / (SAFE_NUM_WHITE_KEYS * 5)) : WIDTH;

    // 计算当前像素对应的键
    // 首先确定是在白键区域还是黑键区域
    wire in_black_key_region = (local_y < BLACK_KEY_HEIGHT);

    // Walk the notes once.  The previous implementation nested a scan of all
    // earlier notes inside this loop, creating an O(NUM_KEYS^2) combinational
    // network for every pixel.
    reg [7:0] current_key;
    reg is_on_black_key;
    reg is_pressed;

    integer k;
    integer note_in_octave;
    integer white_keys_before;
    integer black_key_center_x;
    integer black_key_x1, black_key_x2;
    integer white_key_x1, white_key_x2;
    always @(*) begin
        current_key = 0;
        is_on_black_key = 0;
        is_pressed = 0;

        white_keys_before = 0;
        if (in_x && in_y) begin
            for (k = 0; k < NUM_KEYS; k = k + 1) begin
                note_in_octave = (START_NOTE + k) % 12;
                if (is_black_key(note_in_octave[3:0])) begin
                    if (in_black_key_region) begin
                        black_key_center_x = (white_keys_before * WIDTH) / SAFE_NUM_WHITE_KEYS;
                        black_key_x1 = black_key_center_x - (BLACK_KEY_WIDTH / 2);
                        black_key_x2 = black_key_center_x + (BLACK_KEY_WIDTH / 2);
                        if ((local_x >= black_key_x1) && (local_x < black_key_x2)) begin
                            current_key = k;
                            is_on_black_key = 1'b1;
                            is_pressed = key_states[k];
                        end
                    end
                end else begin
                    white_key_x1 = (white_keys_before * WIDTH) / SAFE_NUM_WHITE_KEYS;
                    white_key_x2 = ((white_keys_before + 1) * WIDTH) / SAFE_NUM_WHITE_KEYS;
                    if (!is_on_black_key && (local_x >= white_key_x1) &&
                        (local_x < white_key_x2)) begin
                        current_key = k;
                        is_pressed = key_states[k];
                    end
                    white_keys_before = white_keys_before + 1;
                end
            end
        end
    end

    // 确定颜色
    reg [23:0] pixel_color;
    always @(*) begin
        if (!active) begin
            pixel_color = 24'd0;
        end else if (is_pressed) begin
            pixel_color = PRESSED_COLOR;
        end else if (is_on_black_key) begin
            pixel_color = BLACK_KEY_COLOR;
        end else begin
            pixel_color = WHITE_KEY_COLOR;
        end
    end

    assign color = pixel_color;

endmodule
