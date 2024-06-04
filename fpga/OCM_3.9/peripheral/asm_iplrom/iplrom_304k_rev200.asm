;
; iplrom*.*
;   initial program loader for Cyclone & EPCS (Altera)
;   Revision 2.00
;
; Copyright (c) 2006 Kazuhiro Tsujikawa (ESE Artists' factory)
; All rights reserved.
;
; Redistribution and use of this source code or any derivative works, are
; permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice,
;    this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright
;    notice, this list of conditions and the following disclaimer in the
;    documentation and/or other materials provided with the distribution.
; 3. Redistributions may not be sold, nor may they be used in a commercial
;    product or activity without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
; TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
; PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
; CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
; OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
; ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
; IPL-ROM Revision 2.00 for 304 kB unpacked
; EPCS4 start adr 34000h - Optimized by KdL 2017.09.18
;
; Coded in TWZ'CA3 w/ TASM80 v3.2ud for OCM-PLD Pack v3.4 or later
;
; SDHC support by Yuukun-OKEI, thanks to MAX
;

            .org        $FC00
;----------------------------------------

SDBIOS_LEN: .equ        32                 ; SDBIOS lenght: 24=384 kB, 32=512 kB
;----------------------------------------

begin:                                     ; ### from low memory ($0000) ###
            di
; self copy
            ld          bc, end-begin      ; bc = ipl-rom file size (bytes)
            ld          de, begin          ; de = RAM start adr
            ld          h, e               ; ld hl, $0000
            ld          l, e               ; hl = IPL-ROM start adr
            ldir                           ; copy to RAM
; set VDP color palette
            ld          hl, data_r16
            ld          bc, $0299          ; 2 bytes => $99
            otir
            ld          bc, $209A          ; 32 bytes => $9A
            otdr
; b = $00
;----------------------------------------

            jp          init_stack         ; WARNING!! DO NOT CHANGE THIS LINE
;----------------------------------------
init_stack:                                ; ### to high memory ($FCXX) ###
            ld          sp, $FFFF          ; initializing stack pointer
            ld          a, $D4
            out         ($40), a           ; I/O $40 = 212
; check 'AB' marker in RAM
            ld          a, $80
            ld          ($7000), a
            ld          hl, ($8000)
            ld          de, 'B'*256+'A'
            sbc         hl, de
            jp          z, init_sys        ; yes 'AB'
; check SD CARD
            ld          a, $40
            ld          ($6000), a

            ld          hl, $C000          ; sector buffer
            inc         b                  ; ld bc, $0100 => sector 0
            ld          c, l
            ld          d, l               ; ld de, $0000
            ld          e, l
load_sd:
;----------------------------------------
;           jp          load_epcs          ; loading BIOS from EPCS only
            call        read_sd            ; read from SD CARD
;----------------------------------------

            jr          c, load_epcs       ; loading BIOS from SD CARD or EPCS (default)
;           jr          c, load_sd         ; loading BIOS from SD CARD only
; read OK => CY = 0
;----------------------------------------

; search 'FAT' checksum
            ld          hl, $C000          ; buffer
            ld          bc, $0080
loop_f:
            ld          a, 'F'             ; 'F'
            cpir
            or          a
            jr          nz, exit_fat
test_fat:
            add         a, (hl)            ; 'A'
            inc         hl
            add         a, (hl)            ; 'T'
            sub         'F'+'A'+'T'
            dec         hl
            jr          nz, loop_f
; yes marker 'FAT'
            ld          c, b               ; ld c, $00
            ld          e, c               ; ld de, $0000
            ld          d, c
            scf
; no 'FAT'
exit_fat:
            jr          c, find_ab         ; CY = 1 => yes 'FAT'
;----------------------------------------

; test MBR, search partition
            ld          b, $04             ; partitions to find
            ld          hl, $C000+$01C6    ; sector offset
find_part:
            push        hl
            ld          e, (hl)
            inc         hl
            ld          d, (hl)
            inc         hl
            ld          c, (hl)
            ld          a, c
            or          d
            or          e
            pop         hl
            jr          nz,exit_mbr        ; yes partition

            ld          de, $0010
            add         hl, de
            djnz        find_part
; no partition
            scf                            ; CY = 1 error
;----------------------------------------

exit_mbr:
            jr          c, load_epcs       ; no partition
; yes partition
            push        de
            push        bc
            ld          b, $01             ; 1 sector
            ld          hl, $C000          ; DAT buffer
            call        read_sd            ; PBR read
            pop         bc
            pop         de
            jr          nc, find_ab        ; CY = 1 => error
;----------------------------------------

load_epcs:
            ld          hl, read_epcs      ; get_data <= call read_epcs
            ld          (get_data+1), hl
;----------------------------------------

; load BIOS from EPCS
            ld          a, $60
            ld          ($6000), a
;----------------------------------------
;           ld          de, $0180          ; EPCS start adr = 30000h / 512 <320k
            ld          de, $01A0          ; EPCS start adr = 34000h / 512 <304k
;----------------------------------------
            ld          a, $80             ; ESE-RAM init adr
            ld          b, 4-1             ; DISK lenght -1
            call        load_blocks        ;  4 * 16 kB [DATA]
            ld          b, 4-1             ; FILL ZERO lenght -1
            call        load_zero_16k      ; +4 * 16 kB [ZERO]
            call        load_blocks        ; +1 * 16 kB [DATA] <= MAIN(1)
            call        set_f4_device      ; set F4 normal or inverted
            ld          b, 6-1             ; MAIN(2)+XBAS+MUS+SUB+KNJ lenght -1
            call        load_blocks        ; +7 * 16 kB [DATA]
;----------------------------------------
;           call        load_blocks        ; +1 * 16 kB [DATA] <= HEX-FILE 320k
            call        load_free_16k      ; +1 * 16 kB [FREE] <= HEX-FILE 304k
;----------------------------------------
            ld          b, 8-1             ; JIS1 lenght -1
            call        load_blocks        ; +8 * 16 kB [DATA]
            jr          set_jis2_ena       ; a = $b0 (384 kB) JIS2 enabler = Off
;----------------------------------------

; test BIOS on SD CARD
find_ab:
            ld          ix, $C000          ; PBR buffer

            ld          l, (ix+$0E)        ; number of reserved
            ld          h, (ix+$0F)        ; sectors
            ld          a, c
            add         hl, de
            adc         a, $00
            ld          c, a

            ld          e, (ix+$11)        ; number of root
            ld          d, (ix+$12)        ; entries
            ld          a, e
            and         $0F
            ld          b, $04
loop1_ab:
            srl         d
            rr          e
            djnz        loop1_ab

            or          a                  ; CY = 0
            jr          z, parse_ab

            inc         de
parse_ab:
            push        de
            ld          b, (ix+$10)        ; FAT type

            ld          e, (ix+$16)        ; number of sectors
            ld          d, (ix+$17)        ; per FAT
            ld          a, c
loop2_ab:
            add         hl, de
            adc         a, $00
            djnz        loop2_ab

            pop         de
            add         hl, de
            ex          de, hl
            ld          c, a

            push        de
            push        bc
            ld          b, $01
            ld          hl, $C000          ; buffer
            call        read_sd            ; read
            jr          c, exit_ab         ; error

            ld          hl, ($C000)        ; first two bytes
            ld          de, 'B'*256+'A'    ; 'AB' marker of Disk-ROM
            or          a                  ; CY = 0
            sbc         hl, de             ; compare
            pop         bc
            pop         de
            jr          z, exit_ab         ; yes marker
            scf                            ; CY = 1 error
;----------------------------------------

exit_ab:
            jp          c, load_epcs       ; test error
; test OK
;----------------------------------------

; load BIOS from SD CARD
            ld          a, $80
            ld          b, 9               ;   9 * 16 kB <= DISK+MAIN(1)
            call        load_erm
            call        set_f4_device      ; set F4 normal or inverted
test_sdbios_len:
            ld          b, SDBIOS_LEN-9    ; (len-9) * 16k <= MAIN(2)+OTHERS
            call        load_erm
            cpl                            ; a = $b0 (384 kB) JIS2 enabler = Off
            rlca                           ; a = $c0 (512 kB) JIS2 enabler = On
set_jis2_ena:
            out         ($4E), a           ; set JIS2 enabler
;----------------------------------------

; start system
init_sys:
            xor         a
            ld          ($6000), a         ; init ESE-RAM adr $6000
            inc         a
            ld          ($6800), a         ; init ESE-RAM adr $6800
            ld          ($7000), a         ; init ESE-RAM adr $7000
            ld          ($7800), a         ; init ESE-RAM adr $7800
            ld          a, $C0
            out         ($A8), a           ; ff_ldbios_n <= '1' [emsx_top.vhd]
;----------------------------------------

            rst         00                 ; reset MSX BASIC
;----------------------------------------  ; $C7 => color 15 (unused/green)

; VDP port 9Ah (set color palette) optimized for otdr
;             unused/green , red/blue
            .db              $77           ; color 15 (red/blue) => .db $77, $07
            .db         $05, $55           ; color 14
            .db         $02, $65           ; color 13
            .db         $04, $11           ; color 12
            .db         $06, $64           ; color 11
            .db         $06, $61           ; color 10
            .db         $03, $73           ; color 9
            .db         $01, $71           ; color 8
            .db         $06, $27           ; color 7
            .db         $01, $51           ; color 6
            .db         $03, $27           ; color 5
            .db         $01, $17           ; color 4
            .db         $07, $33           ; color 3
            .db         $06, $11           ; color 2
            .db         $00                ; color 1 (unused/green)
; VDP port 99h (set register)
data_r16:                                  ; optimized for otir
;              start otir ----->
            .db              $00           ; color 1 (red/blue)
            .db         $90, $00           ; $00 => R16 (Palette) => color 0
;                               <----- start otdr
;----------------------------------------

; F4 device
set_f4_device:
            ex          af, af'
            ld          a, ($8000+$002D)   ; MSX-ID adr = $002D of MAIN-ROM
            sub         $03                ; MSX-ID = 3 is MSXtR
            out         ($4F), a           ; $0X = normal, $FX = inverted
            out         ($F4), a           ; force MSX logo = on
            rrca                           ; free16k ($FF) when MSX-ID = 0, 1, 2
            or          $C9                ; no-logo ($C9) when MSX-ID = 3, 4, 5
            ld          (fill_free_16k+1), a
            ex          af, af'
            ret
;----------------------------------------

load_free_16k:
            ld          hl, $2318          ; set fill_free_16k = on
            jr          load_skip_fill
load_zero_16k:
            ld          hl, $2518          ; set fill_zero_16k = on
load_skip_fill:
            ld          (skip_fill_16k), hl
;----------------------------------------

load_blocks:
            ld          c, e
            inc         b                  ; +1 block (16 kB)
load_erm:
            ld          ($7000), a         ; ermbank2 (8 kB)
            inc         a
            ld          ($7800), a         ; ermbank3 (8 kB)
            inc         a
            push        af
            push        bc
; load page 16 kB
            ld          b, $20             ; 32 sectors
            ld          hl, $8000          ; buffer
get_data:
            call        read_sd            ; or read_epcs (read and load)
            pop         bc
            pop         hl
            ret         c                  ; error
            ld          a, h
            djnz        load_erm

            ld          h, b               ; ld hl, $0000 (default)
            ld          l, b               ; set fill_free_16k = off
            ld          (skip_fill_16k), hl
            ret                            ; OK
;----------------------------------------

; for EPCS
read_epcs:
            push        de
            push        bc
            sla         e
            rl          d
            ld          c, b
            xor         a                  ; a = $00
            ld          b, a
;----------------------------------------

skip_fill_16k:
            nop 
            nop
;           jr          fill_free_16k      ; $1823 => jr +35 bytes
;           jr          fill_zero_16k      ; $1825 => jr +37 bytes
;----------------------------------------

            push        hl                                                  ; +1
            ld          hl, $4000          ; /CS = 0                        ; +3
            ld          (hl), $03                                           ; +2
            ld          (hl), d                                             ; +1
            ld          (hl), e                                             ; +1
            ld          (hl), b                                             ; +1
            ld          a, (hl)                                             ; +1
            pop         de
loop_epcs:                                                                  ; +1
            ld          a, (hl)                                             ; +1
            ld          (de), a                                             ; +1
            inc         de                                                  ; +1
            ld          a, (hl)                                             ; +1
            ld          (de), a                                             ; +1
            inc         de                                                  ; +1
            djnz        loop_epcs          ; 256 cycles * 2 bytes           ; +2

            dec         c                  ; 32 cycles                      ; +1
            jr          nz, loop_epcs                                       ; +2

            ld          a, ($5000)         ; /CS = 1                        ; +3
            pop         bc                                                  ; +1
            pop         hl                                                  ; +1
            xor         a                                                   ; +1
            ld          d, a                                                ; +1
            ld          e, b                                                ; +1
            add         hl, de                                              ; +1
            ex          de, hl                                              ; +1
exit_read_epcs:
            adc         a, c                                                ; +1
            ld          c, a                                                ; +1
            ret                                                             ; +1
;----------------------------------------                                   ;___
                                                                            ;=35
fill_free_16k:
            ld          a, $FF                                              ; +2
fill_zero_16k:                                                              ;___
            ex          de, hl                                              ;=37
loop_fill_16k:
            ld          (de), a
            inc         de
            ld          (de), a
            inc         de
            djnz        loop_fill_16k      ; 256 cycles * 2 bytes

            dec         c                  ; 32 cycles
            jr          nz, loop_fill_16k
            pop         bc
            pop         de
            xor         a
            jr          exit_read_epcs
;----------------------------------------

; set MMC/SDSC or SDHC
set_cmd:
_Z0026:
            ld          a, ($FFCF)
            cp          $03                ; SDHC
            jr          z, _Z0021
            cp          $02                ; MMC/SDSC
            jr          z, _Z0022
            scf
            ret
;----------------------------------------

; SDHC address set
_Z0021:
            ld          a, (hl)            ; SDHC
            ld          (hl), b            ; CMD
            ld          (hl), $00
            ld          (hl), c
            ld          (hl), d
            ld          (hl), e
            ld          (hl), $95          ; CRC
            jr          _Z0023

; shift address x512
_Z0022:  
            sla         e                  ; MMC/SDSC
            rl          d
            rl          c

; SDSC address set & init status
set_cmd2:
_Z0055:
            ld          a, (hl)
            ld          (hl), b            ; CMD
            ld          (hl), c
            ld          (hl), d
            ld          (hl), e
            ld          (hl), $00
            ld          (hl), $95          ; CRC
            jr          _Z0023

; init status set2
set_cmd8:
_Z0056:
            ld          a, (hl)
            ld          (hl), b            ; CMD8
            ld          (hl), $00
            ld          (hl), $00
            ld          (hl), c            ; 01
            ld          (hl), d            ; AA
            ld          (hl), e            ; 87(CRC)

; SD command execute
_Z0023:
            ld          a, (hl)
            ld          bc, $0010          ; 16 cycles
_Z0024:
            ld          a, (hl)
            cp          $FF
            ccf
            ret         nc                 ; no error
            dec         bc
            ld          a, b
            or          c
            jr          nz, _Z0024
            scf                            ; error
            ret
;----------------------------------------

; MMC/SDSC/SDHC read
test_sd:
_Z0027:
            call        init_sd
            pop         bc
            pop         de
            pop         hl
            ret         c                  ; error

; read from SD CARD
read_sd:
_Z0001:
            push        hl
            push        de
            push        bc
            ld          b, $51
            ld          hl, $4000          ; CMD17 - READ_SINGLE_BLOCK
            call        set_cmd
            jr          c, test_sd         ; error
            pop         bc
            pop         de
            pop         hl
            or          a
            scf
            ret         nz                 ; error
            push        de
            push        bc
            ex          de, hl
            ld          bc, $0200          ; 512 bytes
            ld          hl, $4000
_Z0028:
            ld          a, (hl)
            cp          $FE
            jr          nz, _Z0028
            ldir
            ex          de, hl
            ld          a, (de)
            pop         bc
            ld          a, (de)
            pop         de
            inc         de
            ld          a, d
            or          e
            jr          nz, _Z0029
            inc         c
_Z0029:
            djnz        _Z0001
            ret
;----------------------------------------

;SDSC/MMC or SDHC checkflag set
init_sd:
_Z0025:
            call        _Z0061             ; MMC/SDSC/SDHC init
            ret         c
            ret         nz
            ld          hl, $FFCF
            ld          a, $03
            cp          e
            jr          nz, _Z0062
            ld          (hl), $03          ; SDHC
            jr          _Z0063
_Z0062:
            ld          (hl), $02          ; MMC/SDSC
_Z0063:
            xor         a
            ret

; MMC/SDSC/SDHC init
_Z0061:
            ld          hl, $4000
            ld          b, $0A             ; 10 bytes
_Z0054:
            ld          a, ($5000)         ; /CS = 1 (bit12)
            djnz        _Z0054
            ld          bc, $4000          ; CMD0 - GO_IDLE_STATE
            ld          de, $0000
            call        set_cmd2
            ret         c                  ; error
            and         $F3
            cp          $01
            ret         nz                 ; error
            ld          bc, $4801          ; CMD8
            ld          de, $AA87          ; CRC:87H
            call        set_cmd8
            ret         c                  ; error
            cp          $01
            jr          nz, _Z0057
            ld          a, (hl)
            nop         
            ld          a, (hl)
            nop         
            ld          a, (hl)
            and         $0F
            cp          $01
            ret         nz                 ; error
            ld          a, (hl)
            cp          $AA
            ret         nz                 ; error
_Z0058:
            ld          bc, $7700          ; CMD55 - APP_CMD
            ld          de, $0000
            call        set_cmd2
            ret         c                  ; error
            cp          $01
            ret         nz                 ; error
            ld          bc, $6940          ; ACMD41 - APP_SEND_OP_COND
            ld          de, $0000
            call        set_cmd2
            ret         c                  ; error
            and         $01
            cp          $01
            jr          z, _Z0058
            ld          bc, $7A00          ; CMD58 - READ_OCR
            ld          de, $0000
            call        set_cmd2
            ret         c                  ; error
            ld          a, (hl)
            cp          (hl)
            cp          (hl)
            cp          (hl)
            bit         6, a
            ld          e, $02
            jr          z, _Z0059          ; SDHC
            inc         e
_Z0059:
            xor a
            ret
_Z0057:
            ld          bc, $7700          ; CMD55
            ld          de, $0000
            call        set_cmd2
            ret         c
            bit         2, a
            jr          nz, _Z0060
            cp          $01
            ret         nz
            ld          bc, $6900          ; ACMD41 - APP_SEND_OP_COND
            ld          de, $0000
            call        set_cmd2
            ret         c                  ; error
            bit         2, a
            jr          nz, _Z0060
            bit         0, a
            jr          nz, _Z0057
            xor         a
            ld          e, $01             ; MMC?
            ret         
_Z0060:
            ld          bc, $4100          ; CMD1 - SEND_OP_COND
            ld          de, $0000
            call        set_cmd2
            ret         c                  ; error
            cp          $01
            jr          z, _Z0057
            ld          e, $00
            or          a
            ret
;----------------------------------------

end:
            .end

