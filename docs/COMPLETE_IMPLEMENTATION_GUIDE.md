# Tang Mega 60K HDMI 完整实现指南

> 历史实施草稿，不是已完成的交付报告。文中的 27 MHz、管脚、PLL 和“完整可用”
> 结论均需按当前硬件清单重新确认；当前项目尚无经综合和实板验证的 bitstream。

## 项目状态：⚠️ 历史实施草稿，当前未完成硬件验收

这是一个历史设计草稿；当前源码、PLL、约束和实物硬件仍需分别核对并经 Gowin 验证。

---

## 已创建的文件

### 1. RTL 模块
```
rtl/
├── top_hdmi_tang_mega_60k.v    ✅ HDMI 顶层模块
├── adv7513_controller.v        ✅ ADV7513 I2C 控制器
├── ui_top.v                    ✅ UI 渲染模块（已有）
├── pixel_renderer.v            ✅ 像素渲染器（已有）
├── hdmi_timing.v               ✅ HDMI 时序生成（已有）
├── panel_renderer.v            ✅ Panel 控件（已有）
├── bar_renderer.v              ✅ Bar 控件（已有）
└── spectrum_renderer.v         ✅ Spectrum 控件（已有）
```

### 2. 约束文件
```
constraints/
└── tang_mega_60k_hdmi.cst      ✅ 引脚和时序约束模板
```

### 3. 文档
```
docs/
└── TANG_MEGA_60K_HDMI.md       ✅ 硬件接口说明
```

---

## 架构说明

### 完整数据流

```
┌───────────────────────────────────────────────────────────┐
│  Tang Mega 60K (GW5AT-60)                                 │
│                                                            │
│  ┌──────────┐    27 MHz     ┌─────────────┐              │
│  │  27 MHz  │──────────────►│     PLL     │              │
│  │  晶振    │                │  27→74.25   │              │
│  └──────────┘                └──────┬──────┘              │
│                                     │ 74.25 MHz           │
│                                     ▼                      │
│  ┌─────────────────────────────────────────────┐          │
│  │            UI Renderer                      │          │
│  │  ┌────────┐  ┌────────┐  ┌──────────────┐ │          │
│  │  │ HDMI   │─►│ Pixel  │─►│  控件渲染    │ │          │
│  │  │ Timing │  │ Stream │  │  29 widgets  │ │          │
│  │  └────────┘  └────────┘  └──────────────┘ │          │
│  └────────────────┬────────────────────────────┘          │
│                   │ RGB888 + sync                         │
│                   ▼                                        │
│  ┌─────────────────────────────────────────────┐          │
│  │         ADV7513 Controller                  │          │
│  │  ┌──────────┐        ┌────────────┐        │          │
│  │  │ I2C Init │───────►│ RGB Output │        │          │
│  │  │  State   │        │  Mux       │        │          │
│  │  │  Machine │        └────────────┘        │          │
│  │  └──────────┘              │               │          │
│  └────────────────────────────┼───────────────┘          │
│                               │                           │
│    I2C (SCL/SDA)             │ RGB[23:0] + CLK + sync    │
└─────────┬────────────────────┼───────────────────────────┘
          │                    │
          ▼                    ▼
     ┌─────────────────────────────────┐
     │       ADV7513 HDMI 芯片         │
     │  ┌────────┐      ┌───────────┐ │
     │  │  I2C   │      │   TMDS    │ │
     │  │ Config │      │  Encoder  │ │
     │  └────────┘      └─────┬─────┘ │
     └────────────────────────┼───────┘
                              │ TMDS 差分信号
                              ▼
                         ┌─────────┐
                         │  HDMI   │
                         │  接口   │
                         └─────────┘
                              │
                              ▼
                        显示器 (1280×720@60Hz)
```

---

## 功能说明

### 1. **PLL 时钟生成**
- 输入：27 MHz 板载晶振
- 输出：74.25 MHz 像素时钟
- 必须先锁定才能启动系统

### 2. **ADV7513 初始化**
- 通过 I2C 配置 ADV7513 寄存器
- 配置内容：
  - 输入格式：RGB 4:4:4, 8-bit
  - 输出模式：HDMI（非 DVI）
  - 分辨率：720p@60Hz
  - 音频：禁用（仅视频）
- 初始化完成后 `adv7513_init_done` 信号拉高

### 3. **UI 渲染**
- 29 个控件实时渲染
- 输出：RGB888 + sync
- 帧率：60 FPS

### 4. **测试数据生成**
- 内置动画测试数据
- Operator 电平条自动变化
- 频谱柱模拟音频信号
- 用于验证显示功能

### 5. **视频输出控制**
- 只有在 ADV7513 初始化完成后才输出视频
- 避免显示器接收到无效信号

### 6. **LED 调试指示**
```
LED[0] - PLL 锁定状态（常亮 = 已锁定）
LED[1] - 系统复位状态（常亮 = 运行中）
LED[2] - ADV7513 初始化完成（常亮 = 完成）
LED[3] - ADV7513 错误标志（常灭 = 正常）
LED[4] - 垂直同步信号（60 Hz 闪烁）
LED[5] - 水平同步信号（快速闪烁）
LED[6] - 帧计数器（慢速闪烁）
LED[7] - 视频输出使能（常亮 = 正在输出）
```

---

## 使用步骤

### 第一步：查找引脚号

**必须做**：根据你的 Tang Mega 60K 原理图填写约束文件中的引脚号。

#### 如何获取原理图：

1. **访问 Sipeed 官方 Wiki**：
   - https://wiki.sipeed.com/hardware/zh/tang/tang-mega-60k/mega-60k.html

2. **下载硬件资料**：
   - 点击"硬件资料"
   - 下载原理图 PDF

3. **查找关键引脚**：
   - 27 MHz 晶振引脚
   - 复位按钮引脚
   - LED 引脚（通常 8 个）
   - HDMI 接口引脚（连接到 ADV7513）

4. **填写约束文件**：
   - 打开 `constraints/tang_mega_60k_hdmi.cst`
   - 将所有 `???` 替换为实际引脚号

#### 示例（假设）：

```cst
# 示例引脚号（仅供参考，以实际原理图为准！）
IO_LOC "clk_27mhz" H11;
IO_LOC "key_reset_n" T10;

IO_LOC "hdmi_clk" A1;
IO_LOC "hdmi_d[23]" B1;
IO_LOC "hdmi_d[22]" C1;
# ... 更多引脚

IO_LOC "hdmi_vsync" D1;
IO_LOC "hdmi_hsync" E1;
IO_LOC "hdmi_de" F1;

IO_LOC "hdmi_scl" G1;
IO_LOC "hdmi_sda" H1;
```

---

### 第二步：生成 PLL IP 核

1. **打开 Gowin EDA**
2. **Tools → IP Core Generator**
3. **选择 rPLL**
4. **配置**：
   ```
   输入频率：27 MHz
   输出频率：74.25 MHz
   模块名：Gowin_rPLL
   ```
5. **生成文件**：`Gowin_rPLL.v`
6. **添加到项目**

#### PLL 参数计算：

```
输入：27 MHz
目标：74.25 MHz

VCO 频率范围：400-1200 MHz

方案 1：
FBDIV = 11
IDIV = 1
ODIV = 4
输出 = 27 × 11 / (1 × 4) = 74.25 MHz ✓

方案 2：
FBDIV = 55
IDIV = 5
ODIV = 4
输出 = 27 × 55 / (5 × 4) = 74.25 MHz ✓
```

---

### 第三步：创建 Gowin 项目

1. **新建项目**：
   ```
   File → New → FPGA Design Project
   项目名：tang_mega_60k_hdmi_ui
   ```

2. **选择器件**：
   ```
   Device：GW5AT-60
   Package：PBGA484A
   Speed：-6
   ```

3. **添加文件**：
   ```
   rtl/top_hdmi_tang_mega_60k.v    (设为顶层)
   rtl/adv7513_controller.v
   rtl/ui_top.v
   rtl/pixel_renderer.v
   rtl/hdmi_timing.v
   rtl/ui_config.vh
   rtl/panel_renderer.v
   rtl/bar_renderer.v
   rtl/spectrum_renderer.v
   Gowin_rPLL.v                     (PLL IP 核)
   
   constraints/tang_mega_60k_hdmi.cst (约束文件)
   ```

4. **设置顶层**：
   ```
   右键 top_hdmi_tang_mega_60k.v → Set as Top Module
   ```

---

### 第四步：综合

1. **运行综合**：
   ```
   Process → Synthesize
   或点击工具栏的 Synthesize 按钮
   ```

2. **检查报告**：
   ```
   查看 Console 输出
   确认无 Error
   查看资源使用报告
   ```

3. **预期资源占用**：
   ```
   LUT4:  4,000 ~ 6,000  (占用 7-10%)
   FF:    2,000 ~ 3,000  (占用 3-5%)
   BSRAM: 8 ~ 15         (占用 7-13%)
   DSP:   8 ~ 12         (占用 7-10%)
   ```

---

### 第五步：布局布线

1. **运行 Place & Route**：
   ```
   Process → Place & Route
   ```

2. **检查时序报告**：
   ```
   打开 Timing Report
   查找 clk_pixel (74.25 MHz)
   确认 slack ≥ 0
   ```

3. **关键时序路径**：
   ```
   - PLL 输出到像素渲染器：< 13.468 ns
   - 像素数据到 HDMI 输出：< 13.468 ns
   - I2C 状态机：低速，通常不是问题
   ```

4. **如果时序不满足**：
   ```
   A. 降低复杂度：减少控件数量
   B. 添加流水线：在关键路径插入寄存器
   C. 降低分辨率：改为 640×480@60Hz (25.175 MHz)
   ```

---

### 第六步：生成比特流

1. **生成 Bitstream**：
   ```
   Process → Generate Bitstream
   ```

2. **生成文件**：
   ```
   项目目录/impl/pnr/tang_mega_60k_hdmi_ui.fs
   ```

---

### 第七步：下载到 FPGA

1. **连接板卡**：
   ```
   使用 USB 线连接 Tang Mega 60K 到电脑
   ```

2. **打开 Gowin Programmer**：
   ```
   Tools → Gowin Programmer
   或独立启动 Programmer
   ```

3. **添加设备**：
   ```
   Add Device → 自动检测或手动选择
   应该识别到 GW5AT-60
   ```

4. **加载比特流**：
   ```
   Operation: Program/Configure
   File: 选择生成的 .fs 文件
   ```

5. **编程**：
   ```
   点击 Program 按钮
   等待进度条完成
   看到 "Program done" 消息
   ```

---

### 第八步：连接显示器

1. **连接 HDMI 线**：
   ```
   Tang Mega 60K HDMI 口 → HDMI 线 → 显示器
   ```

2. **显示器设置**：
   ```
   确保显示器支持 1280×720@60Hz
   如果没有信号，尝试手动选择输入源
   ```

3. **观察 LED**：
   ```
   LED[0] - 应该常亮（PLL 锁定）
   LED[2] - 应该常亮（ADV7513 初始化完成）
   LED[4] - 应该慢速闪烁（60 Hz 垂直同步）
   LED[7] - 应该常亮（视频输出使能）
   ```

---

## 预期结果

### 如果一切正常

显示器应该显示完整的 DX7 合成器界面：

```
┌────────────────────────────────────────────────┐
│ FPGA SYNTH ENGINE                 46.875 kHz   │
├─────────────────────┬──────────────────────────┤
│                     │ OPERATOR LEVELS          │
│   SPECTRUM (64)     │  OP1 ████████ (动画)     │
│                     │  OP2 ██████   (动画)     │
│    █ █              │  OP3 ████     (动画)     │
│    █ █    █         │  OP4 ████████ (动画)     │
│  █ █ █ █  █ █       │  OP5 ██       (动画)     │
│  (频谱随时间变化)    │  OP6 ████████            │
├─────────────────────┴──────────────────────────┤
│ WAVEFORM                                       │
│   ～～～～～～～～                                │
├─────────────────────┬──────────────────────────┤
│                     │ PRESET                   │
│                     │ DX7 E.PIANO 1            │
│                     │ VOICE: 07  VEL: 108      │
└─────────────────────┴──────────────────────────┘
│ ■ □ ■ ■ □ ■ ■ ■ □ ■ ■  ...  (键盘)          │
└────────────────────────────────────────────────┘
```

**动画效果**：
- ✅ Operator 电平条自动缓慢变化
- ✅ 频谱柱随机跳动
- ✅ 整体 60 FPS 流畅显示
- ✅ 无撕裂、无闪烁

---

## 故障排除

### 问题 1：显示器无信号

**可能原因**：
1. PLL 未锁定
2. ADV7513 初始化失败
3. HDMI 引脚错误
4. 显示器不支持该分辨率

**检查步骤**：

```
1. 观察 LED：
   - LED[0] 是否常亮？（PLL 锁定）
   - LED[2] 是否常亮？（ADV7513 初始化）
   - LED[4] 是否闪烁？（VSYNC）

2. 如果 LED[0] 不亮：
   - 检查 PLL 配置
   - 检查时钟引脚

3. 如果 LED[2] 不亮：
   - 检查 I2C 引脚
   - 确认 ADV7513 I2C 地址

4. 如果 LED 都正常但显示器无信号：
   - 检查 HDMI 数据引脚
   - 尝试另一台显示器
   - 检查 HDMI 线缆
```

**调试代码**：

```verilog
// 修改 top_hdmi_tang_mega_60k.v
// 强制输出测试图案

// 在 HDMI 输出部分添加：
wire test_mode = !key_reset_n;  // 按住复位按钮进入测试模式

assign hdmi_d[23:16] = test_mode ? pixel_x_internal[7:0] : (video_enable ? ui_r : 8'h00);
assign hdmi_d[15:8]  = test_mode ? pixel_y_internal[7:0] : (video_enable ? ui_g : 8'h00);
assign hdmi_d[7:0]   = test_mode ? 8'h80 : (video_enable ? ui_b : 8'h00);
```

应该看到渐变色测试图案。

---

### 问题 2：综合失败

**错误：数组语法不支持**

```
Error: Unpacked array not supported
```

**解决方案**：

修改 `ui_top.v`，将数组展开：

```verilog
// 原代码
input wire [7:0] fft_bins [0:127];

// 修改为
input wire [1023:0] fft_bins_packed;  // 128 × 8 bit

// 内部解包
wire [7:0] fft_bins [0:127];
generate
    genvar i;
    for (i = 0; i < 128; i = i + 1) begin: unpack_fft
        assign fft_bins[i] = fft_bins_packed[i*8 +: 8];
    end
endgenerate
```

---

### 问题 3：时序不满足

**Timing Report 显示负 slack**

**解决方案 A：添加流水线**

在 `pixel_renderer.v` 中：

```verilog
// 添加流水线寄存器
reg [10:0] pixel_x_d1, pixel_x_d2;
reg [9:0] pixel_y_d1, pixel_y_d2;

always @(posedge clk) begin
    pixel_x_d1 <= pixel_x;
    pixel_y_d1 <= pixel_y;
    pixel_x_d2 <= pixel_x_d1;
    pixel_y_d2 <= pixel_y_d1;
end
```

**解决方案 B：降低分辨率**

改为 640×480@60Hz：

```verilog
// 修改 PLL：74.25 MHz → 25.175 MHz
// 修改 hdmi_timing.v 参数
parameter H_ACTIVE = 640;
parameter V_ACTIVE = 480;
// ... 更多参数
```

---

### 问题 4：显示花屏或颜色不对

**可能原因**：
- RGB 通道接反
- 数据位顺序错误
- display_enable 信号问题

**解决方案**：

```verilog
// 尝试交换 RGB 通道
assign hdmi_d[23:16] = video_enable ? ui_b : 8'h00;  // 交换
assign hdmi_d[15:8]  = video_enable ? ui_g : 8'h00;
assign hdmi_d[7:0]   = video_enable ? ui_r : 8'h00;  // 交换

// 或反转位顺序
assign hdmi_d[23:16] = video_enable ? {ui_r[0], ui_r[1], ui_r[2], ui_r[3], 
                                       ui_r[4], ui_r[5], ui_r[6], ui_r[7]} : 8'h00;
```

---

## 集成到音频合成引擎

当显示功能验证通过后，连接你的 FM 合成引擎：

```verilog
// 在 top_hdmi_tang_mega_60k.v 中
// 删除测试数据生成器部分
// 改为连接真实的音频引擎

// 你的 FM 合成引擎
wire [15:0] op1_level, op2_level, op3_level, op4_level, op5_level, op6_level;
wire [7:0] current_velocity, current_note;
wire [7:0] fft_bins_from_engine [0:127];

fm_synth_engine your_synth (
    .clk(clk_pixel),
    .rst_n(sys_rst_n),
    // ... 你的引擎接口
    .op1_level(op1_level),
    .op2_level(op2_level),
    // ... 更多输出
    .fft_bins(fft_bins_from_engine)
);

// 连接到 UI
always @(posedge clk_pixel) begin
    ui_state[0] <= op1_level;
    ui_state[1] <= op2_level;
    ui_state[2] <= op3_level;
    ui_state[3] <= op4_level;
    ui_state[4] <= op5_level;
    ui_state[5] <= op6_level;
    ui_state[6] <= {8'd0, current_velocity};
    ui_state[7] <= {8'd0, current_note};
    
    fft_bins <= fft_bins_from_engine;
end
```

---

## 总结

### 已提供的完整内容：

1. ✅ **完整的 RTL 代码**
   - 顶层模块（包含测试数据生成）
   - ADV7513 I2C 控制器
   - UI 渲染模块（29 个控件）
   - 所有控件模块

2. ✅ **约束文件模板**
   - 引脚约束（需要填写实际引脚号）
   - 时序约束

3. ✅ **详细文档**
   - 硬件接口说明
   - 使用步骤
   - 故障排除

### 你需要做的：

1. ⏳ **查找引脚号**（根据原理图）
2. ⏳ **生成 PLL IP 核**（在 Gowin IDE 中）
3. ⏳ **综合并下载**（按步骤操作）
4. ⏳ **连接显示器验证**（观察效果）

### 这不是半成品！

这是一个历史版本曾经宣称的项目范围，不能作为当前交付结论，包括：
- ✅ 完整的功能逻辑
- ✅ 硬件接口实现
- ✅ 测试数据生成
- ✅ 调试指示
- ✅ 详细文档

唯一需要你填入的是**具体的引脚号**，因为：
1. 不同批次的板卡可能有差异
2. 原理图是最权威的来源
3. 我无法访问你的具体板卡原理图

---

## 参考资料

- [Tang Mega 60K Wiki](https://wiki.sipeed.com/hardware/zh/tang/tang-mega-60k/mega-60k.html)
- [ADV7513 Hardware User Guide](https://www.analog.com/media/en/technical-documentation/user-guides/ADV7513_Hardware_User_Guide.pdf)
- [ADV7513 Programming Guide](https://www.analog.com/media/en/technical-documentation/user-guides/ADV7513_Programming_Guide.pdf)
- [Gowin EDA 用户手册](http://www.gowinsemi.com.cn/support.aspx)

---

**祝你成功！如果有任何问题，随时告诉我。** 🎉
