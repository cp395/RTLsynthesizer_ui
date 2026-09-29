`timescale 1ns / 1ps
//
// Tang Mega 60K 超简单 HDMI 测试
// 直接用 27MHz 时钟，不用 PLL
// 输出固定彩色条纹
//

module top_mega_60k_simple (
    // 27 MHz 板载晶振
    input wire clk_27mhz,

    // 复位按钮（active low）
    input wire key_reset_n,

    // LED 调试（Tang Mega 60K 有 6 个 LED）
    output wire [5:0] led,

    // HDMI 输出（到 ADV7513）
    output wire [23:0] hdmi_d,      // RGB888
    output wire hdmi_clk,           // 像素时钟
    output wire hdmi_vsync,
    output wire hdmi_hsync,
    output wire hdmi_de,

    // I2C（暂时悬空）
    output wire hdmi_scl,
    inout wire hdmi_sda
);

    // ========================================
    // 使用 27MHz 直接输出
    // ========================================
    wire clk_pixel = clk_27mhz;

    // ========================================
    // 复位同步
    // ========================================
    reg [7:0] rst_cnt = 0;
    reg sys_rst_n = 0;

    always @(posedge clk_pixel) begin
        if (!key_reset_n) begin
            rst_cnt <= 0;
            sys_rst_n <= 0;
        end else if (rst_cnt < 255) begin
            rst_cnt <= rst_cnt + 1;
            sys_rst_n <= 0;
        end else begin
            sys_rst_n <= 1;
        end
    end

    // ========================================
    // 简单计数器生成彩色条纹
    // ========================================
    reg [23:0] counter = 0;
    reg [7:0] r_out, g_out, b_out;

    always @(posedge clk_pixel) begin
        if (!sys_rst_n) begin
            counter <= 0;
            r_out <= 8'hFF;
            g_out <= 8'h00;
            b_out <= 8'h00;
        end else begin
            counter <= counter + 1;

            // 每 256 个周期切换颜色
            case (counter[15:13])
                3'h0: begin r_out <= 8'hFF; g_out <= 8'h00; b_out <= 8'h00; end // 红
                3'h1: begin r_out <= 8'h00; g_out <= 8'hFF; b_out <= 8'h00; end // 绿
                3'h2: begin r_out <= 8'h00; g_out <= 8'h00; b_out <= 8'hFF; end // 蓝
                3'h3: begin r_out <= 8'hFF; g_out <= 8'hFF; b_out <= 8'h00; end // 黄
                3'h4: begin r_out <= 8'hFF; g_out <= 8'h00; b_out <= 8'hFF; end // 品红
                3'h5: begin r_out <= 8'h00; g_out <= 8'hFF; b_out <= 8'hFF; end // 青
                3'h6: begin r_out <= 8'hFF; g_out <= 8'hFF; b_out <= 8'hFF; end // 白
                3'h7: begin r_out <= 8'h80; g_out <= 8'h80; b_out <= 8'h80; end // 灰
            endcase
        end
    end

    // ========================================
    // HDMI 输出（直接输出，不管时序）
    // ========================================
    assign hdmi_d = {r_out, g_out, b_out};
    assign hdmi_clk = clk_pixel;
    assign hdmi_vsync = counter[16];    // 慢速切换
    assign hdmi_hsync = counter[12];    // 较快切换
    assign hdmi_de = 1'b1;              // 始终有效

    // ========================================
    // I2C 悬空
    // ========================================
    assign hdmi_scl = 1'b1;
    // hdmi_sda 是 inout，让它悬空

    // ========================================
    // LED 调试指示
    // ========================================
    assign led[0] = sys_rst_n;          // 复位释放后亮
    assign led[1] = counter[23];        // 慢闪
    assign led[2] = counter[20];        // 中速闪
    assign led[3] = counter[16];        // 快闪（同 vsync）
    assign led[4] = r_out[7];           // 红色分量 MSB
    assign led[5] = clk_pixel;          // 时钟指示（会非常快，可能看起来常亮）

endmodule
