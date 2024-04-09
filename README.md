# MSXgoauld_tn20k
MSX Goa'uld board with Tang Nano 20k

![Pantallazo](/pantallazo.jpg)

MSX2+ engine in Z80 socket. It turns one MSX into an MSX2+ by replacing Z80 processor. FPGA in board contains: 
* Z80
* V9958 with hdmi output, 60 Hz only
* MSX2+ BIOS
* RTC

Slot map

![Slot map](/mapa_slots.png)

Warning: not yet fully working on all tangs, some cartridges may not work in slot 1 (used for msx 2+ subrom)

Tips:
* Use turned pins in header to avoid damages in Z80 socket
![turned header](/torneados.jpg)
* Board is sensitive to dirty electrical contacts, way more than Z80. Keep cartridge contacts clean
* Diode avoids hdmi plug from powering the MSX, but causes a voltage drop. If tang doesn't boot, bridge the diode and remember to remove hdmi cable when not using
![diode](/diodo.jpg)
* When soldering headers, start with the inner one (Z80)