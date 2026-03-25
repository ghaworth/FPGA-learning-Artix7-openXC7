#!/usr/bin/env python3
"""
Parse AoC 2025 Day 7 input.txt and generate hex numbers corresponding to splitter positions.
Each splitter row becomes 9 x 16-bit words (141 bits total, LSB = column 0).
"""
import sys
from pathlib import Path


def parse_line(line: str):
    """Convert a grid line to a 141-bit integer. 1 where '^', 0 elsewhere."""
    line = line.strip()
    if not line:
        return None
    result = 0
    for i, char in enumerate(line):
        if char == '^':
            result |= (1 << i)
    return result


def gen_hex(number: int):
    """Chop a 141-bit integer into 9 x 16-bit words, LSB first."""
    hex_result = []
    for i in range(9):
        hex_result.append(number & 0xFFFF)
        number >>= 16
    return hex_result


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} input.txt", file=sys.stderr)
        sys.exit(1)

    input_path = Path(sys.argv[1])
    output_path = input_path.parent / "splitters.hex"

    row_count = 0
    with open(input_path) as f_in, open(output_path, 'w') as f_out:
        for line in f_in:
            splitters = parse_line(line)
            if splitters:
                hex_list = gen_hex(splitters)
                for value in hex_list:
                    f_out.write(f"{value:04x}\n")
                row_count += 1

    map_path = input_path.parent / "splitter_map.hex"
    with open(input_path) as f_in, open(map_path, 'w') as f_out:
        for line in f_in:
            splitters = parse_line(line)
            if splitters is not None and splitters > 0:
                f_out.write(f"{splitters:036x}\n")

    print(f"Generated {output_path} with {row_count} splitter rows ({row_count * 9} hex words)")


if __name__ == "__main__":
    main()