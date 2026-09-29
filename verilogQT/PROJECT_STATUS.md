# FPGA UI Designer - 项目当前状态

> 状态口径：本文档只记录当前目录中可复现的静态检查和已知限制。
> 尚未通过 Gowin 综合、布局布线、时序分析或真实板卡显示验证，因此不能把本项目称为可烧录成品。

## ✅ 已完成的工作

### Python 工具链 ⚠️ 部分可用
- ✅ UI Schema 完整（ColorRGB 别名、序列化方法）
- ✅ 像素渲染器正确（7 种控件，Bar 正确缩放，PCM/键盘支持）
- ⚠️ UI 设计器需要 PySide6（如果 .venv 不可用）
- ⚠️ 测试脚本：实测 4/5 通过；GUI 导入因当前 Python 环境缺少可用的 PySide6

**解决方案：**
```bash
pip install PySide6
# 或使用项目 .venv（如果可用）
```

### RTL 源码和静态检查 ⚠️ 未完成硬件验证
- ✅ 所有端口匹配（PLL lock、hdmi_timing de）
- ✅ 所有变量声明（knob_renderer rel_x/rel_y）
- ✅ 位宽一致（knob 16位值）
- ⚠️ 时钟配置文本统一为 50MHz 输入，但 PLL 目标频率和 IP 参数尚未由 Gowin EDA 验证
- ⚠️ I2C 分频逻辑按 50MHz 输入编写；实际 SCL 频率仍需仿真/硬件确认
- ✅ 字体文件合法 Verilog（无模板残留）
- ✅ 在临时 PLLG stub 下完成了 Icarus 全工程 syntax/elaboration 检查；这不替代 Gowin 综合或时序验证
- ✅ I2C 控制器通过 ACKing-slave 协议冒烟测试（地址、21 组寄存器写入、STOP）；不替代真实 HDMI 芯片验证

**注意：**
- 手写 RTL（rtl/ 目录）是固定演示布局，不自动对应 JSON
- RTL 生成器仅用于快速原型，不生成完整工程

### 配置文件 ⚠️ 仅完成静态一致性检查
- ✅ 器件：GW5AT-60K（build.tcl 和 gprj）
- ✅ 时钟：clk_50mhz（约束、顶层、PLL）
- ✅ Verilog：SystemVerilog 2017
- ✅ 文件列表：构建脚本声明了当前渲染器模块
- ⚠️ 这些检查只比较文本，不能证明器件、封装、IO bank、电压或管脚与实物一致

### 验证状态 ⚠️
- ✅ Icarus syntax/elaboration 在临时 PLLG stub 下通过；真实 Gowin 原语、PLL 参数和综合仍未验证
- ✅ Python 测试：4/5 通过（GUI 需要 PySide6）
- ✅ 快速验证：20/20 静态文件/文本检查通过（不等于综合通过）
- ✅ 本地结构验证：25/25（含 I2C 和异步事件 CDC 测试；不等于 Gowin 综合、时序或实板通过）

---

## ⚠️ 已知限制

### 0. 当前测试边界
- `test_features.py` 在当前系统 Python 下仍因缺少 `PySide6` 为 4/5；项目 `.venv` 的 Python 路径已失效，不能据此声称 GUI 已验收。
- `verify_real.py` 的 25/25 只覆盖 Icarus 结构检查、I2C 协议模型和事件 CDC 模型；临时 PLLG stub 不验证 Gowin 原语参数，模型也不验证真实芯片电气时序。

### 1. RTL 生成器功能有限
**现状：**
- 生成 `ui_top.v`、`pixel_renderer.v`、`ui_interaction.v` 及其渲染依赖，并输出 `build_generated.tcl`
- 可见但未实现 RTL 的控件类型会被拒绝；Text 使用生成目录内的 8x16 ASCII ROM
- Bar/Knob 支持 `ui_state[N]`、`opN_level`、`value` 和 `knob_value` 映射；非法源会在编辑/生成前报错

**建议：**
- 直接使用手写 RTL（rtl/ 目录）作为模板
- RTL 生成器仅用于快速原型设计
- 手动调整生成的代码以匹配实际需求

### 2. Text 控件无真实渲染
**现状：**
- Python 预览：矩形占位
- RTL：未实现（需要字体 ROM 集成）
- 设计器画布：占位绘制

**解决方案：**
- 字体 ROM 文件存在（assets/fonts/）
- 需要手动集成 text_renderer 模块
- 或当前版本跳过 Text 控件

### 3. 手写 RTL 是固定演示布局
**现状：**
- pixel_renderer.v 是固定的 6 控件演示
- 不自动对应 dx7_synth.json 的 29 个控件

**当前定位：**
- 手写 RTL：固定演示布局和参考实现，尚未证明可直接用于生产
- 生成 RTL：快速原型，灵活布局，功能有限

### 4. 其他已知问题
- ⚠️ ui_config.vh 的 NUM_WIDGETS=6 只描述手写演示布局，且当前未被 RTL 引用
- ⚠️ test_renderer.py 逐像素比较仍是 TODO
- ⚠️ 部分设计器画布控件是占位绘制

---

## ⚠️ 需要手动处理的问题

### 1. PLL 参数 ⚠️ 高优先级

**当前问题：**
```verilog
FBDIV_SEL = 1
IDIV_SEL = 1
ODIV_SEL = 8
```
这些参数**不能**从 50MHz 生成 74.25MHz。

**必须操作：**
1. 打开 Gowin EDA
2. Tools → IP Core Generator → rPLL (Clock)
3. 配置：
   - Input Frequency: 50 MHz
   - Output Frequency: 74.25 MHz
   - Device: GW5AT-60
4. 生成 Gowin_rPLL.v
5. 替换 `rtl/Gowin_rPLL.v`

---

### 2. HDMI 管脚分配 ⚠️ 高优先级

**当前问题：**
约束文件中的管脚标记为示例值

**必须操作：**
请根据 Tang Mega 60K **实际原理图**提供管脚。

参考：HARDWARE_INFO_NEEDED.md

---

### 3. Gowin EDA License ⚠️ 必需

**当前问题：**
```
gw_sh 启动时提示: License verification failed
```

**解决方案：**
- 教育版 License（免费）
- 商业版 License
- 或直接使用 Gowin GUI（无需命令行）

---

## 📊 当前可交付状态

### ✅ 可以交付（原型/源码级）
1. **Python 工具链（需要 PySide6）**
   - UI 设计器（可视化设计）
   - 像素渲染器（预览，支持 7 种控件）
   - RTL 生成器（原型，功能有限）

2. **手写 RTL 参考工程**
   - 固定演示布局（6 控件）
   - 所有控件渲染器（7 种）
   - HDMI 时序生成
   - 顶层模块
   - 约束文件模板（当前 HDMI 管脚是示例值）

3. **完整的文档**
   - README.md
   - QUICKSTART.md
   - COMPLEX_WIDGETS.md
   - HARDWARE_INFO_NEEDED.md
   - PROJECT_STATUS.md（本文档）

### ⚠️ 当前不能交付
1. **可烧录、已验证的 Bitstream 文件**
   - 需要正确的 PLL 配置
   - 需要正确的 HDMI 管脚
   - 需要 Gowin EDA License

2. **完全自动化的工具链**
   - RTL 生成器功能有限
   - Text 控件无真实渲染
   - 手写 RTL 不自动对应 JSON

---

## 🎯 项目定位

### 这个项目是什么
- ✅ FPGA UI 设计和渲染框架
- ✅ 手写 RTL 模板和参考实现
- ✅ Python 工具辅助设计和预览
- ✅ 快速原型工具（有限的自动化）

### 这个项目不是什么
- ❌ 完全自动化的 JSON → Bitstream 工具链
- ❌ 生产级 GUI 构建器（如 Qt Designer）
- ❌ 支持所有控件类型的通用框架

### 推荐工作流程
1. 使用 Python 设计器快速原型设计
2. 预览基本布局和控件
3. 使用 RTL 生成器生成初始代码
4. **手动调整和优化生成的 RTL**
5. 或直接使用手写 RTL 模板

---

## 🔍 我能做什么 vs 您需要做什么

### ✅ 当前能确认的工作
- 关键 Python Schema/渲染器测试在无 GUI 的环境下通过
- 配置文件的器件字符串、时钟端口和语言模式完成静态检查
- 已知限制和硬件待确认项已列出

### ⚠️ 您需要提供
1. Tang Mega 60K HDMI 管脚分配
2. 确认晶振频率（假设 50MHz）
3. Gowin EDA License 或使用 GUI

### 🔧 需要 Gowin EDA 完成
1. 使用 PLL Wizard 生成正确的 PLL
2. 运行综合和布局布线
3. 生成 bitstream

---

## 📞 下一步

**立即可做（无需额外依赖）：**
- ✅ 使用手写 RTL 作为参考
- ✅ 修改约束文件（填入真实管脚）
- ✅ 阅读文档了解架构

**需要 PySide6：**
- 运行 UI 设计器
- 进行可视化设计

**需要硬件参数：**
- 更新 HDMI 管脚
- 生成正确的 PLL

**需要 Gowin EDA：**
- 综合和验证
- 生成 bitstream

---

**当前项目状态：原型源码和部分自动化检查可用，等待硬件参数、Gowin 综合/布局布线和实板验证。**
