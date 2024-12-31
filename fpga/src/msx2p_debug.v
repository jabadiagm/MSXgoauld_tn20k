
module msx2p_debug(
    input clk_27m,
    input clk,
    input clk_enable,
    input reset_n,
	input [15:0] bus_addr,
    input [7:0] bus_data,
    input bus_iorq_n,
    input bus_mreq_n,
    input bus_wr_n,
    input send,

    output uart_tx,
    output boot_ok
);

    reg [31:0] counter_tic = 32'd0;
    wire tic;
    always @ (posedge clk_27m) begin
        counter_tic <= counter_tic + 1;
        if (counter_tic > 2700000) begin
            counter_tic <= 32'd0;
        end
    end
    assign tic = (counter_tic == 32'd0) ? 1: 0;

	reg [7:0] debug_state = 8'd0;
    reg [7:0] page23_slot_expanded = 8'd0;
    reg [7:0] primary_slot = 8'd0;
    reg [7:0] secondary_slot = 8'd0;
    reg[7:0] subrom_found = 8'd0;
    reg[7:0] rtc_found = 8'd0;

    always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			debug_state <= 8'd0;
            page23_slot_expanded <= 8'd0;
            primary_slot <= 8'd0;
            secondary_slot <= 8'd0;
            subrom_found <= 8'd0;
            rtc_found <= 8'd0;

        end else if (clk_enable == 1) begin
			case (debug_state)

				8'd00: begin //First byte
					if (bus_addr == 16'h0000 && bus_data == 8'hf3) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd01: begin //Second byte
					if (bus_addr == 16'h0001 && bus_data == 8'hc3) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd02: begin //Third byte
					if (bus_addr == 16'h0002 && bus_data == 8'h16) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd03: begin //jp #0416
					if (bus_addr == 16'h0003 && bus_data == 8'h04) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd04: begin 
					if (bus_addr == 16'h0416) begin //CHKRAM
						debug_state <= debug_state + 1;
					end
				end
				8'd05: begin //Select Slot 0
					if (bus_addr == 16'h0436) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd06: begin //Page2: Slot 0 is expanded / not expanded
					if (bus_addr == 16'h044b) begin
                        page23_slot_expanded[4] <= 1;
						debug_state <= debug_state + 1;
					end
                    else if (bus_addr == 16'h0451) begin
                        debug_state <= debug_state + 1;
                    end
				end
				8'd07: begin //Select Slot 1
					if (bus_addr == 16'h0436) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd08: begin //Page2: Slot 1 is expanded / not expanded
					if (bus_addr == 16'h044b) begin
                        page23_slot_expanded[5] <= 1;
						debug_state <= debug_state + 1;
					end
                    else if (bus_addr == 16'h0451) begin
                        debug_state <= debug_state + 1;
                    end
				end
				8'd09: begin //Select Slot 2
					if (bus_addr == 16'h0436) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd10: begin //Page2: Slot 2 is expanded / not expanded
					if (bus_addr == 16'h044b) begin
                        page23_slot_expanded[6] <= 1;
						debug_state <= debug_state + 1;
					end
                    else if (bus_addr == 16'h0451) begin
                        debug_state <= debug_state + 1;
                    end
				end
				8'd11: begin //Select Slot 3
					if (bus_addr == 16'h0436) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd12: begin //Page2: Slot 3 is expanded / not expanded
					if (bus_addr == 16'h044b) begin
                        page23_slot_expanded[7] <= 1;
						debug_state <= debug_state + 1;
					end
                    else if (bus_addr == 16'h0451) begin
                        debug_state <= debug_state + 1;
                    end
				end
				8'd13: begin //Select Slot 0
					if (bus_addr == 16'h04a2) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd014: begin //Page3: Slot 0 is expanded / not expanded
					if (bus_addr == 16'h04ab) begin
                        page23_slot_expanded[0] <= 1;
						debug_state <= debug_state + 1;
					end
                    else if (bus_addr == 16'h04b4) begin
                        debug_state <= debug_state + 1;
                    end
				end
				8'd15: begin //Select Slot 1
					if (bus_addr == 16'h04a2) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd016: begin //Page3: Slot 1 is expanded / not expanded
					if (bus_addr == 16'h04ab) begin
                        page23_slot_expanded[1] <= 1;
						debug_state <= debug_state + 1;
					end
                    else if (bus_addr == 16'h04b4) begin
                        debug_state <= debug_state + 1;
                    end
				end
				8'd17: begin //Select Slot 2
					if (bus_addr == 16'h04a2) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd018: begin //Page3: Slot 2 is expanded / not expanded
					if (bus_addr == 16'h04ab) begin
                        page23_slot_expanded[2] <= 1;
						debug_state <= debug_state + 1;
					end
                    else if (bus_addr == 16'h04b4) begin
                        debug_state <= debug_state + 1;
                    end
				end
				8'd19: begin //Select Slot 3
					if (bus_addr == 16'h04a2) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd020: begin //Page3: Slot 3 is expanded / not expanded
					if (bus_addr == 16'h04ab) begin
                        page23_slot_expanded[3] <= 1;
						debug_state <= debug_state + 1;
					end
                    else if (bus_addr == 16'h04b4) begin
                        debug_state <= debug_state + 1;
                    end
				end
				8'd21: begin //init2
					if (bus_addr == 16'h7b61) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd22: begin //select primary slot RAM in page 2 and 3; out (#a8),a
					if (bus_addr == 16'h7b66) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd23: begin //out (#a8),a
					if (bus_addr[7:0] == 8'hA8 && bus_iorq_n == 0 && bus_wr_n == 0) begin
                        primary_slot <= bus_data;
						debug_state <= debug_state + 1;
					end
				end
				8'd24: begin //select secundary slot RAM in page 2 and 3; ld (#ffff),a
					if (bus_addr == 16'h7b69) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd25: begin //ld (#ffff),a
					if (bus_addr == 16'hffff && bus_mreq_n == 0 && bus_wr_n == 0) begin
                        secondary_slot <= bus_data;
						debug_state <= debug_state + 1;
					end
				end
				8'd26: begin //ldir - init ram
					if (bus_addr == 16'h7b78) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd27: begin //Set EXPTBL
					if (bus_addr == 16'h7b7a) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd28: begin //Set SSLTLP
					if (bus_addr == 16'h7B80) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd29: begin //JP INIT3; JP #7C76
					if (bus_addr == 16'h7bbb) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd30: begin //Init Basic
					if (bus_addr == 16'h7c76) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd031: begin //Subrom found / not found
					if (bus_addr == 16'h03ca) begin
                        subrom_found[0] <= 1;
						debug_state <= debug_state + 1;
					end
                    else if (bus_addr == 16'h0413) begin
                        debug_state <= 8'hff;
                    end
				end
				8'd32: begin //Init subrom
					if (bus_addr == 16'h035a && bus_data == 8'h21) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd33: begin //Rtc found / not found
					if (bus_addr == 16'h0450) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd034: begin //Rtc found / not found
					if (bus_addr == 16'h045f) begin
                        rtc_found[0] <= 1;
						debug_state <= debug_state + 1;
					end
                    else if (bus_addr == 16'h043c) begin
                        debug_state <= 8'hff;
                    end
				end





				8'd35: begin //Init logo
					if (bus_addr == 16'h7a00 && bus_data == 8'hf3) begin
						debug_state <= debug_state + 1;
					end
				end
				8'd36: begin //Display enabled
					if (bus_addr == 16'h7a24) begin
						debug_state <= debug_state + 1;
					end
				end
/*


				8'd15: begin //Ok and mainloop
					if (bus_addr == 16'h411f) begin
						debug_state <= debug_state + 1;
					end
				end

*/




			endcase
        end
    end

`include "print.v"
defparam tx.uart_freq=115200;
defparam tx.clk_freq=27000000;
assign print_clk = clk_27m;
assign uart_tx = uart_txp;

reg [7:0] send_state = 8'd0;

always @ (posedge clk_27m or negedge reset_n) begin
		if (!reset_n) begin
			send_state <= 8'd0;

        end 
        else if (tic == 1) begin
			case (send_state)

				8'd00: begin
                    if (send == 1) begin
                        send_state <= send_state + 1;
                    end
                end
				8'd01: begin
                    `print("debug_state=", STR);
                    send_state <= send_state + 1;
                end
				8'd02: begin
                    `print(debug_state, HEX);
                    send_state <= send_state + 1;
                end
				8'd03: begin
                    `print("\n", STR);
                    send_state <= send_state + 1;
                end
				8'd04: begin
                    `print("page23_slot_expanded=", STR);
                    send_state <= send_state + 1;
                end
				8'd05: begin
                    `print(page23_slot_expanded, HEX);
                    send_state <= send_state + 1;
                end
				8'd06: begin
                    `print("\n", STR);
                    send_state <= send_state + 1;
                end
				8'd07: begin
                    `print("primary_slot=", STR);
                    send_state <= send_state + 1;
                end
				8'd08: begin
                    `print(primary_slot, HEX);
                    send_state <= send_state + 1;
                end
				8'd09: begin
                    `print("\n", STR);
                    send_state <= send_state + 1;
                end
				8'd10: begin
                    `print("secondary_slot=", STR);
                    send_state <= send_state + 1;
                end
				8'd11: begin
                    `print(secondary_slot, HEX);
                    send_state <= send_state + 1;
                end
				8'd12: begin
                    `print("\n", STR);
                    send_state <= send_state + 1;
                end
				8'd13: begin
                    `print("subrom_found=", STR);
                    send_state <= send_state + 1;
                end
				8'd14: begin
                    `print(subrom_found, HEX);
                    send_state <= send_state + 1;
                end
				8'd15: begin
                    `print("\n", STR);
                    send_state <= send_state + 1;
                end
				8'd16: begin
                    `print("rtc_found=", STR);
                    send_state <= send_state + 1;
                end
				8'd17: begin
                    `print(rtc_found, HEX);
                    send_state <= send_state + 1;
                end
				8'd18: begin
                    `print("\n", STR);
                    send_state <= send_state + 1;
                end

            endcase
        end

    //`print("Initializing HyperRAM test...\n", STR);
    //`print(debug_state, HEX);
end





endmodule
