# Tang Mega 60K 自动演奏 UI 显示工程

这是面向 `GW5AT-LV60PG484AC1/I0` 的独立 1280x720@60Hz 显示验证工程。工程采用 Tang Mega 138K `hdmi_colorbar` 的直连 TMDS 架构，并使用官方 Tang Mega 60K `cam_dvi` 的器件专用 PLL 与 `DVI_TX_Top` IP。

## 打开和构建

- Gowin 工程：`tang_mega_60k_hdmi.gprj`
- 顶层：`rtl/top_tmds_60k.v`
- 命令行：`gw_sh build_tmds.tcl`
- 位流：`impl/pnr/fpga_ui_60k_tmds.fs`

当前顶层仍使用内部自动变化的演示状态，用于确认 60K 板卡、720p 时序、TMDS 管脚和 UI 渲染链路。用户已于 2026-09-29 将本工程生成的比特流烧录到 Tang Mega 60K，并确认 UI 正常显示。该实板验证版本保存在 `release/v0.1.0-board-verified/`；Phase6 的实时状态信号尚未接入。

## 固定生成文件契约

上位机位于 `D:\verilogQT`。每次点击 `Generate RTL` 固定只生成一个 Verilog 文件：

```text
ui_generated_scene.v
```

将它直接覆盖到 `rtl/ui_generated_scene.v`，重新构建即可。不要修改顶层、视频时序、PLL 或 DVI/TMDS 文件。生成场景的模块端口固定为：

- `pixel_x[10:0]`、`pixel_y[9:0]`
- `ui_status_flat[511:0]`：32 个 16 位状态槽
- `note_active[127:0]`：MIDI 音高 0..127 位图
- `pixel_rgb[23:0]`

128 位 MIDI 位图不代表显示 128 个物理琴键。键盘控件使用 `start_note` 和 `keys` 选择显示窗口；当前自动演奏例程显示 MIDI 48 开始的 24 个音高，实际键数以后可改。

状态槽：0..1 `playback_frame`，2..3 `duration_frames`，4 播放标志，5 文件序号，6 进度 0..1023，7 活跃复音数，8 解码错误，9 SD 错误，10 播放错误，11..16 OP1..OP6 电平，17..31 文件名 ASCII（30 字节）。

## 当前验证结果

Gowin V1.9.11.03 Education 全流程已完成：

- Logic：1995 / 59904（4%）
- Register：374 / 60780（<1%）
- DSP：4 / 118（4%）
- 像素时钟约束：74.250 MHz
- 实际 Fmax：80.661 MHz
- Setup/Hold violated endpoints：0 / 0

最终位流 SHA-256：

```text
2B30E3A9906ADE96B0F6AAE299DA4AFF56AA4A40E4A54324596B3255A9F3CC6E
```

Gowin 仍报告 PLL 频率匹配提示和 DVI IP 内部 `clk_d` 通用时钟路由提示；时序报告使用官方 60K DVI 时钟分组方式，最终没有 setup/hold 违例。`release/v0.1.0-board-verified/` 中的位流已经由用户完成实板烧写并确认 UI 正常显示。

本次没有新增、删除或修改 UART 命令，因此根目录 `UART_COMMANDS.md` 无需改变。
