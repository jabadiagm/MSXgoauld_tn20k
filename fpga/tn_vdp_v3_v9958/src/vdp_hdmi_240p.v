// Direct VDP -> 1536x240. Always-write 8-line ring (512 x 8).
// HDMI reads 4 completed lines behind the writer and latches the slot
// at HDMI hblank so a scanline never switches banks mid-line.
// 256-wide (SCREEN 5/8): 16/3 Bresenham (5,5,6). 512-wide: 8/3 (2,3,3).
// Playfield is 1365 HDMI pixels, centered in 1536 (85 + 1365 + 86), R#7 pad.
//
// Analog-visible capture: BWINDOW_Y is the 15 kHz "TV window"
// including R#7 backdrop. colordec already emits W_BACK_COLOR when
// WINDOW=0, so VideoR/G/B on those lines *is* the MSX border.
// HDMI cy locks to BWINDOW_Y rise; 240 lines of that RGB are shown.

module vdp_hdmi_240p #(
    parameter signed [11:0] H_OFF = 0
) (
    input  wire        clk_vdp,
    input  wire        clk_pixel,
    input  wire        reset,

    input  wire [5:0]  video_r,
    input  wire [5:0]  video_g,
    input  wire [5:0]  video_b,
    input  wire [10:0] vdp_cx,
    input  wire        highres,
    input  wire        border_y,
    input  wire [9:0]  y_off,

    input  wire [10:0] hdmi_cx,
    input  wire [9:0]  hdmi_cy,

    output wire [5:0]  out_r,
    output wire [5:0]  out_g,
    output wire [5:0]  out_b
);

    localparam [10:0] H_CAP    = 11'd256;
    localparam [2:0]  WR_DELAY = 3'd4;

    wire [15:0] pix565 = {video_r[5:1], video_g[5:0], video_b[5:1]};

    wire        hr_pix  = (vdp_cx[1:0] == 2'b01) || (vdp_cx[1:0] == 2'b10);
    wire        lr_pix  = (vdp_cx[1:0] == 2'b00);
    wire [10:0] cap_off = (vdp_cx < H_CAP) ? 11'd0 : (vdp_cx - H_CAP);
    wire        in_act  = (vdp_cx >= H_CAP) && (cap_off < 11'd1024);
    wire [8:0]  pix_x   = highres ? cap_off[9:1] : {1'b0, cap_off[9:2]};
    wire        pix_en  = in_act && (highres ? hr_pix : lr_pix);

    (* syn_ramstyle = "block_ram" *)
    reg [15:0] line_ram [0:4095];

    reg [2:0]  wr_idx;
    reg [9:0]  pix_cnt;
    reg        cap_on;
    reg [7:0]  cap_y;
    reg        border_y_d;
    wire       vis_rise = border_y & ~border_y_d;

    always @(posedge clk_vdp)
        border_y_d <= border_y;

    always @(posedge clk_vdp) begin
        if (pix_en && cap_on)
            line_ram[{wr_idx, pix_x}] <= pix565;
    end

    always @(posedge clk_vdp or posedge reset) begin
        if (reset) begin
            wr_idx  <= 3'd0;
            pix_cnt <= 10'd0;
            cap_on  <= 1'b0;
            cap_y   <= 8'd0;
        end else begin
            if (vis_rise) begin
                cap_on <= 1'b1;
                cap_y  <= 8'd0;
            end
            if (vdp_cx == 11'd0) begin
                if (cap_on && pix_cnt != 10'd0)
                    wr_idx <= wr_idx + 3'd1;
                pix_cnt <= 10'd0;
                if (cap_on) begin
                    if (cap_y == 8'd239)
                        cap_on <= 1'b0;
                    else
                        cap_y <= cap_y + 8'd1;
                end
            end else if (pix_en && cap_on) begin
                pix_cnt <= pix_cnt + 10'd1;
            end
        end
    end

    // R#7 backdrop as sampled outside the bitmap (WINDOW=0 in colordec).
    reg [15:0] bord_v;
    always @(posedge clk_vdp)
        if (vdp_cx == 11'd80)
            bord_v <= pix565;

    wire [2:0] wr_gray = wr_idx ^ (wr_idx >> 1);
    reg [2:0] wr_g0, wr_g1;
    always @(posedge clk_pixel) begin
        wr_g0 <= wr_gray;
        wr_g1 <= wr_g0;
    end
    wire [2:0] wr_bin = {
        wr_g1[2],
        wr_g1[2] ^ wr_g1[1],
        wr_g1[2] ^ wr_g1[1] ^ wr_g1[0]
    };

    reg highres_s, highres_ss;
    reg [15:0] bord_s, bord_ss;
    always @(posedge clk_pixel) begin
        highres_s  <= highres;
        highres_ss <= highres_s;
        bord_s     <= bord_v;
        bord_ss    <= bord_s;
    end

    wire [2:0] delay_u = (WR_DELAY == 3'd0) ? 3'd1 : WR_DELAY;

    // 16/3 (256-dot) and 8/3 (512-dot) Bresenham, centered in 1536.
    // DV_H_SHIFT slides that 1365-wide playfield. Gap is R#7; crop only
    // if the shifted window runs off 0..1535.
    localparam signed [12:0] PIC_W = 1365;
    localparam signed [12:0] PAD_L = 85;
    localparam signed [11:0] H_LIM = 1535;
    localparam signed [11:0] H_OFF_C =
        (H_OFF > H_LIM)  ? H_LIM :
        (H_OFF < -H_LIM) ? -H_LIM : H_OFF;
    localparam signed [12:0] PIC_START = PAD_L + H_OFF_C;
    localparam signed [12:0] PIC_END   = PIC_START + PIC_W;
    localparam [10:0] SKIP_N =
        (PIC_START < 0) ?
            ((-PIC_START > PIC_W) ? 11'd1365 : -PIC_START) : 11'd0;
    localparam [11:0] SKIP_MUL = SKIP_N * 4'd3;
    localparam [8:0]  SKIP_X16 = SKIP_MUL / 12'd16;
    localparam [4:0]  SKIP_A16 = SKIP_MUL % 12'd16;
    localparam [8:0]  SKIP_X8  = SKIP_MUL / 12'd8;
    localparam [4:0]  SKIP_A8  = SKIP_MUL % 12'd8;

    wire signed [12:0] cx_s = $signed({2'b00, hdmi_cx});
    wire        pic_h = (cx_s >= PIC_START) && (cx_s < PIC_END) &&
                        (hdmi_cx < 11'd1536);
    wire [10:0] first_pic_cx =
        (PIC_START <= 0)    ? 11'd0 :
        (PIC_START >= 1536) ? 11'd2047 : PIC_START[10:0];
    reg         pic_h_d;
    always @(posedge clk_pixel)
        pic_h_d <= pic_h;

    reg [8:0] disp_x;
    reg [4:0] acc;
    reg [2:0] rd_idx;
    wire [4:0] limit = highres_ss ? 5'd8 : 5'd16;
    always @(posedge clk_pixel) begin
        if (hdmi_cx == 11'd0) begin
            rd_idx <= wr_bin - delay_u;
            if (highres_ss) begin
                disp_x <= SKIP_X8;
                acc    <= SKIP_A8;
            end else begin
                disp_x <= SKIP_X16;
                acc    <= SKIP_A16;
            end
        end else if (pic_h && (hdmi_cx != first_pic_cx)) begin
            if ((acc + 5'd3) >= limit) begin
                acc    <= acc + 5'd3 - limit;
                disp_x <= disp_x + 9'd1;
            end else begin
                acc <= acc + 5'd3;
            end
        end
    end

    reg [15:0] pix16;
    always @(posedge clk_pixel)
        pix16 <= line_ram[{rd_idx, disp_x}];

    // y_off (DV_PIC_Y): pad above the locked 240 with backdrop, not black.
    // h_off (DV_H_SHIFT): pad left/right the same way.
    wire y_vis  = (hdmi_cy >= y_off) && (hdmi_cy < 10'd240);
    wire active = (hdmi_cx < 11'd1536) && (hdmi_cy < 10'd240);
    wire [15:0] out16 = !active ? 16'd0 :
                        (y_vis && pic_h_d) ? pix16 : bord_ss;

    assign out_r = {out16[15:11], out16[15]};
    assign out_g =  out16[10:5];
    assign out_b = {out16[4:0], out16[4]};

endmodule
