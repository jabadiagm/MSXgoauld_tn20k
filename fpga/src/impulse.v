module impulse(
    input       clk,
    input       din,
    output      dout
);

reg din_ff;

always @(posedge clk ) begin
    din_ff <= din;
end

assign dout = din & ~din_ff;

endmodule