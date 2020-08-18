vlib altera_mf
vmap altera_mf ./altera_mf
vlog -work altera_mf {./altera_mf.v}

vlib work

vlog -sv {../rtl/fifo.sv}
vlog -sv {./altera_scfifo.v}
vlog -sv {./fifo_tb.sv}

vsim -t 1ps -L altera_mf -L work -voptargs="+acc"  fifo_tb

do wave.do
run -all