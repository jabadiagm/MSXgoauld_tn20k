`define ENABLE_BIOS
`define ENABLE_SOUND //bios required
`define ENABLE_MAPPER //bios required

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
        .reset(1'b0), //input reset
        .clkin(ex_clk_27m) //input clkin
    );

    wire clk_enable_27m;
    wire clk_enable_54m;
    reg [1:0] cnt_clk_enable_27m;
    always @ (posedge clk_108m) begin
        cnt_clk_enable_27m <= cnt_clk_enable_27m + 1;
    end
    assign clk_enable_27m = ( cnt_clk_enable_27m == 2'b00 ) ? 1'b1: 1'b0;
    assign clk_enable_54m = ( cnt_clk_enable_27m[0] == 1'b1 ) ? 1'b1: 1'b0;

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
        .reset_n(1'b1),
        .din(ex_bus_clk_3m6),
        .dout(bus_clk_3m6)
    );

    wire clk_enable_3m6;
    wire clk_falling_3m6;
    reg bus_clk_3m6_prev;
    always @ (posedge clk_108m) begin
        bus_clk_3m6_prev <= bus_clk_3m6;
    end
    assign clk_enable_3m6 = (bus_clk_3m6_prev == 1'b0 && bus_clk_3m6 == 1'b1);
    assign clk_falling_3m6 = (bus_clk_3m6_prev == 1'b1 && bus_clk_3m6 == 1'b0);

    wire bus_wait_n;
    PINFILTER dn2(
        .clk(clk_108m),
        .reset_n(1'b1),
        .din(ex_bus_wait_n),
        .dout(bus_wait_n)
    );

    wire bus_reset_n;
    PINFILTER dn3(
        .clk(clk_108m),
        .reset_n(1'b1),
        .din(ex_bus_reset_n),
        .dout(bus_reset_n)
    );

    wire int_n;
    PINFILTER dn4(
        .clk(clk_108m),
        .reset_n(1'b1),
        .din(ex_bus_int_n),
        .dout(bus_int_n)
    );

    wire [7:0] bus_data;
    genvar i;
    generate
        for (i = 0; i <= 7; i++)
        begin: bus_din
            PINFILTER dn(
                .clk(clk_108m),
                .reset_n(1'b1),
                .din(ex_bus_data[i]),
                .dout(bus_data[i])
            );
        end
    endgenerate

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
//        if (cnt_clk_enable_27m == 1'b1) begin
//            msel_ff <= ~ msel_ff;
//        end
//    end

    localparam IDLE = 2'd0;
    localparam LATCH = 2'd1;
    localparam [4:0] TON = 4'd5;
    localparam [4:0] TP = 4'd2; //prefetch time
    reg [1:0] state_demux;
    reg [4:0] counter_demux;
    reg [15:0] bus_addr_demux;
    reg low_byte_demux;
    wire update_demux;
    assign update_demux = (bus_addr_demux != bus_addr) ? 1'b1 : 1'b0;
    assign bus_mp = ( low_byte_demux == 1'b0 ) ? bus_addr[15:8] : bus_addr[7:0];
    always @ (posedge clk_108m or negedge bus_reset_n) begin
        if (~bus_reset_n) begin
            state_demux <= IDLE;
            bus_addr_demux <= ~ bus_addr;
            low_byte_demux <= 1'b0;
        end 
        else begin
            counter_demux = counter_demux + 5'd1;
            casex ({state_demux, counter_demux})
                {IDLE, 5'bxxxxx}: begin
                    msel <= 2'b00;
                    counter_demux <= 5'd0;
                    low_byte_demux <= 1'b0;
                    if (update_demux == 1'b1 ) begin
                        state_demux <= LATCH;
                    end
                end
                {LATCH, 5'd1} : begin
                    bus_addr_demux <= bus_addr;
                    msel[1] <= 1'b1;
                end
                {LATCH, 5'd1 + TON} : begin
                    msel[1] <= 1'b0;
                end
                {LATCH, 5'd1 + TON + TP} : begin
                    low_byte_demux <= 1'b1;
                end
                {LATCH, 5'd1 + TON + TP + TP} : begin
                    msel[0] <= 1'b1;
                end
                {LATCH, 5'd1 + TON + TP + TP + TON} : begin
                    msel[0] <= 1'b0;
                    msel[1] <= 1'b0;
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
    //assign ex_bus_mreq_n = bus_mreq_n;
    //assign ex_bus_iorq_n = bus_iorq_n;
    //assign ex_bus_rd_n = bus_rd_n;
    //assign ex_bus_wr_n = bus_wr_n;

    assign bus_mreq_disable = ( 
                        `ifdef ENABLE_BIOS
                                bios_req == 1'b1 || exp_slot3_req_r == 1'b1 || subrom_req == 1'b1 || msx_logo_req == 1'b1 
                        `else
                                1'b0 
                        `endif
                        `ifdef ENABLE_MAPPER
                                || mapper_read == 1'b1 || mapper_write == 1'b1 
                        `endif
                        `ifdef ENABLE_SOUND
                                || scc_req == 1'b1 
                        `endif
                                ) ? 1'b1 : 1'b0;
    //assign bus_mreq_disable = ( bios_req == 1'b1 || subrom_req == 1'b1 || msx_logo_req == 1'b1 || scc_req == 1'b1 || mapper_read == 1'b1 || mapper_write == 1'b1) ? 1'b1 : 1'b0;
    //assign bus_mreq_disable = ( bios_req == 1'b1 || subrom_req == 1'b1 || msx_logo_req == 1'b1 || mapper_read == 1'b1 || mapper_write == 1'b1) ? 1'b1 : 1'b0;
    assign bus_iorq_disable = ( vdp_csr_n == 1'b0 || vdp_csw_n == 1'b0 || rtc_req_r == 1 || rtc_req_w == 1 ) ? 1'b1 : 1'b0;
    assign bus_disable = bus_mreq_disable | bus_iorq_disable;
    assign ex_bus_data = ( bus_data_reverse == 1 /* && bus_disable == 1'b0 */ ) ? cpu_dout : 8'hzz;
    assign cpu_din = 
                `ifdef ENABLE_MAPPER
                     ( mapper_read == 1'b1) ? mapper_dout :
                `endif
                `ifdef ENABLE_BIOS
                     ( exp_slot3_req_r == 1'b1) ? ~exp_slot3  :
                     ( bios_req == 1'b1) ? bios_dout : 
                     ( subrom_req == 1'b1) ? subrom_dout :
                     ( msx_logo_req == 1'b1 ) ? msx_logo_dout :
                `endif
                     ( rtc_req_r == 1 ) ? rtc_dout :
                     ( vdp_csr_n == 1'b0) ? vdp_dout :
                `ifdef ENABLE_SOUND
                     ( scc_req == 1'b1 ) ? scc_dout:
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
            ex_bus_rd_n_ff <= 1'b1;
            ex_bus_wr_n_ff <= 1'b1;
        end 
        else begin
            counter_iso = counter_iso + 3'd1;
            casex ({state_iso, counter_iso})
                {IDLE_ISO, 3'bxxx}: begin
                    ex_bus_rd_n_ff <= 1'b1;
                    ex_bus_wr_n_ff <= 1'b1;
                    counter_iso <= 3'd0;
                    if (bus_rd_n == 1'b0 || bus_wr_n == 1'b0 ) begin
                        state_iso <= ACTIVE_ISO;
                    end
                end
                {ACTIVE_ISO, 3'd2} : begin
                    ex_bus_rd_n_ff <= bus_rd_n;
                    ex_bus_wr_n_ff <= bus_wr_n;
                    state_iso <= WAIT_ISO;
                end
                {WAIT_ISO, 3'bxxx} : begin
                    if ( bus_rd_n == 1'b1 && bus_wr_n == 1'b1 ) begin
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
        .RESET_n   (bus_reset_n ),
        .CLK_n     (clk_108m),
		.clk_enable (clk_enable_3m6),
		.clk_falling (clk_falling_3m6),
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
    assign ppi_req = (bus_addr[7:0] == 8'ha8 && bus_iorq_n == 1'b0 && bus_wr_n == 1'b0)? 1'b1:1'b0;

    always @ (posedge clk_108m or negedge bus_reset_n) begin
        if ( bus_reset_n == 1'b0)
            ppi_port_a <= 8'h00;
        else begin
            if (ppi_req == 1'b1 && bus_wr_n == 1'b0 && bus_addr[1:0] == 2'b00) begin
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
    assign exp_slot3_req_w = ( bus_mreq_n == 1'b0 && bus_wr_n == 1'b0 && xffff == 1'b1 && pri_slot_num[0] == 1'b1 ) ? 1'b1: 1'b0;
    assign exp_slot3_req_r = ( bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && xffff == 1'b1 && pri_slot_num[0] == 1'b1 ) ? 1'b1: 1'b0;

    // slot #3
    always @ (posedge clk_108m or negedge bus_reset_n) begin
        if ( bus_reset_n == 1'b0 )
            exp_slot3 <= 8'h00;
        else begin
            if (exp_slot3_req_w == 1'b1 ) begin
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
    assign slot3_req = ( bus_mreq_n == 1'b0 && (bus_rd_n == 1'b0 || bus_wr_n == 1'b0) && pri_slot_num[3] == 1'b1 && bus_rfsh_n == 1'b1) ? 1'b1 : 1'b0;

`ifdef ENABLE_BIOS
    //bios
    wire bios_req;
    wire [7:0] bios_dout;
    assign bios_req = ( bus_addr[15] == 1'b0 && bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[0] == 1'b1 && exp_slot3_num[0] == 1'b1 ) ? 1'b1 : 1'b0;
    //assign bios_req = ( bus_addr[15] == 1'b0 && bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[0] == 1'b1 ) ? 1'b1 : 1'b0;

    bios_msx2p bios1 (
        .address (bus_addr[14:0]),
        .clock (clk_108m),
        .data (8'h00),
        .wren (1'b0),
        .q (bios_dout)
    );

    //subrom
    wire subrom_req;
    wire [7:0] subrom_dout;
    assign subrom_req = ( bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[0] == 1'b1 && page_num[0] == 1'b1 && exp_slot3_num[1] == 1'b1 ) ? 1'b1 : 1'b0;
    //assign subrom_req = ( bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[2] == 1'b1 && page_num[0] == 1'b1 ) ? 1'b1 : 1'b0;

    subrom_msx2p subrom1 (
        .address (bus_addr[13:0]),
        .clock (clk_108m),
        .data (8'h00),
        .wren (1'b0),
        .q (subrom_dout)
    );

    //msx logo
    wire msx_logo_req;
    wire [7:0] msx_logo_dout;
    assign msx_logo_req = ( bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[0] == 1'b1 && page_num[1] == 1'b1 && exp_slot3_num[1] == 1'b1 ) ? 1'b1 : 1'b0;
    //assign msx_logo_req = ( bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[2] == 1'b1 && page_num[1] == 1'b1 ) ? 1'b1 : 1'b0;

    logo logo1 (
        .address (bus_addr[13:0]),
        .clock (clk_108m),
        .data (8'h00),
        .wren (1'b0),
        .q (msx_logo_dout)
    );
`endif

    //rtc
    wire rtc_req_r;
    wire rtc_req_w;
    wire [7:0] rtc_dout;
    assign rtc_req_w = (bus_addr[7:1] == 7'b1011010 && bus_iorq_n == 1'b0 && bus_wr_n == 1'b0)? 1'b1 : 1'b0; // I/O:B4-B5h   / RTC
    assign rtc_req_r = (bus_addr[7:1] == 7'b1011010 && bus_iorq_n == 1'b0 && bus_rd_n == 1'b0)? 1'b1 : 1'b0; // I/O:B4-B5h   / RTC

    rtc rtc1(
        .clk21m(clk_108m),
        .reset(1'b0),
        .clkena(1'b1),
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
    assign vdp_csw_n = (bus_addr[7:2] == 6'b100110 && bus_iorq_n == 1'b0 && bus_wr_n == 1'b0)? 1'b0:1'b1; // I/O:98-9Bh   / VDP (V9938/V9958)
    assign vdp_csr_n = (bus_addr[7:2] == 6'b100110 && bus_iorq_n == 1'b0 && bus_rd_n == 1'b0)? 1'b0:1'b1; // I/O:98-9Bh   / VDP (V9938/V9958)

    v9958_top vdp4 (
        .clk (clk_27m),
        .s1 (1'b0),
        .clk_50 (1'b0),
        .clk_125 (1'b0),

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

    assign mapper_read = ( s1 == 0 && bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[0] == 1'b1 && exp_slot3_num[3] == 1'b1 && xffff == 1'b0 ) ? 1'b1 : 1'b0;
    assign mapper_write = ( bus_mreq_n == 1'b0 && bus_wr_n == 1'b0 && pri_slot_num[0] == 1'b1 && exp_slot3_num[3] == 1'b1 && xffff == 1'b0 ) ? 1'b1 : 1'b0;
    //assign mapper_read = ( s1 == 0 && bus_mreq_n == 1'b0 && bus_rd_n == 1'b0 && pri_slot_num[2] == 1'b1 ) ? 1'b1 : 1'b0;
    //assign mapper_write = ( bus_mreq_n == 1'b0 && bus_wr_n == 1'b0 && pri_slot_num[2] == 1'b1 ) ? 1'b1 : 1'b0;
    assign mapper_reg_write = ( (bus_iorq_n == 1'b0 && bus_wr_n == 1'b0) && (bus_addr [7:2] == 6'b111111) )?1'b1:1'b0;

    always @(posedge clk_108m or negedge bus_reset_n) begin
        if (bus_reset_n == 1'b0) begin
            mapper_reg0	<= 8'b00000011;
            mapper_reg1	<= 8'b00000010;
            mapper_reg2	<= 8'b00000001;
            mapper_reg3	<= 8'b00000000;
        end
        else if (mapper_reg_write == 1'b1) begin
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

memory memory_ctrl (
    .clk_108m(clk_108m),
    .clk_108m_n(clk_108m_n),
    .reset_n(bus_reset_n ),
    .VideoDLClk(VideoDLClk),
    .WeVdp_n(WeVdp_n),
    .vdp_din(VrmDbo),
    .mapper_din(cpu_dout),
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
    assign psgBdir = ( bus_addr[7:3]== 5'b10100 && iorq_wr_n == 1'b0 && bus_addr[1]== 0 ) ?  1'b1 : 1'b0; // I/O:A0-A2h / PSG(AY-3-8910) bdir = 1 when writing to &HA0-&Ha1
    assign psgBc1 = ( bus_addr[7:3]== 5'b10100 && ((iorq_rd_n==1'b0 && bus_addr[1]== 1) || (bus_addr[1]==0 && iorq_wr_n==1'b0 && bus_addr[0]==1'b0))) ? 1'b1 : 1'b0; // I/O:A0-A2h / PSG(AY-3-8910) bc1 = 1 when writing A0 or reading A2
    assign psgPA =8'h00;
    reg psgPB = 8'hff;

    wire clk_enable_1m8;
    reg clk_1m8_prev;
    always @ (posedge clk_108m) begin
        if (clk_enable_3m6) begin
            clk_1m8 <= ~clk_1m8;
        end
    end
    assign clk_enable_1m8 = (clk_enable_3m6 == 1'b1 && clk_1m8 == 1'b1);


`ifdef ENABLE_SOUND

    YM2149 psg1 (
        .I_DA(cpu_dout),
        .O_DA(),
        .O_DA_OE_L(),
        .I_A9_L(1'b0),
        .I_A8(1'b1),
        .I_BDIR(psgBdir),
        .I_BC2(1'b1),
        .I_BC1(psgBc1),
        .I_SEL_L(1'b1),
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


    //scc
    wire [14:0] scc_wav;
    wire [7:0] scc_dout;
    wire scc_req;
    wire scc_wrt;

    assign scc_req = ( page_num[2] == 1'b1 && bus_mreq_n == 1'b0 && (bus_wr_n == 1'b0 || bus_rd_n == 1'b0 ) && pri_slot_num[0] == 1'b1 && exp_slot3_num[2] == 1'b1 ) ? 1'b1 : 1'b0;
    //assign scc_req = ( page_num[2] == 1'b1 && bus_mreq_n == 1'b0 && (bus_wr_n == 1'b0 || bus_rd_n == 1'b0 ) && pri_slot_num[2] == 1'b1 ) ? 1'b1 : 1'b0;
    assign scc_wrt = ( scc_req == 1'b1 && bus_wr_n == 1'b0 ) ? 1'b1 : 1'b0;

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


    //mixer
    reg [23:0] fm_wav;
    reg [16:0] fm_mix;
    reg [14:0] scc_wav2;
	reg [15:0] audio_sample;
	reg [15:0] audio_sample1;
	reg [15:0] audio_sample2;

    always @ (posedge clk_108m) begin
        if (clk_enable_3m6 == 1'b1 ) begin
            scc_wav2 <= { 1'b0 , ~scc_wav[14] , scc_wav[13:1] };
            fm_wav <= { 1'b0, scc_wav2, 8'b00000000 };

            audio_sample1 <= { 4'b0000 , psgSound1 , 4'b0000 };
            audio_sample2 <= fm_wav[23:8];
            audio_sample <= audio_sample1 + audio_sample2;
        end
    end

`endif


endmodule