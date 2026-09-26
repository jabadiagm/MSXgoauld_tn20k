// Implementation of HDMI audio info frame
// By Sameer Puri https://github.com/sameer

// See Section 8.2.2
module audio_info_frame
#(
    parameter bit [2:0] AUDIO_CHANNEL_COUNT = 3'd1, // 2 channels. See CEA-861-D table 17 for details.
    parameter bit [7:0] CHANNEL_ALLOCATION = 8'h00, // Channel 0 = Front Left, Channel 1 = Front Right (0-indexed)
    parameter bit DOWN_MIX_INHIBITED = 1'b0, // Permitted or no information about any assertion of this. The DM_INH field is to be set only for DVD-Audio applications.
    parameter bit [3:0] LEVEL_SHIFT_VALUE = 4'd0, // 4-bit unsigned number from 0dB up to 15dB, used for downmixing.
    parameter bit [1:0] LOW_FREQUENCY_EFFECTS_PLAYBACK_LEVEL = 2'b00 // No information, LFE = bass-only info < 120Hz, used in Dolby Surround.
)
(
    output logic [23:0] header,
    output logic [55:0] sub0,
    output logic [55:0] sub1,
    output logic [55:0] sub2,
    output logic [55:0] sub3
);

// NOTE—HDMI requires the coding type, sample size and sample frequency fields to be set to 0 ("Refer to Stream Header") as these items are carried in the audio stream
localparam bit [3:0] AUDIO_CODING_TYPE = 4'd0; // Refer to stream header.
localparam bit [2:0] SAMPLING_FREQUENCY = 3'd0; // Refer to stream header.
localparam bit [1:0] SAMPLE_SIZE = 2'd0; // Refer to stream header.

localparam bit [4:0] LENGTH = 5'd10;
localparam bit [7:0] VERSION = 8'd1;
localparam bit [6:0] TYPE = 7'd4;

assign header = {{3'b0, LENGTH}, VERSION, {1'b1, TYPE}};

// PB0-PB6 = sub0
// PB7-13 =  sub1
// PB14-20 = sub2
// PB21-27 = sub3
logic [7:0] packet_bytes [27:0];

assign packet_bytes[0] = 8'd1 + ~(header[23:16] + header[15:8] + header[7:0] + packet_bytes[5] + packet_bytes[4] + packet_bytes[3] + packet_bytes[2] + packet_bytes[1]);
assign packet_bytes[1] = {AUDIO_CODING_TYPE, 1'b0, AUDIO_CHANNEL_COUNT};
assign packet_bytes[2] = {3'd0, SAMPLING_FREQUENCY, SAMPLE_SIZE};
assign packet_bytes[3] = 8'd0;
assign packet_bytes[4] = CHANNEL_ALLOCATION;
assign packet_bytes[5] = {DOWN_MIX_INHIBITED, LEVEL_SHIFT_VALUE, 1'b0, LOW_FREQUENCY_EFFECTS_PLAYBACK_LEVEL};

genvar i;
generate
    for (i = 6; i < 28; i++)
    begin: pb_reserved
        assign packet_bytes[i] = 8'd0;
    end
endgenerate
assign sub0 = {packet_bytes[6],  packet_bytes[5],  packet_bytes[4],  packet_bytes[3],  packet_bytes[2],  packet_bytes[1],  packet_bytes[0]};
assign sub1 = {packet_bytes[13], packet_bytes[12], packet_bytes[11], packet_bytes[10], packet_bytes[9],  packet_bytes[8],  packet_bytes[7]};
assign sub2 = {packet_bytes[20], packet_bytes[19], packet_bytes[18], packet_bytes[17], packet_bytes[16], packet_bytes[15], packet_bytes[14]};
assign sub3 = {packet_bytes[27], packet_bytes[26], packet_bytes[25], packet_bytes[24], packet_bytes[23], packet_bytes[22], packet_bytes[21]};
endmodule
