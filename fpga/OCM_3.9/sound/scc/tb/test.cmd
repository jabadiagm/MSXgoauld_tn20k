vlib work
vcom ram.vhd
vcom ..\scc_wave.vhd
vcom tb_scc.vhd
vsim -t ns tb -do all.do
