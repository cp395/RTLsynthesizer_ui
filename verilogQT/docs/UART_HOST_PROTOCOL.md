# VerilogQT UART 上位机协议

VerilogQT 运行在 PC 上，读取 `UI.json`/`UI_new.json` 后由
`designer.host_app.UIHost` 负责 PC 参考渲染和 UART 传输。协议使用二进制
帧，避免 FPGA 端直接解析不定长 JSON 字符串时丢帧。

## 帧格式

所有整数均为 little-endian。固定头部为 14 字节：

| 偏移 | 大小 | 字段 |
| ---: | ---: | --- |
| 0 | 4 | ASCII `VQT1` |
| 4 | 1 | 协议版本，目前为 `1` |
| 5 | 1 | 消息类型 |
| 6 | 1 | flags（当前保留为 0） |
| 7 | 1 | reserved（发送为 0） |
| 8 | 2 | sequence，循环递增的帧序号 |
| 10 | 4 | payload 长度，最大 1 MiB |

头部之后是 payload，最后为 2 字节 CRC-16/CCITT-FALSE。CRC 覆盖头部的
版本字段到长度字段以及完整 payload，不覆盖 `VQT1` 和 CRC 本身。
接收端应先查找 `VQT1`，检查长度上限，再验证 CRC；这样 UART 噪声或半帧
不会污染下一帧。

## 消息类型

| 值 | 名称 | payload |
| ---: | --- | --- |
| `0x01` | `HELLO` | UTF-8 JSON，例如 `{"client":"VerilogQT","version":1}` |
| `0x02` | `UI_JSON` | UTF-8、紧凑 JSON，内容为 `UIScene.to_dict()` |
| `0x03` | `STATE_SNAPSHOT` | 见下节的固定二进制布局 |
| `0x04` | `EVENT` | `<BBH`：`event_type`、`event_id`、`event_value` |
| `0x80` | `ACK` | 可选 JSON，通常只回显被确认的 sequence |
| `0x81` | `NACK` | 可选 JSON 错误信息 |
| `0x82` | `STATUS` | UTF-8 JSON 状态信息 |

`EVENT` 的字段与 `rtl/ui_event_cdc.v` 一致：`event_type` 使用现有
`docs/INTERACTION_PROTOCOL.md` 的 1..6 触发事件及 8..12 直接状态操作，
`event_id` 为控件/状态/音符编号，`event_value` 为 16 位值。

## 状态快照布局

`STATE_SNAPSHOT` 用于在场景已经加载后快速更新动态显示，不需要重复发送
JSON。payload 总长 576 字节，依次为：

1. 32 个 little-endian `uint16` `ui_state[0..31]`（64 字节）；
2. 128 个 `uint8` `key_states[0..127]`（128 字节，发送时规范化为 0/1）；
3. 128 个 `uint8` `fft_bins[0..127]`（128 字节，0..255）；
4. 128 个 little-endian `int16` `pcm_buffer[0..127]`（256 字节）。

Python 端通过 `encode_state_snapshot`/`decode_state_snapshot` 实现，数据
范围与 `designer/ui_schema.py`、RTL 接口保持一致。

## 常用命令

```text
python host_app.py validate UI.json
python host_app.py render UI.json --output frame.png
python host_app.py send UI.json --port COM7 --baud 115200 --ui-new UI_new.json
python host_app.py receive --port COM7 --timeout 5 --output received_state.json
python host_app.py event --port COM7 --type change --id 3 --value 32768
```

真实串口需要 `pyserial`；`validate` 和 `render` 不需要串口。`UI_new.json`
保留标准 UI 场景字段，并额外写入 `runtime_state` 与 `host_protocol`，因此
仍可直接被编辑器打开，重新加载时运行态会恢复到 PC 预览状态。
