# FPGA UI Designer - 用户指南

> 使用说明和历史示例。它不证明 RTL 已综合或硬件已验证；硬件参数与当前完成度请以
> 根目录 `PROJECT_STATUS.md`、`HARDWARE_INFO_NEEDED.md` 为准。

## 目录
1. [快速开始](#快速开始)
2. [UI Designer 使用](#ui-designer-使用)
3. [控件参考](#控件参考)
4. [RTL 生成](#rtl-生成)
5. [FPGA 集成](#fpga-集成)
6. [调试和验证](#调试和验证)

---

## 快速开始

### 安装依赖

```bash
# Windows
pip install -r requirements.txt

# 或者使用脚本自动安装
start.bat
```

### 三种使用方式

#### 方式 1: 使用现有示例（推荐新手）

```bash
cd examples
python generate_dx7_rtl.py
```

这会从 `dx7_synth.json` 生成完整的 RTL 代码。

#### 方式 2: 修改 JSON 文件

直接编辑 `examples/dx7_synth.json`，然后重新生成：

```json
{
    "type": "panel",
    "x": 100,
    "y": 100,
    "width": 400,
    "height": 300,
    "bg_color": {"r": 15, "g": 19, "b": 28}
}
```

#### 方式 3: 使用可视化设计器（开发中）

```bash
cd designer
python ui_designer.py
```

---

## UI Scene 结构

### Scene 定义

```json
{
    "name": "My_UI",
    "width": 1280,
    "height": 720,
    "background": {"r": 5, "g": 7, "b": 12},
    "widgets": [...]
}
```

### 坐标系统

```
(0,0) ──────────── X ──────────► (1280,0)
  │
  │
  Y
  │
  │
  ▼
(0,720)                         (1280,720)
```

- **X**: 0 ~ 1279
- **Y**: 0 ~ 719
- **原点**: 左上角

### Layer 层级

```
layer 0 (底层) ──► layer 9 (顶层)
```

高 layer 覆盖低 layer。

---

## 控件参考

### 1. Panel（面板）

矩形背景面板，用于分组。

```json
{
    "type": "panel",
    "name": "my_panel",
    "x": 80,
    "y": 80,
    "width": 560,
    "height": 400,
    "bg_color": {"r": 15, "g": 19, "b": 28},
    "border_color": {"r": 56, "g": 189, "b": 248},
    "border_width": 2,
    "layer": 0
}
```

**参数：**
- `bg_color`: 背景颜色 RGB(0~255)
- `border_color`: 边框颜色
- `border_width`: 边框宽度（像素）

**RTL 实现：**
```verilog
// 判断像素是否在 panel 内
wire in_panel = (pixel_x >= X_START) && 
                (pixel_x < X_END) &&
                (pixel_y >= Y_START) && 
                (pixel_y < Y_END);

// 判断是否是边框
wire in_border = in_panel && 
                 ((pixel_x < X_START + BORDER) ||
                  (pixel_x >= X_END - BORDER) ||
                  (pixel_y < Y_START + BORDER) ||
                  (pixel_y >= Y_END - BORDER));

assign color = in_border ? BORDER_COLOR : BG_COLOR;
```

---

### 2. Text（文本）

显示静态文本标签。

```json
{
    "type": "text",
    "name": "title",
    "x": 100,
    "y": 50,
    "text": "FPGA SYNTH",
    "font_size": 16,
    "color": {"r": 255, "g": 255, "b": 255},
    "layer": 2
}
```

**参数：**
- `text`: 要显示的文本（ASCII）
- `font_size`: 字体大小（当前只支持 16）
- `color`: 文字颜色

**RTL 实现：**
需要 `font_rom.v` 模块：

```verilog
// 计算字符索引
wire [7:0] char_index = (pixel_x - TEXT_X) / 8;
wire [7:0] char_code = text_string[char_index];

// 字符内坐标
wire [2:0] char_x = (pixel_x - TEXT_X) % 8;
wire [3:0] char_y = (pixel_y - TEXT_Y);

// 查询字体 ROM
font_rom font (
    .clk(clk),
    .char_code(char_code),
    .row(char_y),
    .pixels(row_pixels)
);

// 判断当前像素
wire pixel_on = row_pixels[7 - char_x];
```

**字符集：**
- 大写字母: A-Z
- 小写字母: a-z
- 数字: 0-9
- 符号: `.,:-+#%/\|` 等

---

### 3. Bar（进度条）

显示数值的横向或纵向进度条。

```json
{
    "type": "bar",
    "name": "op1_level",
    "x": 700,
    "y": 150,
    "width": 240,
    "height": 18,
    "orientation": "horizontal",
    "fill_color": {"r": 56, "g": 189, "b": 248},
    "bg_color": {"r": 22, "g": 29, "b": 43},
    "source": "ui_state[0]",
    "layer": 1
}
```

**参数：**
- `orientation`: "horizontal" 或 "vertical"
- `fill_color`: 填充颜色
- `bg_color`: 背景颜色
- `source`: 数据源（Verilog 表达式）

**数据映射：**
```
ui_state[n] = 0 ~ 65535 (16-bit)
bar_width = (value * MAX_WIDTH) >> 16
```

**RTL 实现：**
```verilog
// 水平进度条
wire [10:0] fill_width = (ui_state[0] * WIDTH) >> 16;
wire in_fill = (pixel_x - X_START) < fill_width;

assign color = in_bar ? (in_fill ? FILL_COLOR : BG_COLOR) 
                      : 24'h000000;
```

---

### 4. Spectrum（频谱）

显示频谱分析器，多根竖条。

```json
{
    "type": "spectrum",
    "name": "fft_display",
    "x": 80,
    "y": 120,
    "width": 600,
    "height": 240,
    "num_bars": 64,
    "bar_color": {"r": 56, "g": 189, "b": 248},
    "bg_color": {"r": 10, "g": 13, "b": 18},
    "source": "fft_bins",
    "layer": 1
}
```

**参数：**
- `num_bars`: 显示多少根柱子（通常 32/64/128）
- `bar_color`: 柱子颜色
- `source`: 数据源数组

**数据格式：**
```verilog
input wire [7:0] fft_bins [0:127];
```

每个 bin: 0 (无信号) ~ 255 (最强)

**RTL 实现：**
```verilog
// 计算当前 x 对应第几根柱子
wire [6:0] bar_index = (pixel_x - X_START) * NUM_BARS / WIDTH;

// 该柱子的高度
wire [7:0] bar_value = fft_bins[bar_index];
wire [9:0] bar_height = (bar_value * HEIGHT) >> 8;

// 判断当前像素是否被点亮
wire in_bar = (HEIGHT - (pixel_y - Y_START)) < bar_height;
```

**平滑动画：**

在你的音频引擎中可以添加：

```verilog
// Attack/Decay 平滑
always @(posedge clk) begin
    if (new_fft[i] > display[i])
        display[i] <= display[i] + ATTACK_SPEED;
    else
        display[i] <= display[i] - DECAY_SPEED;
end
```

---

### 5. Waveform（波形）

显示 PCM 音频波形。

```json
{
    "type": "waveform",
    "name": "audio_wave",
    "x": 80,
    "y": 380,
    "width": 600,
    "height": 120,
    "line_color": {"r": 110, "g": 231, "b": 183},
    "bg_color": {"r": 10, "g": 13, "b": 18},
    "source": "pcm_buffer",
    "layer": 1
}
```

**数据格式：**
```verilog
// UI 输入是最近 128 个有符号 8 位显示采样点
reg signed [7:0] pcm_buffer [0:127];
```

**RTL 实现：**
```verilog
// 根据 x 坐标查询 128 点缓冲区中的采样值
wire [6:0] sample_index = (pixel_x - X_START) * 128 / WIDTH;
wire signed [7:0] sample = pcm_buffer[sample_index];

// 转换为 y 坐标
wire [9:0] wave_y = CENTER_Y - (sample >>> 1);

// 判断当前像素
wire on_wave = (pixel_y >= wave_y - 1) && 
               (pixel_y <= wave_y + 1);
```

---

### 6. Keyboard（钢琴键盘）

显示钢琴键盘，可以显示按键状态。

```json
{
    "type": "keyboard",
    "name": "piano_keys",
    "x": 40,
    "y": 640,
    "width": 1200,
    "height": 60,
    "start_key": 48,
    "num_keys": 25,
    "white_color": {"r": 220, "g": 220, "b": 220},
    "black_color": {"r": 30, "g": 30, "b": 30},
    "pressed_color": {"r": 56, "g": 189, "b": 248},
    "source": "key_states",
    "layer": 2
}
```

**参数：**
- `start_key`: 起始 MIDI note (C4 = 60)
- `num_keys`: 显示多少个键
- `pressed_color`: 按下时的颜色

**数据格式：**
```verilog
// 每个 bit 代表一个键是否按下
input wire [127:0] key_states;
```

**RTL 实现：**
```verilog
// 判断当前像素对应哪个键
wire [4:0] key_index = (pixel_x - X_START) * NUM_KEYS / WIDTH;
wire is_black_key = /* 判断是否是黑键 */;

// 查询按键状态
wire key_pressed = key_states[start_key + key_index];

// 选择颜色
wire [23:0] key_color = key_pressed ? PRESSED_COLOR :
                        is_black_key ? BLACK_COLOR : WHITE_COLOR;
```

---

## RTL 生成

### 从 Python 生成

```python
from ui_schema import *
from rtl_generator import RTLGenerator

# 创建 scene
scene = UIScene(
    name="My_UI",
    width=1280,
    height=720,
    background=Color(5, 7, 12)
)

# 添加控件
scene.add_widget(PanelWidget(
    x=100, y=100,
    width=400, height=300,
    bg_color=Color(15, 19, 28)
))

# 生成 RTL
generator = RTLGenerator()
generator.generate(scene, output_dir=Path("rtl"))
```

### 生成的文件

1. **ui_top.v** - 顶层模块
2. **pixel_renderer.v** - 像素渲染器
3. **hdmi_timing.v** - HDMI 时序
4. **ui_config.vh** - 配置参数
5. **<widget>_renderer.v** - 各个控件模块

---

## FPGA 集成

### 顶层接口

```verilog
module ui_top (
    input wire clk,            // 74.25 MHz pixel clock
    input wire rst_n,
    input wire [10:0] pixel_x,
    input wire [9:0] pixel_y,
    input wire [1023:0] fft_bins_flat,    // 128 bins * 8 bits
    input wire [511:0] ui_state_flat,     // 32 registers * 16 bits
    input wire [1023:0] pcm_buffer_flat,  // 128 signed 8-bit samples
    input wire [87:0] key_states,
    output wire [7:0] rgb_r,
    output wire [7:0] rgb_g,
    output wire [7:0] rgb_b
);
```

### 集成到你的项目

```verilog
// 你的顶层模块
module fpga_synth_top (
    input wire clk_27mhz,
    input wire rst_n,
    // ... MIDI, 音频等接口
    
    // HDMI
    output wire [7:0] hdmi_r,
    output wire [7:0] hdmi_g,
    output wire [7:0] hdmi_b,
    output wire hdmi_hsync,
    output wire hdmi_vsync,
    output wire hdmi_de
);

    // PLL: 27 MHz → 74.25 MHz
    wire clk_pixel;
    pll_hdmi pll (
        .clkin(clk_27mhz),
        .clkout(clk_pixel)  // 74.25 MHz
    );
    
    // 你的音频合成引擎
    // 由合成引擎内部的降采样/定标逻辑驱动，供 UI 显示使用
    wire signed [7:0] pcm_samples [0:127];
    wire [7:0] fft_bins [0:127];
    wire [1023:0] fft_bins_flat;
    wire [1023:0] pcm_buffer_flat;

    genvar fft_i;
    generate
        for (fft_i = 0; fft_i < 128; fft_i = fft_i + 1) begin : gen_fft_flat
            assign fft_bins_flat[fft_i*8 +: 8] = fft_bins[fft_i];
        end
    endgenerate

    // 音频引擎可在内部保持更高精度；UI 接收整理后的 128 点显示数据。
    genvar pcm_i;
    generate
        for (pcm_i = 0; pcm_i < 128; pcm_i = pcm_i + 1) begin : gen_pcm_flat
            assign pcm_buffer_flat[pcm_i*8 +: 8] = pcm_samples[pcm_i];
        end
    endgenerate
    
    synth_engine synth (
        .clk(clk_27mhz),
        .rst_n(rst_n),
        // ... 其他接口
        .fft_bins(fft_bins)
    );
    
    // UI 状态映射
    wire [15:0] ui_state [0:31];
    wire [511:0] ui_state_flat;
    wire [87:0] key_states;
    wire [10:0] pixel_x;
    wire [9:0] pixel_y;
    genvar state_i;
    generate
        for (state_i = 0; state_i < 32; state_i = state_i + 1) begin : gen_state_flat
            assign ui_state_flat[state_i*16 +: 16] = ui_state[state_i];
        end
    endgenerate

    assign ui_state[0] = op1_level;
    assign ui_state[1] = op2_level;
    assign ui_state[2] = op3_level;
    assign ui_state[3] = op4_level;
    assign ui_state[4] = op5_level;
    assign ui_state[5] = op6_level;
    assign ui_state[6] = current_velocity;
    assign ui_state[7] = current_preset;
    // ... 其他状态
    
    // UI 模块
    ui_top ui (
        .clk(clk_pixel),
        .rst_n(rst_n),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .fft_bins_flat(fft_bins_flat),
        .ui_state_flat(ui_state_flat),
        .pcm_buffer_flat(pcm_buffer_flat),
        .key_states(key_states),
        .rgb_r(hdmi_r),
        .rgb_g(hdmi_g),
        .rgb_b(hdmi_b)
    );

endmodule
```

### 时钟约束

```tcl
# SDC 约束文件
create_clock -name clk_pixel -period 13.468 [get_ports clk_pixel]
```

74.25 MHz = 13.468 ns

### 引脚约束

参考 Tang Mega 60K 原理图，找到 HDMI 接口引脚：

```
# .cst 文件示例
IO_LOC "clk_pixel" <PIN>;
IO_LOC "rst_n" <PIN>;

IO_LOC "hdmi_r[0]" <PIN>;
IO_LOC "hdmi_r[1]" <PIN>;
# ... hdmi_r[7]

IO_LOC "hdmi_g[0]" <PIN>;
# ... hdmi_g[7]

IO_LOC "hdmi_b[0]" <PIN>;
# ... hdmi_b[7]

IO_LOC "hdmi_hsync" <PIN>;
IO_LOC "hdmi_vsync" <PIN>;
IO_LOC "hdmi_de" <PIN>;
```

---

## 调试和验证

### Python 参考渲染

```bash
cd testbench
python test_renderer.py
```

生成 `reference_frame.png` 作为参考。

### Verilog 仿真

创建 testbench:

```verilog
module tb_ui_top;
    reg clk_pixel;
    reg rst_n;
    reg [7:0] fft_bins [0:127];
    reg [15:0] ui_state [0:31];
    
    wire [7:0] hdmi_r, hdmi_g, hdmi_b;
    wire hdmi_de, hdmi_hsync, hdmi_vsync;
    
    ui_top dut (.*);
    
    // 生成时钟
    initial clk_pixel = 0;
    always #6.734 clk_pixel = ~clk_pixel;  // 74.25 MHz
    
    // 激励
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
        
        // 设置测试数据
        fft_bins[0] = 128;
        fft_bins[1] = 200;
        // ...
        
        ui_state[0] = 16'hC000;  // OP1 75%
        ui_state[1] = 16'h8000;  // OP2 50%
        // ...
        
        // 运行一帧
        #16700000;  // ~16.7 ms
        
        $finish;
    end
    
    // 捕获 RGB 输出
    integer file;
    initial begin
        file = $fopen("sim_frame.txt", "w");
    end
    
    always @(posedge clk_pixel) begin
        if (hdmi_de) begin
            $fwrite(file, "%02X%02X%02X\n", hdmi_r, hdmi_g, hdmi_b);
        end
    end
endmodule
```

### 像素比对脚本

```python
# compare_frames.py
from PIL import Image
import numpy as np

# 读取参考图
ref = np.array(Image.open("reference_frame.png"))

# 读取仿真输出
sim_pixels = []
with open("sim_frame.txt") as f:
    for line in f:
        rgb = int(line.strip(), 16)
        r = (rgb >> 16) & 0xFF
        g = (rgb >> 8) & 0xFF
        b = rgb & 0xFF
        sim_pixels.append([r, g, b])

sim = np.array(sim_pixels).reshape(720, 1280, 3)

# 逐像素比较
diff = np.abs(ref.astype(int) - sim.astype(int))
max_diff = diff.max()
num_errors = (diff > 0).sum()

print(f"Max difference: {max_diff}")
print(f"Error pixels: {num_errors}")

if num_errors == 0:
    print("✓ Perfect match!")
else:
    # 保存差异图
    diff_img = Image.fromarray(diff.astype(np.uint8))
    diff_img.save("diff.png")
    print("Saved difference to diff.png")
```

---

## 性能优化

### 减少资源占用

1. **减少控件数量**
   - 合并相似的 panel
   - 使用一个大 text 代替多个小 text

2. **简化控件**
   - 去掉不需要的 border
   - 使用更简单的形状

3. **降低分辨率**
   - 1280×720 → 640×480
   - 修改 `hdmi_timing.v`

### 提高频率

1. **添加流水线**
   - 在复杂判断之间插入寄存器
   - 目标: 4~6 级流水线

2. **优化组合逻辑**
   - 避免过深的 if-else 嵌套
   - 使用 case 代替多层 if

3. **时序约束**
   - 正确设置时钟约束
   - 检查 timing report

---

## 常见问题

### Q1: 生成的 RTL 综合失败

**可能原因：**
- 数组语法不兼容
- 模块实例化错误
- 参数超出范围

**解决方案：**
检查 Gowin 综合报告，修改生成器模板。

### Q2: 显示不正常

**检查：**
1. 时钟频率是否正确（74.25 MHz）
2. HDMI 引脚是否正确
3. 数据是否有效
4. 复位是否正常

### Q3: 颜色不对

**检查：**
1. RGB 位宽是否正确（8-bit each）
2. 颜色值是否在正确范围
3. display_active 信号是否正确

### Q4: 文字显示乱码

**检查：**
1. 字体 ROM 是否正确加载
2. 字符编码是否在支持范围
3. 坐标计算是否正确

---

## 进阶功能

### 动态可见性

```verilog
// 根据条件显示/隐藏控件
wire widget_visible = ui_state[10][0];  // bit 0 控制可见性

assign widget_active = in_area && widget_visible;
```

### 颜色动画

```verilog
// 随时间变化的颜色
wire [7:0] hue = frame_counter[15:8];
wire [23:0] dynamic_color = hsv_to_rgb(hue, 255, 255);
```

### 多页面切换

```verilog
// 根据页面索引显示不同控件
wire [1:0] current_page = ui_state[15][1:0];

wire page0_active = (current_page == 0);
wire page1_active = (current_page == 1);

// 每个控件检查页面
assign widget0_visible = page0_active;
assign widget1_visible = page1_active;
```

---

## 扩展新控件

### 步骤

1. **定义 Python 数据结构**

```python
@dataclass
class KnobWidget(Widget):
    type: str = "knob"
    radius: int = 30
    value: int = 0  # 0~255
    color: Color = field(default_factory=lambda: Color(56, 189, 248))
```

2. **实现 Python 渲染**

```python
def render_knob(self, img, widget):
    # 绘制圆环
    # 绘制指针
    pass
```

3. **生成 Verilog 模板**

```python
def generate_knob_renderer(self, output_path):
    code = [
        "module knob_renderer (",
        "    input wire [10:0] pixel_x,",
        "    input wire [9:0] pixel_y,",
        "    input wire [7:0] value,",
        "    output wire active,",
        "    output wire [23:0] color",
        ");",
        # ... 实现逻辑
        "endmodule"
    ]
```

4. **测试**

运行参考渲染和 RTL 仿真，比对结果。

---

## 资源

- [Tang Mega 60K Wiki](https://wiki.sipeed.com/hardware/zh/tang/tang-mega-60k/mega-60k.html)
- [Gowin 半导体官网](http://www.gowinsemi.com.cn/)
- [HDMI 1.4 Specification](https://www.hdmi.org/)
- [PySide6 Documentation](https://doc.qt.io/qtforpython/)

---

**祝你设计出漂亮的 FPGA UI！** 🎨
