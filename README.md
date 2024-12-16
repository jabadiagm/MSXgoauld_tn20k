# MSXgoauld_tn20k
MSX Goa'uld board with Tang Nano 20k

![Pantallazo](/pics/V1_4.jpg)
![goauld_smd](/pics/V1_4_smd.jpg)

MSX2+ engine in Z80 socket. It turns one MSX into an MSX2+ by replacing Z80 processor. FPGA in board contains: 
* Z80
* V9958 with hdmi output
* MSX2+ BIOS
* 4MB mapper
* RTC
* PSG through hdmi
* OPLL through hdmi
* 2MB MegaRAM SCC+ through hdmi

## How it works
Logic acts on bus control signals so that internal devices inside fpga take priority over external devices. 

![Esquema](/pics/esquema.png)

Mind Revision 2, 4 and 4.1 uses 74LVC245 in U5. Although their technical information tells they require 3.3V to operate, they are also 5V tolerant. This has been tested and considered safe. Check https://github.com/jabadiagm/MSXgoauld_tn20k/issues/15 for more information. Revisions 2, 4 are outdated and kept for reference only. 

## Revision 2 Board

Revision 2 uses SOIC-20 for 74HCT373 and 74LVC245 ICs, which are smaller:

![](/kicad/v2/v2_real.jpg)

## Revision 4 Board

Revision 4 uses TSSOP-20 ICs, to get an even smaller footprint:
![](/kicad/v4/image/IMG_20240824_114309792.jpg)

## Slot map

![Slot map](/pics/mapa_slots3.png)

Mapper, MegaRAM can be relocated to slots 1, 2, or 3 using config menu.

## Update from previous hardware
* Replace U1, U2 -> 74HC373, U5 -> 74HC245
* Solder a 10K resistor array to data bus lines, pulled up to 5V
![Array](/pics/array.jpg)

## MegaRAM
Goa'uld features a 2MB Super Mega RAM SCC+ by [lfantoniosi](https://github.com/lfantoniosi/WonderTANG). Most classical rom's will work with sofarun's default settings. Be sure to use sofarun 8.1 at least.
Use utility [GSMRAM.COM](/fpga/src/sdcc/disk) to load roms in the case sofarun doesn't work.
It is possible to disable internal MegaRAM and use an external MegaRAM mapper. In this case, an SCC remains in Slot 0-2 to use with sofarun, using these settings:

![ext_scc](/pics/ext_scc.jpg)

## Configuration
Config menu is showed pressing g during MSX logo. New improved menu is created by [nataliapc](https://github.com/nataliapc/msx_goauld_settings_menu)

![Config](/pics/config2.png)

* Enable Mapper: On by default. Disable when having compatibility issues or to use a different mapper
* Mapper Slot: 0 by default. Change to 1-3 to get mapper in a not expanded slot (best compatibility). Physical slot will be disabled
* Enable MegaRam: On by default. Same as mapper
* MegaRam Slot: 0 by default. Change to 1-3 to get megaram in a not expanded slot (best compatibility). Physical slot will be disabled
* Slot 1 Ghost SCC: Off by default. Enable to get sound from an SCC cartridge located in slot 1
* Enable Scanlines: On by default. Disable to get a clean hdmi picture
* Save & Exit: store new config and continue, changes in mapper/megaram settings will be effective after pressing reset
* Save & Reset: store new config and make software reset, changes will be immediate

## Slots dance
Goa'uld has four internal slots available. As with other modules, internal slots take priority over physical ones. This means that when a device is using internal slot n, then physical slot n is disabled  and any cartridge in that slot will not be detected. 
By default, BIOS, mapper, and MegaRAM occupy internal slot 0, leaving physical slots 1 to 3 available for cartridges. However, this default layout can cause compatibility issues with some software, such as tape games and large ROMs. 
To resolve these issues, you can move the mapper or MegaRAM from expanded slot 0 to one of the non-expanded internal slots (1, 2, or 3). This adjustment can solve many compatibility problems.

## Known issues
* Reset from config menu is not compatible with some hardware. Use physical reset button when possible
* Multimente: shows garbage characters. Move internal mapper to slots 1, 2 or 3
* Tape games fail: move internal mapper to slots 1, 2 or 3
* Big roms (>256 KB) fail: disable internal megaram
* Noises when loading a rom with sofarun: change sofarun settings to use mapper for that rom

> [!WARNING]
> Not yet fully working on all MSX!
>

### Tips
* Get integrated circuits from trusted sources
* Use heatsink when possible
* Use turned pins in header to avoid damages in Z80 socket
![turned header](/pics/torneados.jpg)
* Board is sensitive to dirty electrical contacts, way more than Z80. Keep cartridge & Z80 socket contacts clean
* When soldering headers, start with the inner one (Z80)
