# 交互式预览与 RTL 交互

当前交互链路已经实现：

- 旋钮支持鼠标垂直拖动，并产生 `change` 事件；
- 钢琴键支持鼠标按下/释放和键盘映射，并产生 `key_down`/`key_up` 事件；
- 任意命名控件支持 `press`、`release`、`click` 规则；
- 规则动作支持设置、累加、翻转 UI 状态，以及动态琴键状态；
- 状态变化后立即重新渲染 PC 预览；
- 同一组 JSON 规则生成 `ui_interaction.v`，在 FPGA 时钟域内更新 `ui_state_flat` 和 `key_states`。

## 在设计器中配置

工具栏的 `Interactions` 按钮编辑当前场景的 JSON 规则。规则示例：

```json
[
  {
    "trigger": "click",
    "source": "preset_name",
    "actions": [
      {"action": "set", "target": "ui_state[0]", "value": 65535}
    ]
  },
  {
    "trigger": "change",
    "source": "knob_0",
    "actions": [
      {"action": "set_event_value", "target": "ui_state[1]"}
    ]
  },
  {
    "trigger": "key_down",
    "source": "keyboard_0",
    "actions": [
      {"action": "set_event_key", "target": "key_states[event]", "value": 1}
    ]
  }
]
```

## FPGA 连接

生成的顶层 `top_hdmi_tang_mega_60k` 暴露以下事件输入：

```verilog
input wire event_clk;
input wire event_valid;
output wire event_ready;
input wire [3:0] event_type;
input wire [7:0] event_id;
input wire [15:0] event_value;
```

事件适配器必须保持事件和负载不变，直到 `event_ready` 为高。
`rtl/ui_event_cdc.v` 使用 toggle 握手把事件可靠地送入 `clk_pixel` 域。
`generated_manifest.json` 中的 `widget_event_ids` 给出控件到 `event_id`
的映射，完整编码见 [docs/INTERACTION_PROTOCOL.md](docs/INTERACTION_PROTOCOL.md)。

当前工程没有假定具体通信芯片或可用 FPGA 管脚，因此没有虚构 UART/USB 管脚；
接入实际板卡时需要增加对应输入适配器和约束。
