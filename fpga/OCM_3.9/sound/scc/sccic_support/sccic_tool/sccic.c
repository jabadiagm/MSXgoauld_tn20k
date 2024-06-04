/* --------------------------------------------------------- */
/*  似非SCC+改 for 1chipMSX interpolation control            */
/* ========================================================= */
/*  Copyright(C)2007 t.hara                                  */
/* --------------------------------------------------------- */

#include <stdio.h>
#include <string.h>
#include <msx/msx.h>

typedef enum {
    SCC_TYPE_UNKNOWN = 0,
    SCC_TYPE_SNATCHER,
    SCC_TYPE_MEGAROM
} SCC_TYPE;

/* --------------------------------------------------------- */
static void get_command_line( char *p_command_line, int size ) {
    int target_size;

    target_size = peek( 0x0080 );
    if( target_size >= size ) {
        target_size = size - 1;
    }
    memcpy( p_command_line, (char*)0x0081, target_size );
    p_command_line[ target_size ] = '\0';
}

/* --------------------------------------------------------- */
static int is_ram( int address ) {
    unsigned char mem_back;

    mem_back = peek( address );
    poke( address, ~mem_back );
    if( peek( address ) == mem_back ) {
        return 0;   /* not RAM */
    }
    return 1;   /* RAM */
}

/* --------------------------------------------------------- */
static int get_scc_type( int slot ) {
    char ppi_port_a;
    char mem_back;

    /*  スロットセレクタをバックアップ */
    ppi_port_a = inport( 0xA8 );

    /*  page2 を指定のスロットにする */
    outport( 0xA8, (ppi_port_a & 0xCF) | (slot << 4) );

    poke( 0xB000, 0x80 );
    poke( 0xBFFE, 0x20 );
    poke( 0xB000, 0x00 );

    mem_back = peek( 0xB800 );
    poke( 0xB800, ~mem_back );
    if( is_ram( 0xB800 ) ) {
        outport( 0xA8, ppi_port_a );
        return SCC_TYPE_UNKNOWN;
    }

    poke( 0xB000, 0x80 );
    if( is_ram( 0xB800 ) ) {
        poke( 0xBFFE, 0x00 );
        poke( 0xB000, 0x80 );
        outport( 0xA8, ppi_port_a );
        return SCC_TYPE_SNATCHER;
    }

    poke( 0xBFFE, 0x00 );
    poke( 0x9000, 0x00 );

    if( is_ram( 0x9800 ) ) {
        poke( 0xB000, 0x80 );
        outport( 0xA8, ppi_port_a );
        return SCC_TYPE_UNKNOWN;
    }

    poke( 0x9000, 0x3F );
    if( !is_ram( 0x9800 ) ) {
        poke( 0xB000, 0x80 );
        outport( 0xA8, ppi_port_a );
        return SCC_TYPE_UNKNOWN;
    }

    poke( 0x9000, 0x00 );

    outport( 0xA8, ppi_port_a );
    return SCC_TYPE_MEGAROM;
}

/* --------------------------------------------------------- */
static int is_xdigit( int c ) {

    if( c >= '0' && c <= '9' ) return '0';
    if( c >= 'A' && c <= 'F' ) return 'A' - 10;
    if( c >= 'a' && c <= 'f' ) return 'a' - 10;
    return 0;
}

/* --------------------------------------------------------- */
static char *get_num( char *p, int *p_num ) {
    int c;

    while( *p == ' ' ) {
        p++;
    }
    if( !is_xdigit( *p ) ) {
        return NULL;
    }
    *p_num = 0;

    while( (c = is_xdigit( *p )) ) {
        *p_num = (*p_num << 4) + (*p - c);
        p++;
    }
    return p;
}

/* --------------------------------------------------------- */
static void usage( void ) {

    printf( "Usage> SCCIC <SLOT#> <EN> <TH1> <TH2> <TH3>\n" );
    printf( "(*)HEX NUMBER ONLY\n" );
}

/* --------------------------------------------------------- */
int main( void ) {
    static char command_line[ 128 ], *p;
    int scc_slot, reg_en, reg_th1, reg_th2, reg_th3;
    int ppi_port_a;

    printf( "SCC Interpolation controller\n" );
    printf( "            for 1chipMSX-kai\n" );
    printf( "============================\n" );
    printf( "     Copyright(C)2007 t.hara\n" );

    get_command_line( command_line, sizeof(command_line) );

#if 1
    /* SDCC には sscanf が無い (-_-; */
    p = command_line;
    p = get_num( p, &scc_slot );    if( p == NULL ) { usage(); return 2; }
    p = get_num( p, &reg_en );      if( p == NULL ) { usage(); return 2; }
    p = get_num( p, &reg_th1 );     if( p == NULL ) { usage(); return 2; }
    p = get_num( p, &reg_th2 );     if( p == NULL ) { usage(); return 2; }
    p = get_num( p, &reg_th3 );     if( p == NULL ) { usage(); return 2; }
#else
    if( sscanf( command_line, "%i %i %i %i %i",
            &scc_slot, &reg_en, &reg_th1, &reg_th2, &reg_th3 ) < 5 ) {
        usage();
        return 1;
    }
#endif

    printf( "SCC SLOT#%d\n", scc_slot );
    printf( "REG_EN  <= %02X\n", reg_en  & 255 );
    printf( "REG_TH1 <= %02X\n", reg_th1 & 255 );
    printf( "REG_TH2 <= %02X\n", reg_th2 & 255 );
    printf( "REG_TH3 <= %02X\n", reg_th3 & 255 );

    if( get_scc_type( scc_slot ) == SCC_TYPE_UNKNOWN ) {
        printf( "ERROR: SLOT#%d is not SCC.\n", scc_slot );
        return 2;
    }

    /*  スロットセレクタをバックアップ */
    ppi_port_a = inport( 0xA8 );
    /*  page2 を指定のスロットにする */
    outport( 0xA8, (ppi_port_a & 0xCF) | (scc_slot << 4) );
    /*  モードレジスタ */
    poke( 0xB000, 0x80 );
    poke( 0xBFFE, 0x20 );   /* bit5 = 1, bit4 = 0 */
    /*  書き込み */
    poke( 0xB8E0, reg_en );
    poke( 0xB8E1, reg_th1 );
    poke( 0xB8E2, reg_th2 );
    poke( 0xB8E3, reg_th3 );
    /*  念のため読み出し */
    reg_en  = peek( 0xB8E0 );
    reg_th1 = peek( 0xB8E1 );
    reg_th2 = peek( 0xB8E2 );
    reg_th3 = peek( 0xB8E3 );

    printf( "REG_EN  => %02X\n", reg_en  & 255 );
    printf( "REG_TH1 => %02X\n", reg_th1 & 255 );
    printf( "REG_TH2 => %02X\n", reg_th2 & 255 );
    printf( "REG_TH3 => %02X\n", reg_th3 & 255 );

    poke( 0xBFFE, 0x00 );
    poke( 0xB000, 0x00 );
    poke( 0x9000, 0x3F );
    /*  スロットを戻す */
    outport( 0xA8, ppi_port_a );

    printf( "SUCCESS.\n" );
    return 0;
}
