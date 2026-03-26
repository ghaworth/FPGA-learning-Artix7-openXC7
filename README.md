# FPGA Learning: Artix-7 + openXC7

Hardware implementations on the Digilent Basys 3 (Xilinx Artix-7 XC7A35T) using the open-source openXC7 toolchain. No Vivado.

This repo is a companion to [FPGA-learning-iCE40-Yosys](https://github.com/ghaworth/FPGA-learning-iCE40-Yosys), which targets the Nandland Go Board (Lattice iCE40 HX1K). Designs that outgrow the iCE40's 1,280 logic cells move here — the Artix-7 provides 33,280 LCs with room for wider datapaths, UART output, and VGA visualisation.

## Structure

```
FPGA-learning-Artix7-openXC7/
├── lib/                           # Reusable component library (shared with iCE40 repo)
│   ├── io/
│   │   ├── debounce_switch.v      # Switch debouncing (parameterised for clock speed)
│   │   ├── uart_tx.v              # UART transmitter (Nandland, widened for 100MHz)
│   │   ├── uart_rx.v              # UART receiver (Nandland)
│   │   ├── vga_display.v          # VGA 640x480 timing generator
│   │   ├── value_to_bytes.v       # Parameterised value-to-byte serialiser
│   │   ├── mac_uart.py            # Python UART receiver script
│   │   ├── bin_to_bcd.v           # Binary to BCD (double-dabble)
│   │   └── scroll_display.v       # Scrolling 7-segment display
│   └── converters/
│       └── Binary_To_7Segment.v   # BCD to 7-segment encoding
├── projects/
│   ├── blinky/                    # Initial board test
│   └── aoc_2025/
│       └── day_07/
│           ├── day_07_top.v       # Top module: core + timer + UART + VGA pipeline
│           ├── day_07_core.v      # Beam splitting algorithm (part 1)
│           ├── day_07_timer.v     # Cycle counter
│           ├── day_07_capture.v   # Beam state capture for VGA framebuffer
│           ├── day_07_core_tb.v   # Self-checking testbench
│           ├── splitters.hex      # Block RAM data (packed 16-bit words)
│           ├── splitter_map.hex   # Splitter positions (141-bit rows for VGA)
│           ├── input.txt          # AoC puzzle input
│           ├── mac_uart.py        # UART receiver (configured for Linux)
│           ├── gen_input.py       # Input parser — generates both hex files
│           └── Makefile           # openXC7 build + simulation
├── constraints/
│   └── basys3.xdc                 # Full Basys 3 master constraints
├── .gitignore
└── README.md
```

## Advent of Code 2025

### Day 7: Beam Splitting (Part 1)

Simulates a beam propagating through a 141-wide grid of splitters across 70 rows. A tachyon beam enters at the centre and splits each time it hits a `^` splitter, with new beams continuing left and right.

- **Result**: 1672 splits (verified against simulation and AoC accepted answer)
- **Execution time**: 11,201 clock cycles = 0.112ms at 100MHz
- **UART output**: Sync header (`0xAA 0x55`), 2-byte result (little-endian), 4-byte cycle count
- **VGA output**: Real-time visualisation of beam propagation on 640×480 display — green splitters, red beam, animated playback at 1 row per second

**Architecture**: Button press triggers the core computation and cycle counter simultaneously. The capture module snapshots the 141-bit beam state after each row into a dual-port framebuffer. On completion, a state machine sequences sync bytes, result bytes, and timer bytes through a muxed UART transmitter. The VGA module independently reads the framebuffer and splitter map to render the display, with a playback counter controlling progressive row reveal.

**Modules**:
- `Day_07_Core` — 141-bit bitmask beam simulation with block RAM splitter data
- `Day_07_Timer` — cycle-accurate performance counter (start/stop interface)
- `Day_07_Capture` — edge-detects row completion, writes beam snapshots to framebuffer
- `VGA_Display` — 640×480 @ 60Hz timing generator with 25MHz pixel clock (100MHz / 4)
- `Value_To_Bytes` — parameterised N-bit to byte serialiser for UART transmission
- `uart_tx` — Nandland UART transmitter (parameterised baud rate)

**Techniques**: 141-bit wide bitmask operations, dual-port block RAM framebuffer, state machine with edge-detected transitions, hardware multiplexing of two serialisers to shared UART TX, VGA pixel clock division, `$readmemh` for block RAM initialisation, cycle-accurate performance measurement.

## Toolchain

The openXC7 flow uses entirely open-source tools — no Xilinx Vivado required:

1. **Yosys** — synthesis (`synth_xilinx`)
2. **nextpnr-xilinx** — place and route (with Project X-Ray chip database)
3. **fasm2frames** — FPGA assembly to frame data
4. **xc7frames2bit** — frame data to bitstream
5. **openFPGALoader** — JTAG programming
6. **Icarus Verilog** — simulation
7. **Verilator** — lint and static analysis

All tools built from source on Ubuntu 24.04 ARM64 (Parallels VM on Mac Studio M4).

## Building

Each project has its own Makefile:

```bash
cd projects/aoc_2025/day_07
make              # Build bitstream
make sim          # Run self-checking testbench
make program      # Program FPGA via JTAG
make clean        # Remove build artefacts
```

To regenerate hex files from puzzle input:

```bash
python3 gen_input.py input.txt
```

## Component Library

Reusable modules in `lib/` are shared across projects. Key modules widened for 100MHz:

- **uart_tx.v**: Clock counter widened from 8-bit to 16-bit for `CLKS_PER_BIT` > 255
- **debounce_switch.v**: Counter widened from 18-bit to 20-bit for 1,000,000-count limit
- **vga_display.v**: 640×480 VGA timing with pixel clock derived from 100MHz system clock
- **value_to_bytes.v**: Parameterised serialiser — N-bit value to sequential bytes

## Lessons Learned

- **Register width must match parameter values.** Changing clock frequency without checking counter widths causes silent overflow. Verilator `-Wall` catches width mismatches.
- **UART done signals can be multi-cycle.** The Nandland UART TX asserts `o_Tx_Done` for two cycles. Edge-detect before using as a state transition trigger.
- **XDC port names must match Verilog exactly.** Mismatched names fail silently — pins left unconnected with no error.
- **Uninitialised block RAM shows artefacts.** Use `initial` blocks to zero framebuffers before use.
- **Decouple fast producers from slow consumers.** The framebuffer separates 0.112ms computation from 60Hz VGA display — both sides run independently.

## Hardware

- **Board**: Digilent Basys 3 (Rev B)
- **FPGA**: Xilinx Artix-7 XC7A35T-1CPG236C
- **Clock**: 100MHz on-board oscillator
- **UART**: USB-RS232 via FTDI FT2232, 115200 baud
- **VGA**: 640×480 @ 60Hz, 12-bit colour (4-bit per channel)
- **Host**: Ubuntu 24.04 ARM64 in Parallels on Mac Studio M4
