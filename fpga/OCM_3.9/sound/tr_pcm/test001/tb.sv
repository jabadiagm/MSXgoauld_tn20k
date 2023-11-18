module tb;
    localparam      CLK_BASE    = 1000000000/21480;
    reg             clk21m;
    reg             reset;
    reg             req;
    wire            ack;
    reg             wrt;
    reg             adr;                //  0:A4h, 1:A5h
    wire    [ 7:0]  dbi;
    reg     [ 7:0]  dbo;
    reg     [ 7:0]  wave_in;            //  -128...127 (two's complement)
    wire    [ 7:0]  wave_out;           //  -128...127 (two's complement)
    string          s_test_name;

    // -------------------------------------------------------------
    //  clock generator
    // -------------------------------------------------------------
    always #(CLK_BASE/2) begin
        clk21m  <= ~clk21m;
    end

    // -------------------------------------------------------------
    //  DUT
    // -------------------------------------------------------------
    tr_pcm u_dut (
        .clk21m     ( clk21m    ),
        .reset      ( reset     ),
        .req        ( req       ),
        .ack        ( ack       ),
        .wrt        ( wrt       ),
        .adr        ( adr       ),
        .dbi        ( dbi       ),
        .dbo        ( dbo       ),
        .wave_in    ( wave_in   ),
        .wave_out   ( wave_out  )
    );

    initial begin
        s_test_name     <= "Initialize";
        clk21m          <= 1'b0;
        reset           <= 1'b1;
        req             <= 1'b0;
        wrt             <= 1'b0;
        adr             <= 1'b0;
        dbo             <= 8'd0;
        wave_in         <= 8'd0;
        repeat( 10 ) @( posedge clk21m );

        reset           <= 1'b0;
        repeat( 10 ) @( posedge clk21m );

        req             <= 1'b0;
        wrt             <= 1'b0;
        adr             <= 1'b0;
        dbo             <= 8'd100;
        @( posedge clk21m );

        req             <= 1'b1;
        wrt             <= 1'b1;
        adr             <= 1'b0;
        dbo             <= 8'd100;
        @( posedge clk21m );

        req             <= 1'b0;
        wrt             <= 1'b0;
        adr             <= 1'b0;
        dbo             <= 8'd0;
        repeat( 1400 ) @( posedge clk21m );

        req             <= 1'b1;
        wrt             <= 1'b1;
        adr             <= 1'b0;
        dbo             <= 8'd200;
        @( posedge clk21m );

        req             <= 1'b0;
        wrt             <= 1'b0;
        adr             <= 1'b0;
        dbo             <= 8'd0;
        repeat( 1400 ) @( posedge clk21m );

        $finish;
    end
endmodule
