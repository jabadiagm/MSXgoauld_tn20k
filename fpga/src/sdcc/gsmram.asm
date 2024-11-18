;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler 
; Version 4.4.0 #14620 (MINGW32)
;--------------------------------------------------------
	.module gsmram
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _main
	.globl _runROM_page2_end
	.globl _runROM_page2
	.globl _runROM_page1_end
	.globl _runROM_page1
	.globl _jump
	.globl _hexToNum
	.globl _dos2_getenv
	.globl _dos2_read
	.globl _dos2_close
	.globl _dos2_open
	.globl _chgcpu
	.globl _rdslt
	.globl _enaslt
	.globl _to_upper
	.globl _fputs
	.globl _bdos_c_rawio
	.globl _bdos_c_write
	.globl _bdos
	.globl _printf
	.globl _opll_vol
	.globl _psg_vol
	.globl _scc_vol
	.globl _help
	.globl _page2
	.globl _cpumode
	.globl _presAB
	.globl _paramlen
	.globl _megaram_type
	.globl _filename
	.globl _found
	.globl _c
	.globl _romstart
	.globl _path
	.globl _slotid
	.globl _romsize
	.globl _page
	.globl _addr
	.globl _i
	.globl _bytes_read
	.globl _handle
	.globl _params
	.globl _t
	.globl _b
	.globl _sslt
	.globl _putchar
	.globl _getchar
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
_MEGA_PORT0	=	0x008e
_MEGA_PORT1	=	0x008f
_PPIA	=	0x00a8
_GOAULD_ID	=	0x0040
_GOAULD_CONFIG	=	0x0041
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
_sslt::
	.ds 1
_b::
	.ds 1
_t::
	.ds 2
_params::
	.ds 2
_handle::
	.ds 1
_bytes_read::
	.ds 2
_i::
	.ds 2
_addr::
	.ds 2
_page::
	.ds 1
_romsize::
	.ds 4
_slotid::
	.ds 1
_path::
	.ds 256
_romstart::
	.ds 2
_c::
	.ds 1
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _INITIALIZED
_found::
	.ds 1
_filename::
	.ds 2
_megaram_type::
	.ds 2
_paramlen::
	.ds 1
_presAB::
	.ds 1
_cpumode::
	.ds 1
_page2::
	.ds 1
_help::
	.ds 1
_scc_vol::
	.ds 1
_psg_vol::
	.ds 1
_opll_vol::
	.ds 1
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
	.area _DABS (ABS)
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;gsmram.c:40: void bdos() __naked
;	---------------------------------
; Function bdos
; ---------------------------------
_bdos::
;gsmram.c:49: __endasm;
	push	ix
	push	iy
	call	5
	pop	iy
	pop	ix
	ret
;gsmram.c:50: }
;gsmram.c:52: void bdos_c_write(uchar c) __naked
;	---------------------------------
; Function bdos_c_write
; ---------------------------------
_bdos_c_write::
;gsmram.c:62: __endasm;
	ld	e,a
	ld	c,#2
	call	_bdos
	ret
;gsmram.c:63: }
;gsmram.c:65: uchar bdos_c_rawio() __naked
;	---------------------------------
; Function bdos_c_rawio
; ---------------------------------
_bdos_c_rawio::
;gsmram.c:74: __endasm;
	ld	e,#0xFF;
	ld	c,#6
	call	_bdos
	ret
;gsmram.c:75: }
;gsmram.c:77: int putchar(int c) 
;	---------------------------------
; Function putchar
; ---------------------------------
_putchar::
	ex	de, hl
;gsmram.c:79: if (c >= 0)
	bit	7, d
	ret	NZ
;gsmram.c:80: bdos_c_write((char)c);
	ld	c, e
	push	de
	ld	a, c
	call	_bdos_c_write
	pop	de
;gsmram.c:81: return c;
;gsmram.c:82: }
	ret
;gsmram.c:84: int getchar()
;	---------------------------------
; Function getchar
; ---------------------------------
_getchar::
;gsmram.c:87: do {
00101$:
;gsmram.c:88: c = bdos_c_rawio();
	call	_bdos_c_rawio
	ld	e, a
;gsmram.c:89: } while(c == 0);
	or	a, a
	jr	Z, 00101$
;gsmram.c:90: return (int)c;
	ld	d, #0x00
;gsmram.c:91: }
	ret
;gsmram.c:93: void fputs(const char *s)
;	---------------------------------
; Function fputs
; ---------------------------------
_fputs::
	ex	de, hl
;gsmram.c:95: while(*s != NULL)
00101$:
	ld	a, (de)
	or	a, a
	ret	Z
;gsmram.c:96: putchar(*s++);
	inc	de
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	push	de
	call	_putchar
	pop	de
;gsmram.c:97: }
	jr	00101$
;gsmram.c:99: char to_upper(char c)
;	---------------------------------
; Function to_upper
; ---------------------------------
_to_upper::
;gsmram.c:101: if (c >= 'a' && c <= 'z')
	ld	c, a
	sub	a, #0x61
	jr	C, 00102$
	ld	a, #0x7a
	sub	a, c
	jr	C, 00102$
;gsmram.c:102: c = c - ('a'-'A');
	ld	a, c
	add	a, #0xe0
	ld	c, a
00102$:
;gsmram.c:103: return c;
	ld	a, c
;gsmram.c:104: }
	ret
;gsmram.c:106: void enaslt(uchar slotid, uint addr) __naked
;	---------------------------------
; Function enaslt
; ---------------------------------
_enaslt::
;gsmram.c:128: __endasm;
	push	af
	push	bc
	push	de
	push	hl
	push	ix
	push	iy
	ex	de,hl
	call	#0x0024
	pop	iy
	pop	ix
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;gsmram.c:129: }
;gsmram.c:131: uchar rdslt(uchar slotid, uint addr) __naked
;	---------------------------------
; Function rdslt
; ---------------------------------
_rdslt::
;gsmram.c:146: __endasm;
	push	bc
	push	de
	ex	de,hl
	call	#0x000C
	ex	de,hl
	pop	de
	pop	bc
	ret
;gsmram.c:147: }
;gsmram.c:149: void chgcpu(uchar mode) __naked
;	---------------------------------
; Function chgcpu
; ---------------------------------
_chgcpu::
;gsmram.c:179: __endasm;
	push	bc
	push	de
	push	af
	ld	a,(0xFCC1)
	ld	hl,#0x0180
	call	#0x000C
	cp	#0xC3
	jr	nz,__no_turbo
	ld	a,b
	pop	af
	ld	iy,(0xFCC1 -1)
	ld	ix,#0x0180
	call	#0x001C
	push	af
__no_turbo:
	pop	af
	pop	de
	pop	bc
	ret
;gsmram.c:180: }
;gsmram.c:199: FHANDLE dos2_open(uchar mode, const char* filepath) __naked
;	---------------------------------
; Function dos2_open
; ---------------------------------
_dos2_open::
;gsmram.c:217: __endasm;
	push	bc
	push	de
	push	hl
	ld	c,#0x43
	call	5
	or	a
	jr	z,__open_no_err
	ld	b,#0
__open_no_err:
	ld	a,b
	pop	hl
	pop	de
	pop	bc
	ret
;gsmram.c:218: }
;gsmram.c:220: void dos2_close(FHANDLE hnd) __naked
;	---------------------------------
; Function dos2_close
; ---------------------------------
_dos2_close::
;gsmram.c:230: __endasm;
	push	bc
	ld	a,b
	ld	c,#0x45
	call	5
	pop	bc
	ret
;gsmram.c:231: }
;gsmram.c:233: uint dos2_read(FHANDLE hnd, void *dst, uint size) __naked
;	---------------------------------
; Function dos2_read
; ---------------------------------
_dos2_read::
;gsmram.c:253: __endasm;	
	push	ix
	ld	ix,#0
	add	ix,sp
	push	bc
	ld	b,a
	ld	l, 4 (ix)
	ld	h, 5 (ix)
	ld	c,#0x48
	call	5
	pop	bc
	pop	ix
	ex	de,hl
	ret
;gsmram.c:254: }
;gsmram.c:256: uchar dos2_getenv(char *var, char *buf) __naked
;	---------------------------------
; Function dos2_getenv
; ---------------------------------
_dos2_getenv::
;gsmram.c:264: __endasm;	
	ld	b,#255
	ld	c,#0x6B
	call	5
	ret
;gsmram.c:265: }
;gsmram.c:267: char hexToNum(char h)
;	---------------------------------
; Function hexToNum
; ---------------------------------
_hexToNum::
;gsmram.c:271: if (h >= '0' && h <='9')
	ld	c, a
	sub	a, #0x30
	jr	C, 00102$
	ld	a, #0x39
	sub	a, c
	jr	C, 00102$
;gsmram.c:272: return h-'0';    
	ld	a, c
	add	a, #0xd0
	ret
00102$:
;gsmram.c:273: return 0;
	xor	a, a
;gsmram.c:274: }
	ret
;gsmram.c:276: void jump(uint addr) __naked
;	---------------------------------
; Function jump
; ---------------------------------
_jump::
;gsmram.c:284: __endasm;
	ld	sp,(0x0006)
	jp	(hl)
;gsmram.c:285: }
;gsmram.c:287: void runROM_page1() __naked
;	---------------------------------
; Function runROM_page1
; ---------------------------------
_runROM_page1::
;gsmram.c:303: __endasm;
	di
	ld	sp,#0xCFFF
	ld	hl,#0xFD9A
	ld	a,#0xC9
	ld	(hl),a
	ld	hl,#0xFD9F
	ld	(hl),a
	ld	a,(0xFCC1)
	ld	hl,#0
	call	#0x0024
	ld	hl,(0x4002)
	jp	(hl)
;gsmram.c:304: }
;gsmram.c:305: void runROM_page1_end() __naked {}
;	---------------------------------
; Function runROM_page1_end
; ---------------------------------
_runROM_page1_end::
;gsmram.c:307: void runROM_page2() __naked
;	---------------------------------
; Function runROM_page2
; ---------------------------------
_runROM_page2::
;gsmram.c:323: __endasm;
	di
	ld	sp,#0xCFFF
	ld	hl,#0xFD9A
	ld	a,#0xC9
	ld	(hl),a
	ld	hl,#0xFD9F
	ld	(hl),a
	ld	a,(0xFCC1)
	ld	hl,#0
	call	#0x0024
	ld	hl,(0x8002)
	jp	(hl)
;gsmram.c:324: }
;gsmram.c:325: void runROM_page2_end() __naked {}
;	---------------------------------
; Function runROM_page2_end
; ---------------------------------
_runROM_page2_end::
;gsmram.c:352: int main(void)
;	---------------------------------
; Function main
; ---------------------------------
_main::
;gsmram.c:354: GOAULD_ID = 72;
	ld	a, #0x48
	out	(_GOAULD_ID), a
;gsmram.c:355: if (GOAULD_ID != 0xB7) {
	in	a, (_GOAULD_ID)
	sub	a, #0xb7
	jr	Z, 00102$
;gsmram.c:356: printf("ERROR: Goa'uld not found...\n\r");
	ld	hl, #___str_0
	push	hl
	call	_printf
	pop	af
;gsmram.c:357: return 0;
	ld	de, #0x0000
	ret
00102$:
;gsmram.c:360: if ( (GOAULD_CONFIG & 0x02) == 0) {
	in	a, (_GOAULD_CONFIG)
	bit	1, a
	jr	NZ, 00104$
;gsmram.c:361: printf("ERROR: Super MegaRAM SCC+ not found...\n\r");
	ld	hl, #___str_1
	push	hl
	call	_printf
	pop	af
;gsmram.c:362: return 0;
	ld	de, #0x0000
	ret
00104$:
;gsmram.c:365: i = (GOAULD_CONFIG & 0xC0) >> 6;
	in	a, (_GOAULD_CONFIG)
	and	a, #0xc0
	ld	l, a
;	spillPairReg hl
;	spillPairReg hl
	ld	h, #0x00
;	spillPairReg hl
;	spillPairReg hl
	ld	(_i), hl
	ld	b, #0x06
00643$:
	ld	iy, #_i
	sra	1 (iy)
	rr	0 (iy)
	djnz	00643$
;gsmram.c:366: found = TRUE;
	ld	hl, #_found
	ld	(hl), #0x01
;gsmram.c:367: sslt = 0;
	ld	hl, #_sslt
	ld	(hl), #0x00
;gsmram.c:371: printf("Goa'uld Super MegaRAM SCC+\n\r");
	ld	hl, #___str_2
	push	hl
	call	_printf
;gsmram.c:372: printf("v2.00\n\r");
	ld	hl, #___str_3
	ex	(sp),hl
	call	_printf
	pop	af
;gsmram.c:373: printf("Slot %d\n\r",i);
	ld	hl, (_i)
	push	hl
	ld	hl, #___str_4
	push	hl
	call	_printf
	pop	af
	pop	af
;gsmram.c:375: sslt = 0x80 | (2 << 2) | i;
	ld	a, (_i+0)
	or	a, #0x88
	ld	(_sslt+0), a
;gsmram.c:376: paramlen = *((char*)0x80);
	ld	hl, #0x0080
	ld	a, (hl)
	ld	(_paramlen+0), a
;gsmram.c:377: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, #0x0081
	ld	(_params), hl
00218$:
	ld	bc, (_params)
	ld	a, (bc)
	ld	e, a
	or	a, a
	jr	NZ, 00217$
	ld	a, (_paramlen+0)
	or	a, a
	jp	NZ, 00169$
00217$:
;gsmram.c:379: if (*params != ' ')
	ld	a, e
	sub	a, #0x20
	jp	Z,00219$
;gsmram.c:381: if (*params == '/')
	ld	a, e
	sub	a, #0x2f
	jp	NZ,00162$
;gsmram.c:383: params++;
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
;gsmram.c:384: if (to_upper(*params) == 'R') {
	ld	hl, (_params)
	ld	a, (hl)
	call	_to_upper
	sub	a, #0x52
	jr	NZ, 00155$
;gsmram.c:385: params++;
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
;gsmram.c:377: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	ld	a, (hl)
;gsmram.c:386: if (*params == '6')
	cp	a, #0x36
	jr	NZ, 00115$
;gsmram.c:387: megaram_type = TYPE_K4;
	ld	hl, #0x0004
	ld	(_megaram_type), hl
	jp	00219$
00115$:
;gsmram.c:389: if (*params == '5')
	cp	a, #0x35
	jr	NZ, 00112$
;gsmram.c:390: megaram_type = TYPE_K5;
	ld	hl, #0x0005
	ld	(_megaram_type), hl
	jp	00219$
00112$:
;gsmram.c:392: if (*params == '1')
	cp	a, #0x31
	jr	NZ, 00109$
;gsmram.c:393: megaram_type = TYPE_A16;
	ld	hl, #0x0016
	ld	(_megaram_type), hl
	jp	00219$
00109$:
;gsmram.c:395: if (*params == '3')
	sub	a, #0x33
	jr	NZ, 00106$
;gsmram.c:396: megaram_type = TYPE_A8;
	ld	hl, #0x0008
	ld	(_megaram_type), hl
	jp	00219$
00106$:
;gsmram.c:398: megaram_type = TYPE_UNK;                    
	ld	hl, #0x00ff
	ld	(_megaram_type), hl
	jp	00219$
00155$:
;gsmram.c:400: else if (to_upper(*params) == 'K')
	ld	hl, (_params)
	ld	a, (hl)
	call	_to_upper
	sub	a, #0x4b
	jr	NZ, 00152$
;gsmram.c:402: params++;
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
;gsmram.c:377: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	ld	a, (hl)
;gsmram.c:403: if (*params == '5')
	cp	a, #0x35
	jr	NZ, 00121$
;gsmram.c:404: megaram_type = TYPE_K5;
	ld	hl, #0x0005
	ld	(_megaram_type), hl
	jp	00219$
00121$:
;gsmram.c:406: if (*params == '4')
	sub	a, #0x34
	jr	NZ, 00118$
;gsmram.c:407: megaram_type = TYPE_K4;
	ld	hl, #0x0004
	ld	(_megaram_type), hl
	jp	00219$
00118$:
;gsmram.c:409: megaram_type = TYPE_UNK;
	ld	hl, #0x00ff
	ld	(_megaram_type), hl
	jp	00219$
00152$:
;gsmram.c:411: else if (to_upper(*params) == 'A')
	ld	hl, (_params)
	ld	a, (hl)
	call	_to_upper
	sub	a, #0x41
	jr	NZ, 00149$
;gsmram.c:413: params++;
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
;gsmram.c:377: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	ld	a, (hl)
;gsmram.c:414: if (*params == '8')
	cp	a, #0x38
	jr	NZ, 00130$
;gsmram.c:415: megaram_type = TYPE_A8;
	ld	hl, #0x0008
	ld	(_megaram_type), hl
	jp	00219$
00130$:
;gsmram.c:417: if (*params == '1')
	sub	a, #0x31
	jr	NZ, 00127$
;gsmram.c:419: params++;
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
;gsmram.c:420: if (*params == '6')
	ld	hl, (_params)
	ld	a, (hl)
	sub	a, #0x36
	jr	NZ, 00124$
;gsmram.c:421: megaram_type = TYPE_A16;
	ld	hl, #0x0016
	ld	(_megaram_type), hl
	jp	00219$
00124$:
;gsmram.c:423: megaram_type = TYPE_UNK;
	ld	hl, #0x00ff
	ld	(_megaram_type), hl
	jp	00219$
00127$:
;gsmram.c:426: megaram_type = TYPE_UNK;
	ld	hl, #0x00ff
	ld	(_megaram_type), hl
	jp	00219$
00149$:
;gsmram.c:428: else if (to_upper(*params) == 'Y')
	ld	hl, (_params)
	ld	a, (hl)
	call	_to_upper
	sub	a, #0x59
	jr	NZ, 00146$
;gsmram.c:430: presAB = TRUE;
	ld	hl, #_presAB
	ld	(hl), #0x01
	jr	00219$
00146$:
;gsmram.c:460: else if (to_upper(*params) == 'Z')
	ld	hl, (_params)
	ld	a, (hl)
	call	_to_upper
	sub	a, #0x5a
	jr	NZ, 00143$
;gsmram.c:462: params++;
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
;gsmram.c:377: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	ld	c, (hl)
;gsmram.c:463: if (*params >= '0' && *params <= '3')
	ld	a, c
	sub	a, #0x30
	jr	C, 00219$
	ld	a, #0x33
	sub	a, c
	jr	C, 00219$
;gsmram.c:464: cpumode = *params - '0';
	ld	a, c
	ld	hl, #_cpumode
	add	a, #0xd0
	ld	(hl), a
	jr	00219$
00143$:
;gsmram.c:466: else if (to_upper(*params) == '?')
	ld	hl, (_params)
	ld	a, (hl)
	call	_to_upper
	sub	a, #0x3f
	jr	NZ, 00136$
;gsmram.c:468: help = TRUE;
	ld	hl, #_help
	ld	(hl), #0x01
	jr	00219$
;gsmram.c:473: while(*params++ != 0 && *params != ' ');
00136$:
	ld	hl, (_params)
	ld	c, (hl)
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
	ld	a, c
	or	a, a
	jr	Z, 00219$
	ld	hl, (_params)
	ld	a, (hl)
	sub	a, #0x20
	jr	Z, 00219$
	jr	00136$
00162$:
;gsmram.c:478: filename = params;
	ld	(_filename), bc
;gsmram.c:479: while(*params != 0 && *params != ' ') {
00158$:
;gsmram.c:377: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	ld	c, (hl)
;gsmram.c:479: while(*params != 0 && *params != ' ') {
	ld	a, c
	or	a, a
	jr	Z, 00169$
	ld	a, c
	sub	a, #0x20
	jr	Z, 00169$
;gsmram.c:480: *params = to_upper(*params);
	push	hl
	ld	a, c
	call	_to_upper
	pop	hl
	ld	(hl), a
;gsmram.c:481: params++;
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
	jr	00158$
;gsmram.c:484: break;
00219$:
;gsmram.c:377: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
	ld	iy, #_paramlen
	dec	0 (iy)
	jp	00218$
;gsmram.c:489: } else megaram_type = TYPE_UNK;
00169$:
;gsmram.c:491: if (!found) 
	ld	a, (_found+0)
	or	a, a
	jr	NZ, 00174$
;gsmram.c:493: printf("ERROR: Goa'uld not found...\n\r");
	ld	hl, #___str_0
	push	hl
	call	_printf
	pop	af
;gsmram.c:494: return 0;
	ld	de, #0x0000
	ret
00174$:
;gsmram.c:497: if (help == TRUE || megaram_type == TYPE_UNK)
	ld	a, (_help+0)
	dec	a
	jr	Z, 00170$
	ld	a, (_megaram_type+0)
	inc	a
	ld	hl, #_megaram_type + 1
	or	a, (hl)
	jr	NZ, 00175$
00170$:
;gsmram.c:516: );
	ld	hl, #___str_5
	push	hl
	call	_printf
	pop	af
;gsmram.c:517: return 0;
	ld	de, #0x0000
	ret
00175$:
;gsmram.c:520: printf("\r\nMapper Type: ");
	ld	hl, #___str_6
	push	hl
	call	_printf
	pop	af
;gsmram.c:521: switch(megaram_type)
	ld	a, (_megaram_type+0)
	sub	a, #0x04
	ld	iy, #_megaram_type
	or	a, 1 (iy)
	jr	Z, 00176$
	ld	a, (_megaram_type+0)
	sub	a, #0x05
	or	a, 1 (iy)
	jr	Z, 00177$
	ld	a, (_megaram_type+0)
	sub	a, #0x08
	or	a, 1 (iy)
	jr	Z, 00179$
	ld	a, (_megaram_type+0)
	sub	a, #0x16
	or	a, 1 (iy)
	jr	Z, 00178$
	jr	00180$
;gsmram.c:523: case TYPE_K4:
00176$:
;gsmram.c:524: printf("Konami (/R6 or /K4)\n\r");
	ld	hl, #___str_7
	push	hl
	call	_printf
	pop	af
;gsmram.c:525: break;
	jr	00180$
;gsmram.c:526: case TYPE_K5:
00177$:
;gsmram.c:527: printf("Konami SCC (/R5 or /K5)\n\r");
	ld	hl, #___str_8
	push	hl
	call	_printf
	pop	af
;gsmram.c:528: break;
	jr	00180$
;gsmram.c:529: case TYPE_A16:
00178$:
;gsmram.c:530: printf("ASCII16 (/R1 or /A16)\n\r");
	ld	hl, #___str_9
	push	hl
	call	_printf
	pop	af
;gsmram.c:531: break;
	jr	00180$
;gsmram.c:532: case TYPE_A8:
00179$:
;gsmram.c:533: printf("ASCII8 (/R3 or /A8)\n\r");
	ld	bc, #___str_10+0
	push	bc
	call	_printf
	pop	af
;gsmram.c:535: }
00180$:
;gsmram.c:537: MEGA_PORT1 = 0xF0 | scc_vol;
	ld	a, (_scc_vol+0)
	or	a, #0xf0
	out	(_MEGA_PORT1), a
;gsmram.c:538: MEGA_PORT1 = 0xE0 | psg_vol;
	ld	a, (_psg_vol+0)
	or	a, #0xe0
	out	(_MEGA_PORT1), a
;gsmram.c:539: MEGA_PORT1 = 0xD0 | opll_vol;
	ld	a, (_opll_vol+0)
	or	a, #0xd0
	out	(_MEGA_PORT1), a
;gsmram.c:541: if (filename == 0) {        
	ld	a, (_filename+1)
	ld	hl, #_filename
	or	a, (hl)
	jr	NZ, 00184$
;gsmram.c:542: if (megaram_type != TYPE_UNK)
	ld	a, (_megaram_type+0)
	inc	a
	ld	hl, #_megaram_type + 1
	or	a, (hl)
	jr	Z, 00182$
;gsmram.c:543: MEGA_PORT1 = megaram_type;    
	ld	a, (_megaram_type+0)
	out	(_MEGA_PORT1), a
00182$:
;gsmram.c:544: return 0;
	ld	de, #0x0000
	ret
00184$:
;gsmram.c:547: for(t = filename; *t != ' ' && *t != 0; t++);
	ld	hl, (_filename)
	ld	(_t), hl
00222$:
	ld	hl, (_t)
	ld	a, (hl)
	cp	a, #0x20
	jr	Z, 00185$
	or	a, a
	jr	Z, 00185$
	ld	hl, (_t)
	inc	hl
	ld	(_t), hl
	jr	00222$
00185$:
;gsmram.c:548: *t = 0;
	ld	(hl), #0x00
;gsmram.c:549: handle = dos2_open(0, filename);
	ld	de, (_filename)
	xor	a, a
	call	_dos2_open
	ld	(_handle+0), a
;gsmram.c:551: MEGA_PORT1 = TYPE_K4;
	ld	a, #0x04
	out	(_MEGA_PORT1), a
;gsmram.c:553: if (handle)
	ld	a, (_handle+0)
	or	a, a
	jp	Z, 00195$
;gsmram.c:555: printf("Loading ROM file: %s - ", filename);
	ld	hl, (_filename)
	push	hl
	ld	hl, #___str_11
	push	hl
	call	_printf
	pop	af
	pop	af
;gsmram.c:557: enaslt(sslt, 0x4000);
	ld	de, #0x4000
	ld	a, (_sslt+0)
	call	_enaslt
;gsmram.c:558: page = 0;
	ld	hl, #_page
	ld	(hl), #0x00
;gsmram.c:559: romsize = 0;
	xor	a, a
	ld	(_romsize+0), a
	ld	(_romsize+1), a
	ld	(_romsize+2), a
	ld	(_romsize+3), a
;gsmram.c:560: printf("%04dKB", 0);
	ld	hl, #0x0000
	push	hl
	ld	hl, #___str_12
	push	hl
	call	_printf
	pop	af
	pop	af
;gsmram.c:562: do {
00191$:
;gsmram.c:564: MEGA_PORT0 = 0; // enable paging
	ld	a, #0x00
	out	(_MEGA_PORT0), a
;gsmram.c:565: *((uchar *)0x4000) = page++;
	ld	a, (_page+0)
	ld	c, a
	ld	hl, #_page
	inc	(hl)
	ld	hl, #0x4000
	ld	(hl), c
;gsmram.c:566: b = MEGA_PORT0; (b); // enable ram
	in	a, (_MEGA_PORT0)
	ld	(_b+0), a
;gsmram.c:567: bytes_read = dos2_read(handle, (void*)0x8000, 0x2000);
	ld	h, #0x20
	push	hl
	ld	de, #0x8000
	ld	a, (_handle+0)
	call	_dos2_read
	ld	(_bytes_read), de
;gsmram.c:568: if (presAB == FALSE && romsize == 0) 
	ld	a, (_presAB+0)
	or	a, a
	jr	NZ, 00187$
	ld	a, (_romsize+3)
	ld	iy, #_romsize
	or	a, 2 (iy)
	or	a, 1 (iy)
	or	a, 0 (iy)
	jr	NZ, 00187$
;gsmram.c:569: *((uchar*)(0x8000)) = 0;
	ld	hl, #0x8000
	ld	(hl), #0x00
00187$:
;gsmram.c:570: romsize += bytes_read;
	ld	bc, (_bytes_read)
	ld	de, #0x0000
	ld	a, c
	ld	hl, #_romsize
	add	a, (hl)
	ld	(hl), a
	inc	hl
	ld	a, b
	adc	a, (hl)
	ld	(hl), a
	inc	hl
	ld	a, e
	adc	a, (hl)
	ld	(hl), a
	inc	hl
	ld	a, d
	adc	a, (hl)
	ld	(hl), a
;gsmram.c:571: memcpy((void*)0x4000, (void*)0x8000, bytes_read);
	ld	de, #0x4000
	ld	hl, #0x8000
	ld	bc, (_bytes_read)
	ld	a, b
	or	a, c
	jr	Z, 00689$
	ldir
00689$:
;gsmram.c:572: if (page == 0)
	ld	a, (_page+0)
	or	a, a
	jr	NZ, 00190$
;gsmram.c:573: romstart = *((uint*)0x8002);
	ld	hl, #0x8002
	ld	a, (hl)
	inc	hl
	ld	(_romstart+0), a
	ld	a, (hl)
	ld	(_romstart+1), a
00190$:
;gsmram.c:574: MEGA_PORT0 = 0; // enable paging
	ld	a, #0x00
	out	(_MEGA_PORT0), a
;gsmram.c:575: printf("\b\b\b\b\b\b%04dKB", (uint)(romsize >> 10));
	ld	hl, (_romsize + 1)
	ld	a, (#_romsize + 3)
	ld	e, a
	ld	b, #0x02
00690$:
	srl	e
	rr	h
	rr	l
	djnz	00690$
	push	hl
	ld	hl, #___str_13
	push	hl
	call	_printf
	pop	af
	pop	af
;gsmram.c:577: } while (bytes_read > 0);
	ld	a, (_bytes_read+1)
	ld	hl, #_bytes_read
	or	a, (hl)
	jp	NZ, 00191$
;gsmram.c:579: *((uchar *)0x4000) = 0;
	ld	hl, #0x4000
	ld	(hl), #0x00
;gsmram.c:581: dos2_close(handle);
	ld	a, (_handle+0)
	call	_dos2_close
	jr	00196$
00195$:
;gsmram.c:585: printf("ERROR: Failed loading %s\n\r", filename);
	ld	hl, (_filename)
	push	hl
	ld	hl, #___str_14
	push	hl
	call	_printf
	pop	af
	pop	af
;gsmram.c:586: return 0;
	ld	de, #0x0000
	ret
00196$:
;gsmram.c:588: *t = ' '; // restore space
	ld	hl, (_t)
	ld	(hl), #0x20
;gsmram.c:589: MEGA_PORT1 = megaram_type;
	ld	a, (_megaram_type+0)
	out	(_MEGA_PORT1), a
;gsmram.c:591: enaslt(sslt, 0x4000);
	ld	de, #0x4000
	ld	a, (_sslt+0)
	call	_enaslt
;gsmram.c:592: romstart = 0x4002;
	ld	hl, #0x4002
	ld	(_romstart), hl
;gsmram.c:598: printf("\n\r\n\rStart address: 0x%04x (page %d)\n\r", romstart, page2 == TRUE ? 2 : 1);
	ld	a, (_page2+0)
	dec	a
	jr	NZ, 00226$
	ld	bc, #0x0002
	jr	00227$
00226$:
	ld	bc, #0x0001
00227$:
	push	bc
	ld	hl, #0x4002
	push	hl
	ld	hl, #___str_15
	push	hl
	call	_printf
	pop	af
	pop	af
	pop	af
;gsmram.c:600: switch(megaram_type)
	ld	a, (_megaram_type+0)
	sub	a, #0x04
	ld	iy, #_megaram_type
	or	a, 1 (iy)
	jr	Z, 00200$
	ld	a, (_megaram_type+0)
	sub	a, #0x05
	or	a, 1 (iy)
	jr	Z, 00200$
	ld	a, (_megaram_type+0)
	sub	a, #0x08
	or	a, 1 (iy)
	jr	Z, 00206$
	ld	a, (_megaram_type+0)
	sub	a, #0x16
	or	a, 1 (iy)
	jr	Z, 00203$
	jr	00210$
;gsmram.c:603: case TYPE_K5:
00200$:
;gsmram.c:604: *((uchar *)0x4000) = 0;
	ld	hl, #0x4000
	ld	(hl), #0x00
;gsmram.c:605: *((uchar *)0x6000) = 1;
	ld	h, #0x60
	ld	(hl), #0x01
;gsmram.c:606: if (page2)
	ld	a, (_page2+0)
	or	a, a
	jr	Z, 00210$
;gsmram.c:608: *((uchar *)0x8000) = 0;
	ld	h, #0x80
	ld	(hl), #0x00
;gsmram.c:609: *((uchar *)0xA000) = 1;
	ld	h, #0xa0
	ld	(hl), #0x01
;gsmram.c:611: break;
	jr	00210$
;gsmram.c:612: case TYPE_A16:
00203$:
;gsmram.c:613: *((uchar *)0x6000) = 0;
	ld	hl, #0x6000
	ld	(hl), #0x00
;gsmram.c:614: if (page2)
	ld	a, (_page2+0)
	or	a, a
	jr	Z, 00210$
;gsmram.c:615: *((uchar *)0x8000) = 0;
	ld	h, #0x80
	ld	(hl), #0x00
;gsmram.c:616: break;
	jr	00210$
;gsmram.c:617: case TYPE_A8:
00206$:
;gsmram.c:618: *((uchar *)0x6000) = 0;
	ld	hl, #0x6000
	ld	(hl), #0x00
;gsmram.c:619: *((uchar *)0x6800) = 1;
	ld	h, #0x68
	ld	(hl), #0x01
;gsmram.c:620: if (page2)
	ld	a, (_page2+0)
	or	a, a
	jr	Z, 00210$
;gsmram.c:622: *((uchar *)0x7000) = 0;
	ld	h, #0x70
	ld	(hl), #0x00
;gsmram.c:623: *((uchar *)0x7800) = 1;
	ld	h, #0x78
	ld	(hl), #0x01
;gsmram.c:628: }
00210$:
;gsmram.c:630: if (page2 == TRUE)
	ld	a, (_page2+0)
	dec	a
	jr	NZ, 00212$
;gsmram.c:631: memcpy((void*)0xC000, &runROM_page2, ((uint)&runROM_page2_end - (uint)&runROM_page2));
	ld	hl, #_runROM_page2
	ld	bc, #_runROM_page2_end
	ld	de, #_runROM_page2
	ld	a, c
	sub	a, e
	ld	c, a
	ld	a, b
	sbc	a, d
	ld	b, a
	ld	de, #0xc000
	ld	a, b
	or	a, c
	jr	Z, 00213$
	ldir
	jr	00213$
00212$:
;gsmram.c:633: memcpy((void*)0xC000, &runROM_page1, ((uint)&runROM_page1_end - (uint)&runROM_page1));
	ld	hl, #_runROM_page1
	ld	bc, #_runROM_page1_end
	ld	de, #_runROM_page1
	ld	a, c
	sub	a, e
	ld	c, a
	ld	a, b
	sbc	a, d
	ld	b, a
	ld	de, #0xc000
	ld	a, b
	or	a, c
	jr	Z, 00701$
	ldir
00701$:
00213$:
;gsmram.c:635: if (cpumode != 0)
	ld	a, (_cpumode+0)
	or	a, a
	jr	Z, 00215$
;gsmram.c:636: chgcpu(cpumode == 1 ? Z80_ROM : cpumode == 2 ? R800_ROM : R800_DRAM);
	ld	a, (_cpumode+0)
	dec	a
	jr	NZ, 00228$
	ld	c, a
	jr	00229$
00228$:
	ld	a, (_cpumode+0)
	sub	a, #0x02
	ld	c, #0x81
	jr	Z, 00231$
	ld	c, #0x82
00231$:
00229$:
	ld	a, c
	call	_chgcpu
00215$:
;gsmram.c:639: printf("\n\rPress any key to proceed...\n\r");
	ld	hl, #___str_16
	push	hl
	call	_printf
	pop	af
;gsmram.c:640: c = getchar();
	call	_getchar
	ld	hl, #_c
	ld	(hl), e
;gsmram.c:642: jump(0xC000);
	ld	hl, #0xc000
	call	_jump
;gsmram.c:644: return 1; // make sdcc happy
	ld	de, #0x0001
;gsmram.c:645: }
	ret
___str_0:
	.ascii "ERROR: Goa'uld not found..."
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_1:
	.ascii "ERROR: Super MegaRAM SCC+ not found..."
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_2:
	.ascii "Goa'uld Super MegaRAM SCC+"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_3:
	.ascii "v2.00"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_4:
	.ascii "Slot %d"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_5:
	.db 0x0a
	.db 0x0d
	.ascii "USAGE: GSMRAM [/Rx /Zx /Y] [romfile]"
	.db 0x0a
	.db 0x0d
	.db 0x0a
	.db 0x0d
	.ascii " /Rx: Set MegaROM type"
	.db 0x0a
	.db 0x0d
	.ascii "   1: ASCII16    (/A16)"
	.db 0x0a
	.db 0x0d
	.ascii "   3: ASCII8     (/A8)"
	.db 0x0a
	.db 0x0d
	.ascii "   5: Konami SCC (/K5)"
	.db 0x0a
	.db 0x0d
	.ascii "   6: Konami     (/K4)"
	.db 0x0a
	.db 0x0d
	.db 0x0a
	.db 0x0d
	.ascii " /Zx: Set cpu mode"
	.db 0x0a
	.db 0x0d
	.ascii "   0: current"
	.db 0x0a
	.db 0x0d
	.ascii "   1: Z80"
	.db 0x0a
	.db 0x0d
	.ascii "   2: R800 ROM"
	.db 0x0a
	.db 0x0d
	.ascii "   3: R800 DRAM"
	.db 0x0a
	.db 0x0d
	.db 0x0a
	.db 0x0d
	.ascii " /Y:  Preserve AB header"
	.db 0x0a
	.db 0x0d
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_6:
	.db 0x0d
	.db 0x0a
	.ascii "Mapper Type: "
	.db 0x00
___str_7:
	.ascii "Konami (/R6 or /K4)"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_8:
	.ascii "Konami SCC (/R5 or /K5)"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_9:
	.ascii "ASCII16 (/R1 or /A16)"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_10:
	.ascii "ASCII8 (/R3 or /A8)"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_11:
	.ascii "Loading ROM file: %s - "
	.db 0x00
___str_12:
	.ascii "%04dKB"
	.db 0x00
___str_13:
	.db 0x08
	.db 0x08
	.db 0x08
	.db 0x08
	.db 0x08
	.db 0x08
	.ascii "%04dKB"
	.db 0x00
___str_14:
	.ascii "ERROR: Failed loading %s"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_15:
	.db 0x0a
	.db 0x0d
	.db 0x0a
	.db 0x0d
	.ascii "Start address: 0x%04x (page %d)"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_16:
	.db 0x0a
	.db 0x0d
	.ascii "Press any key to proceed..."
	.db 0x0a
	.db 0x0d
	.db 0x00
	.area _CODE
	.area _INITIALIZER
__xinit__found:
	.db #0x00	; 0
__xinit__filename:
	.dw #0x0000
__xinit__megaram_type:
	.dw #0x0005
__xinit__paramlen:
	.db #0x00	; 0
__xinit__presAB:
	.db #0x00	; 0
__xinit__cpumode:
	.db #0x01	; 1
__xinit__page2:
	.db #0x00	; 0
__xinit__help:
	.db #0x00	; 0
__xinit__scc_vol:
	.db #0x09	; 9
__xinit__psg_vol:
	.db #0x09	; 9
__xinit__opll_vol:
	.db #0x09	; 9
	.area _CABS (ABS)
