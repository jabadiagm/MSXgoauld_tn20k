// HDMI audio sample packet. Packed-only ports/internals: Gowin drops
// SystemVerilog unpacked arrays, which stripped DirectVideo LPCM.

module audio_sample_packet
#(
    parameter bit GRADE = 1'b0,
    parameter bit SAMPLE_WORD_TYPE = 1'b0,
    parameter bit COPYRIGHT_NOT_ASSERTED = 1'b1,
    parameter bit [2:0] PRE_EMPHASIS = 3'b000,
    parameter bit [1:0] MODE = 2'b00,
    parameter bit [7:0] CATEGORY_CODE = 8'd0,
    parameter bit [3:0] SOURCE_NUMBER = 4'd0,
    parameter bit [3:0] SAMPLING_FREQUENCY = 4'b0000,
    parameter bit [1:0] CLOCK_ACCURACY = 2'b00,
    parameter bit [3:0] WORD_LENGTH = 0,
    parameter bit [3:0] ORIGINAL_SAMPLING_FREQUENCY = 4'b0000,
    parameter bit LAYOUT = 1'b0
)
(
    input logic [7:0] frame_counter,
    input logic [3:0] audio_sample_word_present,
    input logic [23:0] sample_l0,
    input logic [23:0] sample_r0,
    input logic [23:0] sample_l1,
    input logic [23:0] sample_r1,
    input logic [23:0] sample_l2,
    input logic [23:0] sample_r2,
    input logic [23:0] sample_l3,
    input logic [23:0] sample_r3,
    output logic [23:0] header,
    output logic [55:0] sub0,
    output logic [55:0] sub1,
    output logic [55:0] sub2,
    output logic [55:0] sub3
);

localparam [3:0] CHANNEL_LEFT = 4'd1;
localparam [3:0] CHANNEL_RIGHT = 4'd2;
localparam [7:0] CHANNEL_STATUS_LENGTH = 8'd192;

wire [191:0] channel_status_left = {152'd0, ORIGINAL_SAMPLING_FREQUENCY, WORD_LENGTH, 2'b00, CLOCK_ACCURACY, SAMPLING_FREQUENCY, CHANNEL_LEFT, SOURCE_NUMBER, CATEGORY_CODE, MODE, PRE_EMPHASIS, COPYRIGHT_NOT_ASSERTED, SAMPLE_WORD_TYPE, GRADE};
wire [191:0] channel_status_right = {152'd0, ORIGINAL_SAMPLING_FREQUENCY, WORD_LENGTH, 2'b00, CLOCK_ACCURACY, SAMPLING_FREQUENCY, CHANNEL_RIGHT, SOURCE_NUMBER, CATEGORY_CODE, MODE, PRE_EMPHASIS, COPYRIGHT_NOT_ASSERTED, SAMPLE_WORD_TYPE, GRADE};

wire [7:0] fc0 = (frame_counter >= CHANNEL_STATUS_LENGTH) ? (frame_counter - CHANNEL_STATUS_LENGTH) : frame_counter;
wire [7:0] fc1 = (frame_counter + 8'd1 >= CHANNEL_STATUS_LENGTH) ? (frame_counter + 8'd1 - CHANNEL_STATUS_LENGTH) : (frame_counter + 8'd1);
wire [7:0] fc2 = (frame_counter + 8'd2 >= CHANNEL_STATUS_LENGTH) ? (frame_counter + 8'd2 - CHANNEL_STATUS_LENGTH) : (frame_counter + 8'd2);
wire [7:0] fc3 = (frame_counter + 8'd3 >= CHANNEL_STATUS_LENGTH) ? (frame_counter + 8'd3 - CHANNEL_STATUS_LENGTH) : (frame_counter + 8'd3);

wire cs_l0 = channel_status_left[fc0];
wire cs_r0 = channel_status_right[fc0];
wire cs_l1 = channel_status_left[fc1];
wire cs_r1 = channel_status_right[fc1];
wire cs_l2 = channel_status_left[fc2];
wire cs_r2 = channel_status_right[fc2];
wire cs_l3 = channel_status_left[fc3];
wire cs_r3 = channel_status_right[fc3];

wire p_l0 = ^{cs_l0, sample_l0};
wire p_r0 = ^{cs_r0, sample_r0};
wire p_l1 = ^{cs_l1, sample_l1};
wire p_r1 = ^{cs_r1, sample_r1};
wire p_l2 = ^{cs_l2, sample_l2};
wire p_r2 = ^{cs_r2, sample_r2};
wire p_l3 = ^{cs_l3, sample_l3};
wire p_r3 = ^{cs_r3, sample_r3};

assign header[7:0]   = 8'd2;
assign header[19:12] = {4'b0000, 3'b000, LAYOUT};
assign header[8]     = audio_sample_word_present[3];
assign header[9]     = audio_sample_word_present[2];
assign header[10]    = audio_sample_word_present[1];
assign header[11]    = audio_sample_word_present[0];
assign header[20]    = (fc3 == 8'd0) && audio_sample_word_present[3];
assign header[21]    = (fc2 == 8'd0) && audio_sample_word_present[2];
assign header[22]    = (fc1 == 8'd0) && audio_sample_word_present[1];
assign header[23]    = (fc0 == 8'd0) && audio_sample_word_present[0];

assign sub0 = audio_sample_word_present[0] ? {{p_r0, cs_r0, 1'b0, 1'b0, p_l0, cs_l0, 1'b0, 1'b0}, sample_r0, sample_l0} : 56'd0;
assign sub1 = audio_sample_word_present[1] ? {{p_r1, cs_r1, 1'b0, 1'b0, p_l1, cs_l1, 1'b0, 1'b0}, sample_r1, sample_l1} : 56'd0;
assign sub2 = audio_sample_word_present[2] ? {{p_r2, cs_r2, 1'b0, 1'b0, p_l2, cs_l2, 1'b0, 1'b0}, sample_r2, sample_l2} : 56'd0;
assign sub3 = audio_sample_word_present[3] ? {{p_r3, cs_r3, 1'b0, 1'b0, p_l3, cs_l3, 1'b0, 1'b0}, sample_r3, sample_l3} : 56'd0;

endmodule
