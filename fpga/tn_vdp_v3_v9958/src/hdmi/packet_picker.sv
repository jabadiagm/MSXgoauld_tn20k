// Implementation of HDMI packet choice logic.
// By Sameer Puri https://github.com/sameer
//
// Gowin cannot keep a 256-entry headers[packet_type] / subs[packet_type]
// sparse array: the audio/infoframe generators look undriven and are swept
// (NL0002), so DirectVideo has picture but no HDMI audio. Mux the six
// packet types explicitly.

module packet_picker
#(
    parameter real VIDEO_RATE = 0,
    parameter bit IT_CONTENT = 1'b0,
    parameter int AUDIO_BIT_WIDTH = 0,
    parameter int AUDIO_RATE = 0,
    parameter bit [8*8-1:0] VENDOR_NAME = 0,
    parameter bit [8*16-1:0] PRODUCT_DESCRIPTION = 0,
    parameter bit [7:0] SOURCE_DEVICE_INFORMATION = 0,
    parameter bit [3:0] PIXEL_REPETITION = 4'b0000
)
(
    input logic clk_pixel,
    input logic clk_audio,
    input logic reset,
    input logic [1:0] stmode,
    input logic [7:0] cea,
    input logic video_field_end,
    input logic packet_enable,
    input logic [4:0] packet_pixel_counter,
    input logic [AUDIO_BIT_WIDTH-1:0] audio_l,
    input logic [AUDIO_BIT_WIDTH-1:0] audio_r,
    output logic [23:0] header,
    output logic [55:0] sub0,
    output logic [55:0] sub1,
    output logic [55:0] sub2,
    output logic [55:0] sub3
);

logic [7:0] packet_type = 8'd0;

wire [23:0] hdr_null = 24'd0;
wire [55:0] sub_null0 = 56'd0;
wire [55:0] sub_null1 = 56'd0;
wire [55:0] sub_null2 = 56'd0;
wire [55:0] sub_null3 = 56'd0;

(* syn_keep = 1 *) wire [23:0] hdr_acr;
wire [55:0] sub_acr0, sub_acr1, sub_acr2, sub_acr3;
logic clk_audio_counter_wrap;
audio_clock_regeneration_packet #(.VIDEO_RATE(VIDEO_RATE), .AUDIO_RATE(AUDIO_RATE)) audio_clock_regeneration_packet (
    .clk_pixel(clk_pixel),
    .clk_audio(clk_audio),
    .clk_audio_counter_wrap(clk_audio_counter_wrap),
    .header(hdr_acr),
    .sub0(sub_acr0),
    .sub1(sub_acr1),
    .sub2(sub_acr2),
    .sub3(sub_acr3)
);

localparam bit [3:0] SAMPLING_FREQUENCY = AUDIO_RATE == 32000 ? 4'b0011
    : AUDIO_RATE == 44100 ? 4'b0000
    : AUDIO_RATE == 88200 ? 4'b1000
    : AUDIO_RATE == 176400 ? 4'b1100
    : AUDIO_RATE == 48000 ? 4'b0010
    : AUDIO_RATE == 96000 ? 4'b1010
    : AUDIO_RATE == 192000 ? 4'b1110
    : 4'b0000;
localparam int AUDIO_BIT_WIDTH_COMPARATOR = AUDIO_BIT_WIDTH < 20 ? 20 : AUDIO_BIT_WIDTH == 20 ? 25 : AUDIO_BIT_WIDTH < 24 ? 24 : AUDIO_BIT_WIDTH == 24 ? 29 : -1;
localparam bit [2:0] WORD_LENGTH = 3'(AUDIO_BIT_WIDTH_COMPARATOR - AUDIO_BIT_WIDTH);
localparam bit WORD_LENGTH_LIMIT = AUDIO_BIT_WIDTH <= 20 ? 1'b0 : 1'b1;

// Sample on clk_pixel. audio_l/r are already in that domain; a clk_audio
// CDC toggle was DCE'd by Gowin so sample_buffer_ready never rose and
// type-2 audio packets were never selected.
reg [9:0] sample_div;
wire sample_tick = (sample_div == 10'd599);
always_ff @(posedge clk_pixel)
begin
    if (sample_tick)
        sample_div <= 10'd0;
    else
        sample_div <= sample_div + 10'd1;
end
wire [23:0] sample_l24 = {audio_l, {(24-AUDIO_BIT_WIDTH){1'b0}}};
wire [23:0] sample_r24 = {audio_r, {(24-AUDIO_BIT_WIDTH){1'b0}}};

logic [1:0] samples_remaining = 2'd0;
logic sample_buffer_used = 1'b0;
logic sample_buffer_ready = 1'b0;
(* syn_keep = 1 *) reg [23:0] acc_l0, acc_l1, acc_l2, acc_l3;
(* syn_keep = 1 *) reg [23:0] acc_r0, acc_r1, acc_r2, acc_r3;
(* syn_keep = 1 *) reg [23:0] pkt_l0, pkt_l1, pkt_l2, pkt_l3;
(* syn_keep = 1 *) reg [23:0] pkt_r0, pkt_r1, pkt_r2, pkt_r3;

always_ff @(posedge clk_pixel)
begin
    if (sample_buffer_used)
        sample_buffer_ready <= 1'b0;

    if (sample_tick)
    begin
        case (samples_remaining)
            2'd0: begin acc_l0 <= sample_l24; acc_r0 <= sample_r24; samples_remaining <= 2'd1; end
            2'd1: begin acc_l1 <= sample_l24; acc_r1 <= sample_r24; samples_remaining <= 2'd2; end
            2'd2: begin acc_l2 <= sample_l24; acc_r2 <= sample_r24; samples_remaining <= 2'd3; end
            default: begin
                pkt_l0 <= acc_l0; pkt_r0 <= acc_r0;
                pkt_l1 <= acc_l1; pkt_r1 <= acc_r1;
                pkt_l2 <= acc_l2; pkt_r2 <= acc_r2;
                pkt_l3 <= sample_l24; pkt_r3 <= sample_r24;
                samples_remaining <= 2'd0;
                sample_buffer_ready <= 1'b1;
            end
        endcase
    end
end

wire [3:0] audio_sample_word_present_packet = 4'b1111;

logic [7:0] frame_counter = 8'd0;
always_ff @(posedge clk_pixel)
begin
    if (reset)
    begin
        frame_counter <= 8'd0;
    end
    else if (packet_pixel_counter == 5'd31 && packet_type == 8'h02)
    begin
        frame_counter = frame_counter + 8'd4;
        if (frame_counter >= 8'd192)
            frame_counter = frame_counter - 8'd192;
    end
end

(* syn_keep = 1 *) wire [23:0] hdr_audio;
wire [55:0] sub_audio0, sub_audio1, sub_audio2, sub_audio3;
audio_sample_packet #(.SAMPLING_FREQUENCY(SAMPLING_FREQUENCY), .WORD_LENGTH({{WORD_LENGTH[0], WORD_LENGTH[1], WORD_LENGTH[2]}, WORD_LENGTH_LIMIT})) audio_sample_packet (
    .frame_counter(frame_counter),
    .audio_sample_word_present(audio_sample_word_present_packet),
    .sample_l0(pkt_l0),
    .sample_r0(pkt_r0),
    .sample_l1(pkt_l1),
    .sample_r1(pkt_r1),
    .sample_l2(pkt_l2),
    .sample_r2(pkt_r2),
    .sample_l3(pkt_l3),
    .sample_r3(pkt_r3),
    .header(hdr_audio),
    .sub0(sub_audio0),
    .sub1(sub_audio1),
    .sub2(sub_audio2),
    .sub3(sub_audio3)
);

(* syn_keep = 1 *) wire [23:0] hdr_avi;
wire [55:0] sub_avi0, sub_avi1, sub_avi2, sub_avi3;
auxiliary_video_information_info_frame #(
    .IT_CONTENT(IT_CONTENT),
    .PIXEL_REPETITION(PIXEL_REPETITION),
    .PICTURE_ASPECT_RATIO(2'b01)
) auxiliary_video_information_info_frame (
    .stmode(stmode),
    .cea(cea),
    .header(hdr_avi),
    .sub0(sub_avi0),
    .sub1(sub_avi1),
    .sub2(sub_avi2),
    .sub3(sub_avi3)
);

(* syn_keep = 1 *) wire [23:0] hdr_spd;
wire [55:0] sub_spd0, sub_spd1, sub_spd2, sub_spd3;
source_product_description_info_frame #(.VENDOR_NAME(VENDOR_NAME), .PRODUCT_DESCRIPTION(PRODUCT_DESCRIPTION), .SOURCE_DEVICE_INFORMATION(SOURCE_DEVICE_INFORMATION)) source_product_description_info_frame (
    .header(hdr_spd),
    .sub0(sub_spd0),
    .sub1(sub_spd1),
    .sub2(sub_spd2),
    .sub3(sub_spd3)
);

(* syn_keep = 1 *) wire [23:0] hdr_aif;
wire [55:0] sub_aif0, sub_aif1, sub_aif2, sub_aif3;
audio_info_frame audio_info_frame (
    .header(hdr_aif),
    .sub0(sub_aif0),
    .sub1(sub_aif1),
    .sub2(sub_aif2),
    .sub3(sub_aif3)
);

wire is_acr   = (packet_type == 8'd1);
wire is_audio = (packet_type == 8'd2);
wire is_avi   = (packet_type == 8'h82);
wire is_spd   = (packet_type == 8'h83);
wire is_aif   = (packet_type == 8'h84);

assign header = is_acr ? hdr_acr : is_audio ? hdr_audio : is_avi ? hdr_avi : is_spd ? hdr_spd : is_aif ? hdr_aif : hdr_null;
assign sub0   = is_acr ? sub_acr0 : is_audio ? sub_audio0 : is_avi ? sub_avi0 : is_spd ? sub_spd0 : is_aif ? sub_aif0 : sub_null0;
assign sub1   = is_acr ? sub_acr1 : is_audio ? sub_audio1 : is_avi ? sub_avi1 : is_spd ? sub_spd1 : is_aif ? sub_aif1 : sub_null1;
assign sub2   = is_acr ? sub_acr2 : is_audio ? sub_audio2 : is_avi ? sub_avi2 : is_spd ? sub_spd2 : is_aif ? sub_aif2 : sub_null2;
assign sub3   = is_acr ? sub_acr3 : is_audio ? sub_audio3 : is_avi ? sub_avi3 : is_spd ? sub_spd3 : is_aif ? sub_aif3 : sub_null3;

logic audio_info_frame_sent = 1'b0;
logic auxiliary_video_information_info_frame_sent = 1'b0;
logic source_product_description_info_frame_sent = 1'b0;
logic last_clk_audio_counter_wrap = 1'b0;
always_ff @(posedge clk_pixel)
begin
    if (sample_buffer_used)
        sample_buffer_used <= 1'b0;

    if (reset || video_field_end)
    begin
        audio_info_frame_sent <= 1'b0;
        auxiliary_video_information_info_frame_sent <= 1'b0;
        source_product_description_info_frame_sent <= 1'b0;
        packet_type <= 8'd0;
    end
    else if (packet_enable)
    begin
        if (last_clk_audio_counter_wrap ^ clk_audio_counter_wrap)
        begin
            packet_type <= 8'd1;
            last_clk_audio_counter_wrap <= clk_audio_counter_wrap;
        end
        else if (sample_buffer_ready)
        begin
            packet_type <= 8'd2;
            sample_buffer_used <= 1'b1;
        end
        else if (!audio_info_frame_sent)
        begin
            packet_type <= 8'h84;
            audio_info_frame_sent <= 1'b1;
        end
        else if (!auxiliary_video_information_info_frame_sent)
        begin
            packet_type <= 8'h82;
            auxiliary_video_information_info_frame_sent <= 1'b1;
        end
        else if (!source_product_description_info_frame_sent)
        begin
            packet_type <= 8'h83;
            source_product_description_info_frame_sent <= 1'b1;
        end
        else
            packet_type <= 8'd0;
    end
end

endmodule
