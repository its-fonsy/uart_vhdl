SRC_DIR	:= src
SRCS	:= $(wildcard $(SRC_DIR)/*.vhdl)
LIB		:= work

VLIB		:= vlib
VLIB_FLAGS	:=

VCOM		:= vcom
VCOM_FLAGS	:= -2008 -quiet -work $(LIB)

VSIM		:= vsim
VSIM_FLAGS	:= -do
VSIM_FLAGS	+= "add wave -group dut /dut/*;
VSIM_FLAGS	+= add wave -group tb /*;
VSIM_FLAGS	+= run -all"

VDEL		:= vdel
VDEL_FLAGS	:= -all -lib $(LIB)

.PHONY: compile clean sim_pcs sim_producer sim_consumer
 
compile: $(SRCS)
	@if [ ! -d work ]; then $(VLIB) $(VLIB_FLAGS) $(LIB); fi
	@$(VCOM) $(VCOM_FLAGS) $^

sim: compile
	$(VSIM) $(VSIM_FLAGS) $(LIB).uart_tb

clean:
	rm -f *.cr.mti *.mpf *.wlf *.vstf transcript
	$(VDEL) $(VDEL_FLAGS)
