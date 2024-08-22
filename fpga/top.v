`define ENABLE_BIOS
`define ENABLE_SOUND //bios required
`define ENABLE_MEGARAM //enable megaram, disable scc. sound required
`define ENABLE_MAPPER //bios required
`define ENABLE_SCAN_LINES

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
    output reg ex_bus_mreq_n,
    output reg ex_bus_iorq_n,
    output reg ex_bus_rd_n,
    output reg ex_bus_wr_n,

    output ex_bus_data_reverse_n,
    output ex_bus_data_reverse,
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
    output [3:0] O_sdram_dqm // 32/4

);

initial begin

end

    //clocks
    wire clk_108m;
    wire clk_108m_n;
    CLK_108P clk_main (
        .clkout(clk_108m), //output clkout
        .lock(), //output lock
        .clkoutp(clk_108m_n), //output clkoutp
        .reset(0), //input reset
        .clkin(ex_clk_27m) //input clkin
    );

    wire clk_enable_27m;
    wire clk_enable_54m;
    reg [1:0] cnt_clk_enable_27m;
    always @ (posedge clk_108m) begin
        cnt_clk_enable_27m <= cnt_clk_enable_27m + 1;
    end
    assign clk_enable_27m = ( cnt_clk_enable_27m == 2'b00 ) ? 1: 0;
    assign clk_enable_54m = ( cnt_clk_enable_27m[0] == 1 ) ? 1: 0;

    wire clk_27m;
    BUFG buf1 (
        .O(clk_27m),
        .I(ex_clk_27m)
    );

//    wire clk_54m;
//    wire clk_54m_buf;
//    Gowin_rPLL pll(
//        .clkout(clk_54m_buf), //output clkout
//        .clkin(ex_clk_27m) //input clkin
//    );

//    BUFG buf2(
//        .O(clk_54m),
//        .I(clk_54m_buf)
//    );

    wire bus_clk_3m6;
    PINFILTER dn1(
        .clk(clk_108m),
        .reset_n(1),
        .din(ex_bus_clk_3m6),
        .dout(bus_clk_3m6)
    );

    wire clk_enable_3m6;
    wire clk_falling_3m6;
    reg bus_clk_3m6_prev;
    always @ (posedge clk_108m) begin
        bus_clk_3m6_prev <= bus_clk_3m6;
    end
    assign clk_enable_3m6 = (bus_clk_3m6_prev == 0 && bus_clk_3m6 == 1);
    assign clk_falling_3m6 = (bus_clk_3m6_prev == 1 && bus_clk_3m6 == 0);

    wire bus_wait_n;
    PINFILTER dn2(
        .clk(clk_108m),
        .reset_n(1),
        .din(ex_bus_wait_n),
        .dout(bus_wait_n)
    );

    wire bus_reset_n;
    PINFILTER dn3(
        .clk(clk_108m),
        .reset_n(1),
        .din(ex_bus_reset_n),
        .dout(bus_reset_n)
    );

    wire int_n;
    PINFILTER dn4(
        .clk(clk_108m),
        .reset_n(1),
        .din(ex_bus_int_n),
        .dout(bus_int_n)
    );

    reg [7:0] bus_data;
//    genvar i;
//    generate
//        for (i = 0; i <= 7; i++)
//        begin: bus_din
//            PINFILTER dn(
//                .clk(clk_108m),
//                .reset_n(1),
//                .din(ex_bus_data[i]),
//                .dout(bus_data[i])
//            );
//        end
//    endgenerate

    always @ (posedge clk_108m) begin
        bus_data <= ex_bus_data;
    end

    //startup logic
    reg reset1_n_ff;
    reg reset2_n_ff;
    reg reset3_n_ff;
    wire reset1_n;
    wire reset2_n;
    wire reset3_n;

    reg [15:0] counter_reset = 0;
    reg [1:0] rst_seq;
    reg rst_step;

    always @ (posedge ex_clk_27m or negedge bus_reset_n) begin
        if (bus_reset_n == 0) begin
            rst_step <= 0;
            counter_reset <= 0;
        end
        else begin
            rst_step <= 0;
            if ( counter_reset <= 16'h8000 ) 
                counter_reset <= counter_reset + 1;
            else begin
                rst_step <= 1;
                counter_reset <= 0;
            end
        end
    end

    always @ (posedge ex_clk_27m or negedge bus_reset_n or posedge sdram_fail) begin
        if (bus_reset_n == 0 || sdram_fail == 1) begin
            rst_seq <= 2'b00;
            reset1_n_ff <= 0;
            reset2_n_ff <= 0;
            reset3_n_ff <= 0;
        end
        else begin
            case ( rst_seq )
                2'b00: 
                    if (rst_step == 1 ) begin
                        reset1_n_ff <= 1;
                        rst_seq <= 2'b01;
                    end
                2'b01: 
                    if (rst_step == 1) begin
                        reset2_n_ff <= 1;
                        rst_seq <= 2'b10;
                    end
                2'b10:
                    if (rst_step == 1) begin
                        reset3_n_ff <= 1;
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
//    reg msel_ff = 0;
    reg [4:0] mp_cnt;
    wire [15:0] bus_addr;
    assign ex_msel = msel;
    assign ex_bus_mp = bus_mp;
//    assign msel = { msel_ff, ~ msel_ff };
//    assign bus_mp = ( msel[1] == 1 ) ? bus_addr[15:8] : bus_addr[7:0];

//    always @ (posedge clk_108m) begin
//        if (cnt_clk_enable_27m == 1) begin
//            msel_ff <= ~ msel_ff;
//        end
//    end

    localparam IDLE = 1'd0;
    localparam LATCH = 1'd1;
    localparam [3:0] TON = 4'd5;
    localparam [3:0] TP = 4'd2; //prefetch time
    reg state_demux;
    reg [3:0] counter_demux;
    reg [15:0] bus_addr_demux;
    reg low_byte_demux;
    wire update_demux;
    assign update_demux = (bus_addr_demux != bus_addr && bus_clk_3m6 == 1) ? 1 : 0;
    assign bus_mp = ( low_byte_demux == 0 ) ? bus_addr[15:8] : bus_addr[7:0];
    always @ (posedge clk_108m) begin
        if (~bus_reset_n) begin
            state_demux <= IDLE;
            bus_addr_demux <= ~ bus_addr;
            low_byte_demux <= 0;
        end 
        else begin
            counter_demux = counter_demux + 4'd1;
            casex ({state_demux, counter_demux})
                {IDLE, 4'bxxxxx}: begin
                    msel <= 2'b00;
                    counter_demux <= 4'd0;
                    low_byte_demux <= 0;
                    if (update_demux == 1 ) begin
                        state_demux <= LATCH;
                    end
                end
                {LATCH, 4'd1} : begin
                    bus_addr_demux <= bus_addr;
                    msel[1] <= 1;
                end
                {LATCH, 4'd1 + TON} : begin
                    msel[1] <= 0;
                end
                {LATCH, 4'd1 + TON + TP} : begin
                    low_byte_demux <= 1;
                end
                {LATCH, 4'd1 + TON + TP + TP} : begin
                    msel[0] <= 1;
                end
                {LATCH, 4'd1 + TON + TP + TP + TON} : begin
                    msel[0] <= 0;
                    msel[1] <= 0;
                    state_demux <= IDLE;
                end
            endcase
        end
    end




    //bus isolation
    wire bus_data_reverse;
    wire bus_m1_n;
    wire bus_mreq_n;
    wire bus_iorq_n;
    wire bus_rd_n;
    wire bus_rfsh_n;
    reg [7:0] cpu_din;
    wire [7:0] cpu_dout;
    wire bus_mreq_disable;
    wire bus_iorq_disable;
    wire bus_enable;
    assign ex_bus_m1_n = bus_m1_n;
    assign ex_bus_rfsh_n = bus_rfsh_n;
    assign ex_bus_data_reverse_n = ~ bus_data_reverse;
    assign ex_bus_data_reverse = bus_data_reverse;
    //assign ex_bus_mreq_n = bus_mreq_n;
    //assign ex_bus_iorq_n = bus_iorq_n;
    //assign ex_bus_rd_n = bus_rd_n;
    //assign ex_bus_wr_n = bus_wr_n;

    assign bus_mreq_disable = ( 
                        `ifdef ENABLE_BIOS
                                bios_req == 1 || exp_slot3_req_r == 1 || subrom_req == 1 || msx_logo_req == 1 
                        `else
                                0 
                        `endif
                        `ifdef ENABLE_MAPPER
                                || mapper_read == 1 || mapper_write == 1 
                        `endif
                        `ifdef ENABLE_SOUND
                            `ifndef ENABLE_MEGARAM
                                || scc_req == 1
                            `else
                                || megaram_scc_req == 1
                            `endif
                        `endif
                                ) ? 1 : 0;
    //assign bus_mreq_disable = ( bios_req == 1 || subrom_req == 1 || msx_logo_req == 1 || scc_req == 1 || mapper_read == 1 || mapper_write == 1) ? 1 : 0;
    //assign bus_mreq_disable = ( bios_req == 1 || subrom_req == 1 || msx_logo_req == 1 || mapper_read == 1 || mapper_write == 1) ? 1 : 0;
    assign bus_iorq_disable = ( vdp_csr_n == 0 || vdp_csw_n == 0 || rtc_req_r == 1 || rtc_req_w == 1 ) ? 1 : 0;
    assign bus_disable = bus_mreq_disable | bus_iorq_disable;
    assign ex_bus_data = ( bus_data_reverse == 1 /* && bus_disable == 0 */ ) ? cpu_dout : 8'hzz;
    assign cpu_din = 
                `ifdef ENABLE_MAPPER
                     ( mapper_read == 1) ? mapper_dout :
                `endif
                `ifdef ENABLE_BIOS
                     ( exp_slot3_req_r == 1) ? ~exp_slot3  :
                     ( bios_req == 1) ? bios_dout : 
                     ( subrom_req == 1) ? subrom_dout :
                     ( msx_logo_req == 1 ) ? msx_logo_dout :
                `endif
                     ( rtc_req_r == 1 ) ? rtc_dout :
                     ( vdp_csr_n == 0) ? vdp_dout :
                `ifdef ENABLE_SOUND
                    `ifndef ENABLE_MEGARAM
                     ( scc_req == 1 ) ? scc_dout:
                    `else
                     ( sccp_req == 1 ) ? sccp_dout:
                     ( megaram_req == 1) ? mapper_dout :
                    `endif
                `endif
                      bus_data;


//    wire ex_bus_rd_n_test;
//    wire ex_bus_wr_n_test;
//    wire ex_bus_iorq_n_test;
//    wire ex_bus_mreq_n_test;
    reg ex_bus_rd_n_ff;
    reg ex_bus_wr_n_ff;
    reg ex_bus_iorq_n_ff;
    reg ex_bus_mreq_n_ff;
    localparam IDLE_ISO = 2'd0;
    localparam ACTIVE_ISO = 2'd1;
    localparam WAIT_ISO = 2'd2;
    reg [1:0] state_iso;
    reg [2:0] counter_iso;

    assign ex_bus_rd_n = ( bus_rd_n | ex_bus_rd_n_ff | bus_disable);
    assign ex_bus_wr_n = ( bus_wr_n | ex_bus_wr_n_ff | bus_disable);
    assign ex_bus_iorq_n = ( bus_iorq_n | bus_iorq_disable );
    assign ex_bus_mreq_n = ( bus_mreq_n | bus_mreq_disable );

    always @ ( posedge clk_108m ) begin
        if (~bus_reset_n) begin
            state_iso <= IDLE_ISO;
            ex_bus_rd_n_ff <= 1;
            ex_bus_wr_n_ff <= 1;
        end 
        else begin
            counter_iso = counter_iso + 3'd1;
            casex ({state_iso, counter_iso})
                {IDLE_ISO, 3'bxxx}: begin
                    ex_bus_rd_n_ff <= 1;
                    ex_bus_wr_n_ff <= 1;
                    counter_iso <= 3'd0;
                    if (bus_rd_n == 0 || bus_wr_n == 0 ) begin
                        state_iso <= ACTIVE_ISO;
                    end
                end
                {ACTIVE_ISO, 3'd2} : begin
                    ex_bus_rd_n_ff <= bus_rd_n;
                    ex_bus_wr_n_ff <= bus_wr_n;
                    state_iso <= WAIT_ISO;
                end
                {WAIT_ISO, 3'bxxx} : begin
                    if ( bus_rd_n == 1 && bus_wr_n == 1 ) begin
                        state_iso <= IDLE_ISO;
                    end
                end
            endcase
        end
    end


    T80a  #(
        .Mode    (0),     // 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
        //.T2Write (0),     //0 => WR_n active in T3, /=0 => WR_n active in T2
        .IOWait   (1)      // 0 => Single I/O cycle, 1 => Std I/O cycle
    ) cpu1 (
        .RESET_n   (bus_reset_n & reset3_n),
        .CLK_n     (clk_108m),
		.clk_enable (clk_enable_3m6),
		.clk_falling (clk_falling_3m6),
        .WAIT_n    (bus_wait_n),
        .INT_n     (bus_int_n & vdp_int),
        .NMI_n     (1),
        .BUSRQ_n   (1),
        .M1_n      (bus_m1_n),
        .MREQ_n    (bus_mreq_n),
        .IORQ_n    (bus_iorq_n),
        .RD_n      (bus_rd_n),
        .WR_n      (bus_wr_n),
        .RFSH_n    (bus_rfsh_n),
        .HALT_n    ( ),
        .BUSAK_n   ( ),
        .A         (bus_addr),
        .DI         (cpu_din),
        .DO         (cpu_dout),
        .Data_Reverse (bus_data_reverse)
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
    assign ppi_req = (bus_addr[7:0] == 8'ha8 && bus_iorq_n == 0 && bus_m1_n == 1 && bus_wr_n == 0)? 1:0;

    always @ (posedge clk_108m or negedge bus_reset_n) begin
        if ( bus_reset_n == 0)
            ppi_port_a <= 8'h00;
        else begin
            if (ppi_req == 1 ) begin
                ppi_port_a <= cpu_dout;
            end
        end
    end

    //expanded slot 3
    reg [7:0] exp_slot3;
    wire [1:0] exp_slot3_page;
    wire [3:0] exp_slot3_num;
    wire exp_slot3_req_r;
    wire exp_slot3_req_w;
    wire xffff;

    assign xffff = ( bus_addr == 16'hffff ) ? 1 : 0;
    assign exp_slot3_req_w = ( bus_mreq_n == 0 && bus_wr_n == 0 && xffff == 1 && pri_slot_num[0] == 1 ) ? 1: 0;
    assign exp_slot3_req_r = ( bus_mreq_n == 0 && bus_rd_n == 0 && xffff == 1 && pri_slot_num[0] == 1 ) ? 1: 0;

    // slot #3
    always @ (posedge clk_108m or negedge bus_reset_n) begin
        if ( bus_reset_n == 0 )
            exp_slot3 <= 8'h00;
        else begin
            if (exp_slot3_req_w == 1 ) begin
                exp_slot3 <= cpu_dout;
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
    assign slot3_req = ( bus_mreq_n == 0 && (bus_rd_n == 0 || bus_wr_n == 0) && pri_slot_num[3] == 1 ) ? 1 : 0;

`ifdef ENABLE_BIOS
    //bios
    wire bios_req;
    wire [7:0] bios_dout;
    assign bios_req = ( bus_addr[15] == 0 && bus_mreq_n == 0 && bus_rd_n == 0 && pri_slot_num[0] == 1 && exp_slot3_num[0] == 1 ) ? 1 : 0;
    //assign bios_req = ( bus_addr[15] == 0 && bus_mreq_n == 0 && bus_rd_n == 0 && pri_slot_num[0] == 1 ) ? 1 : 0;

    bios_msx2p bios1 (
        .address (bus_addr[14:0]),
        .clock (clk_108m),
        .data (8'h00),
        .wren (0),
        .q (bios_dout)
    );

    //subrom
    wire subrom_req;
    wire [7:0] subrom_dout;
    assign subrom_req = ( bus_mreq_n == 0 && bus_rd_n == 0 && pri_slot_num[0] == 1 && page_num[0] == 1 && exp_slot3_num[1] == 1 ) ? 1 : 0;
    //assign subrom_req = ( bus_mreq_n == 0 && bus_rd_n == 0 && pri_slot_num[2] == 1 && page_num[0] == 1 ) ? 1 : 0;

    subrom_msx2p subrom1 (
        .address (bus_addr[13:0]),
        .clock (clk_108m),
        .data (8'h00),
        .wren (0),
        .q (subrom_dout)
    );

    //msx logo
    wire msx_logo_req;
    wire [7:0] msx_logo_dout;
    assign msx_logo_req = ( bus_mreq_n == 0 && bus_rd_n == 0 && pri_slot_num[0] == 1 && page_num[1] == 1 && exp_slot3_num[1] == 1 ) ? 1 : 0;
    //assign msx_logo_req = ( bus_mreq_n == 0 && bus_rd_n == 0 && pri_slot_num[2] == 1 && page_num[1] == 1 ) ? 1 : 0;

  `ifndef ENABLE_MEGARAM
    logo logo1 (
        .address (bus_addr[13:0]),
        .clock (clk_108m),
        .data (8'h00),
        .wren (0),
        .q (msx_logo_dout)
    );
  `else
    logo_fm logo1 (
        .address (bus_addr[13:0]),
        .clock (clk_108m),
        .data (8'h00),
        .wren (0),
        .q (msx_logo_dout)
    );
  `endif
`endif

    //rtc
    wire rtc_req_r;
    wire rtc_req_w;
    wire [7:0] rtc_dout;
    assign rtc_req_w = (bus_addr[7:1] == 7'b1011010 && bus_iorq_n == 0 && bus_m1_n == 1 && bus_wr_n == 0)? 1 : 0; // I/O:B4-B5h   / RTC
    assign rtc_req_r = (bus_addr[7:1] == 7'b1011010 && bus_iorq_n == 0 && bus_m1_n == 1 && bus_rd_n == 0)? 1 : 0; // I/O:B4-B5h   / RTC

    rtc rtc1(
        .clk21m(clk_108m),
        .reset(0),
        .clkena(1),
        .req(rtc_req_w | rtc_req_r),
        .ack(),
        .wrt(rtc_req_w),
        .adr(bus_addr),
        .dbi(rtc_dout),
        .dbo(cpu_dout)
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
    assign vdp_csw_n = (bus_addr[7:2] == 6'b100110 && bus_iorq_n == 0 && bus_m1_n == 1 && bus_wr_n == 0)? 0:1; // I/O:98-9Bh   / VDP (V9938/V9958)
    assign vdp_csr_n = (bus_addr[7:2] == 6'b100110 && bus_iorq_n == 0 && bus_m1_n == 1 && bus_rd_n == 0)? 0:1; // I/O:98-9Bh   / VDP (V9938/V9958)

    v9958_top vdp4 (
        .clk (clk_27m),
        .s1 (0),
        .clk_50 (0),
        .clk_125 (0),

        .reset_n (bus_reset_n ),
        .mode    (bus_addr[1:0]),
        .csw_n   (vdp_csw_n),
        .csr_n   (vdp_csr_n),

        .int_n   (vdp_int),
        .gromclk (),
        .cpuclk  (),
        .cdi     (vdp_dout),
        .cdo     (cpu_dout),

        .audio_sample   (audio_sample),

        .adc_clk  (),
        .adc_cs   (),
        .adc_mosi (),
        .adc_miso (0),

        .maxspr_n    (1),
    `ifdef ENABLE_SCAN_LINES
        .scanlin_n   (0),
    `else
        .scanlin_n   (1),
    `endif
        .gromclk_ena_n (1),
        .cpuclk_ena_n  (1),

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

`ifdef ENABLE_MAPPER
    //mapper
    wire mapper_read;
    wire mapper_write;
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

    assign mapper_read = ( s1 == 0 && bus_mreq_n == 0 && bus_rd_n == 0 && pri_slot_num[0] == 1 && exp_slot3_num[3] == 1 && xffff == 0 ) ? 1 : 0;
    assign mapper_write = ( bus_mreq_n == 0 && bus_wr_n == 0 && pri_slot_num[0] == 1 && exp_slot3_num[3] == 1 && xffff == 0 ) ? 1 : 0;
    //assign mapper_read = ( s1 == 0 && bus_mreq_n == 0 && bus_rd_n == 0 && pri_slot_num[2] == 1 ) ? 1 : 0;
    //assign mapper_write = ( bus_mreq_n == 0 && bus_wr_n == 0 && pri_slot_num[2] == 1 ) ? 1 : 0;
    assign mapper_reg_write = ( (bus_iorq_n == 0 && bus_m1_n == 1 && bus_wr_n == 0) && (bus_addr [7:2] == 6'b111111) )?1:0;

    always @(posedge clk_108m or negedge bus_reset_n) begin
        if (bus_reset_n == 0) begin
            mapper_reg0	<= 8'b00000011;
            mapper_reg1	<= 8'b00000010;
            mapper_reg2	<= 8'b00000001;
            mapper_reg3	<= 8'b00000000;
        end
        else if (mapper_reg_write == 1) begin
            case (bus_addr[1:0])
                2'b00: mapper_reg0 <= cpu_dout;
                2'b01: mapper_reg1 <= cpu_dout;
                2'b10: mapper_reg2 <= cpu_dout;
                2'b11: mapper_reg3 <= cpu_dout;
            endcase
        end
    end
`else
    wire mapper_read;
    wire mapper_write;
    wire [7:0] mapper_dout;
    wire [21:0] mapper_addr;
    assign mapper_read = 0;
    assign mapper_write = 0;
    assign mapper_addr = 22'd0;
`endif

wire [22:0] sdram_addr;
wire sdram_read;
wire sdram_write;
wire sdram_dout;

`ifdef ENABLE_MEGARAM

    assign sdram_addr = (megaram_req == 1) ? megaram_addr[22:0] : mapper_addr;

    assign sdram_read = (mapper_read == 1) ? ~bus_rd_n :
                        (megaram_req == 1) ? ~bus_rd_n :
                        0;

    assign sdram_write = (mapper_write == 1 ) ? ~bus_wr_n :
                         (megaram_req == 1 && megaram_enabled) ? ~bus_wr_n :
                          0;
`else

    assign sdram_addr = mapper_addr;
    assign sdram_read = mapper_read;
    assign sdram_write = mapper_write;

`endif


memory memory_ctrl (
    .clk_108m(clk_108m),
    .clk_108m_n(clk_108m_n),
    .reset_n(bus_reset_n ),
    .VideoDLClk(VideoDLClk),
    .WeVdp_n(WeVdp_n),
    .vdp_din(VrmDbo),
    .mapper_din(cpu_dout),
    .vdp_addr(VdpAdr),
    .mapper_addr(sdram_addr),
    .mapper_read(sdram_read),
    .mapper_write(sdram_write),
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

`ifdef ENABLE_SOUND

    //YM219 PSG
    wire psgBdir;
    wire psgBc1;
    wire iorq_wr_n;
    wire iorq_rd_n;
    wire [7:0] psg_dout;
    wire [7:0] psgSound1;
    wire [7:0] psgPA;
    wire [7:0] psgPB;
    reg clk_1m8;
    assign iorq_wr_n = bus_iorq_n | bus_wr_n;
    assign iorq_rd_n = bus_iorq_n | bus_rd_n;
    assign psgBdir = ( bus_addr[7:3]== 5'b10100 && iorq_wr_n == 0 && bus_addr[1]== 0 ) ?  1 : 0; // I/O:A0-A2h / PSG(AY-3-8910) bdir = 1 when writing to &HA0-&Ha1
    assign psgBc1 = ( bus_addr[7:3]== 5'b10100 && ((iorq_rd_n==0 && bus_addr[1]== 1) || (bus_addr[1]==0 && iorq_wr_n==0 && bus_addr[0]==0))) ? 1 : 0; // I/O:A0-A2h / PSG(AY-3-8910) bc1 = 1 when writing A0 or reading A2
    assign psgPA =8'h00;
    reg psgPB = 8'hff;

    wire clk_enable_1m8;
    reg clk_1m8_prev;
    always @ (posedge clk_108m) begin
        if (clk_enable_3m6) begin
            clk_1m8 <= ~clk_1m8;
        end
    end
    assign clk_enable_1m8 = (clk_enable_3m6 == 1 && clk_1m8 == 1);

    YM2149 psg1 (
        .I_DA(cpu_dout),
        .O_DA(),
        .O_DA_OE_L(),
        .I_A9_L(0),
        .I_A8(1),
        .I_BDIR(psgBdir),
        .I_BC2(1),
        .I_BC1(psgBc1),
        .I_SEL_L(1),
        .O_AUDIO(psgSound1),
        .I_IOA(psgPA),
        .O_IOA(),
        .O_IOA_OE_L(),
        .I_IOB(psgPB),
        .O_IOB(psgPB),
        .O_IOB_OE_L(),
        
        .ENA(clk_enable_1m8), // clock enable for higher speed operation
        .RESET_L(bus_reset_n),
        .CLK(clk_108m),
        .clkHigh(clk_108m),
        .debug ()
    );

    //opll
    wire opll_req_n; 
    wire [9:0] opll_mo;
    wire [9:0] opll_ro;
    reg [11:0] opll_mix;
    wire [15:0] jt2413_wav;

    assign opll_req_n = ( bus_iorq_n == 1'b0 && bus_addr[7:1] == 7'b0111110  &&  bus_wr_n == 1'b0 )  ? 1'b0 : 1'b1;    // I/O:7C-7Dh   / OPLL (YM2413)
  
    jt2413 opll(
        .rst (~bus_reset_n),        // rst should be at least 6 clk&cen cycles long
        .clk (clk_108m),        // CPU clock
        .cen (clk_enable_3m6),        // optional clock enable, if not needed leave as 1'b1
        .din (cpu_dout),
        .addr (bus_addr[0]),
        .cs_n (opll_req_n),
        .wr_n (1'b0),
        // combined output
        .snd (jt2413_wav),
        .sample   ( )
    ); 

    `ifndef ENABLE_MEGARAM
    //scc
     wire [14:0] scc_wav;
     wire [7:0] scc_dout;
     wire scc_req;
     wire scc_wrt;

     assign scc_req = ( page_num[2] == 1 && bus_mreq_n == 0 && (bus_wr_n == 0 || bus_rd_n == 0 ) && pri_slot_num[0] == 1 && exp_slot3_num[2] == 1 ) ? 1 : 0;
     //assign scc_req = ( page_num[2] == 1 && bus_mreq_n == 0 && (bus_wr_n == 0 || bus_rd_n == 0 ) && pri_slot_num[2] == 1 ) ? 1 : 0;
     assign scc_wrt = ( scc_req == 1 && bus_wr_n == 0 ) ? 1 : 0;

     megaram scc1 (
         .clk21m (clk_108m),
         .reset (~bus_reset_n),
         .clkena (clk_enable_3m6),
         .req (scc_req),
         .ack (),
         .wrt (scc_wrt),
         .adr (bus_addr),
         .dbi (scc_dout),
         .dbo (cpu_dout),

         .ramreq (),
         .ramwrt (), 
         .ramadr (), 
         .ramdbi (8'h00),
         .ramdbo  (),

         .mapsel (2'b00),        // "0-":SCC+, "10":ASC8K, "11":ASC16K

         .wavl (scc_wav),
         .wavr ()
     );

    `else

	//megaram
	wire megaram_enabled;
	wire [22:0] megaram_addr;
	wire sccp_req;
	wire [7:0] sccp_dout;
	wire [14:0] sccp_wav;
	wire megaram_req;
	wire megaram_scc_req;
	assign megaram_scc_req = ( bus_mreq_n == 0 && pri_slot_num[3] == 1 && (bus_wr_n == 0 || bus_rd_n == 0 ) ) ? 1 : 0;
	//assign megaram_scc_req = ( bus_mreq_n == 0 && pri_slot_num[0] == 1 && exp_slot3_num[2] == 1 && (bus_wr_n == 0 || bus_rd_n == 0 ) ) ? 1 : 0;

	wire megaram_type_req;
	assign megaram_type_req = (bus_reset_n && ~bus_iorq_n && bus_m1_n && bus_rd_n && ~bus_wr_n && bus_addr[7:0] == 8'h8F) ? 1 : 0;

	wire sccp_enable;
	wire [1:0] megaram_type;
	reg ff_scc_enable;
	reg [1:0] ff_megaram_type; // 0 Konami, 1 Konami SCC+, 2 ASCII16, 3 ASCII8
	assign sccp_enable = ff_scc_enable;
	assign megaram_type = ff_megaram_type;

	always @(posedge clk_108m or negedge bus_reset_n) begin
		if (~bus_reset_n) begin
			ff_megaram_type <= 2'b01;
			ff_scc_enable <= '1;
		end else begin
//			if (megaram_type_req) begin

//				case(cpu_dout)
//					8'h05: begin
//						ff_scc_enable <= 1'b1;
//						ff_megaram_type <= 2'b01;
//					end
//					8'h16: begin
//						ff_scc_enable <= 1'b0;
//						ff_megaram_type <= 2'b10;
//					end
//					8'h08: begin
//						ff_scc_enable <= 1'b0;
//						ff_megaram_type <= 2'b11;
//					end
//					default: begin
//						ff_scc_enable <= 1'b0;
//						ff_megaram_type <= 2'b00;
//					end
//				endcase

//			end
		end
	end

	megaramSCC #
		(
			.OFFSET_ADDR (23'h600000)
		) megaram1 (
		.clk(clk_108m),
		.reset_n(bus_reset_n),
		.addr(bus_addr),
		.cdin(cpu_dout),
		.cdout(sccp_dout),
		.busreq(sccp_req),
		.merq_n(bus_mreq_n),
		.merq2_n(bus_mreq_n),
        .clk_3m6(bus_clk_3m6),
		.enable(clk_enable_3m6),
		.sltsl_n(~megaram_scc_req),
		.iorq_n(bus_iorq_n),
		.m1_n(bus_m1_n),
		.rd_n(bus_rd_n),
		.wr_n(bus_wr_n),
		.ram_ena(megaram_enabled),
		.mem_addr(megaram_addr),
		.cart_ena(megaram_req),
		.scc_wave(sccp_wav),
		.scc_enable(sccp_enable),
		.megaram_type(megaram_type)
	);

    `endif

    //mixer
    reg [23:0] fm_wav;
    reg [16:0] fm_mix;
    reg [14:0] scc_wav2;
	reg [15:0] audio_sample;
	reg [15:0] audio_sample1;
	reg [15:0] audio_sample2;

    always @ (posedge clk_108m) begin
        if (clk_enable_3m6 == 1 ) begin
            audio_sample1 <= { 3'b000 , psgSound1 , 5'b00000 };

          `ifndef ENABLE_MEGARAM
            audio_sample2 <= { scc_wav, 1'b0 } + jt2413_wav;
          `else
            audio_sample2 <= { sccp_wav, 1'b0 } + jt2413_wav;
          `endif

            audio_sample <= audio_sample1 + audio_sample2;

        end
    end

`endif


endmodule