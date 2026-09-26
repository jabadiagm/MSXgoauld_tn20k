// DirectVideo screen placement (1820x264 @ 28.8 MHz).
// Edit DV_H_SHIFT / DV_V_SHIFT / DV_PIC_Y and rebuild.
// Playfield is 1365 HDMI pixels (16/3 of 256, 8/3 of 512), centered
// in 1536 with R#7 side porch (85 + 1365 + 86).
//   DV_H_SHIFT: + right, - left  (HDMI pixels @ 28.8 MHz).
//     Slides the 1365-wide bitmap. About -512 .. +512.
//     Small values fit in the side porch (no crop). Larger values
//     crop the opposite edge; exposed area is R#7.
//   DV_V_SHIFT: + down,  - up    (lines).  Legal about -17 .. +2
//     Still NTSC V porch swap. Totals stay 1820x264 (field lock).
// DV_PIC_Y: extra HDMI lines to shift the bitmap+border inside 240
//   (after VDP visible-start phase lock). + down, - up.

`ifndef DV_ADJUST_VH
`define DV_ADJUST_VH

`ifndef DV_H_SHIFT
`define DV_H_SHIFT +55
`endif
`ifndef DV_V_SHIFT
`define DV_V_SHIFT 0
`endif
`ifndef DV_PIC_Y
`define DV_PIC_Y -5
`endif

`define DV_H_TOTAL    1820
`define DV_H_ACTIVE   1536
`define DV_H_SYNC     135
`define DV_H_FP_BASE  43
`define DV_H_BP_BASE  106

`define DV_V_TOTAL    264
`define DV_V_ACTIVE   240
`define DV_V_SYNC     3
`define DV_V_FP_BASE  3
`define DV_V_BP_BASE  18

`endif
