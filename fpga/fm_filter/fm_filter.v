// Javier Abadía / jabadiagm@gmail.com

module fm_filter
#(
    parameter         DATA_WIDTH = 32
)
(
	input clk_3m6,
	input clk_27m,
	input reset,
    input [DATA_WIDTH-1:0] data_in,
	output [DATA_WIDTH-1:0] data_out
);

wire [DATA_WIDTH-1:0] opll_wav;
wire [DATA_WIDTH-1:0] opll_wav1;
wire [DATA_WIDTH-1:0] opll_wav2;
wire [DATA_WIDTH-1:0] opll_wav3;
wire [DATA_WIDTH-1:0] opll_wav4;
wire [DATA_WIDTH-1:0] opll_wav5;
wire [DATA_WIDTH-1:0] opll_wav6;
wire [DATA_WIDTH-1:0] opll_wav7;
wire [DATA_WIDTH-1:0] opll_wav8;
wire [DATA_WIDTH-1:0] opll_wav9;
wire [DATA_WIDTH-1:0] opll_wav10;
wire [DATA_WIDTH-1:0] opll_wav11;
wire [DATA_WIDTH-1:0] opll_wav12;

reg clk_1m8 = 1'b0;
reg clk_360k = 1'b0;
reg clk_36k = 1'b0;
reg [3:0] clk_360k_counter = 4'd0;
reg [3:0] clk_36k_counter = 4'd0;

//generated clocks

always @ (posedge clk_3m6) begin
    clk_1m8 <= ~clk_1m8;
    if (clk_360k_counter < 4)
        clk_360k_counter <= clk_360k_counter+1;
    else begin
        clk_360k_counter <= 4'd0;
        clk_360k <= ~clk_360k;
    end
end

always @ (posedge clk_360k) begin
    if (clk_36k_counter < 4)
        clk_36k_counter <= clk_36k_counter+1;
    else begin
        clk_36k_counter <= 4'd0;
        clk_36k <= ~clk_36k;
    end
end

assign opll_wav = data_in;

lpf2 #(
	.MSBI(DATA_WIDTH - 1)
	) filter1 (
        .clk21m (clk_3m6),
        .reset (reset),
        .clkena (1'b1),
        .idata (opll_wav),
        .odata  (opll_wav1)
	);

lpf2 #(
	.MSBI(DATA_WIDTH - 1)
	) filter1b (
        .clk21m (clk_3m6),
        .reset (reset),
        .clkena (1'b1),
        .idata (opll_wav1),
        .odata  (opll_wav2)
	);

inter_clock #(
        .DATA_WIDTH(DATA_WIDTH)
    ) interclock1 (
        .clock_low (clk_1m8),
        .clock_high (clk_27m),
        .reset (reset),
        .data_in (opll_wav2),
        .data_out (opll_wav3)
    );

lpf2 #(
	.MSBI(DATA_WIDTH - 1)
	) filter2 (
        .clk21m (clk_1m8),
        .reset (reset),
        .clkena (1'b1),
        .idata (opll_wav3),
        .odata  (opll_wav4)
	);

lpf2 #(
	.MSBI(DATA_WIDTH - 1)
	) filter2b (
        .clk21m (clk_1m8),
        .reset (reset),
        .clkena (1'b1),
        .idata (opll_wav4),
        .odata  (opll_wav5)
	);

inter_clock #(
        .DATA_WIDTH(DATA_WIDTH)
    ) interclock2 (
        .clock_low (clk_360k),
        .clock_high (clk_27m), //(clk_1m8),
        .reset (reset),
        .data_in (opll_wav5),
        .data_out (opll_wav6)
    );

lpf2 #(
	.MSBI(DATA_WIDTH - 1)
	) filter3 (
        .clk21m (clk_360k),
        .reset (reset),
        .clkena (1'b1),
        .idata (opll_wav6),
        .odata  (opll_wav7)
	);

lpf2 #(
	.MSBI(DATA_WIDTH - 1)
	) filter4 (
        .clk21m (clk_360k),
        .reset (reset),
        .clkena (1'b1),
        .idata (opll_wav7),
        .odata  (opll_wav8)
	);

//esefir5 #(
//    .msbi (DATA_WIDTH - 1)
//    ) filter4c (
//        .clk (clk_360k),
//        .reset (reset),
//        .wavin (opll_wav6),
//        .wavout  (opll_wav7)
//    );

//lpf2 #(
//	.MSBI(DATA_WIDTH - 1)
//	) filter4b (
//        .clk21m (clk_360k),
//        .reset (reset),
//        .clkena (1'b1),
//        .idata (opll_wav7),
//        .odata  (opll_wav8)
//	);

//esefir5 #(
//    .msbi (DATA_WIDTH - 1)
//    ) filter4c (
//        .clk (clk_360k),
//        .reset (reset),
//        .wavin (opll_wav7),
//        .wavout  (opll_wav8)
//    );

inter_clock #(
        .DATA_WIDTH(DATA_WIDTH)
    ) interclock3 (
        .clock_low (clk_36k),
        .clock_high (clk_27m), //(clk_360k),
        .reset (reset),
        .data_in (opll_wav8),
        .data_out (opll_wav9)
    );

lpf1 #(
	.MSBI(DATA_WIDTH - 1)
	) filter5 (
        .clk21m (clk_36k),
        .reset (reset),
        .clkena (1'b1),
        .idata (opll_wav9),
        .odata  (opll_wav10)
	);


assign data_out = opll_wav10;

endmodule
