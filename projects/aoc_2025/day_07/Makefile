DEVICE    := xc7a35tcpg236-1
CHIPDB    := $(HOME)/Documents/FPGA/fpga-tools/nextpnr-xilinx/xilinx/xc7a35t.bin
DB_ROOT   := $(HOME)/Documents/FPGA/fpga-tools/nextpnr-xilinx/xilinx/external/prjxray-db/artix7
PART      := xc7a35tcpg236-1
LIB_IO = ../../../lib/io
CONSTRAINTS = ../../../constraints/basys3.xdc

SRCS = day_07_top.v \
       day_07_core.v \
       day_07_part2_core.v \
       day_07_timer.v \
       day_07_capture.v \
       $(LIB_IO)/debounce_switch.v \
       $(LIB_IO)/uart_tx.v \
       $(LIB_IO)/vga_display.v \
       $(LIB_IO)/seg7_mux.v \
       $(LIB_IO)/bin_to_bcd.v \
       $(LIB_IO)/value_to_bytes.v

.PHONY: all clean program sim

all: day_07.bit

day_07.json: $(SRCS)
	yosys -p "synth_xilinx -flatten -abc9 -arch xc7 -top Day_07_Top; write_json day_07.json" $(SRCS)

day_07.fasm: day_07.json
	nextpnr-xilinx --chipdb $(CHIPDB) --xdc $(CONSTRAINTS) --json day_07.json --fasm day_07.fasm --freq 100

day_07.frames: day_07.fasm
	fasm2frames --part $(PART) --db-root $(DB_ROOT) day_07.fasm > day_07.frames

day_07.bit: day_07.frames
	xc7frames2bit --part-file $(DB_ROOT)/$(PART)/part.yaml --part-name $(PART) --frm-file day_07.frames --output-file day_07.bit

program: day_07.bit
	openFPGALoader -b basys3 day_07.bit

sim:
	iverilog -o day_07_tb.vvp day_07_core.v day_07_core_tb.v
	vvp day_07_tb.vvp

clean:
	rm -f day_07.json day_07.fasm day_07.frames day_07.bit