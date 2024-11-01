# MSXgoauld_tn20k
MSX Goa'uld board with Tang Nano 20k

![Pantallazo](/pics/V1_4.jpg)

MSX2+ engine in Z80 socket. It turns one MSX into an MSX2+ by replacing Z80 processor. FPGA in board contains: 
* Z80
* V9958 with hdmi output
* MSX2+ BIOS
* 4MB mapper
* RTC
* PSG through hdmi
* OPLL through hdmi
* MEGARAM-SCC through hdmi

## How it works:
Logic acts on bus control signals so that internal devices inside fpga take priority over external devices. 

![Esquema](/pics/esquema.png)

> [!WARNING]
> Current revisions 2, 4 are known to have a major flaw. Please, do not build these boards. See [Errata](#pcbs-errata).
> 

## Revision 2 Board

Revision 2 uses SOIC-20 for 74HCT373 and 74LVC245 ICs, which are smaller:

![](/kicad/v2/v2_real.jpg)

## Revision 4 Board

Revision 4 uses TSSOP-20 ICs, to get an even smaller footprint:
![](/kicad/v4/image/IMG_20240824_114309792.jpg)

### PCB's Errata

* VCC for U5 75LVC245 is 5V which is out of specs according to the IC datasheet. See [MSXgoauld_tn20k #15](https://github.com/jabadiagm/MSXgoauld_tn20k/issues/15).

## Slot map

![Slot map](/pics/mapa_slots3.png)

Mapper slot can be moved to slots 1, 2, or 3 using config menu.

## Update from previous hardware
* Replace U1, U2 -> 74HC373, U5 -> 74HC245
* Solder a resistor array to data bus lines, pulled up to 5V
![Array](/pics/array.jpg)

## Configuration
Config menu is showed pressing g during MSX logo.

![Config](/pics/config.png)

1 Enable Mapper: On by default. Disable when having compatibility issues or to use a different mapper
2 Enable Megaram: On by default. Same as mapper
3 Enable Scanlines: On by default. Disable to get a clean hdmi picture
4 Mapper Slot: 0 by default. Change to 1-3 to get mapper in a not expanded slot (best compatibility). Physical slot will be disabled
5 Save & Exit: store new config and continue, changes in mapper/megaram settings will be effective after pressing reset
6 Save & Reset: store new config and make software reset, changes will be immediate

## Known issues:
* Reset from config menu is not compatible with some hardware. Use physical reset button when possible
* Multimente: shows garbage characters. Move internal mapper to slots 1, 2 or 3
* Tape games fail: move internal mapper to slots 1, 2 or 3
* Big roms (>256 KB) fail: disable internal megaram

> [!WARNING]
> Not yet fully working on all MSX!
>

### Tips
* Get integrated circuits from trusted sources
* Use turned pins in header to avoid damages in Z80 socket
![turned header](/pics/torneados.jpg)
* Board is sensitive to dirty electrical contacts, way more than Z80. Keep cartridge & Z80 socket contacts clean
* When soldering headers, start with the inner one (Z80)
