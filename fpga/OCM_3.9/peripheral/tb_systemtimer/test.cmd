vlib work
vcom ..\systemtimer.vhd
vcom tb_systemtimer.vhd
vsim -t ns tb -do all.do
