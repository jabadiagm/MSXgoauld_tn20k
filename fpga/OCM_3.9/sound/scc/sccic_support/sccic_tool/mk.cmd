sdcc --out-fmt-ihx -mz80 --code-loc 0x100 --data-loc 0x4000 --opt-code-speed SCCIC.c 2> log.txt
ihx2com SCCIC.ihx SCCIC.COM
del SCCIC.asm
del SCCIC.lst
del SCCIC.map
del SCCIC.sym
del SCCIC.o
del SCCIC.ihx
del SCCIC.lnk
