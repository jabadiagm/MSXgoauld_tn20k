		;; crt0.s

		.module crt0
        .area		_HEADER (ABS)	
        .org		0x0100        
        .globl		_main
        .globl          __himem
        .globl          __lomem
        .globl          __heap_start

        .globl 		l__DATA
        .globl 		s__DATA
        .globl 		l__INITIALIZER
        .globl 		s__INITIALIZED
        .globl 		s__INITIALIZER

        ld              (#__himem),sp        ; store current stack pointer
        ld              hl,#__heap_start
        ld              (#__lomem),hl

        call            gsinit                  ; call SDCC init code

        ld              hl,#0
        ld              de,#0

        call            _main			

        ld              sp,(#__himem)        ; restore original stack pointer

        ;; return to wherever you were called from
        ret	


        ;;	(linker documentation:) where specific ordering is desired - 
        ;;	the first linker input file should have the area definitions 
        ;;	in the desired order
        .area           _GSINIT
        .area           _GSFINAL	
        .area           _HOME
        .area           _CODE
        .area           _INITIALIZER
        .area           _INITFINAL
        .area           _INITIALIZED
        .area           _DATA
        .area           _BSS
        .area           _HEAP

        ;;	this area contains data initialization code.
        .area           _GSINIT
gsinit:	
        ; Default-initialized global variables.
        ld              bc, #l__DATA
        ld              a, b
        or              a, c
        jr              Z, zeroed_data
        ld              hl, #s__DATA
        ld              (hl), #0x00
        dec             bc
        ld              a, b
        or              a, c
        jr              Z, zeroed_data
        ld              e, l
        ld              d, h
        inc             de
        ldir
zeroed_data:
        ; Explicitly initialized global variables.
        ld		bc, #l__INITIALIZER
        ld		a, b
        or		a, c
        jr		Z, gsinit_next
        ld		de, #s__INITIALIZED
        ld		hl, #s__INITIALIZER
        ldir

gsinit_next:
        .area _GSFINAL
        ret

        .area _DATA
        .area _BSS
        ;; this is where we store the stack pointer
__himem:	
        .word 1
__lomem::


        .area _HEAP
__heap_start::
        .word 1