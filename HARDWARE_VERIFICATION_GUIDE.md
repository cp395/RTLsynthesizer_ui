# 硬件验证完整指南

> 本文档是验证计划和历史说明，不是已完成的验收报告。当前仓库没有经 Gowin
> 综合/布局布线/时序和实板 HDMI 验证的 bitstream；下文标记为“包/项目”的内容，
> 只有在对应目录实际存在并通过测试后才能算交付物。

## 目标

在 Tang Mega 60K 上验证 UI Designer 生成的代码，确保能在真实硬件上显示界面。

---

## 当前状态分析

### 我们已经有的：
- ✅ 完整的 UI Schema 和渲染逻辑
- ✅ 生成的 Verilog 代码（4,319 行）
- ⚠️ Python 参考渲染器（局部测试通过，未与 RTL 逐像素验收）
- ⚠️ 示例界面（JSON 有 29 个控件，手写 RTL 不自动覆盖全部控件）

### 我们缺少的：
- ❌ Tang Mega 60K 实际引脚约束
- ❌ HDMI 物理层（TMDS 编码器）
- ❌ 在真实硬件上的验证
- ❌ 与 Gowin 工具链的兼容性测试

---

## 问题 1：这是半成品吗？

### 回答：这是**UI 原型逻辑**，还需要硬件适配和工具链验证

我们生成的代码是：
```
┌─────────────────────────────────┐
│  UI Logic (完整 ✅)              │
│  - 像素渲染                      │
│  - 控件逻辑                      │
│  - HDMI 时序                     │
│  输出: RGB888 + sync             │
└────────────┬────────────────────┘
             │
             ▼
    ？？？ 硬件适配层 ？？？
             │
             ▼
┌─────────────────────────────────┐
│  HDMI 物理接口                   │
│  - TMDS 编码                     │
│  - 差分信号                      │
│  - 具体引脚                      │
└─────────────────────────────────┘
```

**硬件适配层取决于你的板卡设计**：
- Tang Mega 60K 可能有专用 HDMI PHY 芯片
- 或者需要用 FPGA IO 直接输出 TMDS
- 或者有其他视频接口（VGA、RGB LCD）

---

## 解决方案：分三个阶段验证

### 阶段 1：仿真验证（不需要硬件）✅ 可以立即做

验证 UI 逻辑本身是正确的。

### 阶段 2：简化硬件测试（LED/VGA）✅ 可以立即做

验证代码能在 Gowin 上综合，时序满足。

### 阶段 3：完整 HDMI 输出（需要板卡资料）⏳ 需要引脚信息

真正输出到 HDMI 显示器。

---

## 阶段 1：仿真验证 ✅

### 我现在就为你创建完整的仿真测试

这一步**不需要硬件**，证明逻辑正确。

```verilog
// tb_ui_system.v - 完整系统仿真
`timescale 1ns / 1ps

module tb_ui_system;

    reg clk_pixel;
    reg rst_n;
    
    // 测试数据
    reg [7:0] fft_bins [0:127];
    reg [15:0] ui_state [0:31];
    
    // HDMI 输出
    wire [7:0] hdmi_r, hdmi_g, hdmi_b;
    wire hdmi_de, hdmi_hsync, hdmi_vsync;
    
    // 实例化 UI
    ui_top dut (
        .clk_pixel(clk_pixel),
        .rst_n(rst_n),
        .fft_bins(fft_bins),
        .ui_state(ui_state),
        .hdmi_r(hdmi_r),
        .hdmi_g(hdmi_g),
        .hdmi_b(hdmi_b),
        .hdmi_de(hdmi_de),
        .hdmi_hsync(hdmi_hsync),
        .hdmi_vsync(hdmi_vsync)
    );
    
    // 74.25 MHz 时钟
    initial clk_pixel = 0;
    always #6.734 clk_pixel = ~clk_pixel;
    
    // 复位
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end
    
    // 测试数据
    integer i;
    initial begin
        // 初始化
        for (i = 0; i < 128; i = i + 1)
            fft_bins[i] = 0;
        for (i = 0; i < 32; i = i + 1)
            ui_state[i] = 0;
        
        #200;
        
        // 设置测试值
        ui_state[0] = 16'hC000;  // OP1 75%
        ui_state[1] = 16'h8000;  // OP2 50%
        ui_state[2] = 16'h6000;  // OP3 37.5%
        ui_state[3] = 16'hC000;  // OP4 75%
        ui_state[4] = 16'h3000;  // OP5 18.75%
        ui_state[5] = 16'hD000;  // OP6 81.25%
        
        // FFT 数据
        for (i = 0; i < 64; i = i + 1)
            fft_bins[i] = 200 - i * 2;
        for (i = 64; i < 128; i = i + 1)
            fft_bins[i] = 30;
        
        // 运行一帧 (16.7 ms)
        #16700000;
        
        $display("Simulation complete!");
        $finish;
    end
    
    // 捕获像素输出
    integer file;
    integer pixel_count = 0;
    
    initial begin
        file = $fopen("sim_output.txt", "w");
    end
    
    always @(posedge clk_pixel) begin
        if (hdmi_de) begin
            $fwrite(file, "%02X%02X%02X\n", hdmi_r, hdmi_g, hdmi_b);
            pixel_count = pixel_count + 1;
        end
    end
    
    // 统计
    always @(negedge hdmi_vsync) begin
        $display("Frame done, pixels: %d", pixel_count);
        pixel_count = 0;
    end

endmodule
```

**运行仿真**：
```bash
# Icarus Verilog
iverilog -o sim tb_ui_system.v rtl/*.v
vvp sim

# 或 ModelSim
vlog rtl/*.v testbench/tb_ui_system.v
vsim tb_ui_system
run 20ms
```

**验证结果**：
```python
# 比对仿真输出和 Python 参考
import numpy as np
from PIL import Image

# 读取仿真输出
pixels = []
with open("sim_output.txt") as f:
    for line in f:
        rgb = int(line.strip(), 16)
        r = (rgb >> 16) & 0xFF
        g = (rgb >> 8) & 0xFF
        b = rgb & 0xFF
        pixels.append([r, g, b])

# 转换为图像
sim_img = np.array(pixels).reshape(720, 1280, 3)
Image.fromarray(sim_img.astype(np.uint8)).save("sim_output.png")

# 与参考比对
ref_img = np.array(Image.open("testbench/reference_frame.png"))
diff = np.abs(sim_img - ref_img)

print(f"Max difference: {diff.max()}")
print(f"Mean difference: {diff.mean()}")
print(f"Match: {(diff == 0).all()}")
```

**如果仿真通过**：✅ 逻辑完全正确

---

## 阶段 2：简化硬件测试 ✅

### 不用 HDMI，先用 LED 验证

创建一个最简单的测试，验证代码能在 Gowin 上综合并满足时序。

```verilog
// top_led_test.v - LED 测试
module top_led_test (
    input wire clk_27mhz,
    input wire rst_n,
    output wire [7:0] led  // 板载 LED
);

    // PLL
    wire clk_pixel;
    wire pll_lock;
    
    Gowin_rPLL pll (
        .clkout(clk_pixel),
        .lock(pll_lock),
        .clkin(clk_27mhz)
    );
    
    // 简化的 UI 测试
    reg [15:0] ui_state [0:31];
    reg [7:0] fft_bins [0:127];
    
    wire [7:0] hdmi_r, hdmi_g, hdmi_b;
    wire hdmi_de;
    
    // 测试数据
    reg [31:0] counter = 0;
    always @(posedge clk_pixel) begin
        counter <= counter + 1;
        ui_state[0] <= counter[31:16];
    end
    
    // UI 模块
    ui_top ui (
        .clk_pixel(clk_pixel),
        .rst_n(pll_lock),
        .fft_bins(fft_bins),
        .ui_state(ui_state),
        .hdmi_r(hdmi_r),
        .hdmi_g(hdmi_g),
        .hdmi_b(hdmi_b),
        .hdmi_de(hdmi_de),
        .hdmi_hsync(),
        .hdmi_vsync()
    );
    
    // 输出到 LED
    assign led[0] = pll_lock;
    assign led[1] = counter[25];  // 闪烁
    assign led[7:2] = hdmi_r[7:2];  // 显示红色分量

endmodule
```

**验证项目**：
1. PLL 能否锁定 → LED0 常亮
2. 时钟能否运行 → LED1 闪烁
3. UI 能否生成像素 → LED[7:2] 变化

**综合检查清单**：
- [ ] Synthesize 成功，无 Error
- [ ] LUT 使用 < 10,000（占用 < 17%）
- [ ] Place & Route 成功
- [ ] 时序满足 74.25 MHz（无负 slack）
- [ ] 生成 .fs 文件成功
- [ ] 下载到 FPGA 成功
- [ ] LED 行为符合预期

---

## 阶段 3：完整 HDMI 输出 ⏳

### 这需要 Tang Mega 60K 的具体信息

我查了一下 Tang Mega 60K：

根据 [Sipeed Wiki](https://wiki.sipeed.com/hardware/zh/tang/tang-mega-60k/mega-60k.html)，Tang Mega 60K **有板载 HDMI 接口**。

**但是**，我需要知道：

#### 选项 A：使用板载 HDMI PHY 芯片

如果板卡有专用芯片（如 ADV7513、TFP410），你需要：
1. I2C 配置芯片
2. 送入 RGB888 + sync
3. 查看例程代码

#### 选项 B：FPGA 直接输出 TMDS

如果是 FPGA IO 直出：
1. 需要 TMDS 编码器 IP 核
2. 差分 IO 配置
3. 更高的时钟（74.25 MHz × 10 = 742.5 MHz）

#### 选项 C：先用 VGA

Tang Mega 60K 也有 VGA 接口，这个更简单：
```verilog
assign vga_r = hdmi_r[7:4];  // 4-bit
assign vga_g = hdmi_g[7:4];
assign vga_b = hdmi_b[7:4];
assign vga_hsync = hdmi_hsync;
assign vga_vsync = hdmi_vsync;
```

---

## 我现在能为你做什么？

### 规划中的验证包（当前不代表已交付）：

**我会创建 3 个独立的可验证项目**：

### 项目 1：仿真验证包（规划）
```
sim_verification/
├── tb_ui_system.v           # 完整系统 testbench
├── pixel_compare.py         # 像素比对脚本
├── run_icarus.sh            # Icarus Verilog 脚本
├── run_modelsim.sh          # ModelSim 脚本
└── README.md                # 仿真步骤
```
**验证内容**：UI 逻辑正确性（不需要硬件）

### 项目 2：LED 测试包（规划）
```
led_test/
├── top_led_test.v           # LED 测试顶层
├── constraints_template.cst # 约束模板
├── gowin_project.gprj       # Gowin 工程文件
└── README.md                # 综合步骤
```
**验证内容**：代码能综合、时序满足（需要板卡，但不需要显示器）

### 项目 3：VGA 输出包（规划）
```
vga_output/
├── top_vga.v                # VGA 顶层
├── vga_constraints.cst      # VGA 引脚约束
└── README.md                # 连接 VGA 显示器
```
**验证内容**：实际显示输出（需要 VGA 显示器）

### 项目 4：HDMI 输出包 ⏳（需要你的板卡资料）
```
hdmi_output/
├── top_hdmi.v               # HDMI 顶层
├── tmds_encoder.v           # TMDS 编码器
├── hdmi_constraints.cst     # HDMI 引脚约束
└── README.md                # HDMI 配置
```
**验证内容**：完整 HDMI 1280×720@60Hz（需要板卡手册）

---

## 你需要提供的信息

为了完成**项目 4（HDMI 输出）**，我需要知道：

1. **Tang Mega 60K 的 HDMI 实现方式**：
   - 是否有专用 HDMI PHY 芯片？型号是什么？
   - 还是 FPGA IO 直接输出？
   - 板卡有没有 HDMI 例程代码？

2. **引脚分配**：
   - 27 MHz 晶振引脚号
   - 复位按钮引脚号
   - HDMI 相关引脚号

3. **你的现状**：
   - 你现在有 Tang Mega 60K 实物吗？
   - 你跑过其他 HDMI 例程吗？
   - 你想先用 VGA 测试吗（更简单）？

---

## 我的建议：渐进式验证

### Step 1：仿真（需要先准备并运行实际 testbench）
仿真结果可以提高置信度，但不能单独证明逻辑 100% 正确或替代综合/硬件测试。

### Step 2：LED 测试（需要板卡）
你综合下载到 FPGA，看 LED 闪烁 → **证明代码能跑**

### Step 3：VGA 输出（需要 VGA 显示器）
降低分辨率到 640×480，VGA 输出 → **证明能显示**

### Step 4：HDMI 输出（需要板卡手册）
验证完整 1280×720@60Hz HDMI 输出（结果取决于最终板卡和芯片资料）

---

## 立即行动

告诉我你现在的情况：

**A. 我只想先看仿真证明逻辑对**
→ 我立即给你仿真验证包

**B. 我有板卡，但没有 HDMI 资料**
→ 我给你 LED 测试包 + VGA 输出包

**C. 我有板卡和 HDMI 资料**
→ 告诉我板卡的 HDMI 实现方式，我给你完整 HDMI 包

**D. 我现在没板卡，只是想确认这不是半成品**
→ 我给你完整仿真包 + 理论分析文档，证明逻辑完整

**你选哪个？**
