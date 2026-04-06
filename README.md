# FPGA Learning — Artix-7 (openXC7)

FPGA projects targeting the Digilent Basys 3 (Xilinx Artix-7 XC7A35T) using a fully open-source toolchain: Yosys, nextpnr-xilinx, Project X-Ray, and openFPGALoader.

Built on Ubuntu 24.04 ARM64 (Parallels, Mac Studio M4).

## Advent of Code 2025

Hardware implementations of selected AoC 2025 challenges in Verilog — inspired by Jane Street's Advent of FPGA.

Challenges are selected for genuine hardware suitability (fixed data flow, bit manipulation, parallel operations, state machines). Input data is pre-computed offline into Verilog constants or hex files.

### Day 7 — Beam Splitting Simulation

A tachyon particle falls through a 141-column × 70-row grid of splitters. Each splitter sends the particle (or timeline) left and right.

**Part 1**: Count how many splitters the beam hits.
- Answer: **1672**
- Architecture: 141-bit bitmask per row, loaded from Block RAM. Single-cycle parallel OR reduction counts active positions.
- Includes UART transmission pipeline and VGA visualisation (640×480, green splitters, red beam, animated at 1 row/sec via dual-port framebuffer).
- Runs in 11,201 cycles at 100 MHz.

**Part 2**: Count total timelines after quantum splitting (many-worlds interpretation).
- Answer: **231,229,866,702,355** (48-bit value, stored in 70-bit registers)
- Architecture: Serialised FETCH → WAIT → COMPUTE pipeline, processing one column position per iteration across 141 positions per row. Each position computes a 70-bit three-input addition (left neighbour + self pass-through + right neighbour). Accumulator captures timelines exiting the grid at left edge, right edge, and bottom.
- Key design decisions:
  - **Serialised processing** replaced the original single-cycle parallel approach (141 × 70-bit additions) which achieved only 45 MHz — a timing violation at the Basys 3's 100 MHz clock. The serialised version achieves ~110 MHz post-routing.
  - **Distributed RAM** (`(* ram_style = "distributed" *)`) for the count array. Yosys BRAM inference introduced a read-during-write mismatch: simulation returned the old value (correct per Verilog non-blocking semantics), but the inferred RAMB36E1 used a write mode that returned different data on hardware. Distributed registers eliminate this discrepancy.
  - **Two-cycle BRAM read latency**: setting the address (FETCH) and reading the data (COMPUTE) are separated by a WAIT state because both the address latch and the data latch use non-blocking assignments, requiring two clock edges from address to valid data.
  - **Sequential SUM state** with a 3-phase counter (set address → wait → accumulate) totals remaining timelines after the final row, using the same registered read pattern.

**Shared infrastructure:**
- Two-button architecture: `btnL` runs Part 1, `btnR` runs Part 2. A mux selects which result feeds the shared display pipeline. Reusable pattern for future days.
- 7-segment display shows bottom 4 digits as a sanity check.
- LED indicators show which part is active.

---

## Component Library

Reusable modules for Basys 3 projects. Each module is tested and versioned.

### `io/debounce_switch.v`

Debounces mechanical switch or button input.

#### Description

Mechanical switches produce multiple transitions (bounce) when pressed or released. This module filters the input by requiring it to be stable for 10ms before allowing the output to change.

#### Interface

```verilog
module Debounce_Switch (
  input  i_Clk,
  input  i_Switch,
  output o_Switch
);
```

- `i_Clk`: System clock (25 MHz)
- `i_Switch`: Raw switch input (asynchronous)
- `o_Switch`: Debounced switch output

#### Parameters

- `c_DEBOUNCE_LIMIT`: Number of clock cycles for debounce window (default: 250000 = 10ms at 25MHz)

#### Behaviour

- While input differs from internal state AND count < limit: increment counter
- When counter reaches limit: update output, reset counter
- When input matches state: reset counter to 0

#### Example Usage

```verilog
wire w_Switch_Debounced;
Debounce_Switch Debounce_Inst (
  .i_Clk(i_Clk),
  .i_Switch(i_Raw_Switch),
  .o_Switch(w_Switch_Debounced)
);
```

---

### `converters/binary_to_7segment.v`

Converts 4-bit binary value to 7-segment display encoding.

#### Description

A 7-segment display has 7 LED segments arranged to display digits. This module takes a 4-bit binary number (0-15) and outputs which segments should be illuminated to display that value as a decimal digit (0-9) or hexadecimal digit (A-F).

#### Interface

```verilog
module Binary_To_7Segment (
  input        i_Clk,
  input  [3:0] i_Binary_Num,
  output       o_Segment_A,
  output       o_Segment_B,
  output       o_Segment_C,
  output       o_Segment_D,
  output       o_Segment_E,
  output       o_Segment_F,
  output       o_Segment_G
);
```

- `i_Clk`: System clock (synchronous to output changes)
- `i_Binary_Num`: Input value (0-15)
- `o_Segment_A` through `o_Segment_G`: Individual segment outputs (active-high)

#### 7-Segment Layout

```
    aaa
   f   b
    ggg
   e   c
    ddd
```

#### Supported Characters

**Decimal (0-9)**:
- 0: a,b,c,d,e,f (6 segments)
- 1: b,c (2 segments)
- 2: a,b,d,e,g (5 segments)
- 3: a,b,c,d,g (5 segments)
- 4: b,c,f,g (4 segments)
- 5: a,c,d,f,g (5 segments)
- 6: a,c,d,e,f,g (6 segments)
- 7: a,b,c (3 segments)
- 8: a,b,c,d,e,f,g (7 segments)
- 9: a,b,c,d,f,g (6 segments)

**Hexadecimal (A-F)**:
- A: a,b,c,e,f,g (6 segments)
- B: c,d,e,f,g (5 segments)
- C: a,d,e,f (4 segments)
- D: b,c,d,e,g (5 segments)
- E: a,d,e,f,g (5 segments)
- F: a,e,f,g (4 segments)

#### Implementation Notes

- Outputs are **active-high** (1 = segment on)
- The module uses registered (synchronous) outputs (changes on clock edge)
- Go Board segments are **active-low**: invert outputs in your top-level module

#### Example Usage

```verilog
wire [6:0] w_Segments;
Binary_To_7Segment Converter_Inst (
  .i_Clk(i_Clk),
  .i_Binary_Num(digit_value),
  .o_Segment_A(w_Segments[0]),
  .o_Segment_B(w_Segments[1]),
  .o_Segment_C(w_Segments[2]),
  .o_Segment_D(w_Segments[3]),
  .o_Segment_E(w_Segments[4]),
  .o_Segment_F(w_Segments[5]),
  .o_Segment_G(w_Segments[6])
);
// Invert for Go Board (active-low)
assign o_Segments = ~w_Segments;
```

---

## Adding New Components

When creating a new reusable module:

1. Place it in the appropriate subdirectory (`io/`, `converters/`, etc.)
2. Include clear documentation (interface, behaviour, examples)
3. Create a testbench (`*_tb.v`) alongside the module
4. Test thoroughly before other projects depend on it
5. Update this README with description and usage example
