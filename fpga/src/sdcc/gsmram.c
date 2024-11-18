#include<stdio.h>
#include<string.h>
#include "types.h"


#define BDOS                5
#define BDOS_C_WRITE		2
#define BDOS_C_RAWIO		6

#define TYPE_K4  0x04
#define TYPE_K5  0x05
#define TYPE_A16 0x16
#define TYPE_A8  0x08
#define TYPE_UNK 0xFF

#define FHANDLE     uchar
#define DOS2_OPEN	0x43
#define DOS2_CLOSE	0x45
#define DOS2_READ	0x48


#define RDSLT               0x000C
#define CALSLT				0x001C
#define EXPTBL				0xFCC1
#define ENASLT              0x0024
#define HTIMI               0xFD9A
#define HKEYI               0xFD9F
#define CHGCPU	            0x0180

#define Z80_ROM   0x00
#define R800_ROM  0x81
#define R800_DRAM 0x82

#define RAMAD0	0xF341
#define RAMAD1	0xF342
#define RAMAD2	0xF343
#define RAMAD3	0xF344


void bdos() __naked
{
	__asm
	push	ix
	push	iy
	call	BDOS
	pop		iy
	pop		ix
	ret
	__endasm;
}

void bdos_c_write(uchar c) __naked
{
	c;
	__asm

	ld 		e,a
	ld		c,#BDOS_C_WRITE
	call	_bdos

	ret
	__endasm;
}

uchar bdos_c_rawio() __naked
{
	__asm

	ld		e,#0xFF;
	ld		c,#BDOS_C_RAWIO
	call	_bdos

	ret
	__endasm;
}

int putchar(int c) 
{
	if (c >= 0)
		bdos_c_write((char)c);
	return c;
}

int getchar()
{
	uchar c;
	do {
		c = bdos_c_rawio();
	} while(c == 0);
	return (int)c;
}

void fputs(const char *s)
{
	while(*s != NULL)
		putchar(*s++);
}

char to_upper(char c)
{
    if (c >= 'a' && c <= 'z')
        c = c - ('a'-'A');
    return c;
}

void enaslt(uchar slotid, uint addr) __naked
{
    slotid; addr;
    __asm
    push    af
    push    bc
    push    de
    push    hl
    push    ix
    push    iy

    ex      de,hl
    call    #ENASLT

    pop     iy
    pop     ix
    pop     hl
    pop     de
    pop     bc
    pop     af

    ret
    __endasm;
}

uchar rdslt(uchar slotid, uint addr) __naked
{
    slotid; addr;
    __asm
    push    bc
    push    de
 
    ex      de,hl
    call    #RDSLT
    ex      de,hl
 
    pop     de
    pop     bc

    ret
    __endasm;
}

void chgcpu(uchar mode) __naked
{
    mode;
    __asm
    push    bc
    push    de
    push    af

    ld      a,(EXPTBL)
    ld      hl,#CHGCPU
    call    #RDSLT

    cp      #0xC3
    jr      nz,__no_turbo
    ld      a,b

    pop     af

    ld      iy,(EXPTBL-1)
    ld      ix,#CHGCPU
    call    #CALSLT

    push    af

__no_turbo:

    pop     af
    pop     de
    pop     bc
    ret
    __endasm;
}

__sfr __at (0x8E) MEGA_PORT0;
__sfr __at (0x8F) MEGA_PORT1;
__sfr __at (0xA8) PPIA;
__sfr __at (0x40) GOAULD_ID;
__sfr __at (0x41) GOAULD_CONFIG;

#define ENABLE_INT   \
         __asm       \
            ei       \
        __endasm

#define DISABLE_INT  \
         __asm       \
            di       \
        __endasm


FHANDLE dos2_open(uchar mode, const char* filepath) __naked
{
	 filepath; mode;
	__asm
		push	bc
		push	de
		push	hl
		ld 		c,#DOS2_OPEN
		call	BDOS
        or      a
        jr      z,__open_no_err    
        ld      b,#0
__open_no_err:
		ld		a,b
        pop     hl
		pop 	de
		pop     bc
		ret
	__endasm;
}

void dos2_close(FHANDLE hnd) __naked
{
	hnd;
	__asm
		push	bc
		ld   	a,b
		ld 		c,#DOS2_CLOSE
		call	BDOS
		pop     bc
		ret
	__endasm;
}

uint dos2_read(FHANDLE hnd, void *dst, uint size) __naked
{
	hnd; dst; size;
	__asm
		push	ix
		ld		ix,#0
		add		ix,sp
		push	bc

		ld 		b,a
		ld		l, 4 (ix)
		ld		h, 5 (ix)

		ld		c,#DOS2_READ
		call	BDOS

		pop		bc
		pop		ix
		ex 		de,hl
		ret
	__endasm;	
}

uchar dos2_getenv(char *var, char *buf) __naked
{
    var; buf;
	__asm
        ld      b,#255
		ld		c,#0x6B
		call	BDOS
		ret
	__endasm;	
}

char hexToNum(char h)
{
    //if (h >= 'A' && h <= 'F')
    //    return h-'A' + 10;
    if (h >= '0' && h <='9')
        return h-'0';    
    return 0;
}

void jump(uint addr) __naked
{
    addr;
    __asm

    ld      sp,(0x0006)
    jp      (hl)

    __endasm;
}

void runROM_page1() __naked
{
	__asm
    di
    ld      sp,#0xCFFF
    ld      hl,#HTIMI
    ld      a,#0xC9
    ld      (hl),a
    ld      hl,#HKEYI
    ld      (hl),a

    ld      a,(EXPTBL)
    ld      hl,#0
    call    #ENASLT
    ld      hl,(0x4002)
    jp      (hl)
	__endasm;
}
void runROM_page1_end() __naked {}

void runROM_page2() __naked
{
	__asm
    di
    ld      sp,#0xCFFF
    ld      hl,#HTIMI
    ld      a,#0xC9
    ld      (hl),a
    ld      hl,#HKEYI
    ld      (hl),a

    ld      a,(EXPTBL)
    ld      hl,#0
    call    #ENASLT
    ld      hl,(0x8002)
    jp      (hl)
	__endasm;
}
void runROM_page2_end() __naked {}

bool found = FALSE;
char* filename = NULL;
int megaram_type = TYPE_K5;
uchar sslt, b;
uchar *t;
char* params;
char paramlen = 0;
FHANDLE handle;
uint bytes_read;
int i;
uint addr;
uchar page;
ulong romsize;
uchar slotid;
bool presAB = FALSE;
char path[256];
char cpumode = 1; // defaults to Z80_ROM
uint romstart;
bool page2 = FALSE;
bool help = FALSE;
char scc_vol = 9;
char psg_vol = 9;
char opll_vol = 9;
char c;

int main(void)
{
	GOAULD_ID = 72;
	if (GOAULD_ID != 0xB7) {
		printf("ERROR: Goa'uld not found...\n\r");
		return 0;
	}
	
	if ( (GOAULD_CONFIG & 0x02) == 0) {
		printf("ERROR: Super MegaRAM SCC+ not found...\n\r");
		return 0;
	}
	
	i = (GOAULD_CONFIG & 0xC0) >> 6;
    found = TRUE;
    sslt = 0;

    if (found)
    {
        printf("Goa'uld Super MegaRAM SCC+\n\r");
        printf("v2.00\n\r");
		printf("Slot %d\n\r",i);

        sslt = 0x80 | (2 << 2) | i;
        paramlen = *((char*)0x80);
        for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
        {
            if (*params != ' ')
            {
                if (*params == '/')
                {
                    params++;
                    if (to_upper(*params) == 'R') {
                        params++;
                        if (*params == '6')
                            megaram_type = TYPE_K4;
                        else
                        if (*params == '5')
                            megaram_type = TYPE_K5;
                        else
                        if (*params == '1')
                            megaram_type = TYPE_A16;
                        else
                        if (*params == '3')
                            megaram_type = TYPE_A8;
                        else 
                            megaram_type = TYPE_UNK;                    
                    } 
                    else if (to_upper(*params) == 'K')
                    {
                        params++;
                        if (*params == '5')
                            megaram_type = TYPE_K5;
                        else
                        if (*params == '4')
                            megaram_type = TYPE_K4;
                        else
                            megaram_type = TYPE_UNK;
                    }
                    else if (to_upper(*params) == 'A')
                    {
                        params++;
                        if (*params == '8')
                            megaram_type = TYPE_A8;
                        else 
                        if (*params == '1')
                        {
                            params++;
                            if (*params == '6')
                                megaram_type = TYPE_A16;
                            else
                                megaram_type = TYPE_UNK;
                        }
                        else
                            megaram_type = TYPE_UNK;
                    }
                    else if (to_upper(*params) == 'Y')
                    {
                        presAB = TRUE;
                    }
  /*
                    else if (to_upper(*params) == 'V')
                    {
                        params++;
                        uchar param = to_upper(*params++);
                        switch(param)
                        {
                            case 'S': 
                                scc_vol = hexToNum(to_upper(*params));
                                printf("SCC+ volume %d\n\r", (int)scc_vol);
                                break;
                            case 'P': 
                                psg_vol = hexToNum(to_upper(*params));
                                printf("PSG volume %d\n\r", (int)psg_vol);
                                break;
                            case 'O': 
                                opll_vol = hexToNum(to_upper(*params));
                                printf("OPLL volume %d\n\r", (int)opll_vol);
                                break;
                            default:
                            {
                                printf("ERROR: wrong device volume...\n\r");
                                return 0;
                            }
                            break;
                        }
                    }
*/                    
                    else if (to_upper(*params) == 'Z')
                    {
                        params++;
                        if (*params >= '0' && *params <= '3')
                            cpumode = *params - '0';
                    }
                    else if (to_upper(*params) == '?')
                    {
                        help = TRUE;
                    }
                    else
                    {
                        // ignore option
                        while(*params++ != 0 && *params != ' ');
                    }
                } 
                else {
                    // should be filename
                    filename = params;
                    while(*params != 0 && *params != ' ') {
                            *params = to_upper(*params);
                            params++;
                    }

                     break;
                }
            }
        }

    } else megaram_type = TYPE_UNK;

    if (!found) 
    {
        printf("ERROR: Goa'uld not found...\n\r");
        return 0;
    }
    else
    if (help == TRUE || megaram_type == TYPE_UNK)
    {
        printf("\n\rUSAGE: GSMRAM [/Rx /Zx /Y] [romfile]\n\r\n\r"
                " /Rx: Set MegaROM type\n\r"
                "   1: ASCII16    (/A16)\n\r"
                "   3: ASCII8     (/A8)\n\r"
                "   5: Konami SCC (/K5)\n\r"
                "   6: Konami     (/K4)\n\r\n\r"
//                " /Vxy: Set volume for\n\r"
//                "   S: SCC+\n\r"
//                "   P: PSG\n\r"
//                "   O: OPLL\n\r"
//                "   y: 0-9\n\r\n\r"
                " /Zx: Set cpu mode\n\r"
                "   0: current\n\r"
                "   1: Z80\n\r"
                "   2: R800 ROM\n\r"
                "   3: R800 DRAM\n\r\n\r"
                " /Y:  Preserve AB header\n\r\n\r"
        );
        return 0;
    }

    printf("\r\nMapper Type: ");
    switch(megaram_type)
    {
        case TYPE_K4:
                printf("Konami (/R6 or /K4)\n\r");
                break;
        case TYPE_K5:
                printf("Konami SCC (/R5 or /K5)\n\r");
                break;
        case TYPE_A16:
                printf("ASCII16 (/R1 or /A16)\n\r");
                break;
        case TYPE_A8:
                printf("ASCII8 (/R3 or /A8)\n\r");
                break;
    }

    MEGA_PORT1 = 0xF0 | scc_vol;
    MEGA_PORT1 = 0xE0 | psg_vol;
    MEGA_PORT1 = 0xD0 | opll_vol;

    if (filename == 0) {        
        if (megaram_type != TYPE_UNK)
            MEGA_PORT1 = megaram_type;    
        return 0;
    } 

    for(t = filename; *t != ' ' && *t != 0; t++);
    *t = 0;
    handle = dos2_open(0, filename);

    MEGA_PORT1 = TYPE_K4;

    if (handle)
    {
            printf("Loading ROM file: %s - ", filename);
            
            enaslt(sslt, 0x4000);
            page = 0;
            romsize = 0;
            printf("%04dKB", 0);

            do {

                MEGA_PORT0 = 0; // enable paging
                *((uchar *)0x4000) = page++;
                b = MEGA_PORT0; (b); // enable ram
                bytes_read = dos2_read(handle, (void*)0x8000, 0x2000);
                if (presAB == FALSE && romsize == 0) 
                    *((uchar*)(0x8000)) = 0;
                romsize += bytes_read;
                memcpy((void*)0x4000, (void*)0x8000, bytes_read);
                if (page == 0)
                    romstart = *((uint*)0x8002);
                MEGA_PORT0 = 0; // enable paging
                printf("\b\b\b\b\b\b%04dKB", (uint)(romsize >> 10));

            } while (bytes_read > 0);

             *((uchar *)0x4000) = 0;
            
            dos2_close(handle);
    } 
    else 
    {
        printf("ERROR: Failed loading %s\n\r", filename);
        return 0;
    }
    *t = ' '; // restore space
    MEGA_PORT1 = megaram_type;
    
    enaslt(sslt, 0x4000);
    romstart = 0x4002;
    if (romstart > 0x7fff)
    {
        enaslt(sslt, 0x8000);
        page2 = TRUE;
    }
    printf("\n\r\n\rStart address: 0x%04x (page %d)\n\r", romstart, page2 == TRUE ? 2 : 1);

    switch(megaram_type)
    {
        case TYPE_K4:
        case TYPE_K5:
            *((uchar *)0x4000) = 0;
            *((uchar *)0x6000) = 1;
            if (page2)
            {
                *((uchar *)0x8000) = 0;
                *((uchar *)0xA000) = 1;
            }
            break;
        case TYPE_A16:
            *((uchar *)0x6000) = 0;
            if (page2)
                *((uchar *)0x8000) = 0;
            break;
        case TYPE_A8:
            *((uchar *)0x6000) = 0;
            *((uchar *)0x6800) = 1;
            if (page2)
            {
                *((uchar *)0x7000) = 0;
                *((uchar *)0x7800) = 1;
            }
            break;
        default:
            break;
    }

    if (page2 == TRUE)
        memcpy((void*)0xC000, &runROM_page2, ((uint)&runROM_page2_end - (uint)&runROM_page2));
    else
        memcpy((void*)0xC000, &runROM_page1, ((uint)&runROM_page1_end - (uint)&runROM_page1));
    
    if (cpumode != 0)
        chgcpu(cpumode == 1 ? Z80_ROM : cpumode == 2 ? R800_ROM : R800_DRAM);
    

    printf("\n\rPress any key to proceed...\n\r");
    c = getchar();

    jump(0xC000);

    return 1; // make sdcc happy
}


