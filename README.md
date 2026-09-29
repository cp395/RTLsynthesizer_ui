# FPGA UI Designer 上位机

这是从 Tang Mega 60K HDMI 工程分出的 Python 桌面设计器。配套 FPGA 工程位于 `D:\fpga\gowin_fpga_prj\60k_ui_prj`。

当前基线版本为 `v0.1.0-board-verified`；配套 FPGA 位流已由用户在 Tang Mega 60K 实板确认正常显示 UI。

## 运行

当前已在 `D:\verilogQT\.venv` 配好 Python 3.13、PySide6、NumPy 和 Pillow。双击 `start.bat`，选 `1` 启动界面；也可在此目录执行：

```bat
.venv\Scripts\python.exe run.py
```

旧环境保留在 `.venv_legacy`，它指向另一台机器的 Python 3.9，不参与启动。如果需要重建当前环境：

```bat
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt
```

## 功能和目录

- `designer/`：PySide6 可视化编辑器、交互式预览、场景模型和 Python 参考渲染器。
- `generator/`：将场景生成成固定接口、低资源的单个 `ui_generated_scene.v`。
- `examples/`：`autoplay_status.json` 是面向自动演奏状态的低资源例程。
- `rtl/`：生成器使用的 FPGA 渲染与事件接口模板。
- `testbench/`：Python 渲染测试和交互 RTL 测试台。

编辑器可以保存和打开 JSON。`Preview` 支持拖动旋钮、鼠标或电脑键盘弹奏琴键，以及按 JSON 规则执行 `click`、`press`、`release`、`change`、`key_down` 和 `key_up` 动作。`Interactions` 用于编辑规则 JSON。

`Generate RTL` 每次固定只生成 **1 个 Verilog 文件**：`ui_generated_scene.v`。把它覆盖到 FPGA 工程 `rtl/ui_generated_scene.v` 后直接重新编译；顶层、PLL、视频时序、TMDS 和其它业务 RTL 均不需要修改。另生成 `generated_manifest.json` 说明接口，但它不参与 Gowin 工程。

低资源 FPGA 模式只接受 `panel`、`text`、`bar`、`keyboard`。FFT 频谱和 PCM 波形会被明确拒绝，避免再次产生超大扁平总线和不可控资源。文本支持静态 ASCII；`source=filename` 时从状态总线显示最多 30 个 ASCII 字节。

固定接口为 `ui_status_flat[511:0]`（32 个 16 位槽）和 `note_active[127:0]`。`note_active` 的 128 位仅表示 MIDI 音高编号 0..127，不代表显示 128 个物理琴键；每个键盘控件通过 `start_note` 与 `keys` 选择实际显示窗口，且二者之和不能超过 128。

状态槽约定：0..1 `playback_frame`，2..3 `duration_frames`，4 播放标志，5 文件序号，6 进度 0..1023，7 活跃复音数，8 解码错误，9 SD 错误，10 播放错误，11..16 OP1..OP6 电平，17..31 文件名 ASCII（30 字节）。

运行自动演奏例程：

```bat
.venv\Scripts\python.exe examples\generate_dx7_rtl.py
```

输出文件位于 `examples/generated_rtl/ui_generated_scene.v`。当前 PC 交互预览仍可使用，但它属于设计阶段功能；本次 FPGA 输出只覆盖自动演奏显示，不生成手动演奏事件 RTL。

同步前版本保存在 `before_interactive_sync_20260928/`。
