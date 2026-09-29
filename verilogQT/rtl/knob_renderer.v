`timescale 1ns / 1ps
//
// Knob Renderer
// 显示旋钮控件，指针根据 value 旋转
//

module knob_renderer #(
    parameter X_START = 0,
    parameter Y_START = 0,
    parameter SIZE = 80,
    parameter MIN_VALUE = 0,
    parameter MAX_VALUE = 127,
    parameter MIN_ANGLE = -135,
    parameter MAX_ANGLE = 135,
    parameter FG_COLOR = 24'h38BDF8,
    parameter BG_COLOR = 24'h1E2836
) (
    input wire [10:0] pixel_x,
    input wire [9:0] pixel_y,
    input wire [15:0] value,
    output wire active,
    output wire [23:0] color
);

    localparam RADIUS = SIZE / 2;
    localparam CENTER_X = X_START + RADIUS;
    localparam CENTER_Y = Y_START + RADIUS;

    wire in_bounds = (pixel_x >= X_START) && (pixel_x < X_START + SIZE) &&
                     (pixel_y >= Y_START) && (pixel_y < Y_START + SIZE);

    // 计算到中心的距离
    wire signed [11:0] dx = pixel_x - CENTER_X;
    wire signed [11:0] dy = pixel_y - CENTER_Y;
    wire signed [11:0] rel_x = dx;
    wire signed [11:0] rel_y = dy;
    wire [23:0] dist_sq = (dx * dx) + (dy * dy);
    wire [23:0] radius_sq = RADIUS * RADIUS;

    wire in_circle = (dist_sq <= radius_sq);
    wire on_border = (dist_sq > ((RADIUS - 3) * (RADIUS - 3))) &&
                     (dist_sq <= radius_sq);

    assign active = in_bounds && in_circle;

    // 将 value 映射到角度 (使用整数运算)
    // Map value ∈ [MIN_VALUE, MAX_VALUE] to the configured angle range.
    // Clamp the runtime value to the configured range before mapping it.
    // Values above MAX_VALUE used to wrap back to the minimum position.
    wire [31:0] value_normalized = (value <= MIN_VALUE) ? 0 :
                                    (value >= MAX_VALUE ? (MAX_VALUE - MIN_VALUE) :
                                    (value - MIN_VALUE));
    localparam integer VALUE_RANGE = (MAX_VALUE > MIN_VALUE) ?
                                     (MAX_VALUE - MIN_VALUE) : 1;

    localparam integer ANGLE_SPAN = (MAX_ANGLE > MIN_ANGLE) ?
                                    (MAX_ANGLE - MIN_ANGLE) : 0;
    localparam integer ANGLE_FRAC_BITS = 33;
    // value_range and angle_span are elaboration-time constants.  Replacing
    // the variable divider with a precomputed fixed-point multiplier keeps
    // this geometry path bounded and maps well to a DSP/shift implementation.
    localparam [63:0] ANGLE_STEP_Q = (ANGLE_SPAN > 0) ?
                                     ((((64'd1 << ANGLE_FRAC_BITS) * ANGLE_SPAN) + VALUE_RANGE - 1) / VALUE_RANGE) : 0;
    wire [79:0] angle_offset_fp = {48'd0, value_normalized} * {16'd0, ANGLE_STEP_Q};
    wire [31:0] angle_offset = (value_normalized >= VALUE_RANGE) ? ANGLE_SPAN :
                               (angle_offset_fp >> ANGLE_FRAC_BITS);
    wire signed [31:0] angle_deg = MIN_ANGLE + angle_offset;

    // 简化的指针绘制：使用象限判断和粗略角度检查
    // 将角度分为 8 个扇区，检查像素是否在对应扇区的径向线段上

    // 计算极坐标角度（粗略）
    // 使用象限判断避免三角函数
    wire q1 = (rel_x >= 0) && (rel_y < 0);   // 第一象限 (右上)
    wire q2 = (rel_x < 0) && (rel_y < 0);    // 第二象限 (左上)
    wire q3 = (rel_x < 0) && (rel_y >= 0);   // 第三象限 (左下)
    wire q4 = (rel_x >= 0) && (rel_y >= 0);  // 第四象限 (右下)

    // 判断像素是否在指针线段上（简化版本）
    // 指针从中心指向外围，长度约为 3/4 半径
    wire [11:0] indicator_length = (RADIUS * 3) / 4;

    // 粗略匹配：根据目标角度判断像素是否在指针路径上
    wire in_indicator_region = (dist_sq > ((RADIUS/4) * (RADIUS/4))) &&
                                (dist_sq < (indicator_length * indicator_length));

    // 简化的角度匹配（8 个方向）
    // angle_deg depends on the runtime value input, so this must be
    // combinational logic rather than a module-level generate-if.
    reg near_indicator;
    always @* begin
        near_indicator = 1'b0;

        // 根据 angle_deg 判断指针方向
        if (angle_deg >= -22 && angle_deg < 22) begin
            // 0° (向上)
            near_indicator = in_indicator_region && (rel_x > -2 && rel_x < 2) && (rel_y < 0);
        end else if (angle_deg >= 22 && angle_deg < 67) begin
            // 45° (右上)
            near_indicator = in_indicator_region && q1 && (rel_x > 0) && (rel_y < 0) &&
                             ((rel_x + rel_y) > -3 && (rel_x + rel_y) < 3);
        end else if (angle_deg >= 67 && angle_deg < 112) begin
            // 90° (向右)
            near_indicator = in_indicator_region && (rel_y > -2 && rel_y < 2) && (rel_x > 0);
        end else if (angle_deg >= 112 && angle_deg <= 135) begin
            // 135° (右下)
            near_indicator = in_indicator_region && q4 && (rel_x > 0) && (rel_y > 0) &&
                             ((rel_x - rel_y) > -3 && (rel_x - rel_y) < 3);
        end else if (angle_deg < -112) begin
            // -135° (左下)
            near_indicator = in_indicator_region && q3 && (rel_x < 0) && (rel_y > 0) &&
                             ((rel_x + rel_y) > -3 && (rel_x + rel_y) < 3);
        end else if (angle_deg >= -112 && angle_deg < -67) begin
            // -90° (向左)
            near_indicator = in_indicator_region && (rel_y > -2 && rel_y < 2) && (rel_x < 0);
        end else if (angle_deg >= -67 && angle_deg < -22) begin
            // -45° (左上)
            near_indicator = in_indicator_region && q2 && (rel_x < 0) && (rel_y < 0) &&
                             ((rel_x - rel_y) > -3 && (rel_x - rel_y) < 3);
        end
    end

    // 输出颜色
    assign color = active ? (on_border || near_indicator ? FG_COLOR : BG_COLOR) : 24'd0;

endmodule
