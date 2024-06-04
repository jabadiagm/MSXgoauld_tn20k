vlib work
vlog ../*.v
vlog tb.sv
vsim -c -t 1ps -do run.do tb
