# 复杂控件使用指南

本指南介绍如何使用新增的复杂控件：Waveform（波形）和 Keyboard（键盘）。

## 新增功能总结

### ✅ Python UI 设计器改进
- 完整的文件打开/保存功能
- 实时属性编辑和画布更新
- 预览功能（使用 Python 渲染器）
- RTL 生成集成
- 删除控件功能
- 修改状态追踪

### ✅ 复杂控件支持

#### 1. Waveform（波形显示）
- **用途**: 显示 PCM 音频波形
- **Python 渲染**: ✅ 完整实现
- **RTL 模块**: ✅ `rtl/waveform_renderer.v`
- **特性**: 
  - 支持任意采样数（默认 1024）
  - 可配置线条颜色和宽度
  - 实时波形绘制

#### 2. Keyboard（钢琴键盘）
- **用途**: 显示虚拟钢琴键盘
- **Python 渲染**: ✅ 完整实现
- **RTL 模块**: ✅ `rtl/keyboard_renderer.v`
- **特性**:
  - 支持任意起始音符和键数
  - 白键和黑键正确布局
  - 按键状态可视化
  - 按下高亮显示

#### 3. Knob（旋钮）
- **用途**: 显示旋转控制旋钮
- **Python 渲染**: ✅ 完整实现
- **RTL 模块**: ✅ `rtl/knob_renderer.v`
- **特性**:
  - 圆形旋钮显示
  - 值指示器
  - 可配置范围

## 使用 Python UI 设计器

### 启动设计器

```bash
cd designer
python ui_designer.py
```

### 基本操作

1. **添加控件**
   - 从左侧控件列表双击控件类型
   - 或选择控件类型后点击"Add Widget"
   - 新控件出现在画布上

2. **选择和编辑控件**
   - 点击画布上的控件选择
   - 右侧属性面板显示控件属性
   - 修改属性自动更新画布

3. **删除控件**
   - 选择控件后点击"Delete Selected"

4. **保存和打开**
   - File → Save / Save As 保存为 JSON
   - File → Open 打开已有 JSON 文件

5. **预览**
   - Preview 按钮生成实时渲染预览
   - 显示带有动画测试数据的完整界面

6. **生成 RTL**
   - Generate RTL 按钮导出 Verilog 代码
   - 自动生成所有需要的模块

## JSON 配置示例

### Waveform 控件

```json
{
  "type": "waveform",
  "name": "main_waveform",
  "x": 50,
  "y": 450,
  "width": 710,
  "height": 130,
  "samples": 1024,
  "source": "pcm_buffer",
  "line_color": {"r": 110, "g": 231, "b": 183},
  "bg_color": {"r": 10, "g": 13, "b": 18},
  "line_width": 2,
  "visible": true,
  "layer": 2
}
```

### Keyboard 控件

```json
{
  "type": "keyboard",
  "name": "main_keyboard",
  "x": 50,
  "y": 630,
  "width": 1180,
  "height": 50,
  "start_note": 48,
  "keys": 25,
  "source": "key_states",
  "white_key_color": {"r": 240, "g": 240, "b": 245},
  "black_key_color": {"r": 20, "g": 25, "b": 35},
  "pressed_color": {"r": 56, "g": 189, "b": 248},
  "visible": true,
  "layer": 2
}
```

### Knob 控件

```json
{
  "type": "knob",
  "name": "volume_knob",
  "x": 800,
  "y": 100,
  "width": 80,
  "height": 80,
  "source": "ui_state[0]",
  "min_value": 0,
  "max_value": 127,
  "fg_color": {"r": 56, "g": 189, "b": 248},
  "bg_color": {"r": 30, "g": 40, "b": 60},
  "visible": true,
  "layer": 2
}
```

## RTL 集成

### 数据接口

#### Waveform 数据
```verilog
// 在顶层模块
input wire [16383:0] pcm_buffer_flat;  // 1024 samples * 16 bits

// PCM 数据是有符号 16 位采样
// -32768 到 +32767
```

#### Keyboard 数据
```verilog
// 25 键键盘示例
input wire [24:0] key_states;  // 每位表示一个键的状态

// key_states[0] = MIDI note 48 (C3)
// key_states[1] = MIDI note 49 (C#3)
// ...
```

#### Knob 数据
```verilog
// 从 ui_state 数组读取
input wire [15:0] knob_value;  // 0-127 或自定义范围
```

### 在顶层模块中连接

```verilog
// 声明 PCM 缓冲区
reg signed [15:0] pcm_buffer [0:1023];
wire [16383:0] pcm_buffer_flat;

// 展平数组
genvar i;
generate
    for (i = 0; i < 1024; i = i + 1) begin : gen_pcm_flat
        assign pcm_buffer_flat[i*16 +: 16] = pcm_buffer[i];
    end
endgenerate

// 声明键盘状态
reg [24:0] key_states;

// 连接到 pixel_renderer
pixel_renderer renderer (
    .clk(clk_pixel),
    .rst_n(rst_n),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y),
    .fft_bins_flat(fft_bins_flat),
    .ui_state_flat(ui_state_flat),
    .pcm_buffer_flat(pcm_buffer_flat),  // 波形数据
    .key_states(key_states),             // 键盘状态
    .rgb_r(pixel_r),
    .rgb_g(pixel_g),
    .rgb_b(pixel_b)
);
```

## Python 渲染器测试

### 测试所有控件

```python
from designer.pixel_renderer import PixelRenderer
from designer.ui_schema import *
import numpy as np

# 创建测试场景
scene = UIScene(
    name="test_all_widgets",
    width=1280,
    height=720,
    bg_color=ColorRGB(5, 7, 12)
)

# 添加波形
scene.widgets.append(WaveformWidget(
    type="waveform",
    name="waveform1",
    x=50, y=100, width=600, height=200,
    samples=1024,
    source="pcm_buffer",
    line_color=ColorRGB(110, 231, 183),
    bg_color=ColorRGB(10, 13, 18)
))

# 添加键盘
scene.widgets.append(KeyboardWidget(
    type="keyboard",
    name="kbd1",
    x=50, y=350, width=700, height=100,
    start_note=48,
    keys=25,
    white_key_color=ColorRGB(240, 240, 245),
    black_key_color=ColorRGB(20, 25, 35),
    pressed_color=ColorRGB(56, 189, 248)
))

# 添加旋钮
scene.widgets.append(KnobWidget(
    type="knob",
    name="knob1",
    x=800, y=100, width=80, height=80,
    source="ui_state[0]",
    min_value=0,
    max_value=127,
    fg_color=ColorRGB(56, 189, 248),
    bg_color=ColorRGB(30, 40, 60)
))

# 生成测试数据
pcm_buffer = [int(16000 * np.sin(2 * np.pi * i / 100)) for i in range(1024)]
key_states = [True, False, True, False, False] + [False] * 20

ui_state = {
    "pcm_buffer": pcm_buffer,
    "key_states": key_states,
    "ui_state": [64000] + [32768] * 31,  # 旋钮在中间位置
}

# 渲染
renderer = PixelRenderer()
frame = renderer.render_scene(scene, ui_state)

# 保存
renderer.save_frame("test_complex_widgets.png")
print("Rendered frame saved!")
```

## 性能考虑

### Python 渲染器
- 适合设计阶段的快速预览
- 渲染 1280x720 帧约需 0.1-0.5 秒
- 支持实时动画预览

### FPGA RTL
- 实时渲染，每像素一个时钟周期
- 键盘渲染器使用组合逻辑（可能需要优化）
- 波形渲染器使用简化算法
- 旋钮渲染器当前不绘制指示线（需要三角函数查找表）

## 已知限制

### Keyboard 渲染器
- RTL 版本使用较多组合逻辑
- 对于超过 37 键可能需要时序优化
- 建议使用流水线优化

### Waveform 渲染器
- 当前使用简单的点对点连线
- 高分辨率波形可能有锯齿
- 可以添加抗锯齿算法改进

### Knob 渲染器
- RTL 版本当前不绘制指示线
- 需要添加 CORDIC 或查找表实现角度计算
- Python 版本有完整实现

## 故障排除

### Python 设计器无法启动
```bash
# 安装依赖
pip install PySide6 numpy Pillow

# 检查旧版 Qt 绑定是否冲突（当前 GUI 使用 PySide6）
pip uninstall PyQt5
```

### 预览失败
- 确保安装了 Pillow: `pip install Pillow`
- 检查控件坐标是否在屏幕范围内

### RTL 生成失败
- 检查 JSON 文件格式
- 确保所有必需字段都存在
- 查看错误消息中的具体问题

## 下一步

### 推荐改进
1. 添加文本渲染支持（需要字体 ROM）
2. 优化键盘渲染器时序
3. 为旋钮添加指示线渲染
4. 添加更多控件类型（滑块、开关等）
5. 实现控件拖拽功能

### 集成音频引擎
1. 连接实际 PCM 输出到 waveform
2. 连接 MIDI 输入到 keyboard
3. 连接参数控制到 knob
4. 实现完整的音频可视化

## 示例项目

完整的 DX7 合成器 UI 示例在 `examples/dx7_synth.json`，包含：
- 频谱分析器
- 6 个操作符电平条
- 波形显示
- 虚拟键盘
- 多个面板和文本标签

可以在 UI 设计器中打开并编辑！

---

**祝使用愉快！** 如有问题，请参考主 README.md 或查看源代码注释。
