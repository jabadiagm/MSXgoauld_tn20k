GW_SH_PATH?=/home/chandler/gowin-ide/IDE/bin/gw_sh
LIBFONT_CONFIG?=lib/libfontconfig.so.1

.phony: all clean

all:
	LD_PRELOAD=$(LIBFONT_CONFIG) $(GW_SH_PATH) build.tcl

flash: impl/pnr/Z80_goauld.fs
	sudo openFPGALoader -b tangnano20k -f --verify $<

clean:
	rm -rf impl