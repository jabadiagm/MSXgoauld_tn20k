// Implementation of HDMI Spec v1.4a
// By Sameer Puri https://github.com/sameer
//
// MSXnano DirectVideo 1536x240p @ 28.8 MHz (27 * 16/15).
// 1820x264 total integer-locks the V9958 field (59.94 Hz, 15.824 kHz).

`include "../dv_adjust.vh"

module hdmi 
#(
    // The IT content bit indicates that image samples are generated in an ad-hoc
    // manner (e.g. directly from values in a framebuffer, as by a PC video
    // card) and therefore aren't suitable for filtering or analog
    // reconstruction.  This is probably what you want if you treat pixels
    // as "squares".  If you generate a properly bandlimited signal or obtain
    // one from elsewhere (e.g. a camera), this can be turned off.
    //
    // This flag also tends to cause receivers to treat RGB values as full
    // range (0-255).
    parameter bit IT_CONTENT = 1'b1,

    // As specified in Section 7.3, the minimal audio requirements are met: 16-bit or more L-PCM audio at 32 kHz, 44.1 kHz, or 48 kHz.
    // See Table 7-4 or README.md for an enumeration of sampling frequencies supported by HDMI.
    // Note that sinks may not support rates above 48 kHz.
    parameter int AUDIO_RATE = 44100,

    // Defaults to 16-bit audio, the minmimum supported by HDMI sinks. Can be anywhere from 16-bit to 24-bit.
    parameter int AUDIO_BIT_WIDTH = 16,

    // Some HDMI sinks will show the source product description below to users (i.e. in a list of inputs instead of HDMI 1, HDMI 2, etc.).
    // If you care about this, change it below.
    parameter bit [8*8-1:0] VENDOR_NAME = {"Unknown", 8'd0}, // Must be 8 bytes null-padded 7-bit ASCII
    parameter bit [8*16-1:0] PRODUCT_DESCRIPTION = {"FPGA", 96'd0}, // Must be 16 bytes null-padded 7-bit ASCII
    parameter bit [7:0] SOURCE_DEVICE_INFORMATION = 8'h00, // See README.md or CTA-861-G for the list of valid codes
    // CEA-861 AVI PR: 0=none, 5=6x (1536/256)
    parameter bit [3:0] PIXEL_REPETITION = 4'b0101
)
(
    input logic			      clk_pixel_x5,
    input logic			      clk_pixel,
    input logic			      clk_audio,
    // synchronous reset back to 0,0
    input logic [8:0]         total_lines,
    input logic			      reset,
    input logic [1:0]		  stmode, // atari st video mode, 0=60hz ntsc, 1=50hz pal, 2=mono
    input logic [1:0]		  screen,   // try to adopt to wide (4:3) screens
    input logic [23:0]		  rgb,
    input logic               vdp_vs_n,
    input logic               cy_load,
    input logic [9:0]         cy_load_val,
    input logic [AUDIO_BIT_WIDTH-1:0] audio_l,
    input logic [AUDIO_BIT_WIDTH-1:0] audio_r,

    // These outputs go to your HDMI port
`ifdef TMDS_BY_LOGIC
    output logic [5:0] tmds,       // 6+2 pins/pmod used for hdmi
    output logic [1:0] tmds_clock
`else
   // These outputs go to your HDMI port
    output logic [2:0] tmds,
    output logic tmds_clock
`endif,
    // Scope taps: 15.824 kHz H, 59.94 Hz V
    output logic              hsync_dbg,
    output logic              vsync_dbg
);

localparam int NUM_CHANNELS = 3;
logic hsync;
logic vsync;

logic [1:0] invert;
// 1536x240p @ 28.8 MHz. Do not pack these into a sliced vector.
// VIC 0 + AVI PR=6 (1536 active). Playfield is 16/3 of 256 inside that.
// H porches stay NTSC (H pan is content offset in vdp_hdmi_240p).
// V porches still follow DV_V_SHIFT.
localparam [10:0] FRAME_WIDTH       = `DV_H_TOTAL;
localparam [10:0] SCREEN_WIDTH      = `DV_H_ACTIVE;
localparam [10:0] HSYNC_PULSE_START = `DV_H_FP_BASE;
localparam [10:0] HSYNC_PULSE_SIZE  = `DV_H_SYNC;
localparam [9:0]  FRAME_HEIGHT      = `DV_V_TOTAL;
localparam [9:0]  SCREEN_HEIGHT     = `DV_V_ACTIVE;
localparam [9:0]  VSYNC_PULSE_START = `DV_V_FP_BASE - (`DV_V_SHIFT);
localparam [9:0]  VSYNC_PULSE_SIZE  = `DV_V_SYNC;

wire [10:0] wide_extra_width  = 11'd0;
wire [10:0] frame_width       = FRAME_WIDTH;
wire [10:0] screen_width_real = SCREEN_WIDTH;
wire [10:0] screen_width      = SCREEN_WIDTH;
wire [10:0] hsync_pulse_start = HSYNC_PULSE_START;
wire [10:0] hsync_pulse_size  = HSYNC_PULSE_SIZE;
wire [9:0]  frame_height      = FRAME_HEIGHT;
wire [9:0]  screen_height     = SCREEN_HEIGHT;
wire [9:0]  vsync_pulse_start = VSYNC_PULSE_START;
wire [9:0]  vsync_pulse_size  = VSYNC_PULSE_SIZE;
wire [7:0]  cea               = 8'd0;

assign invert = 2'b11;
assign hsync_dbg = hsync;
assign vsync_dbg = vsync;

reg [10:0] cx;
reg [9:0] cy;

always_comb begin
    hsync <= invert[0] ^ (cx >= screen_width + hsync_pulse_start && cx < screen_width + hsync_pulse_start + hsync_pulse_size);
    // vsync pulses should begin and end at the start of hsync, so special
    // handling is required for the lines on which vsync starts and ends
    if (cy == screen_height + vsync_pulse_start - 1)
        vsync <= invert[1] ^ (cx >= screen_width + hsync_pulse_start);
    else if (cy == screen_height + vsync_pulse_start + vsync_pulse_size - 1)
        vsync <= invert[1] ^ (cx < screen_width + hsync_pulse_start);
    else
        vsync <= invert[1] ^ (cy >= screen_height + vsync_pulse_start && cy < screen_height + vsync_pulse_start + vsync_pulse_size);
end

localparam real VIDEO_RATE = 28.8e6;

always_ff @(posedge clk_pixel)
begin
    if (reset)
    begin
        cx <= 11'd0;
        cy <= 10'd0;
    end
    else
    begin
        cx <= (cx == FRAME_WIDTH - 11'd1) ? 11'd0 : cx + 1'b1;
        if (cx == FRAME_WIDTH - 11'd1) begin
            if (cy_load)
                cy <= cy_load_val;
            else
                cy <= (cy == FRAME_HEIGHT - 10'd1) ? 10'd0 : cy + 1'b1;
        end
    end
end

// See Section 5.2
logic video_data_period = 0;
always_ff @(posedge clk_pixel)
begin
    if (reset)
        video_data_period <= 0;
    else
        video_data_period <= cx < screen_width && cy < screen_height;
end

logic [2:0] mode = 3'd1;
logic [23:0] video_data = 24'd0;
logic [5:0] control_data = 6'd0;
logic [11:0] data_island_data = 12'd0;

generate
    begin: true_hdmi_output
        logic video_guard = 1;
        logic video_preamble = 0;
        always_ff @(posedge clk_pixel)
        begin
            if (reset)
            begin
                video_guard <= 1;
                video_preamble <= 0;
            end
            else
            begin
                video_guard <= cx >= frame_width - 2 && cx < frame_width && (cy == frame_height - 1 || cy < screen_height - 1 /* no VG at end of last line */);
                video_preamble <= cx >= frame_width - 10 && cx < frame_width - 2 && (cy == frame_height - 1 || cy < screen_height - 1 /* no VP at end of last line */);
            end
        end

        // See Section 5.2.3.1
        // 1820-1536=284 HBLANK; after guards/preambles: 7 packets.
        // Literals only: Gowin folded generate-block wires/`int`/`5'()` to 0,
        // which killed data islands and HDMI audio.
        // Island: cx=1536+14=1550 .. 1550+7*32=1774. Packet every 32 px at cx[4:0]==14.
        localparam [10:0] DI_START = 11'd1550;
        localparam [10:0] DI_END   = 11'd1774;
        logic data_island_period_instantaneous;
        assign data_island_period_instantaneous = (cx >= DI_START) && (cx < DI_END);
        logic packet_enable;
        assign packet_enable = data_island_period_instantaneous && (cx[4:0] == 5'd14);

        logic data_island_guard = 0;
        logic data_island_preamble = 0;
        logic data_island_period = 0;
        always_ff @(posedge clk_pixel)
        begin
            if (reset)
            begin
                data_island_guard <= 0;
                data_island_preamble <= 0;
                data_island_period <= 0;
            end
            else
            begin
                data_island_guard <= ((cx >= 11'd1548) && (cx < 11'd1550)) ||
                                     ((cx >= DI_END) && (cx < DI_END + 11'd2));
                data_island_preamble <= (cx >= 11'd1540) && (cx < 11'd1548);
                data_island_period <= data_island_period_instantaneous;
            end
        end

        // See Section 5.2.3.4
        logic [23:0] header;
        logic [55:0] sub0, sub1, sub2, sub3;
        logic video_field_end;
        assign video_field_end = cx == screen_width - 1'b1 && cy == screen_height - 1'b1;
        logic [4:0] packet_pixel_counter;
        packet_picker #(
            .VIDEO_RATE(VIDEO_RATE),
            .IT_CONTENT(IT_CONTENT),
            .AUDIO_RATE(AUDIO_RATE),
            .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
            .VENDOR_NAME(VENDOR_NAME),
            .PRODUCT_DESCRIPTION(PRODUCT_DESCRIPTION),
            .SOURCE_DEVICE_INFORMATION(SOURCE_DEVICE_INFORMATION),
            .PIXEL_REPETITION(PIXEL_REPETITION)
        ) packet_picker (
            .clk_pixel(clk_pixel),
            .clk_audio(clk_audio),
            .reset(reset),
            .cea(cea),
            .stmode(stmode),
            .video_field_end(video_field_end),
            .packet_enable(packet_enable),
            .packet_pixel_counter(packet_pixel_counter),
            .audio_l(audio_l),
            .audio_r(audio_r),
            .header(header),
            .sub0(sub0),
            .sub1(sub1),
            .sub2(sub2),
            .sub3(sub3)
        );
        logic [8:0] packet_data;
        packet_assembler packet_assembler (
            .clk_pixel(clk_pixel),
            .reset(reset),
            .data_island_period(data_island_period),
            .header(header),
            .sub0(sub0),
            .sub1(sub1),
            .sub2(sub2),
            .sub3(sub3),
            .packet_data(packet_data),
            .counter(packet_pixel_counter)
        );


        always_ff @(posedge clk_pixel)
        begin
            if (reset)
            begin
                mode <= 3'd2;
                video_data <= 24'd0;
                control_data = 6'd0;
                data_island_data <= 12'd0;
            end
            else
            begin
                mode <= data_island_guard ? 3'd4 : data_island_period ? 3'd3 : video_guard ? 3'd2 : video_data_period ? 3'd1 : 3'd0;
                video_data <= (cx >= wide_extra_width/2 && cx < (screen_width_real + wide_extra_width/2) && cy < screen_height)?rgb:24'h000000;
                control_data <= {{1'b0, data_island_preamble}, {1'b0, video_preamble || data_island_preamble}, {vsync, hsync}}; // ctrl3, ctrl2, ctrl1, ctrl0, vsync, hsync
                data_island_data[11:4] <= packet_data[8:1];
                data_island_data[3] <= cx != 0;
                data_island_data[2] <= packet_data[0];
                data_island_data[1:0] <= {vsync, hsync};
            end
        end
    end
endgenerate

// All logic below relates to the production and output of the 10-bit TMDS code.
logic [9:0] tmds_internal [NUM_CHANNELS-1:0] /* verilator public_flat */ ;
genvar i;
generate
    // TMDS code production.
    for (i = 0; i < NUM_CHANNELS; i++)
    begin: tmds_gen
        tmds_channel #(.CN(i)) tmds_channel (.clk_pixel(clk_pixel), .video_data(video_data[i*8+7:i*8]), .data_island_data(data_island_data[i*4+3:i*4]), .control_data(control_data[i*2+1:i*2]), .mode(mode), .tmds(tmds_internal[i]));
    end
endgenerate

serializer #(.NUM_CHANNELS(NUM_CHANNELS)) serializer(.clk_pixel(clk_pixel), .clk_pixel_x5(clk_pixel_x5), .reset(reset), .tmds_internal(tmds_internal), .tmds(tmds), .tmds_clock(tmds_clock));

endmodule
