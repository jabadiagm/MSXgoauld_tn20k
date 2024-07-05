module megaramSCC#(
    parameter OFFSET_ADDR = 23'h100000
)(
    input clk,
    input reset_n,
    input [15:0] addr,
    input [7:0] cdin,
    output [7:0] cdout,
    output busreq,
    input merq_n,
    input merq2_n,
    input clk_3m6,
    input enable,
    input sltsl_n,
    input iorq_n,
    input m1_n,
    input rd_n,
    input wr_n,
    output ram_ena,
    output cart_ena,
    output [22:0] mem_addr,
    output [14:0] scc_wave, 
    input scc_enable,
    input [1:0] megaram_type
);

reg [7:0] ff_memreg[0:3];
reg ff_ram_ena;
reg ff_scc_ram;

integer i;

wire [1:0] switch_bank_w;

assign switch_bank_w =  megaram_type == 2'b00 ? {addr[14], addr[13]} :
                        megaram_type == 2'b01 ? {addr[14], addr[13]} :
                        megaram_type == 2'b10 ? ((addr[15:12] == 4'h6) ? 2'b01 : 2'b10) :
                                                ((addr[15:11] == 5'b01100) ? 2'b10 :
                                                 (addr[15:11] == 5'b01101) ? 2'b11 :
                                                 (addr[15:11] == 5'b01110) ? 2'b00 : 2'b01);
wire [1:0] page_select_w;
assign page_select_w =  megaram_type == 2'b10 ? {addr[15], addr[14]} : {addr[14], addr[13]};

always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        for (i=0; i<=3; i=i+1)
            ff_memreg[i] <= 3-i;
        ff_ram_ena <= 1'b0;
        ff_scc_ram <= 1'b0;
    end else begin
        if (clk_3m6) begin
            if (~iorq_n && m1_n) begin
                if (addr[7:0] == 8'h8E) begin
                    if (wr_n == 0) begin
                        ff_ram_ena <= 1'b0; // enable rom mode, page selection
                    end
                    if (rd_n == 0) begin
                        ff_ram_ena <= 1'b1; // enable ram mode, disable page selection
                    end
                end
            end
            if (~ff_ram_ena) begin 
                if (wr_n == 0 && cart_ena) begin

                    case(megaram_type)
                        2'b00: ff_memreg[ switch_bank_w ] <= cdin & 8'hff; // konami 
                        2'b01: ff_memreg[ switch_bank_w ] <= cdin & 8'hff; // konami SCC
                        2'b10: ff_memreg[ switch_bank_w ] <= cdin & 8'hff; // ASCII16
                        2'b11: ff_memreg[ switch_bank_w ] <= cdin & 8'hff; // ASCII8

                    endcase
                end
            end
            if (/*~ff_ram_ena &&*/ ~wr_n && cart_ena && addr[15:11] == 5'b10010) begin
                ff_scc_ram <= (cdin[5:0] == 6'h3F) ? scc_enable : 0;
            end
        end
    end
end

wire scc_req_w;

megaram mega1(
    .clk21m(clk),
    .reset(~reset_n),
    .clkena(enable),
    .req(scc_req_w),
    //.ack(),
    .wrt(~wr_n),
    .adr(addr),
    .dbi(cdout),
    .dbo(cdin),
    //.ramreq(),
    //.ramwrt(),
    //.ramadr(),
    .ramdbi(8'h00),
    //.ramdbo(),
    .mapsel(2'b00), // SCC+ "-0":SCC+, "01":ASC8K, "11":ASC16K
    .wavl(scc_wave)
    //.wavr()
);


assign ram_ena = ff_ram_ena;

wire [7:0] page_w;
assign page_w = ff_memreg[ page_select_w ];                            // Konami/KonamiSCC

wire [22:0] page_addr_w;
assign page_addr_w = (megaram_type == 2'b10) ? { 2'b0, page_w[6:0], addr[13:0] } :
                     (megaram_type == 2'b01) ? { 3'b0, page_w[5:0], addr[12:0] } :   
                                               { 2'b0, page_w, addr[12:0] };
assign mem_addr = OFFSET_ADDR + page_addr_w;

reg cart_ena_ff;
always @ (posedge clk) begin
    if ( (addr[15:14] == 2'b01 || addr[15:14] == 2'b10) && ~sltsl_n && ~merq_n && iorq_n == 1) 
        cart_ena_ff <= 1;
    else
        cart_ena_ff <= 0;;
end

//assign cart_ena = (addr[15:14] == 2'b01 || addr[15:14] == 2'b10) && ~sltsl_n && ~merq_n && iorq_n ? 1 : 0;
assign cart_ena = cart_ena_ff;

assign busreq = ff_scc_ram && ~sltsl_n && ~merq2_n && iorq_n && addr[15:11] == 5'b10011 && ~rd_n ? scc_enable : 0;
assign scc_req_w = ~sltsl_n && ~merq2_n && iorq_n && addr[15:12] == 4'b1001 ? scc_enable : 0;

endmodule
