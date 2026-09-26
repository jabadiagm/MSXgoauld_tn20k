# DirectVideo details

- 1536x240 HDMI active; MSX playfield is 1365 (16/3 of 256, or 8/3 of 512 in SCREEN 6/7), centered with R#7 side porch
- `1820x264 @ 28.8 MHz` (rank 8) total
- 28.8 MHz pixel clock = `27 x 16 / 15` (integer-locks the VDP field)
- 144 MHz TMDS (rPLL `27 x 16 / 3`, CLKDIV/5)
- 59.94 Hz vertical
- 15.824 kHz horizontal (+90 Hz vs NTSC 15.734 kHz)
- NTSC-length HSYNC 4.7 us (135 px), front porch 1.5 us (43 px)
- Negative H/V sync
- `27×16/15` easy Pixel Clock from oscillator
- NTSC 83% fill approx Picture width
- 8-line on-chip ring (256 x RGB565 x 8). HDMI reads 4 completed lines behind the VDP writer and holds that slot for the whole HDMI scanline, so capture cannot overwrite the line being displayed.
- No SDRAM frame store. A full 256x240 RGB565 frame does not fit BSRAM.

`1820 x 264 x 15 / 16 = 450450` VDP field clocks, so HDMI and VDP stay phase-locked.

## Screen placement

If Screen is misplaced in your CRT, rebuild the project tweaking these values in `src/dv_adjust.vh`:

```
`define DV_H_SHIFT  0   // + right, - left  (HDMI pixels @ 28.8 MHz)
`define DV_V_SHIFT  0   // + down,  - up    (lines)
`define DV_PIC_Y    0   // bitmap+border down inside 240 (HDMI lines)
```

Example: move 80 pixels right and 1 line up:

```
`define DV_H_SHIFT +80
`define DV_V_SHIFT -1
```

`DV_H_SHIFT` pans the 1365-wide 16/3 (8/3) playfield inside 1536 (about -512..+512). Small values sit in the R#7 side porch; large values crop the opposite edge. `DV_V_SHIFT` still swaps V porches (about -17..+2). Totals stay 1820x264. `DV_PIC_Y` moves the captured VDP visible (border+bitmap) inside the 240-line HDMI active.

## Known Issues

- [ ] Correct some screen modes horizontal scaling to avoid column cropping

## 480i → 240p deinterlace (SCREEN 5/6/7/8, R#9 IL)

V9958 interlace (R#9 bit 3, including two-page SCREEN 7 512×424) is **bob-deinterlaced** to the 240p HDMI raster:

- Each 15 kHz field is captured with a **field-relative** Y (odd-field CY is folded back by 525 / 625).
- A 240-line window is placed around the 192/212 bitmap (shifted later for PAL and 212-line) so those rows are not cropped.
- HDMI still emits 1536×240p @ 59.94 Hz; each field is one 240p frame (60 unique fields/s).

SCREEN 6/7 are 512 pixels wide (2 clocks/dot). HDMI captures all 512 and scales 8/3 Bresenham to 1365 (SCREEN 5/8 are 16/3 of 256). That is the analog V9958 playfield width (~47.4 µs vs 47.68 µs). The leftover 171 HDMI pixels are R#7 L/R porch, not extra stretch. Sampling every 4th clock was shredding glyphs (see `01.png`).

HDMI `cy` is phase-locked to VDP `BWINDOW_Y` (analog 15 kHz visible window in `vdp.vhd`). `vdp_colordec` already puts R#7 backdrop on `PVIDEOR/G/B` when `WINDOW=0`, so the 240 captured lines include the MSX top/bottom border (see `03.png`). `DV_PIC_Y` still shifts that window. `DV_H_SHIFT` pans the 1365-wide bitmap inside the 1536 active (R#7 fill; crop only if the pan runs off the active). `DV_V_SHIFT` remains a V porch macro.

A weave to 424 unique lines cannot fit in 240p. Two-page SCREEN 7 therefore shows even/odd VRAM pages as alternate 240p frames (same as a 15 kHz field on this progressive output).

## Line tight timing solution

Some lines are being updated in a very tight timing so there are some line changes during display presentation so some line steps were found.

To solve that, a small buffer was implemented to add a delay to output to make it not update just in time, which solved the issue. Unfortunately, I found some loosing sync issues there wasn't before that.

About the implementation: The tearing came from the two-bank ping-pong. HDMI and VDP line times are almost the same (63.19 µs vs 63.56 µs), so the “previous” bank was reused as the write bank before HDMI finished the scanline. Mid-line updates showed up as artifacts.

A full 256×240 RGB565 frame does not fit on the Tang Nano 20K (needs ~60 BSRAM; the chip has 46). HDMI now uses an 8-line always-write ring instead:

• VDP always writes the next slot
• HDMI reads 4 completed lines behind the writer
• The ring slot is latched at HDMI hblank, so a scanline never switches banks mid-line

That’s about 250 µs of lag, not a whole frame. Field lock and 1820×264 timing are unchanged.

## Clocks

- 27 MHz oscillator
- 28.8 MHz pixel clock from CLKDIV/5
- 108 MHz system clock from CLK_108P
- 108 MHz / 30 = 3.6 MHz CPU clock