# FPGA Learning: Artix-7 + openXC7

Hardware implementations on the Digilent Basys 3 (Xilinx Artix-7 XC7A35T) using the open-source openXC7 toolchain. No Vivado.

This repo is a companion to [FPGA-learning-iCE40-Yosys](https://github.com/ghaworth/FPGA-learning-iCE40-Yosys), which targets the Nandland Go Board (Lattice iCE40 HX1K). Designs that outgrow the iCE40's 1,280 logic cells move here — the Artix-7 provides 33,280 LCs with room for wider datapaths, UART output, and future VGA visualisation.

## Structure

```
FPGA-learning-Artix7-openXC7/
├── lib/                           # Reusable component library (shared with iCE40 repo)
│   ├── io/
│   │   ├── debounce_switch.v      # Switch debouncing (parameterised for clock speed)
│   │   ├── uart_tx.v              # UART transmitter (Nandland, widened for 100MHz)
│   │   ├── uart_rx.v              # UART receiver (Nandland)
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
│           ├── day_07_top.v       # Top module: core + timer + UART pipeline
│           ├── day_07_core.v      # Beam splitting algorithm
│           ├── day_07_timer.v     # Cycle counter
│           ├── day_07_core_tb.v   # Self-checking testbench
│           ├── splitters.hex      # Block RAM data
│           ├── mac_uart.py        # UART receiver (local copy, configured for Linux)
│           ├── Makefile           # openXC7 build + simulation
│           └── gen_input.py       # Input parser
├── constraints/
│   └── basys3.xdc                 # Full Basys 3 master constraints (active pins uncommented)
├── .gitignore
└── README.md
```

## Advent of Code 2025

### Day 7: Beam Splitting

Simulates a beam propagating through a 141-wide grid of splitters across 70 rows. Ported from the iCE40 when the design exceeded the HX1K's routing capacity.

- **Result**: 1672 (part 1, verified against simulation)
- **Execution time**: 11,201 clock cycles = 0.112ms at 100MHz
- **UART output**: Sync header (`0xAA 0x55`), 2-byte result, 4-byte cycle count — parsed by Python receiver

**Architecture**: Button press triggers computation and cycle counter. On completion, a state machine sequences sync bytes, result bytes, and timer bytes through a muxed UART transmitter. The `Value_To_Bytes` serialiser converts multi-byte values into sequential UART frames. The Python receiver synchronises on the `0xAA 0x55` header and reassembles the little-endian values.

**Techniques**: 141-bit wide bitmask operations, block RAM (`$readmemh`), state machine with edge-detected transitions, parameterised UART (868 clocks/bit at 100MHz), hardware multiplexing of two serialiser outputs to a shared UART TX, cycle-accurate performance measurement.

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

## Component Library

Reusable modules in `lib/` are shared across projects and with the iCE40 repo. Key modules have been widened for 100MHz operation:

- **uart_tx.v**: Clock counter widened from 8-bit to 16-bit to support `CLKS_PER_BIT` values above 255
- **debounce_switch.v**: Debounce counter widened from 18-bit to 20-bit for 1,000,000-count limit at 100MHz
- **value_to_bytes.v**: Parameterised serialiser — converts an N-bit value into sequential bytes for UART transmission

## Lessons Learned

- **Register width must match parameter values.** Changing clock frequency without checking counter widths causes silent overflow — the counter wraps endlessly and comparisons become permanently true or false. No compiler warning, no synthesis error. Verilator's `-Wall` flag catches width mismatches.
- **UART done signals can be multi-cycle.** The Nandland UART TX asserts `o_Tx_Done` for two clock cycles (STOP_BIT and CLEANUP states). State machines that advance on the level rather than the rising edge of `tx_done` will skip states. Edge-detect `tx_done` before using it as a transition trigger.
- **XDC port names must match Verilog exactly.** Unlike PCF constraints on iCE40, mismatched names in XDC files fail silently — the pin is left unconnected with no error.

## Hardware

- **Board**: Digilent Basys 3 (Rev B)
- **FPGA**: Xilinx Artix-7 XC7A35T-1CPG236C
- **Clock**: 100MHz on-board oscillator
- **UART**: USB-RS232 via FTDI FT2232, 115200 baud
- **Host**: Ubuntu 24.04 ARM64 in Parallels on Mac Studio M4
