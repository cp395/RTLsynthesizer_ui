"""
Tang Mega 60K HDMI 完整实现
基于 ADV7513 HDMI 发射芯片
"""

> 历史硬件假设说明。ADV7513、晶振、管脚和电气连接未由用户原理图确认，不能作为当前板卡事实。

# Tang Mega 60K HDMI 接口说明

## 硬件架构

旧资料曾假设 Tang Mega 60K 使用 **ADV7513 HDMI 发射芯片**；必须以当前板卡原理图确认，不能据此连接：

```
┌──────────────────────┐
│  GW5AT-60 FPGA       │
│                      │
│  ┌────────────────┐  │     ┌──────────────┐     ┌──────────┐
│  │   UI Renderer  │  │     │   ADV7513    │     │  HDMI    │
│  │                │──┼────►│              │────►│  输出    │
│  │  RGB888 + sync │  │     │  TMDS 编码   │     │          │
│  └────────────────┘  │     └──────────────┘     └──────────┘
│                      │            ▲
│                      │            │ I2C 配置
└──────────────────────┘            │
```

## ADV7513 接口

### 输入信号（从 FPGA 到 ADV7513）

**视频数据**：
- D[23:0] - 24-bit RGB 数据
  - D[23:16] - Red[7:0]
  - D[15:8]  - Green[7:0]
  - D[7:0]   - Blue[7:0]

**同步信号**：
- VSYNC - 垂直同步
- HSYNC - 水平同步
- DE - 数据使能（显示有效区域）
- CLK - 像素时钟（74.25 MHz for 720p@60Hz）

**控制接口**：
- SCL - I2C 时钟
- SDA - I2C 数据
- INT - 中断（可选）

### 输出信号（ADV7513 到 HDMI 接口）

- TX0+/TX0- - TMDS 数据通道 0 (Blue)
- TX1+/TX1- - TMDS 数据通道 1 (Green)
- TX2+/TX2- - TMDS 数据通道 2 (Red)
- TXCLK+/TXCLK- - TMDS 时钟

## 关键点

1. **无需 TMDS 编码**：ADV7513 芯片已包含 TMDS 编码器，FPGA 只需提供标准 RGB + sync
2. **需要 I2C 配置**：上电后必须通过 I2C 配置 ADV7513 寄存器
3. **支持多种分辨率**：ADV7513 支持最高 165 MHz 像素时钟

## 参考资料

- [ADV7513 Hardware User Guide](https://www.analog.com/media/en/technical-documentation/user-guides/ADV7513_Hardware_User_Guide.pdf)
- [ADV7513 Programming Guide](https://www.analog.com/media/en/technical-documentation/user-guides/ADV7513_Programming_Guide.pdf)
- [Tang Mega 60K Wiki](https://github.com/sipeed/sipeed_wiki/blob/main/docs/hardware/en/tang/tang-mega-60k/mega-60k.md)
- [gbatang - Tang 板 HDMI 实现示例](https://github.com/nand2mario/gbatang/)

## Tang Mega 60K 引脚（需要确认）

**重要**：实际引脚号需要参考你的板卡原理图！

常见配置（示例，请以实际原理图为准）：
```
时钟：
  clk_27mhz   - 板载晶振

RGB 数据（到 ADV7513）：
  hdmi_d[23:16] - Red
  hdmi_d[15:8]  - Green  
  hdmi_d[7:0]   - Blue

同步信号（到 ADV7513）：
  hdmi_clk      - 像素时钟
  hdmi_vsync
  hdmi_hsync
  hdmi_de

I2C（配置 ADV7513）：
  hdmi_scl
  hdmi_sda
```

## 下一步

查看你的 Tang Mega 60K 原理图，确认：
1. HDMI 芯片型号（应该是 ADV7513）
2. FPGA 到 HDMI 芯片的引脚连接
3. I2C 地址（通常 0x72 或 0x39）

然后我会生成完整的 Verilog 实现。
