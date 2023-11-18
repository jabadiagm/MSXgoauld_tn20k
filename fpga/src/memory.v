module memory (
	input clk_108m,
	input clk_108m_n,
	input reset_n,
	input VideoDLClk,
	input WeVdp_n,
	input [7:0] vdp_din,
	input [7:0] mapper_din,
	input [16:0] vdp_addr,
	input [21:0] mapper_addr,
    input mapper_read,
    input mapper_write,
    input refresh,
	output [15:0] vdp_dout,
	output [7:0] mapper_dout,
	output sdram_fail,

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

localparam FREQ = 108_000_000;
wire [21:0] sdram_address;
reg sdram_read;
reg sdram_write;
wire [15:0] sdram_din;
wire [1:0] sdram_wdm;
//wire [7:0] sdram_dout;
wire [15:0] sdram_dout16;
wire sdram_busy;
//wire sdram_fail;
reg sdram_refresh;
reg sdram_req_r;
reg sdram_req_w;
wire sdram_vdp;
wire sdram_read_vdp;
wire sdram_write_vdp;
reg sdram_read_mapper;
reg sdram_write_mapper;
wire sdram_start_vdp;
wire sdram_start_mapper;
wire    VrmWre;
assign  VrmWre = (~WeVdp_n) & VideoDLClk;
assign sdram_vdp = ( VideoDLClk == 1 ) ? 1 : 0;
assign sdram_address = ( sdram_vdp == 1 ) ? { 6'b100000 , vdp_addr[15:0] } : mapper_addr[21:1];
assign sdram_wdm = ( sdram_vdp == 1 ) ? { ~vdp_addr[16], vdp_addr[16] } : { ~mapper_addr[0], mapper_addr[0] };
assign sdram_din = ( sdram_vdp == 1 ) ? { vdp_din, vdp_din } : { mapper_din, mapper_din };
assign sdram_read_vdp = (reset_n == 1 && sdram_start_vdp == 1  && VrmWre == 1'b0) ? 1 : 0 ;
assign sdram_write_vdp = (reset_n == 1 && sdram_start_vdp == 1 && VrmWre == 1'b1) ? 1 : 0 ;
//assign sdram_read_mapper = ( s1 == 1 && sdram_start_mapper == 1 && mapper_read == 1 ) ? 1 : 0;
//assign sdram_write_mapper = ( s1 == 1 && sdram_start_mapper == 1 && mapper_write == 1 ) ? 1 : 0;
//assign sdram_read = sdram_read_vdp; // | sdram_read_mapper;
//assign sdram_write = sdram_write_vdp; // | sdram_write_mapper;
//assign sdram_refresh = (s1 == 1 && sdram_start_mapper == 1 && mapper_read == 0 && mapper_write == 0 && refresh == 0) ? 1 : 0 ;


impulse start_vdp (
    .clk (clk_108m),
    .din (VideoDLClk),
    .dout (sdram_start_vdp)
);

impulse start_mapper (
    .clk (clk_108m),
    .din (~VideoDLClk),
    .dout (sdram_start_mapper)
);

reg [7:0] mapper_dout_ff;
reg mapper_seq;
reg [2:0] mapper_cnt;
always @ (posedge clk_108m or negedge reset_n) begin
    if ( reset_n == 0) begin
        mapper_seq <= 0;
        mapper_cnt <= 3'd0;
    end
    else begin
        case ( mapper_seq )
            1'b0 :
                if ( sdram_start_mapper == 1 && enable_read_w == 1 )begin
                    mapper_cnt <= 3'd0;
                    mapper_seq <= 1;
                end
            1'b1 : begin
                mapper_cnt <= mapper_cnt + 1;
                if ( mapper_cnt == 3'd4 ) begin
                    if ( mapper_addr[0] == 1'b0) begin
                        mapper_dout_ff <= sdram_dout16[7:0];
                    end
                    else begin
                        mapper_dout_ff <= sdram_dout16[15:8];
                    end
                    mapper_seq <= 0;
                end
            end
        endcase
    end
end
assign mapper_dout = mapper_dout_ff;

always @ (posedge clk_108m) begin
    sdram_read <= 1'b0;
    sdram_write <= 1'b0;
    sdram_refresh <= 1'b0;
    if (sdram_start_vdp == 1 ) begin
        if (VrmWre == 1'b1) begin
            sdram_write <= 1'b1;
        end
        else begin
            sdram_read <= 1'b1;
        end
    end
    else if (sdram_start_mapper == 1 ) begin
        if ( enable_read_w == 1'b1 ) begin
            sdram_read <= 1'b1;
        end
        else if ( enable_write_w == 1'b1 ) begin
            sdram_write <= 1'b1;
        end
        else if ( enable_refresh_w == 1 )
            sdram_refresh <= 1'b1;
    end
end

reg [1:0] enable_read_seq;
reg enable_read;
wire enable_read_w;
always @ (posedge clk_108m or negedge reset_n) begin
    if ( reset_n == 0) begin
        enable_read_seq <= 2'd0;
        enable_read <= 0;
    end
    else begin
        enable_read <= 0;
        case ( enable_read_seq )
            2'd0 :
                if ( sdram_start_vdp == 1 && mapper_read == 1 )begin
                    enable_read_seq <= 2'd1;
                end
            2'd1 : begin
                enable_read <= 1;
                if ( sdram_start_vdp == 1 ) begin
                    enable_read_seq <= 2'd2;
                end
            end
            2'd2 :
                if ( mapper_read == 0 ) begin
                    enable_read_seq <= 2'd0;
                end
            default:
                enable_read_seq <= 2'd0;
        endcase
    end
end
assign enable_read_w = enable_read;

reg [1:0] enable_write_seq;
reg enable_write;
wire enable_write_w;
always @ (posedge clk_108m or negedge reset_n) begin
    if ( reset_n == 0) begin
        enable_write_seq <= 2'd0;
        enable_write <= 0;
    end
    else begin
        enable_write <= 0;
        case ( enable_write_seq )
            2'd0 :
                if ( sdram_start_vdp == 1 && mapper_write == 1 )begin
                    enable_write_seq <= 2'd1;
                end
            2'd1 : begin
                enable_write <= 1;
                if ( sdram_start_vdp == 1 ) begin
                    enable_write_seq <= 2'd2;
                end
            end
            2'd2 :
                if ( mapper_write == 0 ) begin
                    enable_write_seq <= 2'd0;
                end
            default:
                enable_write_seq <= 2'd0;
        endcase
    end
end
assign enable_write_w = enable_write;

reg [1:0] enable_refresh_seq;
reg enable_refresh;
wire enable_refresh_w;
always @ (posedge clk_108m or negedge reset_n) begin
    if ( reset_n == 0) begin
        enable_refresh_seq <= 2'd0;
        enable_refresh <= 0;
    end
    else begin
        enable_refresh <= 0;
        case ( enable_refresh_seq )
            2'd0 :
                if ( sdram_start_vdp == 1 && refresh == 0 )begin
                    enable_refresh_seq <= 2'd1;
                end
            2'd1 : begin
                enable_refresh <= 1;
                if ( sdram_start_vdp == 1 ) begin
                    enable_refresh_seq <= 2'd2;
                end
            end
            2'd2 :
                if ( refresh == 1 ) begin
                    enable_refresh_seq <= 2'd0;
                end
            default:
                enable_refresh_seq <= 2'd0;
        endcase
    end
end
assign enable_refresh_w = enable_refresh;

reg [15:0] vdp_dout_ff;
always_latch begin
    if (sdram_vdp) begin
        vdp_dout_ff <= sdram_dout16;
    end
end
assign vdp_dout = vdp_dout_ff;

// SDRAM driver

      wire sdram_enabled;
      memory_controller #(.FREQ(108_000_000) )
       vram(.clk(clk_108m), 
            .clk_sdram(clk_108m_n), 
            .resetn(reset_n),
            .read(sdram_read), 
            .write(sdram_write),
            .refresh(sdram_refresh),
            .addr(sdram_address),
            .din(sdram_din),
            .wdm(sdram_wdm),
            .dout(sdram_dout16),
            .busy(sdram_busy), 
            .fail(sdram_fail), 
            .total_written( ),
            .enabled(sdram_enabled),

            .SDRAM_DQ(IO_sdram_dq), .SDRAM_A(O_sdram_addr), .SDRAM_BA(O_sdram_ba), .SDRAM_nCS(O_sdram_cs_n),
            .SDRAM_nWE(O_sdram_wen_n), .SDRAM_nRAS(O_sdram_ras_n), .SDRAM_nCAS(O_sdram_cas_n), 
            .SDRAM_CLK(O_sdram_clk), .SDRAM_CKE(O_sdram_cke), .SDRAM_DQM(O_sdram_dqm)
    );

    //static vram
//    wire [7:0] vdp_dbi;
//    ram64k vram64k_inst(
//      .clk(ex_clk_27m),
//      .we(~WeVdp_n & VideoDLClk),
//      .re(1'b1), //~ReVdp_n & VideoDLClk),
//      .addr(vdp_addr[15:0] ),
//      .din(vdp_din),
//      .dout(vdp_dbi)
//    );
    //assign vdp_dout = { vdp_dbi, vdp_dbi };
	
endmodule