//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8.10
//Part Number: GW2AR-LV18QN88C8/I7
//Device: GW2AR-18
//Device Version: C
//Created Time: Fri Jun 16 22:06:26 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_rPLL2 your_instance_name(
        .clkout(clkout_o), //output clkout
        .clkoutp(clkoutp_o), //output clkoutp
        .clkin(clkin_i) //input clkin
    );

//--------Copy end-------------------
