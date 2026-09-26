`define GW_IDE
`include "dv_adjust.vh"

// DirectVideo 1536x240p @ 28.8 MHz (27 * 16/15).
// 27 MHz -> rPLL 144 MHz TMDS -> CLKDIV/5 = 28.8 MHz pixel
// 1820x264 total integer-locks the VDP field. 16/3 of 256 (8/3 of 512).

module v9958_top(
    input   clk,
    input   clk_50,
    input   clk_125,
 //   input   clk_111,

    input   s1,

    input   reset_n,
    input   [1:0] mode,
    input   csw_n,
    input   csr_n,

    output  int_n,
    output  gromclk,
    output  cpuclk,
//    output  clk_108m,
//    output  clk_108m_n,
//    inout   [7:0] cd,
//    inout   [0:7] cd,
    output   [7:0] cdi,
    input    [7:0] cdo,

    input [15:0] audio_sample,

    output  adc_clk,
    output  adc_cs,
    output  adc_mosi,
    input   adc_miso,

    //output  [1:0]   led,

    input   maxspr_n,
    input   scanlin_n,
    input   gromclk_ena_n,
    input   cpuclk_ena_n,

    output            tmds_clk_p,
    output            tmds_clk_n,
    output     [2:0]  tmds_data_p,
    output     [2:0]  tmds_data_n,
    output            hsync_dbg,
    output            vsync_dbg,

    output WeVdp_n,
    output [16:0] VdpAdr,
    input [15:0] VrmDbi,
    output [7:0] VrmDbo,

    output VideoDHClk,
    output VideoDLClk
    
    // SDRAM
//    output O_sdram_clk,
//    output O_sdram_cke,
//    output O_sdram_cs_n,            // chip select
//    output O_sdram_cas_n,           // columns address select
//    output O_sdram_ras_n,           // row address select
//    output O_sdram_wen_n,           // write enable
//    inout [31:0] IO_sdram_dq,       // 32 bit bidirectional data bus
//    output [10:0] O_sdram_addr,     // 11 bit multiplexed address bus
//    output [1:0] O_sdram_ba,        // two banks
//    output [3:0] O_sdram_dqm       // 32/4


    );
    assign clk_108m = clk_sdram_w;
    assign clk_108m_n = clk_sdramp_w;


// VDP signals
	wire			VdpReq;
	wire	[7:0]	VdpDbi;
	wire			VideoSC;
	//wire			VideoDLClk;
	//wire			VideoDHClk;
	//wire			WeVdp_n;
    wire            ReVdp_n;
	//wire	[16:0]	VdpAdr;
	//wire	[7:0]	VrmDbo;
	//wire	[15:0]	VrmDbi;
	wire			pVdpInt_n;
	wire	[4:0]	VDP_ID;
	wire	[6:0]	OFFSET_Y;
    wire            blank_o;

    wire            r9palmode;

	// Video signals
	wire	[5:0]	VideoR;								// RGB Red
	wire	[5:0]	VideoG;								// RGB Green
	wire	[5:0]	VideoB;								// RGB Blue
	wire			VideoHS_n;							// Horizontal Sync
	wire			VideoVS_n;							// Vertical Sync
	wire			VideoCS_n;							// Composite Sync

    wire            scanlin;
    wire            reset_n_w;


    wire clk_bufg;

    // 27 MHz -> 144 MHz TMDS, CLKDIV/5 -> 28.8 MHz pixel
    wire clk_tmds;
    wire clk_tmds_w;
    wire clk_tmds_lock_w;
    wire clk_pixel;
    wire clk_pixel_w;

    wire clk_sdram_w;
    wire clk_sdramp_w;
    wire clk_sdram_lock_w;

    logic [10:0] cy;
    logic [10:0] cx;

    wire clk_w;
    BUFG clk_bufg_inst(
    .O(clk_w),
    .I(clk)
    );

    wire clk_50_w;
    BUFG clk_50_bufg_inst(
    .O(clk_50_w),
    .I(clk_50)
    );
    wire clk_125_w;
    BUFG clk_125_bufg_inst(
    .O(clk_125_w),
    .I(clk_125)
    );

    reg s1_n = 0;
    always @(posedge clk_w) s1_n <= ~s1;

    BUFG rst_bufg_inst(
    .O(rst_n),
    .I(s1_n)
    );

    // Inline rPLL: 27 * 16 / 3 = 144 MHz TMDS (5x 28.8 MHz).
    wire clk_tmds_clkoutp;
    wire clk_tmds_clkoutd;
    wire clk_tmds_clkoutd3;
    rPLL clk_tmds_pll (
        .CLKOUT(clk_tmds),
        .LOCK(clk_tmds_lock_w),
        .CLKOUTP(clk_tmds_clkoutp),
        .CLKOUTD(clk_tmds_clkoutd),
        .CLKOUTD3(clk_tmds_clkoutd3),
        .RESET(~rst_n),
        .RESET_P(1'b0),
        .CLKIN(clk),
        .CLKFB(1'b0),
        .FBDSEL(6'b000000),
        .IDSEL(6'b000000),
        .ODSEL(6'b000000),
        .PSDA(4'b0000),
        .DUTYDA(4'b0000),
        .FDLY(4'b1111)
    );
    defparam clk_tmds_pll.FCLKIN = "27";
    defparam clk_tmds_pll.DYN_IDIV_SEL = "false";
    defparam clk_tmds_pll.IDIV_SEL = 2;
    defparam clk_tmds_pll.DYN_FBDIV_SEL = "false";
    defparam clk_tmds_pll.FBDIV_SEL = 15;
    defparam clk_tmds_pll.DYN_ODIV_SEL = "false";
    defparam clk_tmds_pll.ODIV_SEL = 4;
    defparam clk_tmds_pll.PSDA_SEL = "0100";
    defparam clk_tmds_pll.DYN_DA_EN = "false";
    defparam clk_tmds_pll.DUTYDA_SEL = "1000";
    defparam clk_tmds_pll.CLKOUT_FT_DIR = 1'b1;
    defparam clk_tmds_pll.CLKOUTP_FT_DIR = 1'b1;
    defparam clk_tmds_pll.CLKOUT_DLY_STEP = 0;
    defparam clk_tmds_pll.CLKOUTP_DLY_STEP = 0;
    defparam clk_tmds_pll.CLKFB_SEL = "internal";
    defparam clk_tmds_pll.CLKOUT_BYPASS = "false";
    defparam clk_tmds_pll.CLKOUTP_BYPASS = "false";
    defparam clk_tmds_pll.CLKOUTD_BYPASS = "false";
    defparam clk_tmds_pll.DYN_SDIV_SEL = 2;
    defparam clk_tmds_pll.CLKOUTD_SRC = "CLKOUT";
    defparam clk_tmds_pll.CLKOUTD3_SRC = "CLKOUT";
    defparam clk_tmds_pll.DEVICE = "GW2AR-18C";

    CLKDIV clkdiv5_inst (
        .CLKOUT(clk_pixel),
        .HCLKIN(clk_tmds),
        .RESETN(clk_tmds_lock_w),
        .CALIB(1'b0)
    );
    defparam clkdiv5_inst.DIV_MODE = "5";
    defparam clkdiv5_inst.GSREN = "false";

    assign clk_tmds_w  = clk_tmds;
    assign clk_pixel_w = clk_pixel;

    wire rst_n_w;
    assign rst_n_w = rst_n & clk_tmds_lock_w; 

//    CLK_108P clk_sdramp_inst (
//        .clkout(clk_sdram), //output clkout
//        .lock(clk_sdram_lock_w), //output lock
//        .clkoutp(clk_sdramp), //output clkoutp
//        .reset(~rst_n), //input reset
//        .clkin(clk) //input clkin
//    );

//    BUFG clk_sdram_bufg_inst(
//    .O(clk_sdram_w),
//    .I(clk_sdram)
//    );
//    BUFG clk_sdramp_bufg_inst(
//    .O(clk_sdramp_w),
//    .I(clk_sdramp)
//    );

    wire reset_w;
    assign reset_n_w = rst_n_w & reset_n;
    assign reset_w = ~reset_n_w;

    wire ram_busy, ram_fail;

//      wire [19:0] ram_total_written;
//      wire ram_enabled;
//      memory_controller #(.FREQ(108_000_000) )
//       vram(.clk(clk_sdramp_w), 
//            .clk_sdram(clk_sdram_w), 
//            .resetn(reset_n_w),
//            .read(WeVdp_n & VideoDLClk & VideoDHClk & ~ram_busy), 
//            .write(~WeVdp_n & VideoDLClk & VideoDHClk & ~ram_busy),
//            .refresh(~VideoDLClk & ~VideoDHClk & ~ram_busy),
//            .addr({ 5'b0 , VdpAdr[15:0] } ),
//            .din({ VrmDbo, VrmDbo }),
//            .wdm({ ~VdpAdr[16], VdpAdr[16] }),
//            .dout(VrmDbi),
//            .busy(ram_busy), 
//            .fail(ram_fail), 
//            .total_written(ram_total_written),
//            .enabled(ram_enabled),

//            .SDRAM_DQ(IO_sdram_dq), .SDRAM_A(O_sdram_addr), .SDRAM_BA(O_sdram_ba), .SDRAM_nCS(O_sdram_cs_n),
//            .SDRAM_nWE(O_sdram_wen_n), .SDRAM_nRAS(O_sdram_ras_n), .SDRAM_nCAS(O_sdram_cas_n), 
//            .SDRAM_CLK(O_sdram_clk), .SDRAM_CKE(O_sdram_cke), .SDRAM_DQM(O_sdram_dqm)
//    );


//    wire [7:0] vdp_dbi;
//    ram64k vram64k_inst(
//      .clk(clk_w),
//      .we(~WeVdp_n & VideoDLClk),
//      .re(1'b1), //~ReVdp_n & VideoDLClk),
//      .addr(VdpAdr[15:0] ),
//      .din(VrmDbo),
//      .dout(vdp_dbi)
//    );
//    assign VrmDbi = { vdp_dbi, vdp_dbi };

	// Internal bus signals (common)

    reg io_state_r = 1'b0; 
    reg [1:0] cs_latch;
 	wire [7:0]	CpuDbi;

    reg [1:0] csr_sync_r;
    reg [1:0] csw_sync_r;
    wire csr_next;
    wire csw_next;
    reg csrn_sdram_r;
    reg cswn_sdram_r;

 
//    assign cd = csr_n == 0 ? CpuDbi : 8'bzzzzzzzz;
    assign cdi = CpuDbi;

    assign VDP_ID  =  5'b00010; // V9958
    assign OFFSET_Y = 6'd16; 
    assign scanlin = ~scanlin_n;

    wire cswn_w;
//    PINFILTER cswn_filter (
//        .clk(clk_sdram_w),
//        .reset_n(reset_n_w),
//        .din(csw_n),
//        .dout(cswn_w)
//    );
    assign cswn_w = csw_n;

    wire csrn_w;
//    PINFILTER csrn_filter (
//        .clk(clk_sdram_w),
//        .reset_n(reset_n_w),
//        .din(csr_n),
//        .dout(csrn_w)
//    );
    assign csrn_w = csr_n;

	reg			    CpuReq;
	reg 			CpuWrt;
	reg   	[15:0]	CpuAdr;
    reg     [7:0]   CpuDbo;

     always @(posedge clk_w or negedge reset_n_w) begin
        if(reset_n_w == 0) begin
            io_state_r = 1'b0;

            CpuDbo = 1'b0;
            CpuAdr = 15'b0;
            CpuWrt = 1'b0;
            CpuReq = 1'b0;
        end
        else begin

            if (!io_state_r) begin

                CpuAdr = { 14'b0, { mode[1], mode[0] }};
                CpuDbo = cdo; 
                CpuReq = (csrn_w ^ cswn_w);
                CpuWrt = ~cswn_w;

                cs_latch = { csrn_w, cswn_w };
                io_state_r = 1'b1;

            end else begin

                 CpuWrt = 1'b0;
                 CpuReq = 1'b0;

                 if (cs_latch != { csrn_w, cswn_w }) begin
                    io_state_r = 1'b0;
                 end

            end

        end
    end

    wire pal_mode;
    //assign pal_mode = 0;
    wire vdp_hdmi_reset;
    wire [10:0] vdp_cx;
    wire [10:0] vdp_cy;
    wire vdp_interlace;
    wire vdp_y212;
    wire vdp_highres;
    wire vdp_pic_win;
    wire vdp_border_y;
    VDP u_v9958 (
		.CLK21M				( clk_w         					),
		.RESET				( reset_w                           ),
		.REQ				( CpuReq 							),
		.ACK				( 									),
		.WRT				( CpuWrt							),
		.ADR				( CpuAdr							),
		.DBI				( CpuDbi   							),
		.DBO				( CpuDbo   						    ),
		.INT_N				( pVdpInt_n							),
		.PRAMOE_N			( ReVdp_n							),
		.PRAMWE_N			( WeVdp_n							),
		.PRAMADR			( VdpAdr							),
		.PRAMDBI			( VrmDbi							),
		.PRAMDBO			( VrmDbo							),
		.VDPSPEEDMODE		( ~gromclk_ena_n                     ),	// for V9958 MSX2+/tR VDP
		.RATIOMODE			( 3'b000							    ),	// for V9958 MSX2+/tR VDP
		.CENTERYJK_R25_N 	( 1'b0          					),	// for V9958 MSX2+/tR VDP
		.PVIDEOR			( VideoR							),
		.PVIDEOG			( VideoG							),
		.PVIDEOB			( VideoB							),
		.PVIDEOHS_N			( VideoHS_n							),
		.PVIDEOVS_N			( VideoVS_n							),
		.PVIDEOCS_N			( VideoCS_n							),
		.PVIDEODHCLK		( VideoDHClk						),
		.PVIDEODLCLK		( VideoDLClk						),
		.BLANK_o			( blank_o							),
		.DISPRESO			( 1'b0      				        ),  // 15 kHz / true 240p
		.NTSC_PAL_TYPE		( 1'b1      						),
		.FORCED_V_MODE		( 1'b0      						),
		.LEGACY_VGA			( 1'b0      						),
		.VDP_ID				( VDP_ID							),
		.OFFSET_Y			( OFFSET_Y							),
        .HDMI_RESET         ( vdp_hdmi_reset                    ),
        .PAL_MODE           ( pal_mode                      ),
        //.PAL_MODE           (                                 ),
        .SPMAXSPR           ( ~maxspr_n                         ),  
        .CX                 ( vdp_cx                            ),
        .CY                 ( vdp_cy                            ),
        .INTERLACE          ( vdp_interlace                     ),
        .Y212               ( vdp_y212                          ),
        .HIGHRES            ( vdp_highres                       ),
        .PIC_WIN            ( vdp_pic_win                       ),
        .BORDER_Y           ( vdp_border_y                      )
	);

	//--------------------------------------------------------------
	// Video output
	//--------------------------------------------------------------


    wire [7:0] dvi_r;
    wire [7:0] dvi_g;
    wire [7:0] dvi_b;

    wire [5:0] video_r_s, video_g_s, video_b_s;

    // DV_PIC_Y letterbox; DV_H_SHIFT content pan (not HDMI H porch).
    wire [9:0] y_off = (`DV_PIC_Y < 0) ? 10'd0 : `DV_PIC_Y;

    vdp_hdmi_240p #(.H_OFF(`DV_H_SHIFT)) u_hdmi_scale (
        .clk_vdp   (clk_w),
        .clk_pixel (clk_pixel_w),
        .reset     (reset_w),
        .video_r   (VideoR),
        .video_g   (VideoG),
        .video_b   (VideoB),
        .vdp_cx    (vdp_cx),
        .highres   (vdp_highres),
        .border_y  (vdp_border_y),
        .y_off     (y_off),
        .hdmi_cx   (cx),
        .hdmi_cy   (cy[9:0]),
        .out_r     (video_r_s),
        .out_g     (video_g_s),
        .out_b     (video_b_s)
    );

    assign dvi_r = {video_r_s, 2'b0};
    assign dvi_g = {video_g_s, 2'b0};
    assign dvi_b = {video_b_s, 2'b0};


///////////

    wire clk_cpu;
    CLOCK_DIV #(
        .CLK_SRC(125.0),
        .CLK_DIV(315.0/88.0),
        .PRECISION_BITS(16)
    ) cpuclkd (
        .clk_src(clk_125_w),
        .clk_div(clk_cpu)
    );
    BUFG clk_cpuclk_bufg_inst(
    .O(cpuclk_w),
    .I(clk_cpu)
    );

    assign int_n = pVdpInt_n;

//    wire clk_grom;
//    CLOCK_DIV #(
//        .CLK_SRC(125.0),
//        .CLK_DIV(3.58/8.0),
//        .PRECISION_BITS(16)
//    ) gromclkd (
//        .clk_src(clk_125_w),
//        .clk_div(clk_grom)
//    );

//    BUFG clk_gromclk_bufg_inst(
//    .O(gromclk_w),
//    .I(clk_grom)
//    );

    assign gromclk = cpuclk_ena_n ? cpuclk_w : 1'b1; 
    assign cpuclk = cpuclk_ena_n ? 1'bz :  cpuclk_w;
//////////

    localparam [10:0] H_TOTAL  = `DV_H_TOTAL;
    localparam [10:0] H_ACTIVE = `DV_H_ACTIVE;
    localparam [9:0]  V_TOTAL  = `DV_V_TOTAL;
    localparam [9:0]  V_ACTIVE = `DV_V_ACTIVE;

    reg [7:0] rst_cnt;
    reg       hdmi_reset;
    always @(posedge clk_pixel_w or negedge clk_tmds_lock_w) begin
        if (!clk_tmds_lock_w) begin
            rst_cnt    <= 8'd0;
            hdmi_reset <= 1'b1;
        end else if (rst_cnt != 8'hff) begin
            rst_cnt    <= rst_cnt + 8'd1;
            hdmi_reset <= 1'b1;
        end else if (reset_w) begin
            hdmi_reset <= 1'b1;
        end else begin
            hdmi_reset <= 1'b0;
        end
    end

    // Phase-lock HDMI cy to VDP analog-visible start (BWINDOW_Y),
    // which includes R#7 top/bottom border. DV_PIC_Y still applies.
    reg border_y_d;
    always @(posedge clk_w) border_y_d <= vdp_border_y;
    wire vis_rise = vdp_border_y & ~border_y_d;

    reg pic_tog;
    always @(posedge clk_w or posedge reset_w) begin
        if (reset_w) pic_tog <= 1'b0;
        else if (vis_rise) pic_tog <= ~pic_tog;
    end
    reg [2:0] pic_tog_s;
    always @(posedge clk_pixel_w) pic_tog_s <= {pic_tog_s[1:0], pic_tog};
    wire pic_pulse = pic_tog_s[2] ^ pic_tog_s[1];

    reg pic_pend;
    always @(posedge clk_pixel_w) begin
        if (hdmi_reset) pic_pend <= 1'b0;
        else if (pic_pulse) pic_pend <= 1'b1;
        else if (cx == H_TOTAL - 1'b1) pic_pend <= 1'b0;
    end
    wire cy_load = pic_pend && (cx == H_TOTAL - 1'b1);

    always @(posedge clk_pixel_w) begin
        if (hdmi_reset) begin
            cx <= 11'd0;
            cy <= 11'd0;
        end else if (cx == H_TOTAL - 1'b1) begin
            cx <= 11'd0;
            if (cy_load)
                cy <= {1'b0, y_off};
            else
                cy <= (cy == V_TOTAL - 1'b1) ? 11'd0 : cy + 1'b1;
        end else begin
            cx <= cx + 1'b1;
        end
    end

    localparam AUDIO_RATE = 48000;
    localparam AUDIO_BIT_WIDTH = 16;
    localparam PIXEL_CLOCK = 28800000;

    reg       clk_audio;
    reg [8:0] aclk_cnt;
    always @(posedge clk_pixel_w) begin
        if (aclk_cnt < PIXEL_CLOCK / AUDIO_RATE / 2 - 1)
            aclk_cnt <= aclk_cnt + 9'd1;
        else begin
            aclk_cnt  <= 9'd0;
            clk_audio <= ~clk_audio;
        end
    end

    wire [15:0] sample_w;
    assign sample_w = audio_sample;

    reg [15:0] audio_l, audio_r;
    always @(posedge clk_pixel_w) begin
        audio_l <= sample_w;
        audio_r <= sample_w;
    end

    wire [2:0] tmds;
    wire       tmds_clock;

    hdmi #(
        .AUDIO_RATE(AUDIO_RATE),
        .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
        .VENDOR_NAME({"MSXnano", 8'd0}),
        .PRODUCT_DESCRIPTION({"MSXnano", 72'd0}),
        .PIXEL_REPETITION(4'b0101)
    ) hdmi_240p (
        .clk_pixel_x5(clk_tmds_w),
        .clk_pixel(clk_pixel_w),
        .clk_audio(clk_audio),
        .audio_l(audio_l),
        .audio_r(audio_r),
        .tmds(tmds),
        .tmds_clock(tmds_clock),
        .stmode(2'd0),
        .screen(2'd0),
        .total_lines(9'd264),
        .reset(hdmi_reset),
        .vdp_vs_n(VideoVS_n),
        .cy_load(cy_load),
        .cy_load_val(y_off),
        .rgb({dvi_r, dvi_g, dvi_b}),
        .hsync_dbg(hsync_dbg),
        .vsync_dbg(vsync_dbg)
    );

    ELVDS_OBUF tmds_bufds [3:0] (
        .I ({tmds_clock, tmds}),
        .O ({tmds_clk_p, tmds_data_p}),
        .OB({tmds_clk_n, tmds_data_n})
    );

////////////////////

    // ADC
//    wire sck_enable;
//    wire [11:0] audio_sample;
//    SPI_MCP3202 #(
//	.SGL(1),        // sets ADC to single ended mode
//	.ODD(0)         // sets sample input to channel 0
//	)
//    SPI_MCP3202 (
//	.clk(clk_135_w),                 // 125  MHz 
//	.EN(reset_n_w),                  // Enable the SPI core (ACTIVE HIGH)
//	.MISO(adc_miso),                // data out of ADC (Dout pin)
//	.MOSI(adc_mosi),               // Data into ADC (Din pin)
//    .SCK_ENABLE(sck_enable),
//	.o_DATA(audio_sample),      // 12 bit word (for other modules)
//    .CS(adc_cs),                 // Chip Select
//	.DATA_VALID(sample_valid)          // is high when there is a full 12 bit word. 
//	); 

//    localparam SCKCLK_SRCFRQ = 135.0;
//    localparam SCKCLK_FRQ = 0.9;
//    localparam integer SCKCLK_DELAY0 = $floor(SCKCLK_SRCFRQ / SCKCLK_FRQ / 2.0);
//    localparam integer SCKCLK_DELAY1 = SCKCLK_DELAY0 + $floor((SCKCLK_SRCFRQ / SCKCLK_FRQ) - SCKCLK_DELAY0 + 0.5);
//    logic [$clog2(SCKCLK_DELAY1)-1:0] sckclk_divider;
//    logic clk_sck;


//    wire clk_sck;
//    CLOCK_DIV #(
//        .CLK_SRC(135),
//        .CLK_DIV(0.9),
//        .PRECISION_BITS(16)
//    ) adcclkd (
//        .clk_src(clk_135_w),
//        .clk_div(clk_sck)
//    );
//    BUFG clk_sck_bufg_inst(
//    .O(sckclk_w),
//    .I(clk_sck)
//    );

//    assign adc_clk = sckclk_w & sck_enable;
//    
//    reg [15:0] adc_sample;
//    always @(posedge clk_135_w) begin     
//        if (sample_valid)
//            adc_sample <= { audio_sample[11:0], 4'b0 };
//    end

//    wire [31:0] adc_sample_w;
//    assign adc_sample_w = { adc_sample, 16'b0 };

//    reg [31:0] sample;
//    LPF1 #(
//        .MSBI(32)
//    )
//    LPF (
//        .CLK21M(clk_135_w),
//        .RESET(reset_w),
//        .CLKENA(1'b1),
//        .IDATA(adc_sample_w),
//        .ODATA(sample)
//    );

//    assign sample_w = sample[31:16];

endmodule



