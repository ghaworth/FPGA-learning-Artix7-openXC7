DEVICE    := xc7a35tcpg236-1
CHIPDB    := $(HOME)/Documents/FPGA/fpga-tools/nextpnr-xilinx/xilinx/xc7a35t.bin
DB_ROOT   := $(HOME)/Documents/FPGA/fpga-tools/nextpnr-xilinx/xilinx/external/prjxray-db/artix7
PART      := xc7a35tcpg236-1
LIB_IO    = ../../lib/io
CONSTRAINTS = ../../constraints/basys3.xdc

SRCS = bram_test_top.v \
       day_07_part2_core.v \
       $(LIB_IO)/debounce_switch.v \
       $(LIB_IO)/seg7_mux.v

.PHONY: all clean program sim

all: bram_test.bit

bram_test.json: $(SRCS)
	yosys -p "synth_xilinx -flatten -abc9 -arch xc7 -top bram_test_top; write_json bram_test.json" $(SRCS) 2>&1 | tee build.log

bram_test.fasm: bram_test.json
	nextpnr-xilinx --chipdb $(CHIPDB) --xdc $(CONSTRAINTS) --json bram_test.json --fasm bram_test.fasm --freq 100

bram_test.frames: bram_test.fasm
	fasm2frames --part $(PART) --db-root $(DB_ROOT) bram_test.fasm > bram_test.frames

bram_test.bit: bram_test.frames
	xc7frames2bit --part-file $(DB_ROOT)/$(PART)/part.yaml --part-name $(PART) --frm-file bram_test.frames --output-file bram_test.bit

program: bram_test.bit
	openFPGALoader -b basys3 bram_test.bit

sim:
	iverilog -o test -s bram_rdw_test_tb bram_rdw_test.v bram_rdw_test_tb.v
	vvp test

clean:
	rm -f bram_test.json bram_test.fasm bram_test.frames bram_test.bit build.log test bram_rdw_test.vcd
