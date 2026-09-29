# UI interaction protocol

The PC preview and generated RTL use the same scene `interactions` rules.

## Scene format

```json
{
  "interactions": [
    {
      "trigger": "click",
      "source": "button_0",
      "actions": [
        {"action": "set", "target": "ui_state[0]", "value": 65535},
        {"action": "toggle", "target": "key_states[0]"}
      ]
    },
    {
      "trigger": "change",
      "source": "knob_0",
      "actions": [
        {"action": "set_event_value", "target": "ui_state[1]"}
      ]
    }
  ]
}
```

Triggers: `click`, `press`, `release`, `change`, `key_down`, `key_up`.

Actions: `set`, `set_event_value`, `set_event_key`, `add`, `toggle`, `set_key`.

Targets: `ui_state[0]` through `ui_state[31]`, or `key_states[0]`
through `key_states[87]`.

`set_event_key` uses the event's `event_value` as the key index and writes
`key_states[event_value]`; use it with `key_down` and `key_up` triggers.

## FPGA event bus

`top_hdmi_tang_mega_60k` accepts a one-cycle event:

- `event_valid`: event strobe.
- `event_type[3:0]`: operation or scene trigger.
- `event_id[7:0]`: widget ID, state index, or key index.
- `event_value[15:0]`: knob value, key index, or action operand.

The top-level source uses `event_clk`, `event_valid`, and `event_ready`.
The adapter must hold the payload and `event_valid` until `event_ready` is
high. `rtl/ui_event_cdc.v` transfers each accepted event through a toggle
handshake and emits one `event_valid` pulse in the pixel-clock domain. This
avoids sampling a multi-bit UART, USB, or soft-core bus directly in `clk_pixel`.

Scene trigger types:

- `1`: click
- `2`: press
- `3`: release
- `4`: change
- `5`: key down
- `6`: key up

Direct state operations:

- `8`: set `ui_state[event_id] = event_value`
- `9`: add `event_value` to `ui_state[event_id]`
- `10`: logical toggle `ui_state[event_id]` (`0 -> 1`, nonzero -> `0`)
- `11`: set `key_states[event_id]`
- `12`: clear `key_states[event_id]`

The generated `generated_manifest.json` contains `widget_event_ids`. A UART,
USB, soft CPU, or board-input adapter must translate its input into this bus.
The designer does not assume a physical transport because the FPGA board and
available pins are board-specific.
