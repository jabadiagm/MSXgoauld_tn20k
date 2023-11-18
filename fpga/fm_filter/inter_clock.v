module inter_clock
#(
    parameter         DATA_WIDTH = 16
)
(
	input clock_low,
	input clock_high,
	input reset,
    input [DATA_WIDTH-1:0] data_in,
	output reg [DATA_WIDTH-1:0] data_out
);

reg [1:0] state = 2'd0;
always @ (posedge clock_high, posedge clock_high) begin
	if (reset == 1'b1)
		data_out <= 'd0;
	else begin
		case (state)
			2'd0: begin
				data_out <= data_in;
				state <= 2'd1;
			end
			2'd1: begin
				if (clock_low == 1'b0)
					state <= 2'd2;
			end
			2'd2: begin
				if (clock_low == 1'b1)
					state <= 2'd0;
			end
			default: state <= 2'd0; 
		endcase
	end
		
	
end

endmodule