//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.9 Beta-4
//Created Time: 2023-10-11 15:41:18
create_clock -name clock_reset -period 277.778 -waveform {0 138.889} [get_nets {bus_reset_n}] -add
create_clock -name clock_audio -period 277.778 -waveform {0 138.889} [get_nets {vdp4/clk_audio}] -add
create_clock -name clock_VideoDLClk -period 37.037 -waveform {0 18.518} [get_nets {VideoDLClk}] -add
//create_clock -name clock_3m6 -period 277.778 -waveform {0 138.889} [get_nets {bus_clk_3m6}] -add
create_clock -name clock_27m -period 37.037 -waveform {0 18.518} [get_ports {ex_clk_27m}] -add
create_generated_clock -name clock_108m -source [get_ports {ex_clk_27m}] -master_clock clock_27m -multiply_by 4 [get_nets {clk_108m}] -add
set_clock_groups -asynchronous -group [get_clocks {clock_108m   }] -group [get_clocks {clock_reset }] -group [get_clocks {clock_27m clock_VideoDLClk}] -group [get_clocks {clock_env_reset }] 

set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/?*?/D}] -setup -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/u0/Regs/?*?/?*}] -setup -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/u0/?*?/?*}] -setup -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/u0/?*?/D}] -setup -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/u0/?*?/CE}] -setup -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/?*?/CE}] -setup -end 10
//set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/DI_Reg*/SET}] -setup -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {memory_ctrl/vram/u_sdram/?*?/D}] -setup -end 2
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {ppi_port*?/CE}] -setup -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {memory_ctrl/vram/?*?/D}] -setup -end 2

set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/?*?/D}] -hold -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/u0/Regs/?*?/?*}] -hold -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/u0/?*?/?*}] -hold -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/u0/?*?/D}] -hold -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/u0/?*?/CE}] -hold -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/?*?/CE}] -hold -end 10
//set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {cpu1/DI_Reg*/SET}] -hold -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {memory_ctrl/vram/u_sdram/?*?/D}] -hold -end 2
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {ppi_port*?/CE}] -hold -end 10
set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {memory_ctrl/vram/?*?/D}] -hold -end 2



//ENABLE_BIOS
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {bios1/mem*?/AD*}] -setup -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {subrom1/mem*?/AD*}] -setup -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {logo1/mem*?/AD*}] -setup -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {exp_slot?*?/CE}] -setup -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {bios1/mem*?/CE}] -setup -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {bios1/mem*?/AD*}] -hold -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {subrom1/mem*?/AD*}] -hold -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {logo1/mem*?/AD*}] -hold -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {exp_slot?*?/CE}] -hold -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {bios1/mem*?/CE}] -hold -end 10


//ENABLE_MAPPER
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {mapper_reg*?/CE}] -setup -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {memory_ctrl/mapper_dout*/D}] -setup -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {mapper_reg*?/CE}] -hold -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {memory_ctrl/mapper_dout*/D}] -hold -end 10


//ENABLE_SOUND
    create_clock -name clock_env_reset -period 277.778 -waveform {0 138.889} [get_nets {psg1/env_reset}] -add
    set_false_path -from [get_clocks {clock_108m}] -to [get_pins {psg1/?*?/?*}]
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {scc1/SccCh/?*?/?*}] -setup -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {scc1/SccCh/wavemem/?*?/?*}] -setup -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {scc1/?*?/?*}] -setup -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {scc1/SccCh/?*?/?*}] -hold -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {scc1/SccCh/wavemem/?*?/?*}] -hold -end 10
    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {scc1/?*?/?*}] -hold -end 10
    set_false_path -from [get_clocks {clock_108m}] -to [get_pins {opll/?*?/?*?/CE}]
    set_false_path -from [get_clocks {clock_108m}] -to [get_pins {opll/?*?/?*?/?*?/AD*}]
    set_false_path -from [get_clocks {clock_108m}] -to [get_pins {opll/?*?/?*?/D*}]
    set_false_path -from [get_clocks {clock_108m}] -to [get_pins {opll/?*?/?*?/SET}]


set_false_path -from [get_clocks {clock_108m}] -to [get_pins {rtc1/?*?/?*}]
set_false_path -from [get_clocks {clock_108m}] -to [get_pins {rtc1/u_mem/?*?/?*}]
set_false_path -from [get_clocks {clock_27m}] -to [get_pins {vdp4/hdmi_ntsc/true_hdmi_output.packet_picker/audio_sample_word_transfer?*?/D}]


//ENABLE_CONFIG
    set_false_path -from [get_clocks {clock_108m}] -to [get_pins {config_?*/RESET}]
    set_false_path -from [get_clocks {clock_108m}] -to [get_pins {config*/D}]
    set_false_path -from [get_clocks {clock_108m}] -to [get_pins {config*/CE}]
//    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {config0_ff*?/D}] -setup -end 30
//    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {config0_ff*?/D}] -hold -end 30
//    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {config1_ff*?/CE}] -setup -end 30
//    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {config1_ff*?/CE}] -hold -end 30
//    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {config2_ff*?/CE}] -setup -end 20
//    set_multicycle_path -from [get_clocks {clock_108m}] -to [get_pins {config2_ff*?/CE}] -hold -end 20


set_max_delay -from [get_clocks {clock_108m}] -to [get_pins {xffl_s0/D}] 9.6
set_max_delay -from [get_clocks {clock_108m}] -to [get_pins {memory_ctrl/enable_read_seq*/D}] 11.0
set_max_delay -from [get_clocks {clock_108m}] -to [get_pins {memory_ctrl/enable_write_seq*/D}] 11.0
//set_max_delay -from [get_clocks {clock_108m}] -to [get_pins {memory_ctrl/vram/u_sdram/FF_SDRAM_A*/D}] 12.0
//set_max_delay -from [get_clocks {clock_108m}] -to [get_pins {memory_ctrl/vram/u_sdram/FF_SDRAM_BA*/D}] 12.0
//set_max_delay -from [get_clocks {clock_108m}] -to [get_pins {memory_ctrl/vram/u_sdram/FF_SDRAM_DQM*/D}] 12.0

//set_false_path -from [get_clocks {clock_108m}] -to [get_pins {debug/?*?/CE}]
//set_false_path -from [get_clocks {clock_27m}] -to [get_pins {debug/?*?/CE}]
//set_false_path -from [get_clocks {clock_108m}] -to [get_pins {debug/?*?/D}]
//set_false_path -from [get_clocks {clock_27m}] -to [get_pins {debug/?*?/D}]

report_timing -setup -max_paths 200 -max_common_paths 1