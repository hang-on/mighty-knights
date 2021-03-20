; main.asm
;.sdsctag 1.0, "Mighty Knights", "Hack n' slash", "hang-on Entertainment"
; -----------------------------------------------------------------------------
; GLOBAL DEFINITIONS
; -----------------------------------------------------------------------------
.include "sms_constants.asm"
.equ ENABLED $ff
.equ DISABLED 0
; -----------------------------------------------------------------------------
.memorymap
; -----------------------------------------------------------------------------
  defaultslot 0
  slotsize $4000
  slot 0 $0000
  slot 1 $4000
  slot 2 $8000
  slotsize $2000
  slot 3 $c000
.endme
.rombankmap ; 128K rom
  bankstotal 8
  banksize $4000
  banks 8
.endro
;
.include "psglib.inc"
.include "mighty_knights_lib.asm"
.include "actor_tests.asm"        
.include "actors.asm"
; -----------------------------------------------------------------------------
.ramsection "main variables" slot 3
; -----------------------------------------------------------------------------
  temp_byte db                  ; Temporary variable - byte.
  temp_word db                  ; Temporary variable - word.
  ;
  vblank_counter db
  hline_counter db
  pause_flag db
  ;
  arthur instanceof actor


.ends
.org 0
.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Boot" force
; -----------------------------------------------------------------------------
  boot:
  di
  im 1
  ld sp,$dff0
  ;
  ; Initialize the memory control registers.
  ld de,$fffc
  ld hl,initial_memory_control_register_values
  ld bc,4
  ldir
  FILL_MEMORY $00
  ;
  jp init
  ;
  initial_memory_control_register_values:
    .db $00,$00,$01,$02
.ends
.org $0038
; ---------------------------------------------------------------------------
.section "!VDP interrupt" force
; ---------------------------------------------------------------------------
  push af
  push hl
    in a,CONTROL_PORT
    bit INTERRUPT_TYPE_BIT,a  ; HLINE or VBLANK interrupt?
    jp z,+
      ld hl,vblank_counter
      jp ++
    +:
      ld hl,hline_counter
    ++:
  inc (hl)
  pop hl
  pop af
  ei
  reti
.ends
.org $0066
; ---------------------------------------------------------------------------
.section "!Pause interrupt" force
; ---------------------------------------------------------------------------
  push af
    ld a,(pause_flag)
    cpl
    ld (pause_flag),a
  pop af
  retn
.ends
; -----------------------------------------------------------------------------
.section "main" free
; -----------------------------------------------------------------------------
  init:
  ; Run this function once (on game load/reset). 
    ;
    call PSGInit
    ld hl,adventure_awaits
    ;call PSGPlay
    ;
    call clear_vram
    ld hl,vdp_register_init
    call initialize_vdp_registers
    ;
    ld a,5
    ld b,BORDER_COLOR
    call set_register
    ;
    ld a,0
    ld b,demo_palette_end-demo_palette
    ld hl,demo_palette
    call load_cram
    ;
    ld bc,CHARACTER_SIZE*7
    ld de,SPRITE_BANK_START + CHARACTER_SIZE
    ld hl,arthur_standing_0_tiles
    call load_vram

    INITIALIZE_ACTOR arthur, 0, 100, 100, arthur_standing

    .ifdef TEST_MODE
      jp test_bench
    .endif

    ei
    halt
    halt
    xor a
    ld (vblank_counter),a
    ;
    ld a,ENABLED
    call set_display
    ;
  jp main_loop
    vdp_register_init:
    .db %00100110  %10100000 $ff $ff $ff
    .db $ff $fb $f0 $00 $00 $ff
  ; ---------------------------------------------------------------------------
  main_loop:
    call wait_for_vblank
    ; -------------------------------------------------------------------------
    ; Begin vblank critical code (DRAW).
    call load_sat
    ;
    ; -------------------------------------------------------------------------
    ; Begin general updating (UPDATE).
    call PSGFrame
    call PSGSFXFrame
    call refresh_sat_handler

    ld hl,arthur
    call draw_actor


  jp main_loop
.ends
.bank 2 slot 2
 ; ----------------------------------------------------------------------------
.section "Demo assets" free
; -----------------------------------------------------------------------------
  demo_palette:
    .db $00 $10 $12 $18 $06 $15 $2A $3F $13 $0B $0F $0C $38 $26 $27 $2F
    .db $23 $10 $12 $18 $06 $15 $2A $3F $13 $0B $0F $0C $38 $26 $27 $2F
    demo_palette_end:

  arthur_standing_0_tiles:
    .db $24 $18 $18 $00 $24 $18 $18 $00 $24 $18 $18 $00 $24 $18 $18 $00 $27 $18 $18 $00 $27 $18 $1B $00 $67 $18 $1B $00 $40 $3E $3C $01
    .db $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $E0 $00 $00 $00 $F0 $00 $C0 $00 $F0 $00 $E0 $00 $10 $00 $00 $E0
    .db $DE $18 $3F $18 $86 $00 $7F $00 $9A $18 $7F $18 $D9 $78 $5F $58 $E1 $3D $23 $21 $61 $03 $01 $1D $30 $01 $00 $0E $10 $00 $00 $0F
    .db $F0 $A0 $A0 $A0 $F0 $E0 $E0 $E0 $70 $60 $E0 $60 $30 $00 $C0 $00 $E0 $C0 $C0 $C0 $E0 $C0 $C0 $C0 $60 $80 $00 $00 $40 $00 $00 $80
    .db $10 $0F $00 $00 $10 $08 $00 $07 $30 $08 $08 $07 $27 $18 $18 $00 $65 $00 $18 $00 $CF $00 $30 $00 $FF $00 $00 $00 $7F $00 $00 $00
    .db $C0 $00 $00 $00 $60 $00 $00 $80 $30 $C0 $C0 $00 $10 $E0 $E0 $00 $98 $00 $60 $00 $CC $00 $30 $00 $FC $00 $00 $00 $F8 $00 $00 $00
    .db $00 $00 $00 $00 $18 $00 $00 $00 $24 $18 $18 $00 $24 $18 $18 $00 $24 $18 $18 $00 $24 $18 $18 $00 $24 $18 $18 $00 $24 $18 $18 $00

  arthur_standing_0_layout:
    .db -24, -8, 1
    .db -24, 0, 2
    .db -16, -8, 3
    .db -16, 0, 4
    .db -8, -8, 5
    .db -8, 0, 6
    .db -32, -8, 7

  .dstruct arthur_standing animation 7,arthur_standing_0_layout


  adventure_awaits:
    .incbin "adventure_awaits_compr.psg"

  mockup_background_tilemap:
.dw $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000
.dw $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000
.dw $0001 $0001 $0001 $0002 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0002 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0002 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001
.dw $0003 $0004 $0005 $0006 $0003 $0004 $0007 $0008 $0003 $0004 $0005 $0006 $0003 $0004 $0005 $0009 $0001 $0001 $0609 $000A $000B $0004 $000C $0006 $0003 $000C $0005 $000D $000E $000F $0010 $0011
.dw $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0013 $0001 $0001 $0014 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012 $0012
.dw $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0016 $0001 $0001 $0017 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015
.dw $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0018 $0001 $0001 $0618 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015 $0015
.dw $0015 $0015 $0015 $0015 $0019 $001A $001B $0219 $0019 $001A $021A $0219 $0015 $0015 $0015 $0015 $0617 $0001 $0001 $0616 $001C $001D $001D $001D $001E $0015 $0015 $001F $001D $001D $001D $001D
.dw $0015 $0015 $0015 $0015 $0020 $0021 $0021 $0220 $0020 $0021 $0021 $0220 $0015 $0015 $0015 $0015 $0022 $0023 $0024 $0025 $0026 $0027 $0027 $0027 $0028 $0015 $0015 $0029 $0027 $0027 $0027 $0027
.dw $0015 $0015 $0015 $0015 $002A $0021 $0021 $022A $002B $0021 $0021 $022A $0015 $0015 $0015 $0015 $002C $002D $002E $002F $0030 $0031 $0027 $0027 $0028 $0015 $0015 $0029 $0027 $0027 $0027 $0027
.dw $0015 $0015 $0015 $0015 $0032 $0033 $0233 $0232 $0032 $0033 $0233 $0232 $0015 $0015 $0015 $0034 $0035 $0036 $0236 $0037 $0038 $0238 $0039 $0039 $003A $0015 $0015 $003B $0039 $0039 $0039 $0039
.dw $003C $003D $003C $003D $003C $003E $003F $003D $003C $003E $003F $003D $003C $003D $003C $003D $0040 $0041 $0241 $0042 $0043 $0243 $0044 $0045 $0046 $003C $003D $0246 $0045 $0045 $0045 $0045
.dw $0047 $0048 $0047 $0048 $0047 $0048 $0047 $0048 $0047 $0048 $0047 $0048 $0047 $0048 $0047 $0048 $0049 $004A $024A $0249 $004B $024B $0049 $004C $0249 $0047 $0048 $0049 $004C $004C $004C $004C
.dw $004D $004E $004F $0050 $0051 $004E $004F $0052 $004D $0053 $004F $0054 $004D $0053 $0055 $0056 $0057 $004E $004F $0054 $004D $004E $004F $004D $0058 $004F $0054 $004D $0253 $004F $0054 $004D
.dw $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059
.dw $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $005A $005B $005C $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059
.dw $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059
.dw $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059
.dw $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059
.dw $0059 $0059 $0059 $0059 $0059 $0059 $005A $005B $005C $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059 $0059
.dw $0059 $0059 $0059 $0059 $0059 $005A $005B $005C $0059 $0059 $0059 $0059 $0059 $0059 $0059 $005A $005B $005C $0059 $0059 $005A $005B $005D $0059 $005A $005B $005C $0059 $0059 $0059 $0059 $0059
.dw $005E $005F $005E $005F $005E $005F $005E $005F $005E $005F $005E $005F $005E $005F $005E $005F $005E $005F $005E $005F $005E $005F $005E $0060 $005F $005E $005F $005E $005F $005E $005F $005E
.dw $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000
.dw $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000


  
  mockup_background_tiles:
; Tile index $000
.db $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00
; Tile index $001
.db $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $002
.db $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $04 $FB $FF $04
; Tile index $003
.db $00 $FF $FF $00 $7F $80 $FF $7F $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $004
.db $00 $FF $FF $00 $01 $FE $FF $01 $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $005
.db $60 $9F $FF $60 $F0 $0F $FF $F0 $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $006
.db $0E $F1 $FF $0E $3F $C0 $FF $3F $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $007
.db $40 $BF $FF $40 $F0 $0F $FF $F0 $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $008
.db $08 $F7 $FF $08 $3F $C0 $FF $3F $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $009
.db $00 $FF $FF $00 $00 $FF $FF $00 $80 $7F $FF $80 $C0 $3F $FF $C0 $80 $7F $FF $80 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $00A
.db $00 $FF $FF $00 $03 $FC $FF $03 $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $00B
.db $00 $FF $FF $00 $40 $BF $FF $40 $E0 $1F $FF $E0 $F1 $0E $FF $F1 $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $00C
.db $00 $FF $FF $00 $00 $FF $FF $00 $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $00D
.db $00 $FF $FF $00 $38 $C7 $FF $38 $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $00E
.db $00 $FF $FF $00 $7E $81 $FF $7E $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $00F
.db $00 $FF $FF $00 $01 $FE $FF $01 $83 $7C $FF $83 $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $010
.db $40 $BF $FF $40 $E0 $1F $FF $E0 $F0 $0F $FF $F0 $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $011
.db $02 $FD $FF $02 $07 $F8 $FF $07 $3F $C0 $FF $3F $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $012
.db $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $00 $00 $FF $FF $FF $00 $FF $FF $00 $00 $FF $FF $55 $00 $FF $FF
; Tile index $013
.db $80 $7F $FF $80 $C0 $3F $FF $C0 $E0 $1F $FF $E0 $E0 $1F $FF $E0 $00 $0F $FF $F0 $F0 $0F $FF $F0 $00 $07 $FF $F8 $54 $03 $FF $FC
; Tile index $014
.db $00 $FF $FF $00 $00 $FF $FF $00 $01 $FE $FF $01 $03 $FC $FF $03 $00 $F8 $FF $07 $03 $FC $FF $03 $00 $FE $FF $01 $00 $FF $FF $00
; Tile index $015
.db $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF
; Tile index $016
.db $00 $FF $FF $00 $00 $7F $FF $80 $00 $3F $FF $C0 $00 $1F $FF $E0 $00 $3F $FF $C0 $00 $7F $FF $80 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $017
.db $00 $C0 $FF $3F $00 $E0 $FF $1F $00 $F0 $FF $0F $00 $F0 $FF $0F $00 $F8 $FF $07 $00 $F8 $FF $07 $00 $FC $FF $03 $00 $FE $FF $01
; Tile index $018
.db $00 $FF $FF $00 $00 $FF $FF $00 $00 $7F $FF $80 $00 $3F $FF $C0 $00 $7F $FF $80 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $019
.db $00 $00 $FF $FF $01 $00 $FE $FE $03 $01 $FC $FD $07 $03 $F8 $FB $0F $07 $F0 $F7 $1F $0F $E0 $EF $3F $1F $C0 $DF $7F $3F $80 $BF
; Tile index $01A
.db $7F $00 $80 $80 $FF $7F $00 $7F $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $01B
.db $FF $00 $00 $00 $FF $FE $00 $FE $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $01C
.db $00 $00 $FF $FF $00 $00 $FF $FF $01 $00 $FE $FE $03 $00 $FC $FC $03 $00 $FC $FD $03 $00 $FC $FD $03 $00 $FC $FC $01 $00 $FE $FE
; Tile index $01D
.db $00 $00 $FF $FF $00 $00 $FF $FF $FF $00 $00 $00 $00 $FF $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF
; Tile index $01E
.db $00 $00 $FF $FF $00 $00 $FF $FF $F8 $00 $07 $07 $04 $F8 $03 $FB $FA $04 $01 $FD $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE
; Tile index $01F
.db $00 $00 $FF $FF $00 $00 $FF $FF $1F $00 $E0 $E0 $20 $1F $C0 $DF $7F $00 $80 $BF $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F
; Tile index $020
.db $7F $3F $80 $BF $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F
; Tile index $021
.db $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $022
.db $00 $0F $FF $F0 $00 $0F $FF $F0 $00 $07 $FF $F8 $00 $01 $FF $FE $00 $03 $FF $FC $00 $01 $FF $FE $00 $00 $FF $FF $00 $00 $FF $FF
; Tile index $023
.db $00 $FF $FF $00 $00 $FF $FF $00 $04 $FB $FB $00 $3D $C2 $C2 $00 $40 $87 $BF $00 $4E $81 $B1 $00 $D9 $06 $26 $00 $91 $0E $6E $00
; Tile index $024
.db $00 $FF $FF $00 $C0 $3F $3F $00 $3F $00 $C0 $00 $00 $00 $FF $00 $9F $00 $60 $00 $80 $1F $7F $00 $80 $1F $7F $00 $18 $07 $E7 $00
; Tile index $025
.db $00 $FF $FF $00 $00 $FC $FF $03 $80 $7C $7F $03 $F7 $08 $08 $00 $00 $08 $FF $00 $07 $F8 $F8 $00 $07 $F8 $F8 $00 $07 $F8 $F8 $00
; Tile index $026
.db $01 $00 $FE $FE $01 $00 $FE $FE $01 $00 $FE $FE $FF $00 $00 $00 $01 $00 $FE $00 $19 $00 $E6 $00 $3F $00 $C0 $00 $3F $00 $C0 $00
; Tile index $027
.db $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF
; Tile index $028
.db $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE
; Tile index $029
.db $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F
; Tile index $02A
.db $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $3F $7F $3F $80 $BF $7F $3F $80 $9F $3F $1F $C0 $DF $3F $1F $C0 $C7
; Tile index $02B
.db $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $3F $FF $BF $00 $3F $7F $3F $80 $9F $7F $5F $80 $9F $3F $1F $C0 $C7
; Tile index $02C
.db $01 $00 $FE $FE $03 $00 $FC $FC $02 $00 $FD $FC $06 $00 $F9 $F8 $0C $00 $F3 $F0 $19 $00 $E6 $E0 $33 $00 $CC $C0 $67 $00 $98 $80
; Tile index $02D
.db $A0 $1F $5F $00 $61 $1E $9E $00 $78 $06 $87 $00 $F8 $06 $07 $00 $F0 $0E $0F $00 $F8 $06 $07 $00 $FC $00 $03 $00 $F9 $00 $06 $00
; Tile index $02E
.db $30 $0F $CF $00 $30 $0F $CF $00 $70 $0F $8F $00 $60 $1F $9F $00 $60 $1F $9F $00 $E1 $1E $1E $00 $C3 $3C $3C $00 $C3 $3C $3C $00
; Tile index $02F
.db $07 $F8 $F8 $00 $0F $F0 $F0 $00 $1E $E0 $E1 $00 $7E $80 $81 $00 $FE $00 $01 $00 $FC $00 $03 $00 $F8 $00 $07 $00 $F8 $00 $07 $00
; Tile index $030
.db $3F $00 $C0 $00 $3F $00 $C0 $00 $3F $00 $C0 $00 $7F $00 $80 $00 $7F $00 $80 $00 $7F $00 $80 $00 $FF $00 $00 $00 $FF $00 $00 $00
; Tile index $031
.db $FE $00 $01 $00 $FE $00 $01 $00 $FE $00 $01 $00 $FE $00 $01 $00 $FC $00 $03 $00 $FC $00 $03 $00 $FC $00 $03 $00 $FC $00 $03 $00
; Tile index $032
.db $1F $07 $E0 $E7 $0F $07 $F0 $F1 $07 $01 $F8 $F8 $01 $00 $FE $FE $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF
; Tile index $033
.db $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $7F $FF $7F $00 $1F $7F $1F $80 $87 $1F $00 $E7 $E0 $0C $00 $F7 $F0 $0C $00 $F7 $F0
; Tile index $034
.db $00 $00 $FF $FF $00 $00 $FF $FF $01 $00 $FE $FE $03 $00 $FC $FC $06 $00 $F9 $F8 $07 $00 $F8 $F8 $07 $00 $F8 $F8 $03 $00 $FC $FC
; Tile index $035
.db $4F $00 $B0 $80 $CF $00 $33 $03 $9F $00 $67 $07 $3F $00 $CF $0F $3F $00 $CF $0F $FF $00 $1F $1F $FF $00 $1F $1F $FF $00 $3F $3F
; Tile index $036
.db $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $F8 $F8 $F8 $00 $F7 $F0 $F6 $00 $E9 $E0 $EE $00 $D1 $C0
; Tile index $037
.db $F8 $00 $E7 $E0 $F8 $00 $C7 $C0 $F1 $00 $CE $C0 $F1 $00 $8E $80 $F1 $00 $8E $80 $E3 $00 $9C $80 $E3 $00 $9D $81 $E3 $00 $9D $81
; Tile index $038
.db $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $3C $FF $00 $00 $00 $F8 $01 $06 $00 $C0 $09 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00
; Tile index $039
.db $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $3C
; Tile index $03A
.db $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FF $00 $00 $38
; Tile index $03B
.db $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $1C
; Tile index $03C
.db $1F $00 $E0 $E0 $3F $1F $C0 $DF $7F $3F $80 $BF $FF $7F $00 $7F $FF $7F $00 $7F $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $03D
.db $F8 $00 $07 $07 $FC $F0 $03 $F3 $FE $FC $01 $FD $FF $FE $00 $FE $FF $FE $00 $FE $FF $FE $00 $FE $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $03E
.db $FC $00 $07 $00 $FC $F0 $03 $F0 $FE $FC $01 $FC $FF $FE $00 $FE $FF $FE $00 $FE $FF $FE $00 $FE $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $03F
.db $1F $00 $E0 $00 $3F $1F $C0 $1F $7F $3F $80 $3F $FF $7F $00 $7F $FF $7F $00 $7F $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $040
.db $FF $00 $7F $7F $FF $00 $7F $7F $FF $00 $7F $7F $FF $00 $7F $7F $FF $00 $7F $7F $FF $00 $7F $7F $FF $00 $7F $7F $FF $00 $7F $7F
; Tile index $041
.db $EE $00 $D1 $C0 $EE $00 $D1 $C0 $E0 $0E $D1 $C0 $E0 $00 $DF $C0 $EE $00 $D1 $C0 $EE $00 $D1 $C0 $EE $00 $D1 $C0 $E0 $0E $D1 $C0
; Tile index $042
.db $E3 $00 $9C $80 $F7 $00 $88 $80 $FF $00 $C2 $C2 $FF $00 $C6 $C6 $FF $00 $FE $FE $FF $00 $FE $FE $FF $00 $FE $FE $FF $00 $FE $FE
; Tile index $043
.db $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00
; Tile index $044
.db $FF $00 $00 $3C $FF $00 $00 $00 $FF $00 $43 $43 $FF $00 $7F $7F $FF $00 $7F $7F $FF $00 $7F $7F $FF $00 $7F $7F $FF $00 $7F $7F
; Tile index $045
.db $FF $00 $00 $3C $FF $00 $00 $00 $FF $00 $C3 $C3 $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF
; Tile index $046
.db $FF $00 $00 $38 $FF $00 $00 $00 $FF $00 $C6 $C6 $FF $00 $FE $FE $FF $00 $FE $FE $FF $00 $FE $FE $FF $00 $FE $FE $FF $00 $FE $FE
; Tile index $047
.db $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $7F $FF $7F $00 $1F $FD $1D $02 $00 $FC $00 $03 $00 $FA $00 $05 $00 $FF $00 $00 $00
; Tile index $048
.db $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FE $00 $F8 $BF $B8 $40 $00 $1F $00 $E0 $00 $2F $00 $D0 $00 $FF $00 $00 $00
; Tile index $049
.db $FF $00 $7F $00 $FF $00 $00 $00 $FF $00 $7F $7F $FF $00 $7F $7F $FF $00 $7F $7F $FF $00 $7F $7F $FF $00 $00 $00 $FF $00 $00 $00
; Tile index $04A
.db $E0 $00 $DF $00 $FF $00 $00 $00 $FF $00 $C0 $C0 $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $00 $00 $FF $00 $00 $00
; Tile index $04B
.db $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $7F $00 $00 $FF $00 $00 $00 $FF $00 $FF $00 $FF $00 $00 $00
; Tile index $04C
.db $FF $00 $FF $00 $FF $00 $00 $00 $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $00 $00 $FF $00 $00 $00
; Tile index $04D
.db $00 $FF $00 $00 $00 $FF $00 $00 $F8 $FF $F8 $F8 $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $04E
.db $00 $FF $00 $00 $3C $FF $3C $3C $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $04F
.db $00 $FF $00 $00 $00 $FF $00 $00 $0F $FF $0F $0F $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $050
.db $00 $FF $00 $00 $86 $FF $86 $86 $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $051
.db $00 $FF $00 $00 $00 $FF $00 $00 $B8 $FF $B8 $B8 $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $052
.db $00 $FF $00 $00 $0C $FF $0C $0C $BF $FF $BF $BF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $053
.db $00 $FF $00 $00 $1C $FF $1C $1C $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $054
.db $00 $FF $00 $00 $9E $FF $9E $9E $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $055
.db $00 $FF $00 $00 $00 $FF $00 $00 $0F $FE $0E $0E $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $056
.db $00 $FF $00 $00 $9E $7F $1E $1E $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $057
.db $00 $FF $00 $00 $00 $FF $00 $00 $98 $FF $98 $98 $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $058
.db $1C $FF $00 $00 $1C $FF $1C $1C $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $059
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $05A
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $DF $DF $FF $FF $FF $FF $FF $FF $EF $EF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $05B
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $7F $7F $FF $FF $FF $FF $FF $FF $EF $EF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $BF $BF $FF
; Tile index $05C
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $7F $7F $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $05D
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $DF $DF $FF $FF $FF $FF $FF $FF $6F $6F $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $05E
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FE $FE $FF $FF $77 $77 $FF $FF $DB $DB $FF $FF $36 $36 $FF $FF $00 $00 $FF
; Tile index $05F
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $EF $EF $FF $FF $FB $FB $FF $FF $DE $DE $FF $FF $AB $AB $FF $FF $00 $00 $FF
; Tile index $060
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FE $FE $FF $FF $77 $77 $FF $FF $5B $5B $FF $FF $36 $36 $FF $FF $00 $00 $FF

.ends