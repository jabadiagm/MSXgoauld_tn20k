vlib work
vcom ..\tapram.vhd
vcom ..\esefir5.vhd
vcom tb_filter.vhd
vsim -t ns tb -do all.do
