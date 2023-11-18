//
// rtc.v
//   REAL TIME CLOCK (MSX2 CLOCK-IC)
//   Version 1.00
//
// Copyright (c) 2008-2021 Takayuki Hara
// All rights reserved.
//
// Redistribution and use of this source code or any derivative works, are
// permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Redistributions may not be sold, nor may they be used in a commercial
//    product or activity without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================
// History
// 2008/??/??  t.hara
//   First release
// 2021/02/11  t.hara
//   Changed the reference clock from 10Hz to 3,579,545Hz.
//   Added an initial value to FlipFlop for time.
// 2021/02/12  KdL
//   PreScaler with lfsr counter
// 2021/02/13  t.hara
//   Optimize logic by t.hara
// 2021/02/21  t.hara
//   Transcode to VerilogHDL from VHDL
// 2021/02/24  t.hara
//   Fixed a bug that was added during transcoding.
//   Fixed to reset the one-second counter when updating the time.
// 2021/02/25  t.hara
//   Implement the CR bit of the reset register (reg_ptr=15).
//   Removed the circuit that resets the one-second counter every time the time is updated.
// ============================================================================

module rtc (
        input           clk21m,
        input           reset,
        input           clkena,
        input           req,
        output          ack,
        input           wrt,
        input   [15:0]  adr,
        output  [ 7:0]  dbi,
        input   [ 7:0]  dbo
    );

//  for XTAL 21.47727MHz => clk21m / 6 = 3,579,545.454 MHz
    localparam c_1sec_cnt0  = 22'h2D94A3;   // LFSR count = 3579547 clock ticks (approx +1.546)

//  for XTAL 50.00000MHz => clk21m / 6 = 3,580,729.167 MHz
//  localparam c_1sec_cnt0  = 22'h1F53BB;   // LFSR count = 3580730 clock ticks (approx +0.833)

    // ff
    reg             ff_req          = 1'b0;

    // PreScaler by LFSR algorithm
    reg     [21:0]  ff_1sec_cnt     = 22'd0;
    wire            w_lfsr_d0;

    // register ff
    reg     [3:0]   reg_ptr         = 4'd0;
    reg     [3:0]   reg_mode        = 4'b1000;
    reg     [6:0]   reg_sec         = 7'd0;         // 'h00 ... 'h59
    reg     [6:0]   reg_min         = 7'd0;         // 'h00 ... 'h59
    reg     [5:0]   reg_hou         = 6'd0;         // 'h00 ... 'h23
    reg     [2:0]   reg_wee         = 3'd0;         // 'h0  ... 'h6
    reg     [5:0]   reg_day         = 6'd0;         // 'h01 ... 'h31
    reg     [4:0]   reg_mon         = 5'd0;         // 'h01 ... 'h12
    reg     [7:0]   reg_yea         = 8'd0;         // 'h00 ... 'h99
    reg             reg_1224        = 1'b0;         // 1'b0 = 12hour mode, 1'b1 = 24hour mode
    reg     [1:0]   reg_leap        = 2'b0;         // 2'b00 leap year, 2'b01 ... 2'b11 other year

    // wire
    wire            w_wrt;
    wire            w_mem_we;
    wire    [7:0]   w_mem_addr;
    wire    [7:0]   w_mem_q;

    // -------------------------------------------------------------
    assign w_wrt = req & wrt;

    // -------------------------------------------------------------
    // rtc register read
    // -------------------------------------------------------------
    assign dbi =    (                  reg_ptr   == 4'b1101   && adr[0] == 1'b1 ) ? { 4'b1111       , reg_mode      } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b000000 && adr[0] == 1'b1 ) ? { 4'b1111       , reg_sec[3:0]  } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b000001 && adr[0] == 1'b1 ) ? { 5'b11110      , reg_sec[6:4]  } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b000010 && adr[0] == 1'b1 ) ? { 4'b1111       , reg_min[3:0]  } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b000011 && adr[0] == 1'b1 ) ? { 5'b11110      , reg_min[6:4]  } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b000100 && adr[0] == 1'b1 ) ? { 4'b1111       , reg_hou[3:0]  } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b000101 && adr[0] == 1'b1 ) ? { 6'b111100     , reg_hou[5:4]  } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b000110 && adr[0] == 1'b1 ) ? { 5'b11110      , reg_wee[2:0]  } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b000111 && adr[0] == 1'b1 ) ? { 4'b1111       , reg_day[3:0]  } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b001000 && adr[0] == 1'b1 ) ? { 6'b111100     , reg_day[5:4]  } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b001001 && adr[0] == 1'b1 ) ? { 4'b1111       , reg_mon[3:0]  } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b001010 && adr[0] == 1'b1 ) ? { 7'b1111000    , reg_mon[4]    } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b001011 && adr[0] == 1'b1 ) ? { 4'b1111       , reg_yea[3:0]  } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b001100 && adr[0] == 1'b1 ) ? { 4'b1111       , reg_yea[7:4]  } :
                    ( { reg_mode[1:0], reg_ptr } == 6'b011011 && adr[0] == 1'b1 ) ? { 6'b111100     , reg_leap      } :
                    (                                            adr[0] == 1'b1 ) ? { 4'b1111       , w_mem_q[3:0]  } : 8'hFF;

    // -------------------------------------------------------------
    // request and ack
    // -------------------------------------------------------------
    always @( posedge clk21m ) begin
        ff_req <= req;
    end

    assign ack = ff_req;

    // -------------------------------------------------------------
    // RTC register write
    // -------------------------------------------------------------
    assign w_lfsr_d0 = ~(ff_1sec_cnt[21] ^ ff_1sec_cnt[20]);

    always @( posedge clk21m ) begin
        if( w_wrt == 1'b1 && adr[0] == 1'b0 ) begin
            // register pointer
            reg_ptr <= dbo[3:0];
        end
        else if( w_wrt == 1'b1 && adr[0] == 1'b1 ) begin
            // Rtc registers
            if( reg_mode[1:0] == 2'd0 ) begin
                case( reg_ptr )
                    4'd0:       reg_sec[3:0]    <= dbo[3:0];
                    4'd1:       reg_sec[6:4]    <= dbo[2:0];
                    4'd2:       reg_min[3:0]    <= dbo[3:0];
                    4'd3:       reg_min[6:4]    <= dbo[2:0];
                    4'd4:       reg_hou[3:0]    <= dbo[3:0];
                    4'd5:       reg_hou[5:4]    <= dbo[1:0];
                    4'd6:       reg_wee[2:0]    <= dbo[2:0];
                    4'd7:       reg_day[3:0]    <= dbo[3:0];
                    4'd8:       reg_day[5:4]    <= dbo[1:0];
                    4'd9:       reg_mon[3:0]    <= dbo[3:0];
                    4'd10:      reg_mon[4]      <= dbo[0];
                    4'd11:      reg_yea[3:0]    <= dbo[3:0];
                    4'd12:      reg_yea[7:4]    <= dbo[3:0];
                    default:    begin
                            //  hold
                    end
                endcase
            end
            else if( reg_mode[1:0] == 2'd1 ) begin
                case( reg_ptr )
                    4'd10:      reg_1224        <= dbo[0];
                    4'd11:      reg_leap[1:0]   <= dbo[1:0];
                    default:    begin
                            //  hold
                    end
                endcase
            end

            if( reg_ptr == 4'd13 ) begin
                reg_mode <= dbo[3:0];
            end
            else if( reg_ptr == 4'd15 ) begin
                if( dbo[1] == 1'b1 ) begin
                    ff_1sec_cnt <= 22'd0;
                end
            end
        end
        else if( clkena ) begin

            if( ff_1sec_cnt != c_1sec_cnt0 ) begin
                ff_1sec_cnt <= { ff_1sec_cnt[20:0], w_lfsr_d0 };
            end
            else begin
                ff_1sec_cnt <= 22'd0;
                if( reg_sec[3:0] != 4'h9 ) begin
                    reg_sec[3:0] <= reg_sec[3:0] + 4'h1;
                end
                else begin
                    reg_sec[3:0] <= 4'h0;
                    if( reg_sec[6:4] != 3'h5 ) begin
                        reg_sec[6:4] <= reg_sec[6:4] + 3'h1;
                    end
                    else begin
                        reg_sec[6:4] <= 3'h0;
                        if( reg_min[3:0] != 4'h9 ) begin
                            reg_min[3:0] <= reg_min[3:0] + 4'h1;
                        end
                        else begin
                            reg_min[3:0] <= 4'h0;
                            if( reg_min[6:4] != 3'h5 ) begin
                                reg_min[6:4] <= reg_min[6:4] + 3'h1;
                            end
                            else begin
                                reg_min[6:4] <= 3'h0;
                                if( reg_hou[3:0] == 4'h9 ) begin
                                    reg_hou[3:0] <= 4'h0;
                                    reg_hou[5:4] <= reg_hou[5:4] + 2'h1;
                                end
                                else if( ( {reg_1224, reg_hou[4:0] } != 6'b010001) &&
                                         ( {reg_1224, reg_hou[5:0] } != 7'b1100011) ) begin
                                    reg_hou[3:0] <= reg_hou[3:0] + 4'h1;
                                end
                                else begin
                                    reg_hou[4:0]    <= 5'h0;
                                    reg_hou[5]      <= ~reg_hou[5];

                                    if( reg_wee[2:0] != 3'h6 ) begin
                                        reg_wee[2:0] <= reg_wee[2:0] + 3'h1;
                                    end
                                    else begin
                                        reg_wee[2:0] <= 3'h0;
                                    end

                                    if( (reg_mon == 5'h2  && reg_day == 6'h28 && reg_leap != 2'h0) ||
                                        (reg_mon == 5'h2  && reg_day == 6'h29) ||
                                        (reg_mon == 5'h4  && reg_day == 6'h30) ||
                                        (reg_mon == 5'h6  && reg_day == 6'h30) ||
                                        (reg_mon == 5'h9  && reg_day == 6'h30) ||
                                        (reg_mon == 5'h11 && reg_day == 6'h30) ||
                                        (                    reg_day == 6'h31) ) begin
                                        reg_day[5:0] <= 6'h1;

                                        if( reg_mon[3:0] == 4'h9 ) begin
                                            reg_mon[4:0] <= 5'h10;
                                        end
                                        else if( reg_mon[4:0] != 5'h12 ) begin
                                            reg_mon[3:0] <= reg_mon[3:0] + 4'h1;
                                        end
                                        else begin
                                            reg_mon[4:0] <= 5'h1;
                                            reg_leap[1:0] <= reg_leap[1:0] + 2'h1;
                                            if( reg_yea[3:0] != 4'h9 ) begin
                                                reg_yea[3:0] <= reg_yea[3:0] + 4'h1;
                                            end
                                            else begin
                                                reg_yea[3:0] <= 4'h0;
                                                if( reg_yea[7:4] != 4'h9 ) begin
                                                    reg_yea[7:4] <= reg_yea[7:4] + 4'h1;
                                                end
                                                else begin
                                                    reg_yea[7:4] <= 4'h0;
                                                end
                                            end
                                        end
                                    end

                                    else if( reg_day[3:0] != 4'h9 ) begin
                                        reg_day[3:0] <= reg_day[3:0] + 4'h1;
                                    end
                                    else begin
                                        reg_day[3:0] <= 4'h0;
                                        reg_day[5:4] <= reg_day[5:4] + 2'h1;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    // -------------------------------------------------------------
    // backup memory emulation
    // -------------------------------------------------------------
    assign w_mem_addr   = { 2'b00, reg_mode[1:0], reg_ptr };
    assign w_mem_we     = w_wrt & adr[0];

    ram u_mem (
        .adr    ( w_mem_addr    ),
        .clk    ( clk21m        ),
        .we     ( w_mem_we      ),
        .dbo    ( dbo           ),
        .dbi    ( w_mem_q       )
    );
endmodule
