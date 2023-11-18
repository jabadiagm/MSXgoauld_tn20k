//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.9 Beta-4
//Created Time: 2023-10-11 15:41:18
create_clock -name clock_3m6 -period 277.778 -waveform {0 138.889} [get_nets {bus_clk_3m6}] -add
create_clock -name clock_27m -period 37.037 -waveform {0 18.518} [get_nets {clk_27m}] -add
create_generated_clock -name clock_108m -source [get_nets {clk_27m}] -master_clock clock_27m -multiply_by 4 -duty_cycle 50 -phase 0 [get_nets {clk_108m}] -add
create_generated_clock -name clock_108m_n -source [get_nets {clk_27m}] -master_clock clock_27m -multiply_by 4 -duty_cycle 50 -phase 180 -add [get_ports {O_sdram_clk}]
create_generated_clock -name clock_54m -source [get_nets {clk_108m}] -master_clock clock_108m -divide_by 2 [get_nets {clk_54m}] -add
set_clock_groups -asynchronous -group [get_clocks {clock_108m clock_108m_n clock_54m clock_27m }] -group [get_clocks {clock_3m6 }] 
