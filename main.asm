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
.include "actors.asm"
.include "actor_tests.asm"        
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

    INITIALIZE_ACTOR arthur, 0, 160, 70, arthur_standing

    ld bc,96*CHARACTER_SIZE
    ld de,BACKGROUND_BANK_START
    ld hl,mockup_background_tiles
    call load_vram

    ld bc,VISIBLE_NAME_TABLE_SIZE
    ld de,NAME_TABLE_START
    ld hl,mockup_background_tilemap
    call load_vram


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
    ;.db $00 $10 $12 $18 $06 $15 $2A $3F $13 $0B $0F $0C $38 $26 $27 $2F
    .db $00 $20 $12 $08 $06 $15 $2A $3F $13 $0B $0F $0C $38 $25 $3B $1B
    ;.db $00 $20 $12 $08 $16 $15 $3F $3F $13 $0B $0F $0C $38 $26 $27 $2F
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

  arthur_standing_0_y:
    .db -24, -24, -16, -16, -8, -8, -32

  arthur_standing_0_xc:
    .db  -8, 1, 0, 2, -8, 3, 0, 4, -8, 5, 0, 6, -8, 7

  

  .dstruct arthur_standing animation 7,arthur_standing_0_layout

  .dstruct arthur_standing_0 frame 7 arthur_standing_0_layout

  adventure_awaits:
    .incbin "adventure_awaits_compr.psg"

  mockup_background_tilemap:
.dw $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100
.dw $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100
.dw $0101 $0101 $0101 $0102 $0101 $0101 $0101 $0101 $0101 $0101 $0101 $0102 $0101 $0101 $0101 $0101 $0101 $0101 $0101 $0101 $0101 $0101 $0101 $0102 $0101 $0101 $0101 $0101 $0101 $0101 $0101 $0101
.dw $0103 $0104 $0105 $0106 $0103 $0104 $0107 $0108 $0103 $0104 $0105 $0106 $0103 $0104 $0105 $0109 $0101 $0101 $0709 $010A $010B $0104 $010C $0106 $0103 $010C $0105 $010D $010E $010F $0110 $0111
.dw $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0113 $0101 $0101 $0114 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112 $0112
.dw $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0116 $0101 $0101 $0117 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115
.dw $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0118 $0101 $0101 $0718 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115 $0115
.dw $0115 $0115 $0115 $0115 $0119 $011A $011B $0319 $0119 $011A $031A $0319 $0115 $0115 $0115 $0115 $0717 $0101 $0101 $0716 $011C $011D $011D $011D $011E $0115 $0115 $011F $011D $011D $011D $011D
.dw $0115 $0115 $0115 $0115 $0120 $0121 $0121 $0320 $0120 $0121 $0121 $0320 $0115 $0115 $0115 $0115 $0122 $0123 $0124 $0125 $0126 $0127 $0127 $0127 $0128 $0115 $0115 $0129 $0127 $0127 $0127 $0127
.dw $0115 $0115 $0115 $0115 $012A $0121 $0121 $032A $012B $0121 $0121 $032A $0115 $0115 $0115 $0115 $012C $012D $012E $012F $0130 $0131 $0127 $0127 $0128 $0115 $0115 $0129 $0127 $0127 $0127 $0127
.dw $0115 $0115 $0115 $0115 $0132 $0133 $0333 $0332 $0132 $0133 $0333 $0332 $0115 $0115 $0115 $0134 $0135 $0136 $0336 $0137 $0138 $0338 $0139 $0139 $013A $0115 $0115 $013B $0139 $0139 $0139 $0139
.dw $013C $013D $013C $013D $013C $013E $013F $013D $013C $013E $013F $013D $013C $013D $013C $013D $0140 $0141 $0341 $0142 $0143 $0343 $0144 $0145 $0146 $013C $013D $0346 $0145 $0145 $0145 $0145
.dw $0147 $0148 $0147 $0148 $0147 $0148 $0147 $0148 $0147 $0148 $0147 $0148 $0147 $0148 $0147 $0148 $0149 $014A $034A $0349 $014B $034B $0149 $014C $0349 $0147 $0148 $0149 $014C $014C $014C $014C
.dw $014D $014E $014F $0150 $0151 $014E $014F $0152 $014D $0153 $014F $0154 $014D $0153 $0155 $0156 $0157 $014E $014F $0154 $014D $014E $014F $014D $0153 $014F $0154 $014D $0353 $014F $0154 $014D
.dw $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158
.dw $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158
.dw $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158
.dw $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158
.dw $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158
.dw $0158 $0158 $0158 $0158 $0158 $0158 $0159 $015A $015B $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0158
.dw $0158 $0158 $0158 $0158 $0158 $0159 $015A $015B $0158 $0158 $0158 $0158 $0158 $0158 $0158 $0159 $015A $015B $0158 $0158 $0159 $015A $015C $0158 $0159 $015A $015B $0158 $0158 $0158 $0158 $0158
.dw $015D $015E $015D $015E $015D $015E $015D $015E $015D $015E $015D $015E $015D $015E $015D $015E $015D $015E $015D $015E $015D $015E $015D $015F $015E $015D $015E $015D $015E $015D $015E $015D
.dw $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100
.dw $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100 $0100

  
mockup_background_tiles:
; Tile index $100
.db $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00
; Tile index $101
.db $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00
; Tile index $102
.db $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FB $FF $FF $00
; Tile index $103
.db $FF $FF $FF $00 $80 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $104
.db $FF $FF $FF $00 $FE $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $105
.db $9F $FF $FF $00 $0F $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $106
.db $F1 $FF $FF $00 $C0 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $107
.db $BF $FF $FF $00 $0F $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $108
.db $F7 $FF $FF $00 $C0 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $109
.db $FF $FF $FF $00 $FF $FF $FF $00 $7F $FF $FF $00 $3F $FF $FF $00 $7F $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00
; Tile index $10A
.db $FF $FF $FF $00 $FC $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $10B
.db $FF $FF $FF $00 $BF $FF $FF $00 $1F $FF $FF $00 $0E $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $10C
.db $FF $FF $FF $00 $FF $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $10D
.db $FF $FF $FF $00 $C7 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $10E
.db $FF $FF $FF $00 $81 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $10F
.db $FF $FF $FF $00 $FE $FF $FF $00 $7C $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $110
.db $BF $FF $FF $00 $1F $FF $FF $00 $0F $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $111
.db $FD $FF $FF $00 $F8 $FF $FF $00 $C0 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $112
.db $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $00 $FF $FF $00 $FF $FF $00 $00 $00 $FF $FF $00 $55 $FF $AA
; Tile index $113
.db $7F $FF $FF $00 $3F $FF $FF $00 $1F $FF $FF $00 $1F $FF $FF $00 $0F $0F $FF $F0 $0F $FF $FF $00 $07 $07 $FF $F8 $03 $57 $FF $A8
; Tile index $114
.db $FF $FF $FF $00 $FF $FF $FF $00 $FE $FF $FF $00 $FC $FF $FF $00 $F8 $F8 $FF $07 $FC $FF $FF $00 $FE $FE $FF $01 $FF $FF $FF $00
; Tile index $115
.db $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF
; Tile index $116
.db $FF $FF $FF $00 $7F $7F $FF $80 $3F $3F $FF $C0 $1F $1F $FF $E0 $3F $3F $FF $C0 $7F $7F $FF $80 $FF $FF $FF $00 $FF $FF $FF $00
; Tile index $117
.db $C0 $C0 $FF $3F $E0 $E0 $FF $1F $F0 $F0 $FF $0F $F0 $F0 $FF $0F $F8 $F8 $FF $07 $F8 $F8 $FF $07 $FC $FC $FF $03 $FE $FE $FF $01
; Tile index $118
.db $FF $FF $FF $00 $FF $FF $FF $00 $7F $7F $FF $80 $3F $3F $FF $C0 $7F $7F $FF $80 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00
; Tile index $119
.db $00 $00 $FF $FF $01 $00 $FE $FE $03 $01 $FC $FD $07 $03 $F8 $FB $0F $07 $F0 $F7 $1F $0F $E0 $EF $3F $1F $C0 $DF $7F $3F $80 $BF
; Tile index $11A
.db $7F $00 $80 $80 $FF $7F $00 $7F $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $11B
.db $FF $00 $00 $00 $FF $FE $00 $FE $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $11C
.db $00 $00 $FF $FF $00 $00 $FF $FF $01 $00 $FE $FE $03 $00 $FC $FC $03 $00 $FC $FD $03 $00 $FC $FD $03 $00 $FC $FC $01 $00 $FE $FE
; Tile index $11D
.db $00 $00 $FF $FF $00 $00 $FF $FF $FF $00 $00 $00 $00 $FF $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF
; Tile index $11E
.db $00 $00 $FF $FF $00 $00 $FF $FF $F8 $00 $07 $07 $04 $F8 $03 $FB $FA $04 $01 $FD $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE
; Tile index $11F
.db $00 $00 $FF $FF $00 $00 $FF $FF $1F $00 $E0 $E0 $20 $1F $C0 $DF $7F $00 $80 $BF $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F
; Tile index $120
.db $7F $3F $80 $BF $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F
; Tile index $121
.db $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $122
.db $0F $0F $FF $F0 $0F $0F $FF $F0 $07 $07 $FF $F8 $01 $01 $FF $FE $03 $03 $FF $FC $01 $01 $FF $FE $00 $00 $FF $FF $00 $00 $FF $FF
; Tile index $123
.db $FF $FF $FF $00 $FF $FF $FF $00 $FF $FB $FB $00 $FF $C2 $C2 $00 $C7 $87 $BF $00 $CF $81 $B1 $00 $DF $06 $26 $00 $9F $0E $6E $00
; Tile index $124
.db $FF $FF $FF $00 $FF $3F $3F $00 $3F $00 $C0 $00 $00 $00 $FF $00 $9F $00 $60 $00 $9F $1F $7F $00 $9F $1F $7F $00 $1F $07 $E7 $00
; Tile index $125
.db $FF $FF $FF $00 $FC $FC $FF $03 $FC $7C $7F $03 $FF $08 $08 $00 $08 $08 $FF $00 $FF $F8 $F8 $00 $FF $F8 $F8 $00 $FF $F8 $F8 $00
; Tile index $126
.db $01 $00 $FE $FE $01 $00 $FE $FE $01 $00 $FE $FE $FF $00 $00 $00 $01 $00 $FE $00 $19 $00 $E6 $00 $3F $00 $C0 $00 $3F $00 $C0 $00
; Tile index $127
.db $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF
; Tile index $128
.db $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE
; Tile index $129
.db $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F
; Tile index $12A
.db $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $3F $7F $3F $80 $BF $7F $3F $80 $9F $3F $1F $C0 $DF $3F $1F $C0 $C7
; Tile index $12B
.db $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $7F $FF $7F $00 $3F $FF $BF $00 $3F $7F $3F $80 $9F $7F $5F $80 $9F $3F $1F $C0 $C7
; Tile index $12C
.db $01 $00 $FE $FE $03 $00 $FC $FC $02 $00 $FD $FC $06 $00 $F9 $F8 $0C $00 $F3 $F0 $19 $00 $E6 $E0 $33 $00 $CC $C0 $67 $00 $98 $80
; Tile index $12D
.db $BF $1F $5F $00 $7F $1E $9E $00 $7E $06 $87 $00 $FE $06 $07 $00 $FE $0E $0F $00 $FE $06 $07 $00 $FC $00 $03 $00 $F9 $00 $06 $00
; Tile index $12E
.db $3F $0F $CF $00 $3F $0F $CF $00 $7F $0F $8F $00 $7F $1F $9F $00 $7F $1F $9F $00 $FF $1E $1E $00 $FF $3C $3C $00 $FF $3C $3C $00
; Tile index $12F
.db $FF $F8 $F8 $00 $FF $F0 $F0 $00 $FE $E0 $E1 $00 $FE $80 $81 $00 $FE $00 $01 $00 $FC $00 $03 $00 $F8 $00 $07 $00 $F8 $00 $07 $00
; Tile index $130
.db $3F $00 $C0 $00 $3F $00 $C0 $00 $3F $00 $C0 $00 $7F $00 $80 $00 $7F $00 $80 $00 $7F $00 $80 $00 $FF $00 $00 $00 $FF $00 $00 $00
; Tile index $131
.db $FE $00 $01 $00 $FE $00 $01 $00 $FE $00 $01 $00 $FE $00 $01 $00 $FC $00 $03 $00 $FC $00 $03 $00 $FC $00 $03 $00 $FC $00 $03 $00
; Tile index $132
.db $1F $07 $E0 $E7 $0F $07 $F0 $F1 $07 $01 $F8 $F8 $01 $00 $FE $FE $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF
; Tile index $133
.db $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $7F $FF $7F $00 $1F $7F $1F $80 $87 $1F $00 $E7 $E0 $0C $00 $F7 $F0 $0C $00 $F7 $F0
; Tile index $134
.db $00 $00 $FF $FF $00 $00 $FF $FF $01 $00 $FE $FE $03 $00 $FC $FC $06 $00 $F9 $F8 $07 $00 $F8 $F8 $07 $00 $F8 $F8 $03 $00 $FC $FC
; Tile index $135
.db $4F $00 $B0 $80 $CC $03 $33 $00 $98 $07 $67 $00 $30 $0F $CF $00 $30 $0F $CF $00 $E0 $1F $1F $00 $E0 $1F $1F $00 $C0 $3F $3F $00
; Tile index $136
.db $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $07 $F8 $F8 $00 $08 $F0 $F7 $00 $16 $E0 $E9 $00 $2E $C0 $D1 $00
; Tile index $137
.db $18 $E0 $E7 $00 $38 $C0 $C7 $00 $31 $C0 $CE $00 $71 $80 $8E $00 $71 $80 $8E $00 $63 $80 $9C $00 $62 $81 $9D $00 $62 $81 $9D $00
; Tile index $138
.db $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $3C $FF $00 $00 $00 $F8 $01 $06 $00 $C0 $09 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00
; Tile index $139
.db $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $3C
; Tile index $13A
.db $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FD $02 $00 $FE $FF $00 $00 $38
; Tile index $13B
.db $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $7F $FF $00 $00 $1C
; Tile index $13C
.db $1F $00 $E0 $E0 $3F $1F $C0 $DF $7F $3F $80 $BF $FF $7F $00 $7F $FF $7F $00 $7F $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $13D
.db $F8 $00 $07 $07 $FC $F0 $03 $F3 $FE $FC $01 $FD $FF $FE $00 $FE $FF $FE $00 $FE $FF $FE $00 $FE $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $13E
.db $FC $00 $07 $00 $FC $F0 $03 $F0 $FE $FC $01 $FC $FF $FE $00 $FE $FF $FE $00 $FE $FF $FE $00 $FE $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $13F
.db $1F $00 $E0 $00 $3F $1F $C0 $1F $7F $3F $80 $3F $FF $7F $00 $7F $FF $7F $00 $7F $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF
; Tile index $140
.db $80 $7F $7F $00 $80 $7F $7F $00 $80 $7F $7F $00 $80 $7F $7F $00 $80 $7F $7F $00 $80 $7F $7F $00 $80 $7F $7F $00 $80 $7F $7F $00
; Tile index $141
.db $2E $C0 $D1 $00 $2E $C0 $D1 $00 $20 $CE $D1 $00 $20 $C0 $DF $00 $2E $C0 $D1 $00 $2E $C0 $D1 $00 $2E $C0 $D1 $00 $20 $CE $D1 $00
; Tile index $142
.db $63 $80 $9C $00 $77 $80 $88 $00 $3D $C2 $C2 $00 $39 $C6 $C6 $00 $01 $FE $FE $00 $01 $FE $FE $00 $01 $FE $FE $00 $01 $FE $FE $00
; Tile index $143
.db $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00
; Tile index $144
.db $FF $00 $00 $3C $FF $00 $00 $00 $BC $43 $43 $00 $80 $7F $7F $00 $80 $7F $7F $00 $80 $7F $7F $00 $80 $7F $7F $00 $80 $7F $7F $00
; Tile index $145
.db $FF $00 $00 $3C $FF $00 $00 $00 $3C $C3 $C3 $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00
; Tile index $146
.db $FF $00 $00 $38 $FF $00 $00 $00 $39 $C6 $C6 $00 $01 $FE $FE $00 $01 $FE $FE $00 $01 $FE $FE $00 $01 $FE $FE $00 $01 $FE $FE $00
; Tile index $147
.db $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $7F $FF $7F $00 $1F $FD $1D $02 $00 $FC $00 $03 $00 $FA $00 $05 $00 $FF $00 $00 $00
; Tile index $148
.db $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FE $00 $F8 $BF $B8 $40 $00 $1F $00 $E0 $00 $2F $00 $D0 $00 $FF $00 $00 $00
; Tile index $149
.db $FF $00 $7F $00 $FF $00 $00 $00 $80 $7F $7F $00 $80 $7F $7F $00 $80 $7F $7F $00 $80 $7F $7F $00 $FF $00 $00 $00 $FF $00 $00 $00
; Tile index $14A
.db $E0 $00 $DF $00 $FF $00 $00 $00 $3F $C0 $C0 $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $FF $00 $00 $00 $FF $00 $00 $00
; Tile index $14B
.db $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $49 $36 $00 $80 $7F $00 $00 $FF $00 $00 $00 $FF $00 $FF $00 $FF $00 $00 $00
; Tile index $14C
.db $FF $00 $FF $00 $FF $00 $00 $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FF $00 $FF $00 $00 $00 $FF $00 $00 $00
; Tile index $14D
.db $00 $FF $00 $00 $00 $FF $00 $00 $F8 $FF $F8 $F8 $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $14E
.db $00 $FF $00 $00 $3C $FF $3C $3C $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $14F
.db $00 $FF $00 $00 $00 $FF $00 $00 $0F $FF $0F $0F $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $150
.db $00 $FF $00 $00 $86 $FF $86 $86 $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $151
.db $00 $FF $00 $00 $00 $FF $00 $00 $B8 $FF $B8 $B8 $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $152
.db $00 $FF $00 $00 $0C $FF $0C $0C $BF $FF $BF $BF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $153
.db $00 $FF $00 $00 $1C $FF $1C $1C $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $154
.db $00 $FF $00 $00 $9E $FF $9E $9E $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $155
.db $00 $FF $00 $00 $00 $FF $00 $00 $0F $FE $0E $0E $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $156
.db $00 $FF $00 $00 $9E $7F $1E $1E $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $157
.db $00 $FF $00 $00 $00 $FF $00 $00 $98 $FF $98 $98 $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $158
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $159
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $DF $DF $FF $FF $FF $FF $FF $FF $EF $EF $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $15A
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $7F $7F $FF $FF $FF $FF $FF $FF $EF $EF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $BF $BF $FF
; Tile index $15B
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $7F $7F $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $15C
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $DF $DF $FF $FF $FF $FF $FF $FF $6F $6F $FF $FF $FF $FF $FF $FF $FF $FF $FF
; Tile index $15D
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FE $FE $FF $FF $77 $77 $FF $FF $DB $DB $FF $FF $36 $36 $FF $FF $00 $00 $FF
; Tile index $15E
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $EF $EF $FF $FF $FB $FB $FF $FF $DE $DE $FF $FF $AB $AB $FF $FF $00 $00 $FF
; Tile index $15F
.db $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FF $FE $FE $FF $FF $77 $77 $FF $FF $5B $5B $FF $FF $36 $36 $FF $FF $00 $00 $FF

.ends