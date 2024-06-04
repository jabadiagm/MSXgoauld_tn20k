--Copyright (C)2014-2022 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--GOWIN Version: V1.9.8.10
--Part Number: GW2AR-LV18QN88C8/I7
--Device: GW2AR-18
--Device Version: C
--Created Time: Thu Jun 15 18:49:58 2023

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component Gowin_rPLL2
    port (
        clkout: out std_logic;
        clkoutp: out std_logic;
        clkin: in std_logic
    );
end component;

your_instance_name: Gowin_rPLL2
    port map (
        clkout => clkout_o,
        clkoutp => clkoutp_o,
        clkin => clkin_i
    );

----------Copy end-------------------
