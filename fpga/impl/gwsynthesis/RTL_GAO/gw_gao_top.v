module gw_gao(
    ex_clk_27m,
    ex_bus_clk_3m6,
    clk_enable_3m6,
    ex_bus_reset_n,
    ex_bus_wait_n,
    ex_bus_int_n,
    ex_bus_rfsh_n,
    ex_bus_m1_n,
    ex_bus_mreq_n,
    bus_mreq_n,
    ex_bus_iorq_n,
    bus_iorq_n,
    ex_bus_rd_n,
    bus_rd_n,
    ex_bus_wr_n,
    bus_wr_n,
    sccp_req,
    megaram_req,
    megaram_scc_req,
    \bus_addr[15] ,
    \bus_addr[14] ,
    \bus_addr[13] ,
    \bus_addr[12] ,
    \bus_addr[11] ,
    \bus_addr[10] ,
    \bus_addr[9] ,
    \bus_addr[8] ,
    \bus_addr[7] ,
    \bus_addr[6] ,
    \bus_addr[5] ,
    \bus_addr[4] ,
    \bus_addr[3] ,
    \bus_addr[2] ,
    \bus_addr[1] ,
    \bus_addr[0] ,
    \cpu_dout[7] ,
    \cpu_dout[6] ,
    \cpu_dout[5] ,
    \cpu_dout[4] ,
    \cpu_dout[3] ,
    \cpu_dout[2] ,
    \cpu_dout[1] ,
    \cpu_dout[0] ,
    problema,
    \ex_bus_data[7] ,
    \ex_bus_data[6] ,
    \ex_bus_data[5] ,
    \ex_bus_data[4] ,
    \ex_bus_data[3] ,
    \ex_bus_data[2] ,
    \ex_bus_data[1] ,
    \ex_bus_data[0] ,
    \bus_data[7] ,
    \bus_data[6] ,
    \bus_data[5] ,
    \bus_data[4] ,
    \bus_data[3] ,
    \bus_data[2] ,
    \bus_data[1] ,
    \bus_data[0] ,
    clk_108m,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input ex_clk_27m;
input ex_bus_clk_3m6;
input clk_enable_3m6;
input ex_bus_reset_n;
input ex_bus_wait_n;
input ex_bus_int_n;
input ex_bus_rfsh_n;
input ex_bus_m1_n;
input ex_bus_mreq_n;
input bus_mreq_n;
input ex_bus_iorq_n;
input bus_iorq_n;
input ex_bus_rd_n;
input bus_rd_n;
input ex_bus_wr_n;
input bus_wr_n;
input sccp_req;
input megaram_req;
input megaram_scc_req;
input \bus_addr[15] ;
input \bus_addr[14] ;
input \bus_addr[13] ;
input \bus_addr[12] ;
input \bus_addr[11] ;
input \bus_addr[10] ;
input \bus_addr[9] ;
input \bus_addr[8] ;
input \bus_addr[7] ;
input \bus_addr[6] ;
input \bus_addr[5] ;
input \bus_addr[4] ;
input \bus_addr[3] ;
input \bus_addr[2] ;
input \bus_addr[1] ;
input \bus_addr[0] ;
input \cpu_dout[7] ;
input \cpu_dout[6] ;
input \cpu_dout[5] ;
input \cpu_dout[4] ;
input \cpu_dout[3] ;
input \cpu_dout[2] ;
input \cpu_dout[1] ;
input \cpu_dout[0] ;
input problema;
input \ex_bus_data[7] ;
input \ex_bus_data[6] ;
input \ex_bus_data[5] ;
input \ex_bus_data[4] ;
input \ex_bus_data[3] ;
input \ex_bus_data[2] ;
input \ex_bus_data[1] ;
input \ex_bus_data[0] ;
input \bus_data[7] ;
input \bus_data[6] ;
input \bus_data[5] ;
input \bus_data[4] ;
input \bus_data[3] ;
input \bus_data[2] ;
input \bus_data[1] ;
input \bus_data[0] ;
input clk_108m;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire ex_clk_27m;
wire ex_bus_clk_3m6;
wire clk_enable_3m6;
wire ex_bus_reset_n;
wire ex_bus_wait_n;
wire ex_bus_int_n;
wire ex_bus_rfsh_n;
wire ex_bus_m1_n;
wire ex_bus_mreq_n;
wire bus_mreq_n;
wire ex_bus_iorq_n;
wire bus_iorq_n;
wire ex_bus_rd_n;
wire bus_rd_n;
wire ex_bus_wr_n;
wire bus_wr_n;
wire sccp_req;
wire megaram_req;
wire megaram_scc_req;
wire \bus_addr[15] ;
wire \bus_addr[14] ;
wire \bus_addr[13] ;
wire \bus_addr[12] ;
wire \bus_addr[11] ;
wire \bus_addr[10] ;
wire \bus_addr[9] ;
wire \bus_addr[8] ;
wire \bus_addr[7] ;
wire \bus_addr[6] ;
wire \bus_addr[5] ;
wire \bus_addr[4] ;
wire \bus_addr[3] ;
wire \bus_addr[2] ;
wire \bus_addr[1] ;
wire \bus_addr[0] ;
wire \cpu_dout[7] ;
wire \cpu_dout[6] ;
wire \cpu_dout[5] ;
wire \cpu_dout[4] ;
wire \cpu_dout[3] ;
wire \cpu_dout[2] ;
wire \cpu_dout[1] ;
wire \cpu_dout[0] ;
wire problema;
wire \ex_bus_data[7] ;
wire \ex_bus_data[6] ;
wire \ex_bus_data[5] ;
wire \ex_bus_data[4] ;
wire \ex_bus_data[3] ;
wire \ex_bus_data[2] ;
wire \ex_bus_data[1] ;
wire \ex_bus_data[0] ;
wire \bus_data[7] ;
wire \bus_data[6] ;
wire \bus_data[5] ;
wire \bus_data[4] ;
wire \bus_data[3] ;
wire \bus_data[2] ;
wire \bus_data[1] ;
wire \bus_data[0] ;
wire clk_108m;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top_0  u_la0_top(
    .control(control0[9:0]),
    .trig0_i(ex_bus_m1_n),
    .trig1_i(ex_bus_reset_n),
    .trig2_i({\bus_addr[15] ,\bus_addr[14] ,\bus_addr[13] ,\bus_addr[12] ,\bus_addr[11] ,\bus_addr[10] ,\bus_addr[9] ,\bus_addr[8] ,\bus_addr[7] ,\bus_addr[6] ,\bus_addr[5] ,\bus_addr[4] ,\bus_addr[3] ,\bus_addr[2] ,\bus_addr[1] ,\bus_addr[0] }),
    .trig3_i({\ex_bus_data[7] ,\ex_bus_data[6] ,\ex_bus_data[5] ,\ex_bus_data[4] ,\ex_bus_data[3] ,\ex_bus_data[2] ,\ex_bus_data[1] ,\ex_bus_data[0] }),
    .trig4_i(bus_iorq_n),
    .trig5_i({\bus_data[7] ,\bus_data[6] ,\bus_data[5] ,\bus_data[4] ,\bus_data[3] ,\bus_data[2] ,\bus_data[1] ,\bus_data[0] }),
    .trig6_i({\bus_addr[7] ,\bus_addr[6] ,\bus_addr[5] ,\bus_addr[4] ,\bus_addr[3] ,\bus_addr[2] ,\bus_addr[1] ,\bus_addr[0] }),
    .trig7_i(bus_rd_n),
    .trig8_i(problema),
    .data_i({ex_clk_27m,ex_bus_clk_3m6,clk_enable_3m6,ex_bus_reset_n,ex_bus_wait_n,ex_bus_int_n,ex_bus_rfsh_n,ex_bus_m1_n,ex_bus_mreq_n,bus_mreq_n,ex_bus_iorq_n,bus_iorq_n,ex_bus_rd_n,bus_rd_n,ex_bus_wr_n,bus_wr_n,sccp_req,megaram_req,megaram_scc_req,\bus_addr[15] ,\bus_addr[14] ,\bus_addr[13] ,\bus_addr[12] ,\bus_addr[11] ,\bus_addr[10] ,\bus_addr[9] ,\bus_addr[8] ,\bus_addr[7] ,\bus_addr[6] ,\bus_addr[5] ,\bus_addr[4] ,\bus_addr[3] ,\bus_addr[2] ,\bus_addr[1] ,\bus_addr[0] ,\cpu_dout[7] ,\cpu_dout[6] ,\cpu_dout[5] ,\cpu_dout[4] ,\cpu_dout[3] ,\cpu_dout[2] ,\cpu_dout[1] ,\cpu_dout[0] ,problema}),
    .clk_i(clk_108m)
);

endmodule
