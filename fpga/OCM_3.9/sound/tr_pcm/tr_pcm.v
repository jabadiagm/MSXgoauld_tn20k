//
// tr_pcm.v
//   turboR PCM Device
//   Revision 1.00
//
// Copyright (c) 2019 Takayuki Hara
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
// ----------------------------------------------------------------------------
//  Update history
//  22nd,March,2021
//      Modified by KdL
//      PreScaler with lfsr counter.
//
//  04th,December,2019
//      Modified by t.hara
//      Initial value of ff_da0 and ff_da1 changed to 127 (level=0).
//
//  30th,November,2019
//      First release by t.hara
//      But not implemented a digital filter (LPF) yet.
//

module tr_pcm (
    input           clk21m,
    input           reset,
    input           req,
    output          ack,
    input           wrt,
    input           adr,                //  0:A4h, 1:A5h
    output  [ 7:0]  dbi,
    input   [ 7:0]  dbo,
    input   [ 7:0]  wave_in,            //  -128...127 (two's complement)
    output  [ 7:0]  wave_out            //  -128...127 (two's complement)
);
    wire    [ 7:0]  w_port_a4h;
    wire    [ 7:0]  w_port_a5h;
    wire    [ 7:0]  w_wave_in;
    wire    [ 7:0]  w_wave_out;
    wire    [ 7:0]  w_sample_hold_in;
    wire    [ 7:0]  w_filter_in;
    wire    [ 7:0]  w_filter_out;
    reg     [ 7:0]  ff_sample_hold;
    reg     [ 7:0]  ff_wave_out;
    reg     [10:0]  ff_counter_low;     //  0...1363 (PreScaler by LFSR algorithm)
    wire            w_lfsr_d0;
    wire            w_counter_low_end;
    wire    [ 7:0]  w_active_buffer;
    reg     [ 1:0]  ff_counter;         //  2bit counter (63.5usec)
    reg             ff_adda;            //  ADDA buffer type select   0: double buffer, 1: single buffer
    reg             ff_mute_off;        //  mute control              0: mute, 1: active
    reg             ff_filt;            //  sample hold signal select 0: base signal, 1: filter signal
    reg             ff_sel;             //  filter input select       0: D/A converter output, 1: wave_in
    reg             ff_smpl;            //  sample hold               0: disable, 1: enable
    reg     [ 7:0]  ff_da0;             //  wave data 1st
    reg     [ 7:0]  ff_da1;             //  wave data 2nd
    wire            w_comp;             //  result of comparison      0: D/A out > sample hold, 1: D/A out < sample hold

    //--------------------------------------------------------------
    // latch
    //--------------------------------------------------------------
    always @( posedge reset or posedge clk21m ) begin
        if( reset ) begin
            ff_da0 <= 8'd127;
        end
        else if( req && wrt && !adr ) begin
            ff_da0 <= dbo;
        end
        else begin
            //  hold
        end
    end

    always @( posedge reset or posedge clk21m ) begin
        if( reset ) begin
            ff_da1 <= 8'd127;
        end
        else if( w_counter_low_end ) begin
            ff_da1 <= ff_da0;
        end
        else begin
            //  hold
        end
    end

    assign w_active_buffer  = (ff_adda == 1'b0) ? ff_da1 : ff_da0;

    //--------------------------------------------------------------
    // base counter
    //--------------------------------------------------------------
    xnor(w_lfsr_d0,ff_counter_low[10],ff_counter_low[8]);
    assign w_counter_low_end = (ff_counter_low == 11'd67);  // LFSR count = 1364 clock ticks

    always @( posedge reset or posedge clk21m ) begin
        if( reset ) begin
            ff_counter_low <= 11'd0;
        end
        else begin
            ff_counter_low <= w_counter_low_end ? 11'd0 : {ff_counter_low[9:0],w_lfsr_d0};
        end
    end

    always @( posedge reset or posedge clk21m ) begin
        if( reset ) begin
            ff_counter <= 2'd0;
        end
        else begin
            if( w_counter_low_end ) begin
                ff_counter = ff_counter + 2'd1;
            end
            else begin
                //  hold
            end
        end
    end

    //--------------------------------------------------------------
    // sample hold
    //--------------------------------------------------------------
    always @( posedge reset or posedge clk21m ) begin
        if( reset ) begin
            ff_smpl <= 1'b0;
        end
        else begin
            if( req && wrt && adr ) begin
                ff_smpl <= dbo[4];
            end
            else begin
                //  hold
            end
        end
    end

    always @( posedge reset or posedge clk21m ) begin
        if( reset ) begin
            ff_sample_hold <= 8'd0;
        end
        else begin
            if( !ff_smpl ) begin
                ff_sample_hold <= w_sample_hold_in;
            end
            else begin
                //  hold
            end
        end
    end

    assign w_sample_hold_in = ( ff_filt ) ? ff_wave_out : w_filter_out;
    assign w_wave_in        = 8'd127 - wave_in;

    //--------------------------------------------------------------
    // selector
    //--------------------------------------------------------------
    always @( posedge reset or posedge clk21m ) begin
        if( reset ) begin
            ff_sel <= 1'b0;
        end
        else begin
            if( req && wrt && adr ) begin
                ff_sel <= dbo[3];
            end
            else begin
                //  hold
            end
        end
    end

    always @( posedge reset or posedge clk21m ) begin
        if( reset ) begin
            ff_filt <= 1'b0;
        end
        else begin
            if( req && wrt && adr ) begin
                ff_filt <= dbo[2];
            end
            else begin
                //  hold
            end
        end
    end

    always @( posedge reset or posedge clk21m ) begin
        if( reset ) begin
            ff_mute_off <= 1'b0;
        end
        else begin
            if( req && wrt && adr ) begin
                ff_mute_off <= dbo[1];
            end
            else begin
                //  hold
            end
        end
    end

    always @( posedge reset or posedge clk21m ) begin
        if( reset ) begin
            ff_adda <= 1'b0;
        end
        else begin
            if( req && wrt && adr ) begin
                ff_adda <= dbo[0];
            end
            else begin
                //  hold
            end
        end
    end

    //--------------------------------------------------------------
    // digital filter (T.B.D.: currently through)
    //--------------------------------------------------------------
    assign w_filter_in  = ( ff_sel == 1'b0 ) ? ff_wave_out : w_wave_in;
    assign w_filter_out = w_filter_in;

    //--------------------------------------------------------------
    // comparison for PCM recode
    //--------------------------------------------------------------
    assign w_comp       = (w_active_buffer > ff_sample_hold ) ? 1'b0 : 1'b1;

    //--------------------------------------------------------------
    // PCM register read
    //--------------------------------------------------------------
    assign w_port_a4h   = { 6'd0, ff_counter };
    assign w_port_a5h   = { w_comp, 2'd0, ff_smpl, ff_sel, ff_filt, ff_mute_off, ff_adda };

    assign dbi          = (adr == 1'b0) ? w_port_a4h : w_port_a5h;

    //--------------------------------------------------------------
    // PCM data output
    //--------------------------------------------------------------
    assign w_wave_out   = 8'd127 - w_active_buffer;

    always @( posedge reset or posedge clk21m ) begin
        if( reset ) begin
            ff_wave_out <= 8'd0;
        end
        else begin
            ff_wave_out = w_wave_out;
        end
    end

    assign wave_out     = (ff_mute_off == 1'b0 ) ? 8'd0 : w_filter_out; //  range: -128...127
    assign ack          = req;
endmodule
