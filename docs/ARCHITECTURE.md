# FPGA UI Designer - 架构设计文档

> 架构草稿。硬件章节中的晶振、器件、HDMI 芯片和资源/时序数字是示例假设，
> 当前未由 Gowin 综合或实板测量验证；当前状态以项目根目录 `PROJECT_STATUS.md` 为准。

## 系统架构概览

### 设计理念

传统 FPGA UI 方案通常采用以下架构：

```
CPU (软核/外部) → Framebuffer (DDR) → DMA → HDMI
```

**问题：**
- 需要 CPU 和完整的软件栈
- 需要大量外部 RAM (几 MB)
- 需要复杂的 DMA 控制器
- 帧率受限于内存带宽

---

### 本方案：编译型 UI

我们采用**编译时固定布局，运行时实时渲染**的架构：

```
PC 端设计
    ↓
编译为 RTL
    ↓
FPGA 像素流生成
    ↓
HDMI 输出
```

**核心思想：**
> 控件的位置、大小、类型在综合时确定；
> 显示内容（数值、状态）在运行时更新。

类比：
- 传统方案 = 解释型语言 (每帧都要"绘制")
- 本方案 = 编译型语言 (UI 逻辑直接变成硬件)

---

## 三层架构

### Layer 1: PC 端设计工具

```
┌──────────────────────────────────────┐
│         UI Designer (PySide6)        │
│  - 可视化编辑                         │
│  - 实时预览                           │
│  - 导出 JSON                          │
└──────────────┬───────────────────────┘
               │
        ui_scene.json
               │
┌──────────────▼───────────────────────┐
│      RTL Generator (Python)          │
│  - 解析 UI Schema                     │
│  - 生成 Verilog 代码                  │
│  - 生成 ROM 数据                      │
└──────────────┬───────────────────────┘
               │
       Verilog .v files
```

**职责：**
- 设计界面布局
- 预览最终效果
- 生成 FPGA 可综合代码

---

### Layer 2: RTL 渲染引擎

```
┌─────────────────────────────────────────┐
│             ui_top.v                    │
│  ┌──────────────┐   ┌────────────────┐ │
│  │ HDMI Timing  │──►│ Pixel Renderer │ │
│  │              │   │                │ │
│  │ pixel_x      │   │  ┌───────────┐ │ │
│  │ pixel_y      │   │  │ Widget 0  │ │ │
│  │ display_en   │   │  │ Widget 1  │ │ │
│  └──────────────┘   │  │ ...       │ │ │
│                     │  │ Widget N  │ │ │
│  ┌──────────────┐   │  └───────────┘ │ │
│  │  UI State    │──►│                │ │
│  │  - fft_bins  │   │   Compositor   │ │
│  │  - ui_state  │   │                │ │
│  └──────────────┘   └────────┬───────┘ │
│                               │         │
│                           RGB888        │
└───────────────────────────────┼─────────┘
                                ▼
                          HDMI Interface
```

**职责：**
- 生成 HDMI 时序
- 实时计算每个像素颜色
- 合成多层控件

---

### Layer 3: 硬件实现

```
Tang Mega 60K
├── PLL: 27 MHz → 74.25 MHz
│
├── UI 子系统
│   ├── HDMI Timing Generator
│   ├── Pixel Renderer
│   └── Font/Icon ROMs
│
├── 音频合成引擎
│   ├── FM Operators
│   ├── PCM Generator
│   └── FFT/Spectrum Analyzer
│
└── 数据桥接
    ├── fft_bins[0:127]
    └── ui_state[0:31]
```

**职责：**
- 实际硬件综合
- 时序收敛
- 与其他模块交互

---

## 核心模块详解

### 1. HDMI Timing Generator

**功能：** 生成标准 1280×720@60Hz 时序

**时序参数：**

| 参数           | 值      |
|---------------|---------|
| 像素时钟       | 74.25 MHz |
| H Active      | 1280    |
| H Front Porch | 110     |
| H Sync Width  | 40      |
| H Back Porch  | 220     |
| H Total       | 1650    |
| V Active      | 720     |
| V Front Porch | 5       |
| V Sync Width  | 5       |
| V Back Porch  | 20      |
| V Total       | 750     |

**时序图：**

```
Horizontal:
|<--- 1280 --->|<110>|<40>|<220>|
 Active         FP    Sync  BP

Vertical:
|<--- 720 --->|<5>|<5>|<20>|
 Active        FP  Sync BP
```

**状态机：**

```verilog
// 水平计数器
always @(posedge clk) begin
    if (h_count == H_TOTAL - 1)
        h_count <= 0;
    else
        h_count <= h_count + 1;
end

// 垂直计数器
always @(posedge clk) begin
    if (h_count == H_TOTAL - 1) begin
        if (v_count == V_TOTAL - 1)
            v_count <= 0;
        else
            v_count <= v_count + 1;
    end
end

// 有效显示区域
assign display_active = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);
assign pixel_x = h_count;
assign pixel_y = v_count;

// 同步信号
assign hsync = (h_count >= H_ACTIVE + H_FP) && 
               (h_count < H_ACTIVE + H_FP + H_SYNC);
assign vsync = (v_count >= V_ACTIVE + V_FP) && 
               (v_count < V_ACTIVE + V_FP + V_SYNC);
```

**资源占用：**
- LUT: ~50
- FF: ~30
- 无 DSP, 无 BRAM

---

### 2. Pixel Renderer

**功能：** 根据当前扫描位置实时生成像素颜色

**架构：**

```
pixel_x, pixel_y
    |
    ├──► Widget 0 ───► active[0], color[0]
    ├──► Widget 1 ───► active[1], color[1]
    ├──► Widget 2 ───► active[2], color[2]
    ├──► ...
    └──► Widget N ───► active[N], color[N]
    
    ▼
Compositor (按 layer 合成)
    
    ▼
final RGB
```

**流水线：**

```
Stage 0: 坐标输入
    pixel_x, pixel_y
    
Stage 1: 区域判断
    in_widget[0] = (x >= X0) && (x < X1) && (y >= Y0) && (y < Y1)
    in_widget[1] = ...
    
Stage 2: 颜色生成
    color[0] = f(pixel_x, pixel_y, state)
    color[1] = ...
    
Stage 3: 合成
    找到 layer 最高且 active 的控件
    
Stage 4: 输出
    rgb_out
```

**伪代码：**

```verilog
// Stage 1: 所有控件判断是否激活
wire [N-1:0] widget_active;
wire [23:0] widget_color [0:N-1];
wire [3:0] widget_layer [0:N-1];

generate
    for (i = 0; i < N; i++) begin
        widget_renderer #(...) inst_i (
            .pixel_x(pixel_x),
            .pixel_y(pixel_y),
            .state(ui_state[i]),
            .active(widget_active[i]),
            .color(widget_color[i]),
            .layer(widget_layer[i])
        );
    end
endgenerate

// Stage 2: 找到最高层且激活的控件
reg [23:0] final_color;
always @(*) begin
    final_color = BACKGROUND_COLOR;
    
    for (int i = 0; i < N; i++) begin
        if (widget_active[i] && widget_layer[i] >= current_layer) begin
            final_color = widget_color[i];
            current_layer = widget_layer[i];
        end
    end
end

// Stage 3: 输出
assign rgb_r = final_color[23:16];
assign rgb_g = final_color[15:8];
assign rgb_b = final_color[7:0];
```

**优化：**

1. **并行判断**：所有控件同时判断
2. **提前剪枝**：坐标明显不在范围内时跳过
3. **流水线**：插入寄存器阶段

---

### 3. Widget Renderer

每种控件都是一个独立模块。

#### 3.1 Panel Renderer

```verilog
module panel_renderer #(
    parameter X_START = 0,
    parameter Y_START = 0,
    parameter WIDTH = 100,
    parameter HEIGHT = 100,
    parameter BG_COLOR = 24'h0F131C,
    parameter BORDER_COLOR = 24'h38BDF8,
    parameter BORDER_WIDTH = 2
) (
    input wire [10:0] pixel_x,
    input wire [9:0] pixel_y,
    output wire active,
    output wire [23:0] color
);

    localparam X_END = X_START + WIDTH;
    localparam Y_END = Y_START + HEIGHT;
    
    // 判断是否在区域内
    wire in_panel = (pixel_x >= X_START) && (pixel_x < X_END) &&
                    (pixel_y >= Y_START) && (pixel_y < Y_END);
    
    // 判断是否在边框
    wire in_border = in_panel && (
        (pixel_x < X_START + BORDER_WIDTH) ||
        (pixel_x >= X_END - BORDER_WIDTH) ||
        (pixel_y < Y_START + BORDER_WIDTH) ||
        (pixel_y >= Y_END - BORDER_WIDTH)
    );
    
    assign active = in_panel;
    assign color = in_border ? BORDER_COLOR : BG_COLOR;

endmodule
```

**资源占用：**
- LUT: ~20
- FF: 0
- 纯组合逻辑

---

#### 3.2 Bar Renderer

```verilog
module bar_renderer #(
    parameter X_START = 0,
    parameter Y_START = 0,
    parameter WIDTH = 240,
    parameter HEIGHT = 18,
    parameter ORIENTATION = "horizontal",  // or "vertical"
    parameter FILL_COLOR = 24'h38BDF8,
    parameter BG_COLOR = 24'h161D2B
) (
    input wire [10:0] pixel_x,
    input wire [9:0] pixel_y,
    input wire [15:0] value,  // 0~65535
    output wire active,
    output wire [23:0] color
);

    localparam X_END = X_START + WIDTH;
    localparam Y_END = Y_START + HEIGHT;
    
    wire in_bar = (pixel_x >= X_START) && (pixel_x < X_END) &&
                  (pixel_y >= Y_START) && (pixel_y < Y_END);
    
    // 计算填充长度
    wire [10:0] fill_width = (value * WIDTH) >> 16;
    
    // 判断是否在填充区域
    wire [10:0] rel_x = pixel_x - X_START;
    wire in_fill = (rel_x < fill_width);
    
    assign active = in_bar;
    assign color = in_fill ? FILL_COLOR : BG_COLOR;

endmodule
```

**资源占用：**
- LUT: ~40
- FF: 0
- DSP: 1 (乘法器)

**优化版（避免 DSP）：**

```verilog
// 使用查找表
reg [10:0] fill_width_lut [0:255];

initial begin
    for (int i = 0; i < 256; i++)
        fill_width_lut[i] = (i * WIDTH) / 255;
end

wire [7:0] value_8bit = value[15:8];
wire [10:0] fill_width = fill_width_lut[value_8bit];
```

---

#### 3.3 Spectrum Renderer

```verilog
module spectrum_renderer #(
    parameter X_START = 80,
    parameter Y_START = 120,
    parameter WIDTH = 600,
    parameter HEIGHT = 240,
    parameter NUM_BARS = 64,
    parameter BAR_COLOR = 24'h38BDF8,
    parameter BG_COLOR = 24'h0A0D12
) (
    input wire clk,
    input wire [10:0] pixel_x,
    input wire [9:0] pixel_y,
    input wire [7:0] spectrum [0:127],
    output reg active,
    output reg [23:0] color
);

    localparam X_END = X_START + WIDTH;
    localparam Y_END = Y_START + HEIGHT;
    localparam BAR_WIDTH = WIDTH / NUM_BARS;
    
    always @(posedge clk) begin
        active <= 0;
        color <= BG_COLOR;
        
        if ((pixel_x >= X_START) && (pixel_x < X_END) &&
            (pixel_y >= Y_START) && (pixel_y < Y_END)) begin
            
            active <= 1;
            
            // 计算当前是第几根柱子
            wire [6:0] bar_index = (pixel_x - X_START) / BAR_WIDTH;
            
            // 获取该柱子的高度值
            wire [7:0] bar_value = spectrum[bar_index];
            
            // 计算柱子像素高度
            wire [9:0] bar_height = (bar_value * HEIGHT) >> 8;
            
            // 判断当前像素是否点亮
            wire [9:0] rel_y = pixel_y - Y_START;
            wire [9:0] from_bottom = HEIGHT - rel_y;
            
            if (from_bottom < bar_height)
                color <= BAR_COLOR;
        end
    end

endmodule
```

**资源占用：**
- LUT: ~100
- FF: ~50
- DSP: 2
- BRAM: 1 (存储 spectrum 数组)

---

### 4. Font Renderer

**字体格式：** 8×16 点阵

```
  01234567
0 ░░███░░░
1 ░█░░░█░░
2 █░░░░░█░
3 █░░░░░█░
4 █░░░░░█░
5 █░░░░░█░
6 ████████
7 █░░░░░█░
8 █░░░░░█░
...
```

**存储结构：**

```verilog
module font_rom (
    input wire clk,
    input wire [7:0] char_code,  // ASCII 码
    input wire [3:0] row,         // 第几行 (0~15)
    output reg [7:0] pixels       // 8 个像素
);

    always @(posedge clk) begin
        case (char_code)
            8'd65: begin // 'A'
                case (row)
                    4'd0: pixels = 8'b00111000;
                    4'd1: pixels = 8'b01000100;
                    4'd2: pixels = 8'b10000010;
                    ...
                endcase
            end
            // ... 其他字符
        endcase
    end

endmodule
```

**文本渲染：**

```verilog
module text_renderer #(
    parameter X_START = 100,
    parameter Y_START = 50,
    parameter TEXT = "HELLO",
    parameter TEXT_LEN = 5,
    parameter COLOR = 24'hFFFFFF
) (
    input wire clk,
    input wire [10:0] pixel_x,
    input wire [9:0] pixel_y,
    output reg active,
    output reg [23:0] color
);

    wire in_text_area = (pixel_x >= X_START) && 
                        (pixel_x < X_START + TEXT_LEN * 8) &&
                        (pixel_y >= Y_START) && 
                        (pixel_y < Y_START + 16);
    
    // 计算字符索引
    wire [7:0] char_index = (pixel_x - X_START) / 8;
    
    // 字符内坐标
    wire [2:0] char_x = (pixel_x - X_START) % 8;
    wire [3:0] char_y = pixel_y - Y_START;
    
    // 获取字符 ASCII 码
    reg [7:0] char_code;
    always @(*) begin
        case (char_index)
            0: char_code = "H";
            1: char_code = "E";
            2: char_code = "L";
            3: char_code = "L";
            4: char_code = "O";
            default: char_code = " ";
        endcase
    end
    
    // 查询字体
    wire [7:0] row_pixels;
    font_rom font (
        .clk(clk),
        .char_code(char_code),
        .row(char_y),
        .pixels(row_pixels)
    );
    
    // 判断当前像素
    wire pixel_on = row_pixels[7 - char_x];
    
    always @(posedge clk) begin
        active <= in_text_area && pixel_on;
        color <= COLOR;
    end

endmodule
```

**资源占用：**
- LUT: ~50 per text
- FF: ~30
- BRAM: ~1 (共享字体 ROM)

---

## 数据流

### UI State 设计

**接口：**

```verilog
input wire [7:0] fft_bins [0:127];   // FFT 频谱数据
input wire [15:0] ui_state [0:31];   // 通用状态寄存器
```

**映射示例：**

```verilog
// 在你的顶层模块
assign ui_state[0] = op1_level;       // 16'h0000~16'hFFFF
assign ui_state[1] = op2_level;
assign ui_state[2] = op3_level;
assign ui_state[3] = op4_level;
assign ui_state[4] = op5_level;
assign ui_state[5] = op6_level;
assign ui_state[6] = current_velocity;
assign ui_state[7] = current_preset;
assign ui_state[8] = current_note;
assign ui_state[9] = {7'b0, active_voices}; // 9 bit
assign ui_state[10] = {15'b0, page_select}; // 1 bit
// ... 更多状态
```

**频谱数据：**

```verilog
// FFT 输出连接
wire [7:0] fft_magnitude [0:511];  // 完整 FFT 输出

// 降采样到 128 bins
generate
    for (i = 0; i < 128; i++) begin
        assign fft_bins[i] = fft_magnitude[i*4];  // 每 4 个取一个
    end
endgenerate
```

---

## 资源预算

### 示例项目（29 控件）

| 模块                | LUT   | FF    | BRAM | DSP |
|---------------------|-------|-------|------|-----|
| hdmi_timing         | 50    | 30    | 0    | 0   |
| pixel_renderer      | 1500  | 800   | 0    | 0   |
| 7× panel            | 140   | 0     | 0    | 0   |
| 13× text            | 650   | 390   | 1    | 0   |
| 1× spectrum         | 100   | 50    | 1    | 2   |
| 6× bar              | 240   | 0     | 0    | 6   |
| 1× waveform         | 80    | 40    | 2    | 0   |
| 1× keyboard         | 200   | 100   | 0    | 0   |
| font_rom            | 50    | 0     | 4    | 0   |
| **总计**            | **3010** | **1410** | **8** | **8** |

### 占用率（Tang Mega 60K）

| 资源  | 可用    | 使用  | 占用率 |
|-------|---------|-------|--------|
| LUT4  | 59,904  | 3,010 | 5%     |
| FF    | 59,904  | 1,410 | 2%     |
| BSRAM | 118     | 8     | 7%     |
| DSP   | 118     | 8     | 7%     |

**结论：资源占用非常低！**

---

## 时序分析

### 关键路径

1. **像素坐标 → 控件判断**
   ```
   pixel_x/y → comparator → in_area
   延迟: ~2 ns
   ```

2. **状态查询 → 颜色计算**
   ```
   ui_state[n] → multiplier → color
   延迟: ~5 ns
   ```

3. **多控件合成**
   ```
   N × (active, color) → priority encoder → final_color
   延迟: ~3 ns
   ```

4. **输出寄存**
   ```
   final_color → output register
   延迟: ~1 ns
   ```

**总延迟：** ~11 ns < 13.468 ns (74.25 MHz)

**余量：** 2.5 ns (18%)

### 优化策略

1. **插入流水线**
   ```
   Stage 1: 坐标判断
   Stage 2: 状态查询
   Stage 3: 颜色计算
   Stage 4: 合成输出
   ```

2. **复制寄存器**
   ```
   pixel_x/y 复制给每个控件，减少扇出
   ```

3. **提前计算**
   ```
   某些静态参数在复位后预计算
   ```

---

## 扩展性

### 添加新分辨率

修改 `hdmi_timing.v`:

```verilog
// 640×480@60Hz
parameter H_ACTIVE = 640;
parameter H_FP = 16;
parameter H_SYNC = 96;
parameter H_BP = 48;
parameter H_TOTAL = 800;

parameter V_ACTIVE = 480;
parameter V_FP = 10;
parameter V_SYNC = 2;
parameter V_BP = 33;
parameter V_TOTAL = 525;

// 像素时钟: 25.175 MHz
```

### 添加新控件类型

1. 定义 Python 类
2. 实现 Python 渲染
3. 编写 Verilog 模板
4. 添加到生成器
5. 测试验证

### 多页面支持

```verilog
input wire [1:0] current_page;

// 每个控件关联页面
wire widget_visible = (widget_page == current_page);
assign widget_active = in_area && widget_visible;
```

---

## 对比其他方案

### 方案 A: CPU + Framebuffer

```
优点:
  - UI 开发容易（LVGL 等框架）
  - 支持复杂效果

缺点:
  - 需要 CPU 核（RV32 等）
  - 需要大量 RAM（2~4 MB）
  - 需要 DMA 控制器
  - 复杂度高
```

### 方案 B: GPU 硬件加速

```
优点:
  - 性能强
  - 可以做复杂效果

缺点:
  - 设计复杂度极高
  - 资源占用大
  - 不适合简单 UI
```

### 方案 C: 本方案

```
优点:
  ✓ 无需 CPU
  ✓ 无需 framebuffer
  ✓ 资源占用低
  ✓ 延迟极低
  ✓ 像素级可控

缺点:
  - UI 布局固定
  - 不适合通用 GUI
  - 需要重新综合才能改布局
```

**适用场景：** 仪器仪表、合成器、示波器等**固定界面应用**

---

## 未来改进

### 1. 动态文本

当前文本是编译时字符串，可改为：

```verilog
input wire [7:0] text_buffer [0:255];
input wire [7:0] text_length;
```

### 2. 透明度

添加 alpha 通道：

```verilog
output wire [7:0] alpha;

// 合成时
final_color = fg * alpha + bg * (255 - alpha);
```

### 3. 抗锯齿

对圆形、斜线进行超采样抗锯齿。

### 4. 触摸输入

```verilog
input wire [10:0] touch_x;
input wire [9:0] touch_y;
input wire touch_valid;

// 每个控件判断是否被点击
wire clicked = touch_valid && in_area;
```

---

## 总结

本架构的核心是：

> **在 PC 端设计，在 FPGA 端执行**

把 UI 布局**编译**成优化的硬件逻辑，而不是在运行时**解释**执行。

这种方式特别适合：
- 固定功能的仪器界面
- 实时性要求高的场景
- 资源受限的 FPGA
- 不需要频繁更改 UI 的应用

**关键优势：**
1. 零软件栈
2. 零 framebuffer
3. 零延迟
4. 高度优化

**对于你的合成器项目，这是最合适的方案。** 🎹

---

**文档版本：** 1.0  
**最后更新：** 2026-09-19
