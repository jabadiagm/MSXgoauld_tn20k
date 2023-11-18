//`define FMMUSIC

module top(
    input ex_clk_27m,
    input s1,
    input s2,

    input ex_bus_wait_n,
    input ex_bus_int_n,
    input ex_bus_reset_n,
    input ex_bus_clk_3m6,

    inout [7:0] ex_bus_data,
    
    output [1:0] ex_msel,
    output ex_bus_m1_n,
    output ex_bus_rfsh_n,
    output ex_bus_mreq_n,
    output ex_bus_iorq_n,
    output ex_bus_rd_n,
    output ex_bus_wr_n,

    output ex_bus_data_reverse_n,
    output [7:0] ex_bus_mp,

    //hdmi out
    output [2:0] data_p,
    output [2:0] data_n,
    output clk_p,
    output clk_n,

    // Magic ports for SDRAM to be inferred
    output O_sdram_clk,
    output O_sdram_cke,
    output O_sdram_cs_n, // chip select
    output O_sdram_cas_n, // columns address select
    output O_sdram_ras_n, // row address select
    output O_sdram_wen_n, // write enable
    inout [31:0] IO_sdram_dq, // 32 bit bidirectional data bus
    output [10:0] O_sdram_addr, // 11 bit multiplexed address bus
    output [1:0] O_sdram_ba, // two banks
    output [3:0] O_sdram_dqm, // 32/4

    output notocar

);

initial begin

end

    //clocks
    wire clk_27m;
    BUFG buf1 (
        .O(clk_27m),
        .I(ex_clk_27m)
    );

    wire clk_108m;
    wire clk_108m_buf;
    wire clk_108m_n;
    wire clk_108m_n_buf;
    CLK_108P clk_sdramp (
        .clkout(clk_108m_buf), //output clkout
        .lock(), //output lock
        .clkoutp(clk_108m_n_buf), //output clkoutp
        .reset(1'b0), //input reset
        .clkin(ex_clk_27m) //input clkin
    );
    BUFG buf2 (
        .O(clk_108m),
        .I(clk_108m_buf)
    );
    BUFG buf3 (
        .O(clk_108m_n),
        .I(clk_108m_n_buf)
    );

    wire clk_54m;
    wire clk_54m_buf;
    Gowin_CLKDIV2 clkdiv2(
        .clkout(clk_54m_buf), //output clkout
        .hclkin(clk_108m_buf), //input hclkin
        .resetn(1'b1) //input resetn
    );
    BUFG buf4(
        .O(clk_54m),
        .I(clk_54m_buf)
    );

    //input filtering
    wire bus_clk_3m6;
    PINFILTER dn1(
        .clk(clk_54m),
        .reset_n(1'b1),
        .din(ex_bus_clk_3m6),
        .dout(bus_clk_3m6)
    );
    //assign bus_clk_3m6 = ex_bus_clk_3m6;

    wire bus_wait_n;
    PINFILTER dn2(
        .clk(clk_54m),
        .reset_n(1'b1),
        .din(ex_bus_wait_n),
        .dout(bus_wait_n)
    );
    //assign bus_wait_n = ex_bus_wait_n;

    wire bus_reset_n;
    PINFILTER dn3(
        .clk(clk_54m),
        .reset_n(1'b1),
        .din(ex_bus_reset_n),
        .dout(bus_reset_n)
    );
    //assign bus_reset_n = ex_bus_reset_n;

    wire bus_int_n;
    PINFILTER dn4(
        .clk(clk_54m),
        .reset_n(1'b1),
        .din(ex_bus_int_n),
        .dout(bus_int_n)
    );
    //assign bus_int_n = ex_bus_int_n;

    wire [7:0] bus_data;
    genvar i;
    generate
        for (i = 0; i <= 7; i++)
        begin: bus_din
            PINFILTER dn(
                .clk(clk_54m),
                .reset_n(1'b1),
                .din(ex_bus_data[i]),
                .dout(bus_data[i])
            );
        end
    endgenerate

    //startup logic
    reg reset1_n_ff;
    reg reset2_n_ff;
    reg reset3_n_ff;
    wire reset1_n;
    wire reset2_n;
    wire reset3_n;

    reg [25:0] counter_reset = 0;
    reg [1:0] rst_seq;
    reg rst_step;

    always @ (posedge ex_clk_27m or negedge bus_reset_n) begin
        if (bus_reset_n == 1'b0) begin
            rst_step <= 1'b0;
            counter_reset <= 0;
        end
        else begin
            rst_step <= 1'b0;
            if ( counter_reset <= 8000000 ) 
                counter_reset <= counter_reset + 1;
            else begin
                rst_step <= 1'b1;
                counter_reset <= 0;
            end
        end
    end

    always @ (posedge ex_clk_27m or negedge bus_reset_n or posedge sdram_fail) begin
        if (bus_reset_n == 1'b0 || sdram_fail == 1'b1) begin
            rst_seq <= 2'b00;
            reset1_n_ff <= 1'b0;
            reset2_n_ff <= 1'b0;
            reset3_n_ff <= 1'b0;
        end
        else begin
            case ( rst_seq )
                2'b00: 
                    if (rst_step == 1'b1 ) begin
                        reset1_n_ff <= 1'b1;
                        rst_seq <= 2'b01;
                    end
                2'b01: 
                    if (rst_step == 1'b1) begin
                        reset2_n_ff <= 1'b1;
                        rst_seq <= 2'b10;
                    end
                2'b10:
                    if (rst_step == 1'b1) begin
                        reset3_n_ff <= 1'b1;
                        rst_seq <= 2'b11;
                    end
            endcase
        end
    end
    assign reset1_n = reset1_n_ff;
    assign reset2_n = reset2_n_ff;
    assign reset3_n = reset3_n_ff;

    //bus demux
    reg [1:0] msel;
    reg [7:0] bus_mp;
    reg msel_ff = 0;
    wire [15:0] bus_addr;
    assign ex_msel = msel;
    assign ex_bus_mp = bus_mp;
    assign msel = { msel_ff, ~ msel_ff };
    assign bus_mp = ( msel[1] == 1 ) ? bus_addr[15:8] : bus_addr[7:0];

    always @ (posedge clk_27m) begin
        msel_ff <= ~ msel_ff;
    end

    //bus isolation
    wire bus_data_reverse;
    wire bus_m1_n;
    wire bus_mreq_n;
    wire bus_iorq_n;
    wire bus_rd_n;
    wire bus_rfsh_n;
    wire [7:0] cpu_data;
    wire [7:0] cpu_din;
    assign ex_bus_m1_n = bus_m1_n;
    assign ex_bus_rfsh_n = bus_rfsh_n;
    assign ex_bus_data_reverse_n = ~ bus_data_reverse;

    assign cpu_data = ( bus_data_reverse == 0 ) ? cpu_din : 8'hzz;
    assign ex_bus_data = ( bus_data_reverse == 1 ) ? cpu_data : 8'hzz;

    //assign ex_bus_mreq_n = ( bios_req == 1'b1 || scc_req == 1'b1 || exp_slot3_req_r == 1'b1 || mapper_read == 1'b1 ) ? 1 : bus_mreq_n;
    //assign ex_bus_mreq_n = ( bios_req == 1'b1 || scc_req == 1'b1 || slot3_req == 1'b1 ) ? 1 : bus_mreq_n;
    assign ex_bus_mreq_n = ( bios_req == 1'b1 ||  scc_req == 1'b1 || subrom_req == 1'b1 || fm_logo_req == 1'b1 || exp_slot3_req_r == 1'b1 || mapper_read == 1'b1 ) ? 1 : bus_mreq_n;
    assign ex_bus_iorq_n = ( vdp_csr_n == 1'b0 || vdp_csw_n == 1'b0 || rtc_req_r == 1 || rtc_req_w == 1 )? 1'b1 : bus_iorq_n;
    assign ex_bus_wr_n = ( vdp_csw_n == 1'b0 || rtc_req_w == 1 )? 1'b1 : bus_wr_n;
    assign ex_bus_rd_n = ( vdp_csr_n == 1'b0 || rtc_req_r == 1 )? 1'b1 : bus_rd_n;
    assign cpu_din = ( vdp_csr_n == 1'b0) ? vdp_dout : 
                         ( exp_slot3_req_r == 1'b1) ? ~exp_slot3  :
                         ( mapper_read == 1'b1) ? mapper_dout :
                         ( bios_req == 1'b1) ? bios_dout :
                         ( subrom_req == 1'b1) ? subrom_dout :
                         ( rtc_req_r == 1 ) ? rtc_dout :
                         ( scc_req == 1 ) ? scc_dout:
                         ( fm_logo_req == 1'b1 ) ? fm_logo_dout : bus_data;

//    always @ (clk_108m) begin
//        cpu_din <= bus_data;
//        if ( vdp_csr_n == 1'b0) cpu_din <= vdp_dout;
//        if ( exp_slot3_req_r == 1'b1) cpu_din <= ~exp_slot3;
//        if ( mapper_read == 1'b1) cpu_din <= mapper_dout;
//        if ( bios_req == 1'b1) cpu_din <= bios_dout;
//        if ( subrom_req == 1'b1) cpu_din <= subrom_dout;
//        if ( rtc_req_r == 1 ) cpu_din <= rtc_dout;
//        if ( scc_req == 1 ) cpu_din <= scc_dout;
//        if ( fm_logo_req == 1'b1 ) cpu_din <= fm_logo_dout;
//    end

    T80a  #(
        .Mode    (0),     // 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
        .IOWait   (1)      // 0 => Single I/O cycle, 1 => Std I/O cycle
    ) cpu1 (
        .RESET_n   (bus_reset_n & reset3_n),
        .CLK_n     (bus_clk_3m6),
        .WAIT_n    (bus_wait_n),
        .INT_n     (bus_int_n & vdp_int),
        .NMI_n     (1'b1),
        .BUSRQ_n   (1'b1),
        .M1_n      (bus_m1_n),
        .MREQ_n    (bus_mreq_n),
        .IORQ_n    (bus_iorq_n),
        .RD_n      (bus_rd_n),
        .WR_n      (bus_wr_n),
        .RFSH_n    (bus_rfsh_n),
        .HALT_n    ( ),
        .BUSAK_n   ( ),
        .A         (bus_addr),
        .D         (cpu_data),
        .Data_Reverse (bus_data_reverse)
    );

    //vdp
	wire vdp_csw_n; //VDP write request
	wire vdp_csr_n; //VDP read request	
    wire [7:0] vdp_dout;
    wire vdp_int;
    wire WeVdp_n;
    wire [16:0] VdpAdr;
    wire [15:0] VrmDbi;
    wire [7:0] VrmDbo;
    wire VideoDHClk;
    wire VideoDLClk;
    assign vdp_csw_n = (bus_addr[7:2] == 6'b100110 && bus_iorq_n == 1'b0 && bus_wr_n == 1'b0)? 1'b0:1'b1; // I/O:98-9Bh   / VDP (V9938/V9958)
    assign vdp_csr_n = (bus_addr[7:2] == 6'b100110 && bus_iorq_n == 1'b0 && bus_rd_n == 1'b0)? 1'b0:1'b1; // I/O:98-9Bh   / VDP (V9938/V9958)

    v9958_top vdp4 (
        .clk (clk_27m),
        .s1 (1'b0),
        .clk_50 (1'b0),
        .clk_125 (1'b0),

        .reset_n (bus_reset_n & reset2_n),
        .mode    (bus_addr[1:0]),
        .csw_n   (vdp_csw_n),
        .csr_n   (vdp_csr_n),

        .int_n   (vdp_int),
        .gromclk (),
        .cpuclk  (),
        .cdi     (vdp_dout),
        .cdo     (cpu_data),

        .audio_sample   (audio_sample),

        .adc_clk  (),
        .adc_cs   (),
        .adc_mosi (),
        .adc_miso (1'b0),

        .maxspr_n    (1'b1),
        .scanlin_n   (1'b0),
        .gromclk_ena_n (1'b1),
        .cpuclk_ena_n  (1'b1),

        .WeVdp_n(WeVdp_n),
        .VdpAdr(VdpAdr),
        .VrmDbi(VrmDbi),
        .VrmDbo(VrmDbo),

        .VideoDHClk(VideoDHClk),
        .VideoDLClk(VideoDLClk),

        .tmds_clk_p    (clk_p),
        .tmds_clk_n    (clk_n),
        .tmds_data_p   (data_p),
        .tmds_data_n   (data_n)

    );

    //slots decoding
    reg [7:0] ppi_port_a;
    wire ppi_req;
    wire [1:0] pri_slot;
    wire [3:0] pri_slot_num;
    wire [3:0] page_num;

    //----------------------------------------------------------------
    //-- PPI(8255) / primary-slot
    //----------------------------------------------------------------
    assign ppi_req = (bus_addr[7:0] == 8'ha8 && bus_iorq_n == 1'b0 && bus_wr_n == 1'b0)? 1'b1:1'b0;

    always @ (posedge bus_clk_3m6 or negedge bus_reset_n) begin
        if ( bus_reset_n == 1'b0)
            ppi_port_a <= 8'h00;
        else begin
            if (ppi_req == 1'b1 && bus_wr_n == 1'b0 && bus_addr[1:0] == 2'b00) begin
                ppi_port_a <= cpu_data;
            end
        end
    end

    //expanded slot 3 signals
    reg [7:0] exp_slot3;
    wire [1:0] exp_slot3_page;
    wire [3:0] exp_slot3_num;
    wire exp_slot3_req_r;
    wire exp_slot3_req_w;
    wire xffff;

    assign xffff = ( bus_addr == 16'hffff ) ? 1 : 0;
    assign exp_slot3_req_w = ( bus_mreq_n == 1'b0 && bus_wr_n == 1'b0 && xffff == 1'b1 && pri_slot_num[3] == 1'b1 ) ? 1'b1: 1'b0;
    assign exp_slot3_req_r = ( bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && xffff == 1'b1 && pri_slot_num[3] == 1'b1 ) ? 1'b1: 1'b0;

    // slot #3
    always @ (posedge bus_clk_3m6 or negedge bus_reset_n) begin
        if ( bus_reset_n == 1'b0 )
            exp_slot3 <= 8'h00;
        else begin
            if (exp_slot3_req_w == 1'b1 ) begin
                exp_slot3 <= cpu_data;
            end
        end
    end

    // slots decoding
    assign pri_slot = ( bus_addr[15:14] == 2'b00) ? ppi_port_a[1:0] :
                      ( bus_addr[15:14] == 2'b01) ? ppi_port_a[3:2] :
                      ( bus_addr[15:14] == 2'b10) ? ppi_port_a[5:4] :
                                             ppi_port_a[7:6];

    assign pri_slot_num = ( pri_slot == 2'b00 ) ? 4'b0001 :
                          ( pri_slot == 2'b01 ) ? 4'b0010 :
                          ( pri_slot == 2'b10 ) ? 4'b0100 :
                                                  4'b1000;

    assign page_num = ( bus_addr[15:14] == 2'b00) ? 4'b0001 :
                      ( bus_addr[15:14] == 2'b01) ? 4'b0010 :
                      ( bus_addr[15:14] == 2'b10) ? 4'b0100 :
                                                    4'b1000;

    assign exp_slot3_page = ( bus_addr[15:14] == 2'b00) ? exp_slot3[1:0] :
                            ( bus_addr[15:14] == 2'b01) ? exp_slot3[3:2] :
                            ( bus_addr[15:14] == 2'b10) ? exp_slot3[5:4] :
                                                          exp_slot3[7:6];

    assign exp_slot3_num = ( exp_slot3_page == 2'b00 ) ? 4'b0001 :
                           ( exp_slot3_page == 2'b01 ) ? 4'b0010 :
                           ( exp_slot3_page == 2'b10 ) ? 4'b0100 :
                                                         4'b1000;

    wire slot3_req;
    assign slot3_req = ( bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[3] == 1'b1 ) ? 1'b1 : 1'b0;

    //mapper
    reg mapper_read;
    reg mapper_write;
    wire [7:0] mapper_dout;
    wire [21:0] mapper_addr;
    reg [7:0] mapper_reg0;
    reg [7:0] mapper_reg1;
    reg [7:0] mapper_reg2;
    reg [7:0] mapper_reg3;
    wire mapper_reg_write;

    assign mapper_addr = (bus_addr [15:14] == 2'b00 ) ? { mapper_reg0, bus_addr[13:0] } :
                         (bus_addr [15:14] == 2'b01 ) ? { mapper_reg1, bus_addr[13:0] } :
                         (bus_addr [15:14] == 2'b10 ) ? { mapper_reg2, bus_addr[13:0] } :
                                                        { mapper_reg3, bus_addr[13:0] };

//assign mapper_read = ( s1 == 0 && bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[3] == 1'b1 && exp_slot3_num[3] == 1'b1 && xffff == 1'b0 ) ? 1'b1 : 1'b0;
//assign mapper_write = ( bus_mreq_n == 1'b0 && bus_wr_n == 1'b0 && pri_slot_num[3] == 1'b1 && exp_slot3_num[3] == 1'b1 && xffff == 1'b0 ) ? 1'b1 : 1'b0;
//assign mapper_read = ( s1 == 0 && bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[2] == 1'b1 ) ? 1'b1 : 1'b0;
//assign mapper_write = ( bus_mreq_n == 1'b0 && bus_wr_n == 1'b0 && pri_slot_num[2] == 1'b1 ) ? 1'b1 : 1'b0;
always @ (posedge clk_54m) begin
    mapper_read <= 1'b0;
    mapper_write <= 1'b0;
    //if (s1 == 0 && bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[2] == 1'b1) mapper_read <= 1'b1;
    //if ( bus_mreq_n == 1'b0 && bus_wr_n == 1'b0 && pri_slot_num[2] == 1'b1 ) mapper_write <= 1'b1;
    if (s1 == 0 && bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[3] == 1'b1 && exp_slot3_num[3] == 1'b1 && xffff == 1'b0) mapper_read <= 1'b1;
    if ( bus_mreq_n == 1'b0 && bus_wr_n == 1'b0 && pri_slot_num[3] == 1'b1 && exp_slot3_num[3] == 1'b1 && xffff == 1'b0 ) mapper_write <= 1'b1;
end

assign mapper_reg_write = ( (bus_iorq_n == 1'b0 && bus_wr_n == 1'b0) && (bus_addr [7:2] == 6'b111111) )?1'b1:1'b0;

always @(posedge clk_54m or negedge bus_reset_n) begin
    if (bus_reset_n == 1'b0) begin
        mapper_reg0	<= 8'b00000011;
        mapper_reg1	<= 8'b00000010;
        mapper_reg2	<= 8'b00000001;
        mapper_reg3	<= 8'b00000000;
    end
    else if (mapper_reg_write == 1'b1) begin
        case (bus_addr[1:0])
            2'b00: mapper_reg0 <= cpu_data;
            2'b01: mapper_reg1 <= cpu_data;
            2'b10: mapper_reg2 <= cpu_data;
            2'b11: mapper_reg3 <= cpu_data;
        endcase
    end
end

memory memory_ctrl (
    .clk_108m(clk_108m),
    .clk_108m_n(clk_108m_n),
    .reset_n(bus_reset_n & reset1_n),
    .VideoDLClk(VideoDLClk),
    .WeVdp_n(WeVdp_n),
    .vdp_din(VrmDbo),
    .mapper_din(cpu_data),
    .vdp_addr(VdpAdr),
    .mapper_addr(mapper_addr),
    .mapper_read(mapper_read),
    .mapper_write(mapper_write),
    .refresh(ex_bus_rfsh_n),
    .vdp_dout(VrmDbi),
    .mapper_dout(mapper_dout),
    .sdram_fail(sdram_fail),
    .O_sdram_clk(O_sdram_clk),
    .O_sdram_cke(O_sdram_cke),
    .O_sdram_cs_n(O_sdram_cs_n),
    .O_sdram_cas_n(O_sdram_cas_n),
    .O_sdram_ras_n(O_sdram_ras_n),
    .O_sdram_wen_n(O_sdram_wen_n),
    .IO_sdram_dq(IO_sdram_dq),
    .O_sdram_addr(O_sdram_addr),
    .O_sdram_ba(O_sdram_ba),
    .O_sdram_dqm(O_sdram_dqm)
);

    //bios
    wire bios_req;
    wire [7:0] bios_dout;
    assign bios_req = ( bus_addr[15] == 1'b0 && bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[0] == 1'b1 ) ? 1'b1 : 1'b0;

    bios_msx2p bios1 (
        .address (bus_addr[14:0]),
        .clock (bus_clk_3m6),
        .data (8'h00),
        .wren (1'b0),
        .q (bios_dout)
    );

    //subrom
    wire subrom_req;
    wire [7:0] subrom_dout;

    assign subrom_req = ( bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[3] == 1'b1 && page_num[0] == 1'b1 && exp_slot3_num[0] == 1'b1 ) ? 1'b1 : 1'b0;

    subrom_msx2p subrom1 (
        .address (bus_addr[13:0]),
        .clock (bus_clk_3m6),
        .data (8'h00),
        .wren (1'b0),
        .q (subrom_dout)
    );

    //fm+logo
    wire [7:0] fm_logo_dout;
    assign fm_logo_req = ( bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[3] == 1'b1 && page_num[1] == 1'b1 && exp_slot3_num[0] == 1'b1 ) ? 1'b1 : 1'b0;

`ifdef FMMUSIC
    fm_logo fm_logo1 (
        .address (bus_addr[13:0]),
        .clock (bus_clk_3m6),
        .data (8'h00),
        .wren (1'b0),
        .q (fm_logo_dout)
    );
`else
    logo logo1 (
        .address (bus_addr[13:0]),
        .clock (bus_clk_3m6),
        .data (8'h00),
        .wren (1'b0),
        .q (fm_logo_dout)
    );
`endif

    //rtc
    wire rtc_req_r;
    wire rtc_req_w;
    wire [7:0] rtc_dout;

    assign rtc_req_w = (bus_addr[7:1] == 7'b1011010 && bus_iorq_n == 1'b0 && bus_wr_n == 1'b0)? 1'b1 : 1'b0; // I/O:B4-B5h   / RTC
    assign rtc_req_r = (bus_addr[7:1] == 7'b1011010 && bus_iorq_n == 1'b0 && bus_rd_n == 1'b0)? 1'b1 : 1'b0; // I/O:B4-B5h   / RTC

    rtc rtc1(
        .clk21m(bus_clk_3m6),
        .reset(1'b0),
        .clkena(1'b1),
        .req(rtc_req_w | rtc_req_r),
        .ack(),
        .wrt(rtc_req_w),
        .adr(bus_addr),
        .dbi(rtc_dout),
        .dbo(cpu_data)
    );

    //YM219 PSG
    wire psgBdir;
    wire psgBc1;
    wire iorq_wr_n;
    wire iorq_rd_n;
    wire [7:0] psg_dout;
    wire [7:0] psgSound1;
    wire [7:0] psgPA;
    wire [7:0] psgPB;
    wire clk_1m8;
    assign iorq_wr_n = bus_iorq_n | bus_wr_n;
    assign iorq_rd_n = bus_iorq_n | bus_rd_n;
    assign psgBdir = ( bus_addr[7:3]== 5'b10100 && iorq_wr_n == 1'b0 && bus_addr[1]== 0 ) ?  1'b1 : 1'b0; // I/O:A0-A2h / PSG(AY-3-8910) bdir = 1 when writing to &HA0-&Ha1
    assign psgBc1 = ( bus_addr[7:3]== 5'b10100 && ((iorq_rd_n==1'b0 && bus_addr[1]== 1) || (bus_addr[1]==0 && iorq_wr_n==1'b0 && bus_addr[0]==1'b0))) ? 1'b1 : 1'b0; // I/O:A0-A2h / PSG(AY-3-8910) bc1 = 1 when writing A0 or reading A2
    //psgBc1 <= '1' when busAddress (7 downto 3) = "10100" and ((ioRd_n='0' and busAddress(1)='1') or (busAddress(1)='0' and ioWr_n='0' and busAddress(0)='0')) else '0'; -- I/O:A0-A2h / PSG(AY-3-8910) bc1 = 1 when
    assign psgPA =8'h00;
    reg psgPB = 8'hff;

    Gowin_CLKDIV2 clkdiv2_2(
        .clkout(clk_1m8), //output clkout
        .hclkin(bus_clk_3m6), //input hclkin
        .resetn(1'b1) //input resetn
    );

    YM2149 psg1 (
        .I_DA(cpu_data),
        .O_DA(),
        .O_DA_OE_L(),
        // control
        .I_A9_L(1'b0),
        .I_A8(1'b1),
        .I_BDIR(psgBdir),
        .I_BC2(1'b1),
        .I_BC1(psgBc1),
        .I_SEL_L(1'b1),
        
        .O_AUDIO(psgSound1),
        // port a
        .I_IOA(psgPA),
        .O_IOA(),
        .O_IOA_OE_L(),
        // port b
        .I_IOB(psgPB),
        .O_IOB(psgPB),
        .O_IOB_OE_L(),
        
        .ENA(1'b1), // clock enable for higher speed operation
        .RESET_L(bus_reset_n),
        .CLK(clk_1m8),
        .clkHigh(clk_27m),
        .debug ()
    );

    //opll
    wire opll_req_n; 
    wire [9:0] opll_mo;
    wire [9:0] opll_ro;
    reg [11:0] opll_mix;

    assign opll_req_n = ( bus_iorq_n == 1'b0 && bus_addr[7:1] == 7'b0111110  &&  bus_wr_n == 1'b0 )  ? 1'b0 : 1'b1;    // I/O:7C-7Dh   / OPLL (YM2413)

    opll  opll1 (
        .xin (bus_clk_3m6),
        .xout (),
        .xena (1'b1),
        .d (cpu_data),
        .a (bus_addr[0]),
        .cs_n (opll_req_n),
        .we_n (1'b0),
        .ic_n (bus_reset_n),
        .mo (opll_mo),
        .ro (opll_ro)
    );

    //scc
    wire [14:0] scc_wav;
    wire [7:0] scc_dout;
    wire scc_req;
    wire scc_wrt;

    assign scc_req = ( page_num[2] == 1'b1 && bus_mreq_n == 1'b0 && (bus_wr_n == 1'b0 || bus_rd_n == 1'b0 ) && pri_slot_num[0] == 1'b1 ) ? 1'b1 : 1'b0;
    assign scc_wrt = ( scc_req == 1'b1 && bus_wr_n == 1'b0 ) ? 1'b1 : 1'b0;

    megaram scc1 (
        .clk21m (bus_clk_3m6),
        .reset (~bus_reset_n),
        .clkena (1'b1),
        .req (scc_req),
        .ack (),
        .wrt (scc_wrt),
        .adr (bus_addr),
        .dbi (scc_dout),
        .dbo (cpu_data),

        .ramreq (),
        .ramwrt (), 
        .ramadr (), 
        .ramdbi (8'h00),
        .ramdbo  (),

        .mapsel (2'b00),        // "0-":SCC+, "10":ASC8K, "11":ASC16K

        .wavl (scc_wav),
        .wavr ()
    );

    //mixer
    reg [23:0] fm_wav;
    reg [16:0] fm_mix;
    reg [14:0] scc_wav2;
	reg [15:0] audio_sample;
	reg [15:0] audio_sample1;
	reg [15:0] audio_sample2;

`ifdef FMMUSIC
    always @ (posedge bus_clk_3m6) begin
        opll_mix <= {2'b00, opll_mo} + {2'b00, opll_ro} - 12'b001000000000;
        fm_mix <= { opll_mix , 5'b00000 };
        fm_wav <=  { fm_mix[14:0] , 9'b000000000 };

        audio_sample1 <= { 4'b0000 , psgSound1 , 4'b0000 };
        audio_sample2 <= { 1'b0 , fm_wav_filter[23] , fm_wav_filter[21:8] };
        audio_sample <= audio_sample1 + audio_sample2;
    end
`else
    always @ (posedge bus_clk_3m6) begin
        scc_wav2 <= { 1'b0 , ~scc_wav[14] , scc_wav[13:1] };
        fm_wav <= { 1'b0, scc_wav2, 8'b00000000 };

        audio_sample1 <= { 4'b0000 , psgSound1 , 4'b0000 };
        audio_sample2 <= fm_wav[23:8];
        audio_sample <= audio_sample1 + audio_sample2;
    end
`endif

    wire [23:0] fm_wav_filter;
    fm_filter  #(
        .DATA_WIDTH(24)
    )
    filtro_fm (
        .clk_3m6 (bus_clk_3m6),
        .clk_27m  (clk_27m),
        .reset (~bus_reset_n),
        .data_in (fm_wav),
        .data_out (fm_wav_filter)
    );

assign notocar = 1; //psgSound1[7] ^ psgSound1[6] ^ psgSound1[5] ^ psgSound1[4] ^ psgSound1[3] ^ psgSound1[2] ^ psgSound1[1] ^ psgSound1[0];

endmodule
