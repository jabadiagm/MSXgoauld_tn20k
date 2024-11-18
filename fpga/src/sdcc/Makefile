CC = sdcc
CFLAGS = -mz80 --opt-code-size --std-sdcc11
ASM = sdasz80
ASMFLAGS =

%.asm : %.c
	$(CC) $(CFLAGS) -S $<

gsmram.com: crt0.rel gsmram.rel 
	$(CC) $(CFLAGS) --data-loc 0 --code-loc 0x200 --no-std-crt0 $^ -ogsmram.ihx
	hex2bin -e com gsmram.ihx
	cp gsmram.com disk/GSMRAM.COM

all: gsmram.com

gsmram.rel: gsmram.c types.h

%.rel : %.c
	$(CC) $(CFLAGS) -o$@ -c $<

%.rel : %.s
	$(ASM) $(ASMFLAGS) -o $@ $<

clean:
	+rm *.rel *.asm *.lst *.sym *.map *.ihx gsmram.com *.lk *.noi disk/gsmram.com
	

