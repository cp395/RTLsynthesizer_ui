# Tang Mega 60K HDMI UI 完整验证清单

> 验证计划而非验收结果。清单中的“生产就绪”或旧时钟/器件示例只有在 Gowin 综合、
> 时序、真实管脚和实板显示全部完成后才能勾选；当前状态以 `PROJECT_STATUS.md` 为准。

## 📋 预检清单（开始前）

- [ ] 有 Tang Mega 60K 实物或仿真环境
- [ ] 有 Gowin EDA V1.9.11.03 Education (64-bit) 已安装
- [ ] 有 HDMI 显示器（支持 1280×720@60Hz）
- [ ] 有 USB 线连接 Tang Mega 60K
- [ ] 找到了 Tang Mega 60K 原理图（PDF）
- [ ] 有文本编辑器（修改约束文件）

---

## 🔧 步骤 1：环境准备

### 1.1 验证 Gowin EDA 版本

```bash
# 在 Gowin EDA 中
Help → About Gowin EDA
验证版本：v1.9.11.03 Education (64-bit)
```

**预期**：看到正确的版本号

**如果版本不对**：从 Gowin 官网下载正确版本

### 1.2 验证 FPGA 连接

```bash
# 连接 Tang Mega 60K 到电脑（USB）
打开 Device Manager 或系统设置
查找 FTDI USB 设备（应该有）
```

**预期**：在 Device Manager 中看到 USB 设备，无错误标记

**如果未找到**：
- 尝试另一条 USB 线
- 安装 FTDI 驱动
- 检查 USB 口是否损坏

---

## 📄 步骤 2：查找并验证引脚号

### 2.1 下载原理图

```
访问：https://wiki.sipeed.com/hardware/zh/tang/tang-mega-60k/mega-60k.html
点击"硬件资料"
下载 Schematic PDF
文件名通常是：Tang_Mega_60K_Schematic_*.pdf
```

**预期**：成功下载 PDF 文件

**如果无法下载**：
- 检查网络连接
- 尝试从 GitHub 下载：https://github.com/sipeed/sipeed_wiki

### 2.2 查找关键引脚

**打开原理图 PDF，查找以下内容**：

#### A. 时钟和复位

```
搜索："27MHz" 或 "Oscillator"
→ 找到晶振引脚号，记为 clk_27mhz_pin

搜索："RST" 或 "RESET"
→ 找到复位按钮引脚号，记为 reset_pin

示例：
  clk_27mhz = H11
  reset_n = T10
```

#### B. LED

```
搜索："LED" 或 "D1" ... "D8"
→ 找到 8 个 LED 引脚号

示例：
  led[0] = L14
  led[1] = L15
  led[2] = L16
  led[3] = M15
  led[4] = M16
  led[5] = N14
  led[6] = N15
  led[7] = N16
```

#### C. HDMI 接口

```
搜索："HDMI" 或 "ADV7513"
→ 找到 HDMI/ADV7513 部分

需要找到：
  - 24 条 RGB 数据线：D[23:0]
  - 时钟线：CLK
  - 同步线：HSYNC, VSYNC, DE
  - I2C 线：SCL, SDA

通常会看到这样的标记：
  HDMI_D0 ~ HDMI_D23 (或 RGB_B0~B7, RGB_G0~G7, RGB_R0~R7)
  HDMI_CLK
  HDMI_HSYNC, HDMI_VSYNC, HDMI_DE
  HDMI_SCL, HDMI_SDA
```

### 2.3 记录引脚号

**创建一个文本文件 `pinout.txt`**：

```
================== Tang Mega 60K HDMI Pinout ==================

时钟和复位：
  clk_27mhz = ???
  key_reset_n = ???

LED：
  led[0] = ???
  led[1] = ???
  led[2] = ???
  led[3] = ???
  led[4] = ???
  led[5] = ???
  led[6] = ???
  led[7] = ???

HDMI RGB 数据：
  hdmi_d[23] = ???  (Red[7])
  hdmi_d[22] = ???  (Red[6])
  ... (继续到 hdmi_d[0])

HDMI 时钟和同步：
  hdmi_clk = ???
  hdmi_vsync = ???
  hdmi_hsync = ???
  hdmi_de = ???

HDMI I2C（ADV7513 配置）：
  hdmi_scl = ???
  hdmi_sda = ???

说明：
  ??? = 需要从原理图中查找
  示例：A1, B1, C1 等（BGA 封装引脚号）
```

**预期**：成功找到所有引脚号

**如果找不到**：
- 再仔细看原理图
- 搜索"连接器"或"Header"部分
- 查找 FPGA 引脚分配（Pin Assignment）表

---

## ⚙️ 步骤 3：准备项目文件

### 3.1 复制文件

```bash
# 创建项目目录
mkdir -p ~/fpga_projects/tang_mega_60k_hdmi_ui
cd ~/fpga_projects/tang_mega_60k_hdmi_ui

# 从 60k_ui_prj 复制文件
cp -r ~/Desktop/60k_ui_prj/rtl .
cp -r ~/Desktop/60k_ui_prj/assets .
cp ~/Desktop/60k_ui_prj/constraints/tang_mega_60k_hdmi.cst .
```

**预期**：所有文件复制成功

### 3.2 编辑约束文件

**打开 `tang_mega_60k_hdmi.cst`**：

```bash
# 用文本编辑器打开
notepad tang_mega_60k_hdmi.cst
# 或
vi tang_mega_60k_hdmi.cst
```

**替换所有 `???` 为实际引脚号**：

示例（假设从原理图查到）：

```cst
# 替换前
IO_LOC "clk_27mhz" ???;
IO_LOC "key_reset_n" ???;

# 替换后
IO_LOC "clk_27mhz" H11;
IO_LOC "key_reset_n" T10;
```

**逐行替换**：
- [ ] 时钟（clk_27mhz）
- [ ] 复位（key_reset_n）
- [ ] LED[0-7]
- [ ] HDMI_D[0-23]
- [ ] HDMI_CLK, HSYNC, VSYNC, DE
- [ ] HDMI_SCL, SDA

**预期**：约束文件中没有 `???` 了

**验证**：

```bash
# 检查是否还有未替换的
grep "???" tang_mega_60k_hdmi.cst

# 应该输出空（无结果）
```

---

## 🔨 步骤 4：生成 PLL IP 核

### 4.1 打开 Gowin EDA

```
启动 Gowin EDA V1.9.11.03
```

### 4.2 打开 IP 核生成器

```
菜单：Tools → IP Core Generator
或右键项目 → IP Core Generator
```

### 4.3 创建 rPLL

```
1. 在 IP 核列表中找到 rPLL
2. 双击打开配置对话框
3. 填写参数：
   
   基本设置：
   - Clock Name：clk_27mhz
   - Frequency：27
   
   输出时钟：
   - Clock Out：clk_pixel
   - Frequency：74.25
   
   模块设置：
   - Module Name：Gowin_rPLL
   - Output File：Gowin_rPLL.v
   
4. 点击 Generate

预期：生成 Gowin_rPLL.v 文件
```

**验证生成的文件**：

```bash
# 检查是否生成成功
ls -la Gowin_rPLL.v

# 查看文件内容（应该包含参数配置）
grep "FBDIV\|IDIV\|ODIV" Gowin_rPLL.v

# 应该看到类似：
# .FBDIV_SEL(11),
# .IDIV_SEL(1),
# .ODIV_SEL(4),
```

---

## 📁 步骤 5：创建 Gowin 工程

### 5.1 新建项目

```
File → New → FPGA Design Project

项目名：tang_mega_60k_hdmi_ui
项目位置：~/fpga_projects/tang_mega_60k_hdmi_ui
```

### 5.2 选择器件

```
Device Selection:
- Device：GW5AT-LV60P484A (或 GW5AT-60)
- Package：PBGA484
- Speed Grade：-6
```

**验证**：确认器件型号正确（GW5AT-60）

### 5.3 添加文件

```
Project → Add Files

需要添加的文件：
[ ] rtl/top_hdmi_tang_mega_60k.v
[ ] rtl/adv7513_controller.v
[ ] rtl/ui_top.v
[ ] rtl/pixel_renderer.v
[ ] rtl/hdmi_timing.v
[ ] rtl/ui_config.vh
[ ] rtl/panel_renderer.v
[ ] rtl/bar_renderer.v
[ ] rtl/spectrum_renderer.v
[ ] Gowin_rPLL.v (生成的 IP 核)
```

**验证**：左侧 File List 中能看到所有文件

### 5.4 设置顶层模块

```
在 File List 中右键 top_hdmi_tang_mega_60k.v
选择 "Set as Top Module"
```

**验证**：文件前面显示特殊图标表示是顶层

### 5.5 添加约束文件

```
Project → Add Constraint Files
选择 tang_mega_60k_hdmi.cst
```

**验证**：约束文件出现在 File List 中

---

## 🔧 步骤 6：综合（Synthesize）

### 6.1 运行综合

```
Process → Synthesize
或点击工具栏 Synthesize 按钮
或右键顶层文件 → Synthesize
```

### 6.2 观察输出

```
底部 Console 面板显示综合进度
预期输出内容：
  - Parsing...
  - Analyzing...
  - Optimizing...
  - Generating...
  - [Done]
```

**预期**：完成但可能有 Warning（不能有 Error）

### 6.3 检查报告

```
Process → Synthesize Report
查看 rtl_stat.txt

记录资源占用：
- LUT4: ???? (应该 < 10,000)
- FF: ???? (应该 < 10,000)
- BSRAM: ?? (应该 < 20)
```

**预期资源占用**：

```
╔═══════════╦═══════════╦════════════════╗
║ 资源      ║ 占用数量  ║ 占用百分比     ║
╠═══════════╬═══════════╬════════════════╣
║ LUT4      ║ 4,000-6,000 │ 7-10%        ║
║ FF        ║ 2,000-3,000 │ 3-5%         ║
║ BSRAM     ║ 8-15    │ 7-13%        ║
║ DSP       ║ 8-12    │ 7-10%        ║
╚═══════════╩═══════════╩════════════════╝
```

**如果 Error**：

```
常见错误及解决方案：

1. "Unpacked array not supported"
   → 需要展开数组（见故障排除）

2. "Module not found"
   → 检查 rtl 文件是否都添加了

3. "Pin constraint conflict"
   → 检查约束文件中是否有重复引脚号

4. "Unexpected token"
   → 检查 Verilog 语法，可能有空格问题
```

**预期**：看到 Synthesis complete 消息，无 Error

---

## 🎯 步骤 7：布局布线（Place & Route）

### 7.1 运行 P&R

```
Process → Place & Route
或点击工具栏按钮
```

### 7.2 等待完成

```
进度条显示：
  - Reading...
  - Placement...
  - Routing...
  - [Done]
  
预期时间：1-5 分钟（取决于复杂度）
```

### 7.3 检查时序

```
Process → Timing Report (生成前)
或打开：impl/pnr/report/timing_summary.txt

查找：
  - clk_pixel (74.25 MHz) 时序
  - 应该看到 "Slack: positive" 或 ">= 0"
  - 不能有负 slack
```

**预期**：

```
Clock Summary:
  clk_pixel: 74.25 MHz
    Setup:    Slack = +0.123ns  ✓
    Hold:     Slack = +0.456ns  ✓
```

**如果时序不满足**：

```
症状：显示负 Slack
例如：Setup: Slack = -1.234ns

解决方案：
A. 降低目标时钟
   改为 50 MHz（改分辨率）

B. 添加流水线
   在关键路径插入寄存器
```

**预期**：P&R complete，时序满足

---

## 📦 步骤 8：生成比特流

### 8.1 生成 Bitstream

```
Process → Generate Bitstream
或点击工具栏按钮
```

### 8.2 等待完成

```
进度条显示完成
预期时间：1-2 分钟
```

### 8.3 验证生成的文件

```bash
# 检查是否生成成功
ls -la impl/pnr/tang_mega_60k_hdmi_ui.fs

# 应该看到：
# -rw-r--r-- 1 user group xxxxxx tang_mega_60k_hdmi_ui.fs
```

**预期**：文件大小应该在 1-5 MB 范围

**如果未生成**：
- 检查 P&R 是否成功
- 查看 Console 中的错误信息

---

## 🖲️ 步骤 9：下载到 FPGA

### 9.1 连接硬件

```
1. 用 USB 线连接 Tang Mega 60K 到电脑
2. 观察板卡 LED：
   - 可能会闪烁（正常）
3. 打开 Device Manager 确认设备识别
```

**预期**：FTDI USB 设备显示在设备列表

### 9.2 打开 Programmer

```
Gowin EDA:
  Tools → Programmer
或独立应用：
  启动 Gowin Programmer
```

### 9.3 添加设备

```
1. 点击 "Refresh Device" 或 "Detect"
2. 应该自动检测到 GW5AT-60
3. 点击 "Add Device" (如果没有自动检测)
```

**预期**：看到 GW5AT-60 设备在列表中

### 9.4 加载比特流

```
1. 右键设备 → Properties
   或点击设备后点击 "Configure"

2. 选择 File：
   impl/pnr/tang_mega_60k_hdmi_ui.fs

3. 选择 Device：
   "Embedded Flash" (片上 Flash) 或 "SRAM" (临时)
   
   建议：
   - 测试阶段用 SRAM（速度快，不需要验证）
   - 最终部署用 Flash（掉电保存）
```

### 9.5 编程

```
1. 点击 "Program" 按钮
2. 观察进度条

预期输出：
  - "Programming..."
  - "Verifying..."
  - "Program done" ✓
```

**预期**：看到成功消息，无错误

**如果失败**：

```
常见错误：

1. "Device not found"
   → USB 连接问题，重新连接

2. "Invalid bitstream file"
   → 文件损坏，重新生成

3. "Programming failed"
   → FPGA 故障，联系 Sipeed 技术支持

4. 超时
   → USB 驱动问题，重新安装 FTDI 驱动
```

---

## 📺 步骤 10：连接显示器验证

### 10.1 连接 HDMI

```
1. 用 HDMI 线连接 Tang Mega 60K HDMI 口
2. 连接到显示器
3. 打开显示器电源
```

### 10.2 观察 LED

```
编程完成后，观察板卡 LED：

LED[0] (PLL 锁定)
  预期：常亮（绿色）
  
LED[1] (系统复位)
  预期：常亮（绿色）
  
LED[2] (ADV7513 初始化)
  预期：常亮（绿色），约 100ms 后亮起
  
LED[3] (ADV7513 错误)
  预期：熄灭（黑色）
  
LED[4] (VSYNC - 60Hz)
  预期：缓慢闪烁
  
LED[5] (HSYNC)
  预期：快速闪烁
  
LED[7] (视频输出)
  预期：常亮（绿色）
```

**预期 LED 序列**：
```
上电
  ↓
LED[0,1,7] 立即亮起
  ↓
LED[2] 在 100-200ms 后亮起
  ↓
LED[4,5] 开始闪烁
  ↓
显示器收到信号
```

### 10.3 检查显示器

```
显示器应该显示：
  
  ┌────────────────────────────────────────────────┐
  │ FPGA SYNTH ENGINE             46.875 kHz       │
  │                                                │
  │ ┌─────────────────────────┐  ┌──────────────┐  │
  │ │                         │  │ OPERATOR     │  │
  │ │  SPECTRUM (64 bars)     │  │OP1 ██████    │  │
  │ │                         │  │OP2 ████      │  │
  │ │     █ █                 │  │OP3 ██        │  │
  │ │     █ █    █            │  │OP4 ██████    │  │
  │ │   █ █ █ █  █ █          │  │OP5 ██        │  │
  │ │                         │  │OP6 ████████  │  │
  │ └─────────────────────────┘  └──────────────┘  │
  │                                                │
  │ Envelope  Wave  Preset: DX7 E.PIANO 1         │
  │                                                │
  │ [■□■■□■■■□■■...] Keyboard                    │
  └────────────────────────────────────────────────┘
```

**动画效果**（应该看到）：
- ✓ Operator 条自动变化
- ✓ Spectrum 柱随机跳动
- ✓ 60 FPS 流畅显示
- ✓ 无撕裂、无闪烁

**预期**：完整的合成器 UI 显示正常

### 10.4 故障排除

**问题：显示器无信号**

```
检查清单：
[ ] USB 线连接正确
[ ] LED[0] 是否常亮（PLL）
[ ] LED[2] 是否常亮（ADV7513）
[ ] LED[7] 是否常亮（视频输出）
[ ] HDMI 线缆是否接好
[ ] 显示器是否打开
[ ] 显示器是否选择了正确的输入源

如果都检查过还无信号：
1. 尝试另一台显示器
2. 尝试另一条 HDMI 线
3. 按复位按钮重新启动
4. 重新下载比特流
```

**问题：显示花屏或颜色不对**

```
可能原因：
1. RGB 通道接反
   → 修改 top_hdmi_tang_mega_60k.v 交换通道

2. 数据位顺序错误
   → 查看约束文件引脚号是否正确

3. 时序问题
   → 检查时序报告

解决方法：
1. 重新检查约束文件
2. 修改代码试验不同的通道排列
3. 重新综合下载
```

---

## ✅ 完成检查表

### 全部成功！

```
[✓] PLL 锁定 (LED[0] 常亮)
[✓] 系统复位 (LED[1] 常亮)
[✓] ADV7513 初始化完成 (LED[2] 常亮)
[✓] VSYNC 信号输出 (LED[4] 闪烁)
[✓] 视频输出启用 (LED[7] 常亮)
[✓] 显示器接收到 1280×720@60Hz 信号
[✓] UI 显示正确
[✓] 动画流畅运行
[✓] 所有 29 个控件渲染正确
[✓] 频谱动画
[✓] Operator 条变化
[✓] 无花屏、无闪烁
```

---

## 🎉 恭喜！

完成清单后才可能得到可用的 Tang Mega 60K HDMI 系统；当前项目尚未完成这些验收步骤。

### 下一步

1. **集成你的音频合成引擎**：
   - 替换测试数据生成器
   - 连接真实的 Operator 电平
   - 连接真实的 FFT 频谱

2. **定制 UI 界面**：
   - 修改 `ui_schema.py` 改变控件布局
   - 运行 RTL 生成器生成新的 Verilog
   - 重新综合下载

3. **添加交互功能**：
   - 连接键盘
   - 连接旋钮
   - 连接滑块

---

## 📞 需要帮助？

如果遇到问题：

1. 检查本文档中的故障排除部分
2. 查看控制台输出信息
3. 检查硬件连接
4. 参考 ADV7513 数据手册

---

**项目完成日期**：2025-09-20  
**版本**：1.0 完整版  
**状态**：⚠️ 待综合、时序、管脚和实板验证
