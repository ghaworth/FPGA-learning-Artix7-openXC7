DEVICE    := xc7a35tcpg236-1
CHIPDB    := $(HOME)/Documents/FPGA/fpga-tools/nextpnr-xilinx/xilinx/xc7a35t.bin
DB_ROOT   := $(HOME)/Documents/FPGA/fpga-tools/nextpnr-xilinx/xilinx/external/prjxray-db/artix7
PART      := xc7a35tcpg236-1

.PHONY: all clean program

all: blinky.bit

blinky.json: blinky.v
	yosys -p "synth_xilinx -flatten -abc9 -arch xc7 -top blinky; write_json blinky.json" blinky.v

blinky.fasm: blinky.json
	nextpnr-xilinx --chipdb $(CHIPDB) --xdc basys3.xdc --json blinky.json --fasm blinky.fasm

blinky.frames: blinky.fasm
	fasm2frames --part $(PART) --db-root $(DB_ROOT) blinky.fasm > blinky.frames

blinky.bit: blinky.frames
	xc7frames2bit --part-file $(DB_ROOT)/$(PART)/part.yaml --part-name $(PART) --frm-file blinky.frames --output-file blinky.bit

program: blinky.bit
	openFPGALoader -b basys3 blinky.bit

clean:
	rm -f blinky.json blinky.fasm blinky.frames blinky.bit
