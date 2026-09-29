# Tang Mega 60K 硬件参数需求清单

## 需要您提供的硬件信息

> 下面的值不能仅凭项目文件或附件推断。请以手上板卡的原理图、丝印和器件实物为准；
> 在这些信息确认前，约束文件中的 HDMI 管脚只能作为示例，不能生成可烧录结论。

### 0. 板卡身份（必须先确认）

```
板卡品牌/型号：Tang Mega 60K / 其他：________
PCB revision：________
FPGA 完整料号（含封装、速度/温度后缀）：________
```

项目当前文件写的是 `GW5AT-LV60PG484AC1/I0` / `GW5AT-60`；这只是工程目标，
不是对用户实物的确认。器件后缀或封装不同会导致管脚约束不能复用。

### 1. HDMI 接口管脚分配 ⚠️ 必需

请根据 Tang Mega 60K 实际原理图提供以下管脚：

先确认 HDMI 输出架构（只能选实际存在的一项）：

```
[ ] FPGA 输出并行 RGB 到外部 HDMI 发射芯片
[ ] FPGA 直接输出 TMDS（差分对）
[ ] 其他：________________
HDMI/视频芯片型号和完整后缀：________________
```

如果使用外部发射芯片，请确认 RGB 位序、同步/DE 是否接入该芯片，以及
芯片的 `RESET/PD/HPD/INT`、`SCL/SDA` 和上拉电阻连接。若是直接 TMDS，
当前 RTL 的并行 RGB 端口和约束不能直接使用。

```
# HDMI 时钟
hdmi_clk = ?

# HDMI RGB 数据 [23:0]
# 红色 [23:16]
hdmi_d[23] = ?
hdmi_d[22] = ?
hdmi_d[21] = ?
hdmi_d[20] = ?
hdmi_d[19] = ?
hdmi_d[18] = ?
hdmi_d[17] = ?
hdmi_d[16] = ?

# 绿色 [15:8]
hdmi_d[15] = ?
hdmi_d[14] = ?
hdmi_d[13] = ?
hdmi_d[12] = ?
hdmi_d[11] = ?
hdmi_d[10] = ?
hdmi_d[9] = ?
hdmi_d[8] = ?

# 蓝色 [7:0]
hdmi_d[7] = ?
hdmi_d[6] = ?
hdmi_d[5] = ?
hdmi_d[4] = ?
hdmi_d[3] = ?
hdmi_d[2] = ?
hdmi_d[1] = ?
hdmi_d[0] = ?

# HDMI 同步信号
hdmi_hsync = ?
hdmi_vsync = ?
hdmi_de = ?

# I2C 控制（用于 ADV7513 或 HDMI 芯片初始化）
hdmi_scl = ?
hdmi_sda = ?
```

### 2. 晶振频率确认

Tang Mega 60K 板载晶振频率：
- [ ] 50 MHz (当前假设)
- [ ] 27 MHz
- [ ] 其他: ______ MHz

```
晶振输入 FPGA 管脚：________
晶振电压/IO bank：________
```

### 3. 按键和 LED 管脚（可选，用于调试）

```
# 复位按键
key_reset_n = T10 (当前值)

# LED 调试输出
led[0] = L14 (当前值)
led[1] = L15 (当前值)
...
```

### 4. 电气和视频时序（必须确认）

```
HDMI/RGB 所在 IO bank 及 VCCIO：________________
信号电平（LVCMOS 电压或 TMDS 标准）：________________
I2C 上拉电压和电阻值：________________
目标分辨率/刷新率：________________
HSYNC 极性：________   VSYNC 极性：________
像素数据采样边沿：________
```

还需要根据最终晶振、器件和目标视频模式重新运行 PLL Wizard，确认输出频率、
抖动、锁定时间和时序约束；不能把当前 `Gowin_rPLL.v` 中的占位参数视为已验证配置。

---

## 关于 PLL 配置 ⚠️

当前 PLL 参数（FBDIV=1, IDIV=1, ODIV=8）**不正确**，无法从 50MHz 生成 74.25MHz。

### 需要操作：

1. **使用 Gowin PLL Wizard 重新生成 PLL**
   - 打开 Gowin EDA
   - Tools → IP Core Generator
   - 选择 rPLL (Clock)
   - 输入时钟：50 MHz
   - 输出时钟：74.25 MHz
   - 生成 Gowin_rPLL.v 替换当前文件

2. **或者提供正确的 PLL 参数**
   ```
   FCLKIN = 50 MHz
   IDIV_SEL = ?
   FBDIV_SEL = ?
   ODIV_SEL = ?
   ```

---

## Gowin EDA License

当前显示 "License verification failed"。

### 需要确认：

1. 是否已安装 Gowin EDA？
2. 是否有有效的 License？
   - 教育版 License（免费）
   - 商业版 License
3. License 是否支持 GW5AT-60 器件？

---

## 确认后的验收顺序

完成并核对以上信息后，仍需按以下顺序验收，不能提前承诺结果：

1. 更新约束和 HDMI 芯片初始化参数。
2. 用 Gowin EDA PLL Wizard 生成匹配最终器件/晶振的 PLL。
3. 在有效 License 下运行综合、布局布线和时序分析。
4. 生成 `.fs` 后再用实际板卡、显示器和示波器/逻辑分析仪验证输出。

只有综合、时序、烧录和实板显示均通过，才可称为硬件交付版本。

---

**请提供以上信息，我将立即更新配置文件。**
