# MSXgoauld_tn20k
MSX Goa'uld board with Tang Nano 20k

![Pantallazo](/pantallazo.jpg)

MSX2+ engine in Z80 socket. It turns one MSX into an MSX2+ by replacing Z80 processor. FPGA in board contains: 
* Z80
* V9958 with hdmi output
* MSX2+ BIOS
* 4MB mapper
* PSG through hdmi
* SCC (audio only) through hdmi
* RTC

Slot map

![Slot map](/mapa_slots.png)

Warning: not yet fully working on all tangs

Tips:
* Use turned pins in header to avoid damages in Z80 socket
![turned header](/torneados.jpg)
* Diode avoids hdmi plug from powering the MSX, but causes a voltage drop. If tang doesn't boot, bridge the diode and rememeber to remove hdmi cable when not using
![diode](/diode.jpg)
* When soldering headers, start with the inner one (Z80)
* Firmwares: start with the less demanding (Z80 + V9958), this is the one that works with most of the tangs