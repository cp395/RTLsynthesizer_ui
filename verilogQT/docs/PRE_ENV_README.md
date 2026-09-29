# FPGA UI Designer 上位机

这是从 Tang Mega 60K HDMI 工程中分出的 Python 桌面设计器。FPGA 工程位于 `D:\fpga\gowin_fpga_prj\60k_ui_prj`。

## 启动

在 `D:\verilogQT` 下使用 Python 3.8+ 安装 `requirements.txt`，然后执行 `python run.py`。Windows 也可使用 `start.bat`。迁移前留下的 `.venv` 指向另一台机器上的 Python 3.9，不能直接作为当前环境使用；请创建新的虚拟环境并安装依赖。

## 功能和目录

- `designer/`：PySide6 可视化编辑器、场景 JSON 模型和 Python 参考渲染器。
- `generator/`：根据场景生成 RTL 原型及字体 ROM 的脚本。
- `examples/`：DX7 示例 JSON、生成脚本及既有生成结果。
- `testbench/test_renderer.py`：Python 预览图测试。

编辑器可以保存和打开 JSON、预览模拟数据，并生成 `ui_top.v`、`pixel_renderer.v`。生成的 RTL 仍需与 FPGA 工程中的渲染器模块及实际数据接口集成；它不会自动综合或烧录。Text 等控件尚未完整落到 RTL。

`verify*.py` 和旧报告来自原先混合目录，包含 FPGA 工程的相对路径检查；分离后不能作为独立上位机验收脚本使用。
