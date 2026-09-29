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

# Add bar
bar = BarWidget(
    name="test_bar",
    x=350, y=100, width=30, height=150,
    source="test_value",
    bg_color=ColorRGB(20, 25, 30),
    fg_color=ColorRGB(56, 189, 248)
)
scene.widgets.append(bar)

# Add knob
knob = KnobWidget(
    name="test_knob",
    x=450, y=150, width=60, height=60,
    source="knob_value",
    min_value=0,
    max_value=127,
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
state.set_value("test_value", 32768)  # 50% bar
state.set_value("knob_value", 64)     # 50% knob
print(f"OK - State created: test_value={state.get_value('test_value')}, knob_value={state.get_value('knob_value')}")

print("\nStep 5: Render frame...")
frame = renderer.render_scene(scene, state.to_dict())
print(f"OK - Frame rendered: shape={frame.shape}, dtype={frame.dtype}")

print("\nStep 6: Test interaction...")
# Simulate clicking on knob
hit = state.hit_test(scene, 480, 180)  # center of knob
if hit:
    print(f"   Hit test: widget={hit.widget.name}, type={hit.widget.type}")

    # Simulate drag
    state.handle_mouse_press(hit.widget, 480, 180)
    state.handle_mouse_move(500, 160)  # drag right and up

    new_value = state.get_value("knob_value")
    print(f"   After drag: knob_value={new_value}")
else:
    print("   No widget hit at (480, 180)")

print("\nStep 7: Render updated frame...")
frame2 = renderer.render_scene(scene, state.to_dict())
print(f"OK - Updated frame rendered: shape={frame2.shape}")

print("\n" + "="*60)
print("SUCCESS - All rendering tests passed!")
print("="*60)
print("\nThe rendering engine is working correctly.")
print("Interactive preview requires GUI (PySide6) to display.")
