#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Font Generator - 从 PIL 字体生成 Verilog ROM
"""

from PIL import Image, ImageDraw, ImageFont
import numpy as np
from pathlib import Path


class FontGenerator:
    """生成字体 ROM"""

    def __init__(self, font_size: int = 16):
        if font_size <= 0:
            raise ValueError("font_size must be positive")
        self.font_size = font_size
        self.char_width = 8 if font_size == 16 else 16
        self.char_height = font_size
        self.row_addr_width = max(1, (self.char_height - 1).bit_length())

    def render_char(self, char: str, font=None) -> np.ndarray:
        """渲染单个字符为位图"""
        img = Image.new('L', (self.char_width, self.char_height), color=0)
        draw = ImageDraw.Draw(img)

        if font:
            draw.text((0, 0), char, fill=255, font=font)
        else:
            # 使用默认字体
            draw.text((0, 0), char, fill=255)

        return np.array(img) > 128  # 二值化

    def generate_ascii_font_rom(self, output_path: Path, chars: str = None):
        """生成 ASCII 字体 ROM"""
        if chars is None:
            # 默认字符集：可打印 ASCII
            chars = ''.join(chr(i) for i in range(32, 127))

        print(f"Generating font ROM for {len(chars)} characters...")

        # 渲染所有字符
        bitmaps = []
        for char in chars:
            bitmap = self.render_char(char)
            bitmaps.append(bitmap)

        # 生成 Verilog ROM
        code = []
        code.append("//")
        code.append(f"// Font ROM - {self.char_width}×{self.char_height}")
        code.append(f"// Characters: {len(chars)}")
        code.append("//")
        code.append("")
        code.append("module font_rom (")
        code.append("    input wire clk,")
        code.append("    input wire [7:0] char_code,")
        code.append(f"    input wire [{self.row_addr_width-1}:0] row,")
        code.append(f"    output reg [{self.char_width-1}:0] pixels")
        code.append(");")
        code.append("")
        code.append("    always @(posedge clk) begin")
        code.append("        case (char_code)")

        for i, (char, bitmap) in enumerate(zip(chars, bitmaps)):
            char_code = ord(char)
            code.append(f"            8'd{char_code}: begin // '{char}'")
            code.append("                case (row)")

            for row_idx in range(self.char_height):
                row_data = bitmap[row_idx]
                # 转换为二进制字符串
                bin_str = ''.join('1' if pixel else '0' for pixel in row_data)
                code.append(
                    f"                    {self.row_addr_width}'d{row_idx}: "
                    f"pixels = {self.char_width}'b{bin_str};"
                )

            code.append(f"                    default: pixels = {self.char_width}'d0;")
            code.append("                endcase")
            code.append("            end")

        code.append("            default: begin")
        code.append("                case (row)")
        for row_idx in range(self.char_height):
            code.append(
                f"                    {self.row_addr_width}'d{row_idx}: "
                f"pixels = {self.char_width}'d0;"
            )
        code.append(f"                    default: pixels = {self.char_width}'d0;")
        code.append("                endcase")
        code.append("            end")
        code.append("        endcase")
        code.append("    end")
        code.append("")
        code.append("endmodule")

        output_path.write_text("\n".join(code), encoding='utf-8')
        print(f"[OK] Generated font ROM: {output_path}")

        return len(chars)

    def generate_mem_file(self, output_path: Path, chars: str = None):
        """生成 .mem 文件用于 BRAM 初始化"""
        if chars is None:
            chars = ''.join(chr(i) for i in range(32, 127))

        print(f"Generating .mem file for {len(chars)} characters...")

        bitmaps = []
        for char in chars:
            bitmap = self.render_char(char)
            bitmaps.append(bitmap)

        # 生成 .mem 格式
        lines = []
        lines.append(f"// Font ROM Memory Initialization File")
        lines.append(f"// {self.char_width}×{self.char_height} font")
        lines.append(f"// {len(chars)} characters")
        lines.append("")

        for i, (char, bitmap) in enumerate(zip(chars, bitmaps)):
            char_code = ord(char)
            lines.append(f"// Character '{char}' (0x{char_code:02X})")

            for row in bitmap:
                # 转换为十六进制
                value = 0
                for j, pixel in enumerate(row):
                    if pixel:
                        value |= (1 << (len(row) - 1 - j))

                lines.append(f"{value:0{(self.char_width+3)//4}X}")

        output_path.write_text("\n".join(lines), encoding='utf-8')
        print(f"[OK] Generated .mem file: {output_path}")


def generate_synth_font():
    """生成合成器界面专用字体"""
    # 合成器界面常用字符
    synth_chars = (
        # 字母
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "abcdefghijklmnopqrstuvwxyz"
        # 数字
        "0123456789"
        # 常用符号
        " .,:-+#%/\\|"
        # 音频符号
        "♪♫"  # 如果字体支持
    )

    # 只保留 ASCII
    synth_chars = ''.join(c for c in synth_chars if ord(c) < 128)

    generator = FontGenerator(font_size=16)

    output_dir = Path(__file__).parent.parent / "assets" / "fonts"
    output_dir.mkdir(parents=True, exist_ok=True)

    # 生成 Verilog ROM
    generator.generate_ascii_font_rom(
        output_dir / "font_8x16.v",
        chars=synth_chars
    )

    # 生成 .mem 文件
    generator.generate_mem_file(
        output_dir / "font_8x16.mem",
        chars=synth_chars
    )

    print("\n[OK] Synth font generation complete!")
    print(f"  Characters: {len(synth_chars)}")
    print(f"  Output: {output_dir}")


def generate_full_ascii_font():
    """生成完整 ASCII 字体"""
    generator = FontGenerator(font_size=16)

    output_dir = Path(__file__).parent.parent / "assets" / "fonts"
    output_dir.mkdir(parents=True, exist_ok=True)

    # 完整 ASCII (32~126)
    full_ascii = ''.join(chr(i) for i in range(32, 127))

    generator.generate_ascii_font_rom(
        output_dir / "font_8x16_full.v",
        chars=full_ascii
    )

    generator.generate_mem_file(
        output_dir / "font_8x16_full.mem",
        chars=full_ascii
    )

    print("\n[OK] Full ASCII font generation complete!")
    print(f"  Characters: {len(full_ascii)}")


if __name__ == "__main__":
    print("=" * 60)
    print("Font ROM Generator")
    print("=" * 60)
    print()

    # 生成合成器字体（精简）
    generate_synth_font()

    print()

    # 生成完整 ASCII 字体
    generate_full_ascii_font()

    print("\n" + "=" * 60)
    print("Font generation complete!")
    print("Add these files to your Gowin project.")
    print("=" * 60)
