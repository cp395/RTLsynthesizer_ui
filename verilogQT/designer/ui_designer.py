#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FPGA UI Designer - Main Application
基于 PySide6 的可视化 UI 设计器 - 完整版
"""

import sys
import json
import numpy as np
from pathlib import Path

# Prefer UTF-8 on Windows without replacing/closing the process streams when
# this module is imported by a test or another application.
if sys.platform == 'win32':
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')

from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QSplitter, QListWidget, QGraphicsView, QGraphicsScene,
    QPushButton, QLabel, QSpinBox, QLineEdit, QComboBox,
    QGroupBox, QFormLayout, QColorDialog, QFileDialog, QMessageBox,
    QGraphicsRectItem, QGraphicsTextItem, QDialog, QCheckBox,
    QPlainTextEdit, QDialogButtonBox
)
from PySide6.QtCore import Qt, QRectF, QPointF, Signal, QTimer
from PySide6.QtGui import QColor, QPen, QBrush, QPainter, QImage, QPixmap

try:
    # Package imports (for example ``python -m designer.ui_designer``).
    from .ui_schema import *
    from .pixel_renderer import PixelRenderer
except ImportError:
    # Keep the existing direct/script entry points working.
    from ui_schema import *
    from pixel_renderer import PixelRenderer


class DesignCanvas(QGraphicsView):
    """设计画布"""

    widget_selected = Signal(object)
    scene_changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.scene = QGraphicsScene()
        self.setScene(self.scene)

        self.setBackgroundBrush(QBrush(QColor(5, 7, 12)))

        # 抗锯齿
        self.setRenderHint(QPainter.Antialiasing)

        self.ui_scene = UIScene()
        self.ui_scene.name = "new_scene"
        self.ui_scene.width = 1280
        self.ui_scene.height = 720
        self.ui_scene.bg_color = ColorRGB(5, 7, 12)
        # 1280x720 画布
        self.scene.setSceneRect(0, 0, self.ui_scene.width, self.ui_scene.height)

        self.selected_widget = None
        self.widget_graphics_map = {}  # widget -> graphics item 映射

    def add_widget(self, widget_type: str):
        """添加控件"""
        # 默认位置和大小
        x, y = 100, 100
        w, h = 200, 100

        if widget_type == "panel":
            widget = PanelWidget(
                type="panel", name=f"panel_{len(self.ui_scene.widgets)}",
                x=x, y=y, width=w, height=h,
                bg_color=ColorRGB(15, 19, 28),
                border_color=ColorRGB(50, 70, 100),
                border_width=2
            )
        elif widget_type == "text":
            widget = TextWidget(
                type="text", name=f"text_{len(self.ui_scene.widgets)}",
                x=x, y=y, width=w, height=30,
                text="Text Label",
                font_size=16,
                color=ColorRGB(200, 210, 230)
            )
        elif widget_type == "bar":
            widget = BarWidget(
                type="bar", name=f"bar_{len(self.ui_scene.widgets)}",
                x=x, y=y, width=w, height=20,
                source="ui_state[0]",
                max_value=100,
                fg_color=ColorRGB(56, 189, 248),
                bg_color=ColorRGB(30, 40, 60)
            )
        elif widget_type == "spectrum":
            widget = SpectrumWidget(
                type="spectrum", name=f"spectrum_{len(self.ui_scene.widgets)}",
                x=x, y=y, width=600, height=240,
                bars=64,
                source="fft_bins",
                bar_color=ColorRGB(56, 189, 248),
                bg_color=ColorRGB(10, 13, 18)
            )
        elif widget_type == "waveform":
            widget = WaveformWidget(
                type="waveform", name=f"waveform_{len(self.ui_scene.widgets)}",
                x=x, y=y, width=600, height=200,
                samples=128,
                source="pcm_buffer",
                line_color=ColorRGB(110, 231, 183),
                bg_color=ColorRGB(10, 13, 18),
                line_width=2
            )
        elif widget_type == "keyboard":
            widget = KeyboardWidget(
                type="keyboard", name=f"keyboard_{len(self.ui_scene.widgets)}",
                x=x, y=y, width=700, height=120,
                start_note=48,
                keys=25,
                source="key_states",
                white_key_color=ColorRGB(240, 240, 245),
                black_key_color=ColorRGB(20, 25, 35),
                pressed_color=ColorRGB(56, 189, 248)
            )
        elif widget_type == "knob":
            widget = KnobWidget(
                type="knob", name=f"knob_{len(self.ui_scene.widgets)}",
                x=x, y=y, width=80, height=80,
                source="ui_state[0]",
                min_value=0,
                max_value=127,
                fg_color=ColorRGB(56, 189, 248),
                bg_color=ColorRGB(30, 40, 60)
            )
        else:
            return

        self.ui_scene.widgets.append(widget)
        self.redraw()
        self.scene_changed.emit()

    def load_scene(self, scene: UIScene):
        """加载场景"""
        self.ui_scene = scene
        self.selected_widget = None
        self.redraw()
        self.scene_changed.emit()

    def redraw(self):
        """重绘画布"""
        self.scene.clear()
        self.widget_graphics_map.clear()

        self.scene.setSceneRect(
            0, 0, self.ui_scene.width, self.ui_scene.height
        )

        # 更新背景色
        bg = self.ui_scene.bg_color
        self.setBackgroundBrush(QBrush(QColor(bg.r, bg.g, bg.b)))

        # Match the reference renderer: hidden widgets are skipped and
        # visible widgets are painted from low to high layer.
        for widget in sorted(self.ui_scene.widgets, key=lambda item: item.layer):
            if not widget.visible:
                continue

            if widget.type == "panel":
                item = self._draw_panel(widget)
            elif widget.type == "text":
                item = self._draw_text(widget)
            elif widget.type == "bar":
                item = self._draw_bar(widget)
            elif widget.type == "spectrum":
                item = self._draw_spectrum(widget)
            elif widget.type == "waveform":
                item = self._draw_waveform(widget)
            elif widget.type == "keyboard":
                item = self._draw_keyboard(widget)
            elif widget.type == "knob":
                item = self._draw_knob(widget)
            else:
                continue

            if item:
                # Dataclass widgets are mutable and therefore unhashable.
                self.widget_graphics_map[id(widget)] = item

    def _draw_panel(self, widget: PanelWidget):
        """绘制面板"""
        bg = widget.bg_color
        border = widget.border_color

        rect = self.scene.addRect(
            widget.x, widget.y, widget.width, widget.height,
            QPen(QColor(border.r, border.g, border.b), widget.border_width),
            QBrush(QColor(bg.r, bg.g, bg.b))
        )
        rect.setData(0, widget)
        rect.setFlag(QGraphicsRectItem.ItemIsSelectable)
        return rect

    def _draw_text(self, widget: TextWidget):
        """绘制文本"""
        text = self.scene.addText(widget.text)
        text.setPos(widget.x, widget.y)
        text.setDefaultTextColor(QColor(widget.color.r, widget.color.g, widget.color.b))
        text.setData(0, widget)
        text.setFlag(QGraphicsTextItem.ItemIsSelectable)
        return text

    def _draw_bar(self, widget: BarWidget):
        """绘制进度条"""
        # 背景
        bg_rect = self.scene.addRect(
            widget.x, widget.y, widget.width, widget.height,
            QPen(Qt.NoPen),
            QBrush(QColor(widget.bg_color.r, widget.bg_color.g, widget.bg_color.b))
        )
        bg_rect.setData(0, widget)
        bg_rect.setFlag(QGraphicsRectItem.ItemIsSelectable)

        # 前景 (50% 示例)
        fg_width = widget.width // 2
        self.scene.addRect(
            widget.x, widget.y, fg_width, widget.height,
            QPen(Qt.NoPen),
            QBrush(QColor(widget.fg_color.r, widget.fg_color.g, widget.fg_color.b))
        )

        return bg_rect

    def _draw_spectrum(self, widget: SpectrumWidget):
        """绘制频谱占位"""
        rect = self.scene.addRect(
            widget.x, widget.y, widget.width, widget.height,
            QPen(QColor(100, 120, 160), 2),
            QBrush(QColor(widget.bg_color.r, widget.bg_color.g, widget.bg_color.b))
        )
        rect.setData(0, widget)
        rect.setFlag(QGraphicsRectItem.ItemIsSelectable)

        label = self.scene.addText(f"SPECTRUM\n{widget.bars} bars")
        label.setPos(widget.x + 10, widget.y + 10)
        label.setDefaultTextColor(QColor(150, 170, 200))

        return rect

    def _draw_waveform(self, widget: WaveformWidget):
        """绘制波形占位"""
        rect = self.scene.addRect(
            widget.x, widget.y, widget.width, widget.height,
            QPen(QColor(100, 120, 160), 2),
            QBrush(QColor(widget.bg_color.r, widget.bg_color.g, widget.bg_color.b))
        )
        rect.setData(0, widget)
        rect.setFlag(QGraphicsRectItem.ItemIsSelectable)

        label = self.scene.addText(f"WAVEFORM\n{widget.samples} samples")
        label.setPos(widget.x + 10, widget.y + 10)
        label.setDefaultTextColor(QColor(150, 170, 200))

        return rect

    def _draw_keyboard(self, widget: KeyboardWidget):
        """绘制键盘占位"""
        rect = self.scene.addRect(
            widget.x, widget.y, widget.width, widget.height,
            QPen(QColor(100, 120, 160), 2),
            QBrush(QColor(240, 240, 245))
        )
        rect.setData(0, widget)
        rect.setFlag(QGraphicsRectItem.ItemIsSelectable)

        label = self.scene.addText(f"KEYBOARD\n{widget.keys} keys from note {widget.start_note}")
        label.setPos(widget.x + 10, widget.y + 10)
        label.setDefaultTextColor(QColor(60, 70, 80))

        return rect

    def _draw_knob(self, widget: KnobWidget):
        """绘制旋钮占位"""
        ellipse = self.scene.addEllipse(
            widget.x, widget.y, widget.width, widget.height,
            QPen(QColor(widget.fg_color.r, widget.fg_color.g, widget.fg_color.b), 2),
            QBrush(QColor(widget.bg_color.r, widget.bg_color.g, widget.bg_color.b))
        )
        ellipse.setData(0, widget)
        ellipse.setFlag(QGraphicsRectItem.ItemIsSelectable)

        return ellipse

    def mousePressEvent(self, event):
        """鼠标点击选择控件"""
        item = self.itemAt(event.pos())
        if item:
            widget = item.data(0)
            if widget:
                self.selected_widget = widget
                self.widget_selected.emit(widget)
        super().mousePressEvent(event)

    def delete_selected(self):
        """删除选中的控件"""
        if self.selected_widget and self.selected_widget in self.ui_scene.widgets:
            self.ui_scene.widgets.remove(self.selected_widget)
            self.selected_widget = None
            self.redraw()
            self.scene_changed.emit()


class PropertyPanel(QWidget):
    """属性面板"""

    property_changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.current_widget = None
        self.canvas = None
        self.init_ui()

    def set_canvas(self, canvas):
        """设置画布引用"""
        self.canvas = canvas

    def clear_widget(self):
        """清除已删除或已卸载控件的属性引用。"""
        self.current_widget = None
        self.blockSignals(True)
        try:
            self.name_edit.clear()
            self.x_spin.setValue(0)
            self.y_spin.setValue(0)
            self.width_spin.setValue(1)
            self.height_spin.setValue(1)
            self.visible_check.setChecked(False)
            while self.special_layout.rowCount() > 0:
                self.special_layout.removeRow(0)
        finally:
            self.blockSignals(False)

    def init_ui(self):
        layout = QVBoxLayout()

        self.title_label = QLabel("Properties")
        self.title_label.setStyleSheet("font-weight: bold; font-size: 14px;")
        layout.addWidget(self.title_label)

        # 基本属性组
        basic_group = QGroupBox("Basic")
        basic_layout = QFormLayout()

        self.name_edit = QLineEdit()
        self.name_edit.textChanged.connect(self.on_property_changed)

        self.x_spin = QSpinBox()
        self.x_spin.setRange(0, 1280)
        self.x_spin.valueChanged.connect(self.on_property_changed)

        self.y_spin = QSpinBox()
        self.y_spin.setRange(0, 720)
        self.y_spin.valueChanged.connect(self.on_property_changed)

        self.width_spin = QSpinBox()
        self.width_spin.setRange(1, 1280)
        self.width_spin.valueChanged.connect(self.on_property_changed)

        self.height_spin = QSpinBox()
        self.height_spin.setRange(1, 720)
        self.height_spin.valueChanged.connect(self.on_property_changed)

        self.visible_check = QCheckBox()
        self.visible_check.setChecked(True)
        self.visible_check.stateChanged.connect(self.on_property_changed)

        basic_layout.addRow("Name:", self.name_edit)
        basic_layout.addRow("X:", self.x_spin)
        basic_layout.addRow("Y:", self.y_spin)
        basic_layout.addRow("Width:", self.width_spin)
        basic_layout.addRow("Height:", self.height_spin)
        basic_layout.addRow("Visible:", self.visible_check)

        basic_group.setLayout(basic_layout)
        layout.addWidget(basic_group)

        # 特殊属性组
        self.special_group = QGroupBox("Widget Properties")
        self.special_layout = QFormLayout()
        self.special_group.setLayout(self.special_layout)
        layout.addWidget(self.special_group)

        layout.addStretch()
        self.setLayout(layout)

    def on_property_changed(self):
        """属性修改"""
        if self.current_widget:
            # 更新基本属性
            self.current_widget.name = self.name_edit.text()
            self.current_widget.x = self.x_spin.value()
            self.current_widget.y = self.y_spin.value()
            self.current_widget.width = self.width_spin.value()
            self.current_widget.height = self.height_spin.value()
            self.current_widget.visible = self.visible_check.isChecked()

            # 重绘画布
            if self.canvas:
                self.canvas.redraw()

            self.property_changed.emit()

    def load_widget(self, widget: Widget):
        """加载控件属性"""
        # Ignore value-change signals while replacing the editor contents.
        # QSignalBlocker on the panel itself does not block child widgets.
        self.current_widget = None

        # 阻止信号触发
        self.blockSignals(True)

        scene_width = self.canvas.ui_scene.width if self.canvas else 1280
        scene_height = self.canvas.ui_scene.height if self.canvas else 720
        self.x_spin.setRange(0, max(0, scene_width))
        self.y_spin.setRange(0, max(0, scene_height))
        self.width_spin.setRange(1, max(1, scene_width))
        self.height_spin.setRange(1, max(1, scene_height))
        self.name_edit.setText(widget.name)
        self.x_spin.setValue(widget.x)
        self.y_spin.setValue(widget.y)
        self.width_spin.setValue(widget.width)
        self.height_spin.setValue(widget.height)
        self.visible_check.setChecked(widget.visible)

        # 清空特殊属性
        while self.special_layout.rowCount() > 0:
            self.special_layout.removeRow(0)

        # 根据类型添加特殊属性
        if widget.type == "text":
            text_edit = QLineEdit(widget.text)
            text_edit.textChanged.connect(lambda: setattr(widget, 'text', text_edit.text()))
            text_edit.textChanged.connect(self.on_property_changed)
            self.special_layout.addRow("Text:", text_edit)

            source_edit = QLineEdit(getattr(widget, 'source', ''))
            source_edit.setPlaceholderText("empty=static, filename=FPGA status")
            source_edit.textChanged.connect(lambda: setattr(widget, 'source', source_edit.text()))
            source_edit.textChanged.connect(self.on_property_changed)
            self.special_layout.addRow("Source:", source_edit)

            font_spin = QSpinBox()
            font_spin.setRange(8, 72)
            font_spin.setValue(widget.font_size)
            font_spin.valueChanged.connect(lambda v: setattr(widget, 'font_size', v))
            font_spin.valueChanged.connect(self.on_property_changed)
            self.special_layout.addRow("Font Size:", font_spin)

        elif widget.type == "bar":
            source_edit = QLineEdit(widget.source)
            source_edit.textChanged.connect(lambda: setattr(widget, 'source', source_edit.text()))
            source_edit.textChanged.connect(self.on_property_changed)
            self.special_layout.addRow("Source:", source_edit)

            max_spin = QSpinBox()
            max_spin.setRange(1, 65535)
            max_spin.setValue(widget.max_value)
            max_spin.valueChanged.connect(lambda v: setattr(widget, 'max_value', v))
            max_spin.valueChanged.connect(self.on_property_changed)
            self.special_layout.addRow("Max Value:", max_spin)

        elif widget.type == "spectrum":
            bars_spin = QSpinBox()
            # The flattened RTL interface exposes 128 FFT bins.
            bars_spin.setRange(1, 128)
            bars_spin.setValue(widget.bars)
            bars_spin.valueChanged.connect(lambda v: setattr(widget, 'bars', v))
            bars_spin.valueChanged.connect(self.on_property_changed)
            self.special_layout.addRow("Bars:", bars_spin)

            source_edit = QLineEdit(widget.source)
            source_edit.textChanged.connect(lambda: setattr(widget, 'source', source_edit.text()))
            source_edit.textChanged.connect(self.on_property_changed)
            self.special_layout.addRow("Source:", source_edit)

        elif widget.type == "waveform":
            samples_spin = QSpinBox()
            # The compact RTL bus contains 128 signed 8-bit PCM samples.
            samples_spin.setRange(1, 128)
            samples_spin.setValue(widget.samples)
            samples_spin.valueChanged.connect(lambda v: setattr(widget, 'samples', v))
            samples_spin.valueChanged.connect(self.on_property_changed)
            self.special_layout.addRow("Samples:", samples_spin)

            source_edit = QLineEdit(widget.source)
            source_edit.textChanged.connect(lambda: setattr(widget, 'source', source_edit.text()))
            source_edit.textChanged.connect(self.on_property_changed)
            self.special_layout.addRow("Source:", source_edit)

        elif widget.type == "keyboard":
            start_spin = QSpinBox()
            start_spin.setRange(0, 127)
            start_spin.setValue(widget.start_note)
            start_spin.valueChanged.connect(lambda v: setattr(widget, 'start_note', v))
            start_spin.valueChanged.connect(self.on_property_changed)
            self.special_layout.addRow("Start Note:", start_spin)

            keys_spin = QSpinBox()
            keys_spin.setRange(1, max(1, 128 - widget.start_note))
            keys_spin.setValue(widget.keys)
            keys_spin.valueChanged.connect(lambda v: setattr(widget, 'keys', v))
            keys_spin.valueChanged.connect(self.on_property_changed)
            start_spin.valueChanged.connect(
                lambda v: keys_spin.setMaximum(max(1, 128 - v))
            )
            self.special_layout.addRow("Keys:", keys_spin)

        # 恢复信号
        self.blockSignals(False)
        self.current_widget = widget


class PreviewDialog(QDialog):
    """预览对话框"""

    def __init__(self, image: QImage, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Preview - Rendered Frame")
        self.setGeometry(100, 100, 1300, 750)

        layout = QVBoxLayout()

        label = QLabel()
        pixmap = QPixmap.fromImage(image)
        label.setPixmap(pixmap)
        label.setScaledContents(False)

        layout.addWidget(label)
        self.setLayout(layout)


class InteractionEditorDialog(QDialog):
    """Edit scene interaction rules as readable JSON."""

    def __init__(self, scene: UIScene, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Edit Interactions")
        self.resize(720, 520)
        self.scene = scene
        layout = QVBoxLayout(self)
        layout.addWidget(QLabel(
            'Rules use trigger/source/actions. Example: '
            '{"trigger":"click","source":"button_0",'
            '"actions":[{"action":"set","target":"ui_state[0]","value":65535}]}'
        ))
        self.editor = QPlainTextEdit()
        self.editor.setPlainText(json.dumps(scene.interactions, indent=2, ensure_ascii=True))
        layout.addWidget(self.editor)
        buttons = QDialogButtonBox(QDialogButtonBox.Save | QDialogButtonBox.Cancel)
        buttons.accepted.connect(self._save)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

    def _save(self):
        try:
            rules = json.loads(self.editor.toPlainText() or "[]")
            if not isinstance(rules, list) or any(not isinstance(item, dict) for item in rules):
                raise ValueError("interactions must be a JSON array of objects")
            # Use the same rule validator as RTL generation so a preview cannot
            # accept a JSON rule that will later crash or generate differently.
            from generator.rtl_generator import RTLGenerator
            candidate = UIScene(
                name=self.scene.name,
                width=self.scene.width,
                height=self.scene.height,
                bg_color=self.scene.bg_color,
                widgets=self.scene.widgets,
                interactions=rules,
            )
            RTLGenerator.validate_interaction_rules(candidate)
            self.scene.interactions = rules
            self.accept()
        except (json.JSONDecodeError, ValueError, TypeError, ImportError) as exc:
            QMessageBox.warning(self, "Invalid interactions", str(exc))


class MainWindow(QMainWindow):
    """主窗口"""

    def __init__(self):
        super().__init__()
        self.setWindowTitle("FPGA UI Designer - Tang Mega 60K")
        self.setGeometry(100, 100, 1600, 900)

        self.current_file = None
        self.is_modified = False

        self.init_ui()

    def init_ui(self):
        # 中心部件
        central = QWidget()
        self.setCentralWidget(central)

        layout = QHBoxLayout()

        # 左侧：控件列表
        left_panel = QWidget()
        left_layout = QVBoxLayout()

        title = QLabel("Widgets")
        title.setStyleSheet("font-weight: bold; font-size: 14px;")
        left_layout.addWidget(title)

        self.widget_list = QListWidget()
        widgets = ["Panel", "Text", "Bar", "Spectrum", "Waveform",
                   "Knob", "Keyboard"]
        self.widget_list.addItems(widgets)
        self.widget_list.itemDoubleClicked.connect(self.on_add_widget)
        left_layout.addWidget(self.widget_list)

        add_btn = QPushButton("Add Widget")
        add_btn.clicked.connect(self.on_add_widget)
        left_layout.addWidget(add_btn)

        del_btn = QPushButton("Delete Selected")
        del_btn.clicked.connect(self.on_delete_widget)
        left_layout.addWidget(del_btn)

        left_panel.setLayout(left_layout)
        left_panel.setMaximumWidth(200)

        # 中间：画布
        self.canvas = DesignCanvas()
        self.canvas.widget_selected.connect(self.on_widget_selected)
        self.canvas.scene_changed.connect(self.on_scene_changed)

        # 右侧：属性面板
        self.property_panel = PropertyPanel()
        self.property_panel.set_canvas(self.canvas)
        self.property_panel.property_changed.connect(self.on_scene_changed)
        self.property_panel.setMaximumWidth(300)

        # 分割器
        splitter = QSplitter()
        splitter.addWidget(left_panel)
        splitter.addWidget(self.canvas)
        splitter.addWidget(self.property_panel)
        splitter.setStretchFactor(1, 3)

        layout.addWidget(splitter)
        central.setLayout(layout)

        # 工具栏
        self.create_toolbar()

        # 状态栏
        self.statusBar().showMessage("Ready")

    def create_toolbar(self):
        """创建工具栏"""
        toolbar = self.addToolBar("Main")

        new_action = toolbar.addAction("New")
        new_action.triggered.connect(self.on_new)

        open_action = toolbar.addAction("Open")
        open_action.triggered.connect(self.on_open)

        save_action = toolbar.addAction("Save")
        save_action.triggered.connect(self.on_save)

        save_as_action = toolbar.addAction("Save As")
        save_as_action.triggered.connect(self.on_save_as)

        toolbar.addSeparator()

        preview_action = toolbar.addAction("Preview")
        preview_action.triggered.connect(self.on_preview)

        interaction_action = toolbar.addAction("Interactions")
        interaction_action.triggered.connect(self.on_edit_interactions)

        generate_action = toolbar.addAction("Generate RTL")
        generate_action.triggered.connect(self.on_generate_rtl)

    def on_edit_interactions(self):
        """Open the scene-level interaction rule editor."""
        dialog = InteractionEditorDialog(self.canvas.ui_scene, self)
        if dialog.exec():
            self.on_scene_changed()

    def on_add_widget(self):
        """添加控件"""
        current = self.widget_list.currentItem()
        if current:
            widget_type = current.text().lower()
            self.canvas.add_widget(widget_type)

    def on_delete_widget(self):
        """删除控件"""
        self.canvas.delete_selected()
        self.property_panel.clear_widget()

    def on_widget_selected(self, widget):
        """控件被选中"""
        self.property_panel.load_widget(widget)
        self.statusBar().showMessage(f"Selected: {widget.name} ({widget.type})")

    def on_scene_changed(self):
        """场景修改"""
        self.is_modified = True
        self.update_title()

    def update_title(self):
        """更新标题"""
        title = "FPGA UI Designer - Tang Mega 60K"
        if self.current_file:
            title += f" - {Path(self.current_file).name}"
        if self.is_modified:
            title += " *"
        self.setWindowTitle(title)

    def on_new(self):
        """新建项目"""
        if not self._confirm_save_if_needed():
            return

        self.canvas.ui_scene = UIScene()
        self.canvas.ui_scene.name = "new_scene"
        self.canvas.ui_scene.width = 1280
        self.canvas.ui_scene.height = 720
        self.canvas.ui_scene.bg_color = ColorRGB(5, 7, 12)
        self.canvas.selected_widget = None
        self.property_panel.clear_widget()
        self.canvas.redraw()

        self.current_file = None
        self.is_modified = False
        self.update_title()
        self.statusBar().showMessage("New scene created")

    def on_open(self):
        """打开项目"""
        filename, _ = QFileDialog.getOpenFileName(
            self, "Open UI Scene", "", "JSON Files (*.json)"
        )
        if filename and self._confirm_save_if_needed():
            try:
                scene = UIScene.from_json(filename)
                self.canvas.load_scene(scene)
                self.property_panel.clear_widget()
                self.current_file = filename
                self.is_modified = False
                self.update_title()
                self.statusBar().showMessage(f"Loaded: {filename}")
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to load file:\n{e}")

    def on_save(self):
        """保存项目"""
        if self.current_file:
            return self._save_to_file(self.current_file)
        return self.on_save_as()

    def on_save_as(self):
        """另存为"""
        filename, _ = QFileDialog.getSaveFileName(
            self, "Save UI Scene", "", "JSON Files (*.json)"
        )
        if filename:
            return self._save_to_file(filename)
        return False

    def _save_to_file(self, filename):
        """保存到文件"""
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(self.canvas.ui_scene.to_dict(), f, indent=2)
            self.current_file = filename
            self.is_modified = False
            self.update_title()
            self.statusBar().showMessage(f"Saved: {filename}")
            return True
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to save file:\n{e}")
            return False

    def _confirm_save_if_needed(self):
        """Return False when the user cancels or saving fails."""
        if not self.is_modified:
            return True

        reply = QMessageBox.question(
            self, "Unsaved Changes",
            "Do you want to save changes?",
            QMessageBox.Save | QMessageBox.Discard | QMessageBox.Cancel
        )
        if reply == QMessageBox.Save:
            return self.on_save()
        return reply == QMessageBox.Discard

    def on_preview(self):
        """预览渲染 - 使用交互式预览"""
        try:
            # 尝试加载交互式预览
            try:
                try:
                    from .interactive_preview import InteractivePreviewDialog
                except ImportError:
                    from interactive_preview import InteractivePreviewDialog

                # 显示交互式预览
                dialog = InteractivePreviewDialog(self.canvas.ui_scene, self)
                dialog.exec()

                self.statusBar().showMessage("Interactive preview closed")
            except ImportError as ie:
                # 降级到静态预览
                QMessageBox.warning(
                    self, "Interactive Preview Unavailable",
                    f"Interactive preview module not found: {ie}\nUsing static preview instead."
                )
                self._static_preview()
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Preview failed:\n{e}")

    def _static_preview(self):
        """静态预览（原方法）"""
        renderer = PixelRenderer()

        # 模拟 UI 状态 - 生成动态测试数据
        fft_bins = [int(128 + 100 * np.sin(i * 0.1)) for i in range(128)]
        ui_state = [32768] * 32  # 50% 默认值
        ui_state[0] = 40000  # OP1
        ui_state[1] = 50000  # OP2
        ui_state[2] = 30000  # OP3
        ui_state[3] = 45000  # OP4
        ui_state[4] = 35000  # OP5
        ui_state[5] = 55000  # OP6

        # 生成 PCM 波形数据（正弦波）
        pcm_buffer = [int(120 * np.sin(i * 2 * np.pi / 128)) for i in range(128)]

        # 生成键盘状态（模拟按下 C、E、G 和弦）
        key_states = [0] * 128
        key_states[0] = 1   # C
        key_states[4] = 1   # E
        key_states[7] = 1   # G

        state_dict = {
            "fft_bins": fft_bins,
            "ui_state": ui_state,
            "pcm_buffer": pcm_buffer,
            "key_states": key_states,
        }

        frame = renderer.render_scene(self.canvas.ui_scene, state_dict)

        # 转换为 QImage
        height, width, channels = frame.shape
        bytes_per_line = channels * width
        qimage = QImage(frame.data, width, height, bytes_per_line, QImage.Format_RGB888)

        # 显示预览对话框
        dialog = PreviewDialog(qimage, self)
        dialog.exec()

        self.statusBar().showMessage("Static preview generated")

    def on_generate_rtl(self):
        """生成 RTL"""
        output_dir = QFileDialog.getExistingDirectory(
            self, "Select Output Directory"
        )
        if output_dir:
            try:
                try:
                    from generator.rtl_generator import RTLGenerator
                except ModuleNotFoundError:
                    from rtl_generator import RTLGenerator
                generator = RTLGenerator()
                generator.generate(self.canvas.ui_scene, Path(output_dir))
                QMessageBox.information(
                    self, "Success",
                    "Generated exactly one replaceable Verilog file:\n"
                    f"{Path(output_dir) / 'ui_generated_scene.v'}"
                )
                self.statusBar().showMessage(f"RTL generated: {output_dir}")
            except Exception as e:
                QMessageBox.critical(self, "Error", f"RTL generation failed:\n{e}")

    def closeEvent(self, event):
        """窗口关闭"""
        if self._confirm_save_if_needed():
            event.accept()
        else:
            event.ignore()


def main():
    app = QApplication(sys.argv)

    # 设置样式
    app.setStyle("Fusion")

    window = MainWindow()
    window.show()

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
