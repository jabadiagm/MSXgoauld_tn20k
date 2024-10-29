# MSXgoauld_tn20k
MSX Goa'uld board with Tang Nano 20k

![Pantallazo](/pantallazo.jpg)

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

![Esquema](/esquema.png)

## Revision 2 Board

Revision 2 uses SOIC-20 for 74HCT373 and 74LVC245 ICs, which are smaller:

![](/kicad/v2/v2_real.jpg)

## Revision 4 Board

## Revision 4 Board

> [!WARNING]
> Revision 4 is known to have a major flaw. Please, do not build this board. See [Errata](#rev4-errata).
> 

Revision 4 uses TSSOP-20 ICs, to get an even smaller footprint:
![](/kicad/v4/image/IMG_20240824_114309792.jpg)

### Rev4 Errata

* VCC for U5 75LVC245 is 5V which is out of specs according to the IC datasheet. See [MSXgoauld_tn20k #15](https://github.com/jabadiagm/MSXgoauld_tn20k/issues/15).

## Slot map

![Slot map](/mapa_slots3.png)

Warning: not yet fully working on all MSX!

Tips:
* Get integrated circuits from trusted sources
* Use turned pins in header to avoid damages in Z80 socket
![turned header](/torneados.jpg)
* Board is sensitive to dirty electrical contacts, way more than Z80. Keep cartridge & Z80 socket contacts clean
* Diode avoids hdmi plug from powering the MSX, but causes a voltage drop. If tang doesn't boot, bridge the diode and remember to remove hdmi cable when not using
![diode](/diodo.jpg)
* When soldering headers, start with the inner one (Z80)
