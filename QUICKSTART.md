# Tang Mega 60K FPGA UI Designer - 快速开始指南

> 当前项目状态提示：本指南含历史假设和操作示例，不代表已经综合或可烧录；请先确认
> `PROJECT_STATUS.md`、`HARDWARE_INFO_NEEDED.md` 中的阻塞项。

## 重要提示 ⚠️

**在烧录到 FPGA 之前，你必须验证和修改引脚分配！**

当前的约束文件包含示例引脚，可能与你的板卡不匹配。使用错误的引脚可能导致：
- 无法通过布局布线
- 板卡无响应
- 显示无输出

## 5 分钟快速测试

### 步骤 1: 验证项目完整性

```bash
cd 60k_ui_prj

# 检查关键文件
ls rtl/*.v
ls constraints/*.cst
ls tang_mega_60k_ui.gprj
```

你应该看到：
- ✅ 10 个 .v 文件在 rtl/ 目录
- ✅ 1 个 .cst 文件在 constraints/ 目录
- ✅ tang_mega_60k_ui.gprj 项目文件

### 步骤 2: 配置引脚（最重要！）

1. **获取你的板卡原理图**

   访问：https://wiki.sipeed.com/hardware/en/tang/tang-mega-60k/
   
   下载 PDF 原理图文件

2. **找到以下信号的实际引脚**

   必须找到的信号：
   - [ ] 时钟输入（CLK_IN, OSC, XTAL 等）
   - [ ] 复位按钮（KEY, RST, RESET 等）
   - [ ] LED 输出（LED0-LED7）
   - [ ] HDMI 芯片数据引脚（D0-D23）
   - [ ] HDMI 控制信号（CLK, DE, HSYNC, VSYNC）
   - [ ] I2C 引脚（SCL, SDA）

3. **更新约束文件**

   编辑 `constraints/tang_mega_60k_hdmi.cst`
   
   示例修改：
   ```tcl
   # 如果原理图显示时钟在 H11
   IO_LOC "clk_27mhz" H11;
   
   # 如果原理图显示 LED0 在 R1
   IO_LOC "led[0]" R1;
   
   # ...对所有信号重复此操作
   ```

4. **检查时钟频率**

   Tang Mega 60K 可能使用 50 MHz 晶振而不是 27 MHz！
   
   如果是 50 MHz：
   - 更新 `constraints/tang_mega_60k_hdmi.cst` 第 48 行：
     ```tcl
     create_clock -name clk_27mhz -period 20.0 -waveform {0 10.0} [get_ports {clk_27mhz}]
     ```
   - 更新 `rtl/Gowin_rPLL.v` 的 PLL 参数（或使用 Gowin IP Core Generator 重新生成）

### 步骤 3: 首次构建（仅 LED 测试）

为了安全，首次构建时只测试 LED：

1. 打开 `rtl/top_hdmi_tang_mega_60k.v`

2. 临时注释掉 HDMI 输出（第 167-182 行）：

   ```verilog
   // 临时禁用 HDMI 输出用于初始测试
   assign hdmi_d = 24'h000000;
   assign hdmi_clk = 1'b0;
   assign hdmi_vsync = 1'b0;
   assign hdmi_hsync = 1'b0;
   assign hdmi_de = 1'b0;
   
   // 原有代码已注释
   // assign hdmi_d[23:16] = video_enable ? ui_r : 8'h00;
   // ...
   ```

3. 构建项目：
   ```bash
   gw_sh build.tcl
   ```
   
   或使用 Gowin IDE：
   - File → Open → tang_mega_60k_ui.gprj
   - Process → Run All

4. 检查是否有错误：
   - ✅ 综合成功
   - ✅ 布局布线成功
   - ✅ 生成 bitstream 成功

5. 烧录到 FPGA

6. **观察 LED**：
   - LED[0] 应该亮起（PLL 锁定）
   - LED[1] 应该亮起（系统复位完成）
   - LED[4] 应该缓慢闪烁（60Hz，可能难以看见）
   - LED[6] 应该慢闪（帧计数器）

如果 LED 表现符合预期，继续步骤 4。如果不符合，检查时钟和复位引脚。

### 步骤 4: 启用 HDMI 输出

1. 恢复 `rtl/top_hdmi_tang_mega_60k.v` 中的 HDMI 输出代码（移除步骤 3 的注释）

2. 验证 HDMI 引脚分配是否正确

3. 重新构建和烧录

4. 连接 HDMI 显示器

5. **观察显示器**：
   - LED[2] 应在约 1 秒后亮起（HDMI 初始化完成）
   - LED[3] 应保持熄灭（无 I2C 错误）
   - 显示器应显示 UI（深色背景 + 面板 + 动画条和频谱）

### 步骤 5: 故障排除

#### LED[0] 不亮（PLL 未锁定）
→ 时钟输入引脚错误或时钟频率配置错误

#### LED[2] 不亮，LED[3] 亮（I2C 错误）
→ I2C 引脚错误或 HDMI 芯片地址不正确

**查找 I2C 地址**：
- 查看 HDMI 芯片型号（ADV7513, IT66121, 等）
- 检查数据手册中的 I2C 地址
- 更新 `rtl/adv7513_controller.v` 第 21 行

#### 显示器无信号
→ HDMI 数据引脚错误或时序问题

#### 布局布线失败："Port exceeds resource"
→ 在 Gowin IDE 中设置顶层模块：
   Project → Configuration → General → Top Module → top_hdmi_tang_mega_60k

## 完整构建流程

### 使用 Gowin IDE（推荐）

1. 打开 Gowin IDE
2. File → Open Project → 选择 `tang_mega_60k_ui.gprj`
3. 验证设置：
   - Project → Configuration → General
   - Device: GW5AT-60（工程假设；完整料号需按实物确认）
   - Package: PG484A
   - Top Module: top_hdmi_tang_mega_60k
4. 构建：
   - Process → Run All
   - 或分步执行：Synthesize → Place & Route → Generate Bitstream
5. 烧录：
   - Tools → Programmer
   - 选择生成的 .fs 文件
   - 点击 Program

### 使用命令行

```bash
# 在项目根目录
gw_sh build.tcl

# 如果成功，烧录
# （需要根据你的编程器类型调整）
openFPGALoader -b tangmega60k impl/pnr/fpga_ui_60k.fs
```

## 验证清单

构建前检查：
- [ ] 所有引脚分配已验证
- [ ] 时钟频率配置正确
- [ ] 顶层模块设置为 top_hdmi_tang_mega_60k
- [ ] 所有 RTL 文件在项目中

构建后检查：
- [ ] 无综合错误或警告
- [ ] 无布局布线错误
- [ ] 时序收敛（检查时序报告）
- [ ] 生成了 .fs 文件

烧录后检查：
- [ ] LED[0] 亮（PLL 锁定）
- [ ] LED[1] 亮（系统运行）
- [ ] LED[2] 亮（HDMI 初始化）
- [ ] LED[3] 灭（无错误）
- [ ] 显示器有输出

## 下一步

✅ 硬件工作后：
- 阅读完整的 README.md
- 尝试修改 UI 设计（examples/dx7_synth.json）
- 连接你自己的音频引擎
- 添加更多控件

## 获取帮助

遇到问题？

1. 检查 README.md 的故障排除章节
2. 验证引脚分配（最常见问题）
3. 检查 Gowin EDA 日志文件
4. 在项目 Issues 中搜索相似问题

## 重要文件位置

- 项目文件：`tang_mega_60k_ui.gprj`
- 顶层模块：`rtl/top_hdmi_tang_mega_60k.v`
- 约束文件：`constraints/tang_mega_60k_hdmi.cst`
- PLL 配置：`rtl/Gowin_rPLL.v`
- UI 定义：`rtl/pixel_renderer.v`
- 构建输出：`impl/pnr/fpga_ui_60k.fs`

## 常见错误速查

| 错误信息 | 可能原因 | 解决方案 |
|---------|---------|---------|
| "Module not found" | 缺少源文件 | 检查 .gprj 中的文件列表 |
| "Port exceeds limit" | 顶层模块错误 | 设置正确的顶层模块 |
| "Invalid location" | 引脚不存在 | 检查引脚名称是否匹配封装 |
| "Timing not met" | 时序违例 | 检查时钟约束和 PLL 配置 |
| LED 都不亮 | 严重硬件错误 | 检查电源和基本引脚 |
| LED[3] 亮 | I2C 失败 | 检查 I2C 引脚和地址 |
| 显示无信号 | HDMI 配置错误 | 检查 HDMI 引脚和时序 |

祝你好运！🚀
