#!/usr/bin/env python3
"""Interaction schema, PC state, and generated RTL regression tests."""

import json
import subprocess
import tempfile
from pathlib import Path

from designer.interactive_state import InteractiveState
from designer.pixel_renderer import PixelRenderer
from designer.ui_schema import KeyboardWidget, KnobWidget, PanelWidget, UIScene
from generator.rtl_generator import RTLGenerator


def build_scene():
    return UIScene(
        name="interaction_test",
        widgets=[
            PanelWidget(name="button_0", x=0, y=0, width=100, height=40),
            KnobWidget(name="knob_0", source="ui_state[0]", x=120, y=0,
                       width=64, height=64, min_value=0, max_value=65535),
            KeyboardWidget(name="keyboard_0", x=0, y=80, width=400, height=80),
        ],
        interactions=[
            {"trigger": "click", "source": "button_0", "actions": [
                {"action": "set", "target": "ui_state[0]", "value": 1234},
                {"action": "toggle", "target": "key_states[3]"},
                {"action": "set", "target": "ui_state[2]", "value": 4660},
                {"action": "toggle", "target": "ui_state[2]"},
            ]},
            {"trigger": "change", "source": "knob_0", "actions": [
                {"action": "set_event_value", "target": "ui_state[1]"},
                {"action": "add", "target": "ui_state[1]", "value": 5},
            ]},
            {"trigger": "key_down", "source": "keyboard_0", "actions": [
                {"action": "set_event_key", "target": "key_states[event]", "value": 1},
            ]},
            {"trigger": "press", "source": "button_0", "actions": [
                {"action": "set_event_value", "target": "key_states[4]"},
                {"action": "set", "target": "ui_state[3]", "value": 3},
                {"action": "add", "target": "ui_state[3]", "value": -5},
            ]},
            {"trigger": "release", "source": "button_0", "actions": [
                {"action": "set", "target": "ui_state[2]", "value": 65530},
                {"action": "add", "target": "ui_state[2]", "value": 10},
            ]},
        ],
    )


def test_schema_roundtrip():
    scene = build_scene()
    restored = UIScene.from_dict(scene.to_dict())
    assert restored.interactions == scene.interactions


def test_pc_actions():
    state = InteractiveState()
    state.apply_action({"action": "set", "target": "ui_state[0]", "value": 7})
    state.apply_action({"action": "add", "target": "ui_state[0]", "value": 5})
    state.apply_action({"action": "toggle", "target": "key_states[3]"})
    state.apply_action({"action": "set_event_value", "target": "ui_state[1]"}, 321)
    state.apply_action({"action": "set_event_key", "target": "key_states[event]", "value": 1}, 7)
    assert state.ui_values[0] == 12
    assert state.ui_values[1] == 321
    assert state.key_states[3] == 1
    assert state.key_states[7] == 1


def test_pc_edge_semantics_and_validation():
    state = InteractiveState()
    state.apply_action({"action": "set", "target": "ui_state[0]", "value": 65535})
    state.apply_action({"action": "add", "target": "ui_state[0]", "value": 1})
    assert state.ui_values[0] == 65535

    state.apply_action({"action": "set", "target": "ui_state[0]", "value": 0x1234})
    state.apply_action({"action": "toggle", "target": "ui_state[0]"})
    assert state.ui_values[0] == 0

    state.apply_action({"action": "set", "target": "ui_state[0]", "value": 3})
    state.apply_action({"action": "add", "target": "ui_state[0]", "value": -5})
    assert state.ui_values[0] == 0

    state.apply_action({"action": "set_event_value", "target": "key_states[4]"}, 2)
    assert state.key_states[4] == 1
    state.apply_action({"action": "set_event_key", "target": "key_states[event]", "value": "0"}, 4)
    assert state.key_states[4] == 0

    duplicate = build_scene()
    duplicate.widgets[1].name = duplicate.widgets[0].name
    try:
        RTLGenerator.validate_interaction_rules(duplicate)
    except ValueError as exc:
        assert "duplicate widget name" in str(exc)
    else:
        raise AssertionError("duplicate widget names were accepted")

    invalid_key = build_scene()
    invalid_key.interactions[0]["key_index"] = 88
    try:
        RTLGenerator.validate_interaction_rules(invalid_key)
    except ValueError as exc:
        assert "key_index" in str(exc)
    else:
        raise AssertionError("out-of-range key_index was accepted")

    renderer = PixelRenderer(16, 16)
    assert renderer._get_value_from_state(
        "ui_state [ 2 ]", {"ui_state": [0, 0, 456]}
    ) == 456


def test_generated_rtl():
    with tempfile.TemporaryDirectory(prefix="fpga_ui_interaction_") as temp_dir:
        output = Path(temp_dir)
        RTLGenerator().generate(build_scene(), output)
        manifest = json.loads((output / "generated_manifest.json").read_text())
        assert manifest["interaction_rules"] == 5
        assert manifest["widget_event_ids"] == {
            "button_0": 0, "knob_0": 1, "keyboard_0": 2
        }
        result = subprocess.run(
            ["iverilog", "-g2012", "-t", "null", "-s", "ui_interaction",
             str(output / "ui_interaction.v")],
            capture_output=True,
            text=True,
            check=False,
        )
        assert result.returncode == 0, result.stderr
        tb_path = Path(__file__).parent / "testbench" / "tb_ui_interaction.v"
        sim_path = output / "ui_interaction_sim.out"
        compile_result = subprocess.run(
            ["iverilog", "-g2012", "-o", str(sim_path), "-s", "tb_ui_interaction",
             str(tb_path), str(output / "ui_interaction.v")],
            capture_output=True,
            text=True,
            check=False,
        )
        assert compile_result.returncode == 0, compile_result.stderr
        run_result = subprocess.run(
            ["vvp", str(sim_path)], capture_output=True, text=True, check=False
        )
        assert run_result.returncode == 0 and "PASS: generated RTL event behavior" in run_result.stdout, (
            run_result.stdout + run_result.stderr
        )


if __name__ == "__main__":
    test_schema_roundtrip()
    test_pc_actions()
    test_pc_edge_semantics_and_validation()
    test_generated_rtl()
    print("PASS: interaction schema, PC actions, and generated RTL")
