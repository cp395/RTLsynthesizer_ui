# FPGA UI Designer

用于 FPGA 的 UI 设计器和 RTL 原型生成器，当前工程目标为 Tang Mega 60K 的
`GW5AT-60` 器件变体。实际板卡型号、封装和管脚仍需以原理图确认。

## 项目状态

✅ **当前可用/可检查功能**:
- Python Schema 和参考渲染器（可在依赖齐全时运行）
- 有限的 JSON → RTL 原型生成器
- 手写 RTL 的固定演示布局和若干控件渲染器
- 示例 DX7 合成器 UI 配置（用于预览/原型）

⚠️ **需要用户确认/硬件验证**:
- 板卡 PCB revision、FPGA 完整料号和 HDMI 输出架构
- 晶振频率/输入管脚、HDMI/RGB/I2C/控制信号的真实管脚
- IO bank 电压、芯片型号和 I2C 地址
- PLL 参数、综合、布局布线、时序和实板显示

🚧 **已知限制**:
- Text 仍是占位/未集成完整字体渲染
- RTL 生成器不覆盖所有控件，也不生成完整可烧录工程
- 手写 RTL 布局不自动对应示例 JSON 的全部控件
- 尚无经过 Gowin 综合、布局布线和实板验证的 bitstream

## 快速开始

### 1. 硬件要求

- 与工程器件和约束匹配的 Tang Mega 60K 板卡（完整料号需确认）
- 带 HDMI 输出的开发板或外部 HDMI 模块
- HDMI 显示器（支持 720p60）

### 2. 软件要求

- Gowin EDA (免费版) - 用于 FPGA 综合和布局布线
- Python 3.8+ (可选，仅用于 UI 设计器)
- PySide6（可选，用于 GUI 设计器）

### 3. 构建流程

#### 方法 A: 使用 Gowin IDE（推荐新手）

1. 打开 Gowin IDE
2. 打开项目文件：`tang_mega_60k_ui.gprj`
3. **重要**: 验证约束文件中的引脚分配
   - 打开 `constraints/tang_mega_60k_hdmi.cst`
   - 根据你的板卡原理图检查 HDMI 引脚
   - 如果引脚不正确，参考板卡文档修改
4. 运行综合：Process → Synthesize
5. 运行布局布线：Process → Place & Route
6. 生成比特流：Process → Generate Bitstream
7. 烧录到 FPGA：Tools → Programmer

#### 方法 B: 使用命令行（自动化构建）

```bash
# 在项目根目录
gw_sh build.tcl
```

命令行构建是否成功取决于 Gowin EDA、许可证、器件支持和真实约束；当前仓库没有已验证的 bitstream。

### 4. 验证构建（仅在 Gowin 工具可用且硬件参数确认后）

只有在综合、布局布线和时序均成功后，才应看到：
- `impl/pnr/fpga_ui_60k.fs` - 烧录文件
- 无布局布线错误
- 时序收敛（所有约束满足）

烧录后，板载 LED 应显示：
- LED[0]: PLL 锁定（应常亮）
- LED[1]: 系统复位状态（应常亮）
- LED[2]: HDMI 初始化完成（约 1 秒后亮起）
- LED[3]: I2C 错误（应灭，如果亮则表示 I2C 通信失败）
- LED[4]: 垂直同步（60Hz 闪烁）
- LED[5]: 水平同步（快速闪烁）
- LED[6]: 帧计数器（慢闪）
- LED[7]: 视频输出使能（应常亮）

HDMI 显示器应显示：
- 深蓝色背景
- 多个灰色面板
- 一个 64 柱频谱分析器（动画）
- 六个彩色电平条（OP1-OP6，动画）

## 引脚配置指南

### 查找正确的引脚分配

1. 访问 Sipeed Tang Mega 60K 文档：
   https://wiki.sipeed.com/hardware/en/tang/tang-mega-60k/

2. 下载原理图 PDF

3. 查找以下信号：
   - 晶振时钟（通常是 50 MHz 或 27 MHz）
   - HDMI 发射芯片（ADV7513、IT66121、ANX9134 等）
   - HDMI 数据信号（24 位 RGB + CLK + DE + HSYNC + VSYNC）
   - I2C 信号（SCL、SDA）

4. 更新 `constraints/tang_mega_60k_hdmi.cst` 中的引脚分配

### 示例：如何修改引脚

如果原理图显示 HDMI 时钟在引脚 R16：

```tcl
# 修改前
IO_LOC "hdmi_clk" AA4;

# 修改后
IO_LOC "hdmi_clk" R16;
```

### 时钟频率调整

如果你的板卡使用的晶振不是工程当前假设的 50 MHz：

1. 更新 `constraints/tang_mega_60k_hdmi.cst` 中的时钟约束：
   ```tcl
   # 示例：50 MHz 输入时钟；名称和周期必须与实际端口/晶振一致
   create_clock -name clk_50mhz -period 20.0 -waveform {0 10.0} [get_ports {clk_50mhz}]
   ```

2. 更新 `rtl/Gowin_rPLL.v` 中的 PLL 配置以匹配 50 MHz 输入

## 自定义 UI

### 从示例开始

项目包含一个示例 DX7 合成器 UI：

```bash
# 查看示例 JSON
cat examples/dx7_synth.json

# 生成 RTL 原型（可选；不覆盖手写 rtl/，也不生成完整工程）
python examples/generate_dx7_rtl.py
```

### 创建自定义 UI

1. 创建 JSON 配置文件（参考 `examples/dx7_synth.json`）

2. 定义控件：
   ```json
   {
     "name": "my_ui",
     "width": 1280,
     "height": 720,
     "bg_color": {"r": 10, "g": 13, "b": 18},
     "widgets": [
       {
         "type": "panel",
         "name": "main_panel",
         "x": 0, "y": 0,
         "width": 1280, "height": 720,
         "bg_color": {"r": 15, "g": 19, "b": 28}
       },
       {
         "type": "bar",
         "name": "level_bar",
         "x": 100, "y": 100,
         "width": 300, "height": 20,
         "source": "ui_state[0]",
         "fg_color": {"r": 56, "g": 189, "b": 248},
         "bg_color": {"r": 30, "g": 40, "b": 60}
       }
     ]
   }
   ```

3. 生成 RTL：
   ```python
   from generator.rtl_generator import RTLGenerator
   from designer.ui_schema import UIScene
   
   # 加载配置
   scene = UIScene.from_json("your_ui.json")
   
   # 生成 RTL
   generator = RTLGenerator()
   generator.generate(scene, Path("rtl"))
   ```

4. 重新构建 FPGA 项目

### 支持的控件类型

| 控件 | 状态 | 描述 |
|------|------|------|
| `panel` | ✅ 完全支持 | 矩形面板，可作为背景或容器 |
| `bar` | ✅ 完全支持 | 水平进度条，从 `ui_state[]` 读取值 |
| `spectrum` | ✅ 完全支持 | 频谱分析器，从 `fft_bins[]` 读取值 |
| `text` | ⚠️ 部分支持 | 需要字体 ROM（未包含） |
| `waveform` | ⚠️ 参考渲染器/RTL 模块存在，仍需集成验证 | 波形显示 |
| `keyboard` | ⚠️ 参考渲染器/RTL 模块存在，仍需集成验证 | 虚拟键盘 |
| `knob` | ⚠️ 参考渲染器/RTL 模块存在，仍需集成验证 | 旋钮控件 |

## 数据接口

### UI 状态输入

顶层模块接受两个扁平化数组：

```verilog
input wire [1023:0] fft_bins_flat;  // 128 个 8 位 FFT 频谱值
input wire [511:0] ui_state_flat;   // 32 个 16 位通用状态寄存器
```

### 数据映射

- `fft_bins[0..127]`: 频谱分析器数据（0-255）
- `ui_state[0..31]`: 通用 UI 状态（0-65535）

示例映射：
- `ui_state[0]` → OP1 电平
- `ui_state[1]` → OP2 电平
- `ui_state[2]` → OP3 电平
- ...
- `fft_bins[0..63]` → 频谱分析器显示

### 连接到音频引擎

你需要提供实际的音频处理逻辑。当前的 `top_hdmi_tang_mega_60k.v` 包含测试数据生成器，产生动画效果。

要连接真实音频：

1. 实例化你的音频引擎模块
2. 连接 FFT 输出到 `fft_bins_flat`
3. 连接控制参数到 `ui_state_flat`

## 故障排除

### 综合失败

**错误**: "Syntax error in file..."
- 确认 Gowin 工程按 `SystemVerilog 2017` 配置，并查看综合日志中的具体错误

**错误**: "Module 'xxx' not found"
- 确保所有依赖文件都在 `tang_mega_60k_ui.gprj` 中列出
- 检查 `rtl/` 目录中是否包含所有模块

### 布局布线失败

**错误**: "Port count exceeds resource limit"
- 这通常意味着顶层模块设置错误
- 在 Gowin IDE 中，确保顶层模块是 `top_hdmi_tang_mega_60k`

**错误**: "Invalid location constraint for port..."
- 检查约束文件中的引脚名称是否正确
- 验证引脚是否存在于你的 FPGA 封装中（PG484A）

### HDMI 无输出

**检查项**:
1. LED[0]（PLL 锁定）是否亮起？
   - 否 → 检查时钟输入引脚
2. LED[2]（HDMI 初始化）是否亮起？
   - 否 → 检查 I2C 引脚和 HDMI 芯片地址
3. LED[3]（I2C 错误）是否亮起？
   - 是 → I2C 通信失败，检查引脚和上拉电阻
4. 显示器是否支持 720p60？
   - 尝试其他显示器或电视

### I2C 初始化失败

**可能原因**:
1. I2C 地址不正确
   - ADV7513: 通常是 0x72 (7-bit: 0x39)
   - 检查你的 HDMI 芯片数据手册
   - 修改 `rtl/adv7513_controller.v` 中的 `I2C_ADDR`

2. I2C 引脚错误
   - 验证 SCL/SDA 引脚分配
   - 确保使用 OPEN_DRAIN 模式

3. 时钟频率不匹配
   - I2C 控制器当前按 50 MHz 输入时钟配置；如果实际晶振不同，必须重新计算 `clk_div`

## 项目结构

```
60k_ui_prj/
├── rtl/                      # Verilog RTL 源文件
│   ├── top_hdmi_tang_mega_60k.v    # 顶层模块
│   ├── ui_top.v                     # UI 渲染顶层
│   ├── pixel_renderer.v             # 像素渲染器（实例化所有控件）
│   ├── hdmi_timing.v                # HDMI 时序生成器
│   ├── panel_renderer.v             # Panel 控件渲染器
│   ├── bar_renderer.v               # Bar 控件渲染器
│   ├── spectrum_renderer.v          # Spectrum 控件渲染器
│   ├── adv7513_controller.v         # I2C HDMI 芯片控制器
│   ├── Gowin_rPLL.v                 # PLL 配置（IP 核）
│   └── ui_config.vh                 # UI 配置头文件
├── constraints/
│   └── tang_mega_60k_hdmi.cst       # 引脚和时序约束
├── designer/                 # Python UI 设计器（可选）
│   ├── ui_designer.py               # GUI 设计器主程序
│   ├── ui_schema.py                 # UI 数据模型
│   └── pixel_renderer.py            # Python 参考渲染器
├── generator/                # RTL 代码生成器
│   ├── rtl_generator.py             # 从 JSON 生成 Verilog
│   ├── font_generator.py            # 字体 ROM 生成器
│   └── top_module_generator.py      # 顶层模块生成器
├── examples/                 # 示例配置
│   ├── dx7_synth.json               # DX7 合成器 UI 配置
│   └── generate_dx7_rtl.py          # 生成示例 RTL 的脚本
├── assets/                   # 资源文件
│   └── fonts/                       # 字体数据（待修复）
├── testbench/                # 测试文件（未完成）
├── tang_mega_60k_ui.gprj     # Gowin IDE 项目文件
├── build.tcl                 # 命令行构建脚本
└── README.md                 # 本文件
```

## 开发路线图

### 近期目标
- [ ] 验证 Tang Mega 60K 实际硬件引脚
- [ ] 添加 Verilog testbench
- [ ] 实现文本渲染（修复字体生成器）
- [ ] 完善 Python UI 设计器功能

### 中期目标
- [ ] 支持更多控件类型（Waveform、Keyboard）
- [ ] 添加动画和过渡效果
- [ ] 支持触摸输入
- [ ] 多分辨率支持

### 长期目标
- [ ] 完整的 WYSIWYG 设计器
- [ ] 实时预览和调试
- [ ] 支持其他 FPGA 平台
- [ ] 集成音频处理示例

## 许可证

本项目仅供学习和研究使用。

## 贡献

欢迎提交 Issue 和 Pull Request！

特别需要帮助的领域：
- 验证 Tang Mega 60K 实际引脚分配
- 测试不同的 HDMI 芯片（IT66121、ANX9134 等）
- 添加更多示例 UI 设计
- 改进文档和教程

## 致谢

- Sipeed Tang Mega 60K 文档和社区
- Gowin EDA 工具
- HDMI 规范和参考设计

## 支持

遇到问题？
1. 查看本 README 的故障排除章节
2. 检查 `.claude/plan.md` 了解已知问题
3. 在 GitHub Issues 中搜索类似问题
4. 创建新的 Issue 并附上：
   - 完整的错误信息
   - 你的开发板型号
   - 使用的 Gowin EDA 版本
   - 修改过的引脚分配（如有）
