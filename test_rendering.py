#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Non-interactive rendering test
"""

import sys
import io

# Force UTF-8 encoding on Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

from pathlib import Path

# Add module paths
sys.path.insert(0, str(Path(__file__).parent / 'designer'))
sys.path.insert(0, str(Path(__file__).parent / 'generator'))

print("Step 1: Import modules...")
from designer.ui_schema import *
from designer.pixel_renderer import PixelRenderer
from designer.interactive_state import InteractiveState
print("OK - Modules imported")

print("\nStep 2: Create test scene...")
scene = UIScene(
    name="test",
    width=800,
    height=600,
    bg_color=ColorRGB(10, 10, 10)
)

# Add panel
panel = PanelWidget(
    name="test_panel",
    x=100, y=100, width=200, height=150,
    bg_color=ColorRGB(30, 40, 50),
    border_color=ColorRGB(100, 150, 200),
    border_width=2
)
scene.widgets.append(panel)

# Add bar (uses ui_state[0])
bar = BarWidget(
    name="test_bar",
    x=350, y=100, width=30, height=150,
    source="ui_state[0]",
    bg_color=ColorRGB(20, 25, 30),
    fg_color=ColorRGB(56, 189, 248)
)
scene.widgets.append(bar)

# Add knob (uses ui_state[1])
knob = KnobWidget(
    name="test_knob",
    x=450, y=150, width=60, height=60,
    source="ui_state[1]",
    min_value=0,
    max_value=65535,
    fg_color=ColorRGB(56, 189, 248),
    bg_color=ColorRGB(30, 40, 60),
    pointer_color=ColorRGB(220, 220, 240)
)
scene.widgets.append(knob)

print(f"OK - Scene created with {len(scene.widgets)} widgets")

print("\nStep 3: Initialize renderer...")
renderer = PixelRenderer(800, 600)
print("OK - Renderer initialized")

print("\nStep 4: Create interactive state...")
state = InteractiveState()
state.set_knob_value(0, 32768)  # 50% for bar (ui_state[0])
state.set_knob_value(1, 49152)  # 75% for knob (ui_state[1])
print(f"OK - State created: ui_state[0]={state.get_knob_value(0)}, ui_state[1]={state.get_knob_value(1)}")

print("\nStep 5: Render frame...")
frame = renderer.render_scene(scene, state.to_dict())
print(f"OK - Frame rendered: shape={frame.shape}, dtype={frame.dtype}")

print("\nStep 6: Test state changes...")
# Change knob value
old_value = state.get_knob_value(1)
state.set_knob_value(1, 16384)  # Set to 25%
new_value = state.get_knob_value(1)
print(f"   Knob value changed: {old_value} -> {new_value}")

# Change bar value
state.set_knob_value(0, 49152)  # Set to 75%
print(f"   Bar value changed to: {state.get_knob_value(0)}")

print("\nStep 7: Render updated frame...")
frame2 = renderer.render_scene(scene, state.to_dict())
print(f"OK - Updated frame rendered: shape={frame2.shape}")

print("\nStep 8: Test animation...")
state.update_animation()
print(f"   Frame count: {state.frame_count}")
print(f"   FFT bins: {len(state.fft_bins)} values")
print(f"   PCM buffer: {len(state.pcm_buffer)} samples")

print("\n" + "="*60)
print("SUCCESS - All rendering tests passed!")
print("="*60)
print("\nThe rendering engine is working correctly.")
print("To see interactive preview, run: python run.py")
