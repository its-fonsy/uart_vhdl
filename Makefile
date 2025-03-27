SRC_DIR	:= src
SRCS	:= $(wildcard $(SRC_DIR)/*.vhdl)
LIB		:= work

TB_ENTITY 	:= uart_tb

VLIB		:= vlib
VLIB_FLAGS	:=

VCOM		:= vcom
VCOM_FLAGS	:= -2008 -quiet -work $(LIB)

VSIM			:= vsim
VSIM_GUI_FLAGS	:= -do
VSIM_GUI_FLAGS	+= "add wave -group dut /dut/*;
VSIM_GUI_FLAGS	+= add wave -group tb /*;
VSIM_GUI_FLAGS	+= run -all"
VSIM_CLI_FLAGS	:= -do "run -all" -suppress GroupWarning -quiet

VDEL		:= vdel
VDEL_FLAGS	:= -all -lib $(LIB)

.PHONY: compile clean sim_pcs sim_producer sim_consumer
 
compile: $(SRCS)
	@if [ ! -d work ]; then $(VLIB) $(VLIB_FLAGS) $(LIB); fi
	@$(VCOM) $(VCOM_FLAGS) $^

sim: compile
	$(VSIM) $(VSIM_GUI_FLAGS) $(LIB).$(TB_ENTITY)

batch: compile
	$(VSIM) -c $(VSIM_CLI_FLAGS) $(LIB).$(TB_ENTITY)

clean:
	rm -f *.cr.mti *.mpf *.wlf *.vstf transcript
	$(VDEL) $(VDEL_FLAGS)
