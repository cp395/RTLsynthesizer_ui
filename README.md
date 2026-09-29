# RTLsynthesizer UI

Tang Mega 60K 自动演奏 UI 的单仓库工程，包含电脑端 Qt 设计器/Verilog 生成器和已经通过实板显示验证的 FPGA 工程。

## 目录

- `verilogQT/`：PySide6 上位机、交互预览、场景文件和紧凑 RTL 生成器。
- `60k_ui_prj/`：Tang Mega 60K 720p TMDS 显示工程。

## 联动方式

1. 在 `verilogQT/` 中编辑或载入 UI 场景。
2. 生成固定数量的文件：`ui_generated_scene.v`。
3. 用生成文件覆盖 `60k_ui_prj/rtl/ui_generated_scene.v`。
4. 在 `60k_ui_prj/` 中运行 `gw_sh build_tmds.tcl` 完成综合、布局布线和位流生成。

FPGA 工程的 `release/v0.1.0-board-verified/` 保存了用户已烧录并确认能够正常显示 UI 的版本。`impl/`、Python 虚拟环境和临时生成输出不纳入 Git。

## 当前基线

- Qt 上位机：`v0.1.0`
- FPGA 实板基线：`v0.1.0-board-verified`
- FPGA 器件：`GW5AT-LV60PG484AC1/I0`
- 显示模式：1280x720@60Hz
