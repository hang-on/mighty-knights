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
.include "objects.asm"
.include "object_tests.asm"        
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
  arthur_y_buffer dsb 9
  arthur_y db
  arthur_xc_buffer dsb 9*2
  arthur_x db

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
    ;

    ; Set globals y and x.
    ld a,100
    ld (arthur_y),a
    ld (arthur_x),a

    ld hl,arthur_standing_0_y_offsets
    ld de,arthur_y_buffer
    ld b,7
    -:
      ld a,(arthur_y)
      add a,(hl)
      inc hl
      ld (de),a
      inc de
    djnz -

    ld hl,arthur_standing_0_x_offsets_and_chars
    ld de,arthur_xc_buffer
    ld b,7
    -:
      ld a,(arthur_x)
      add a,(hl)
      ld (de),a
      inc de
      inc hl
      ld a,(hl)
      ld (de),a
      inc hl
      inc de
    djnz -

    ld bc,7
    ld de,SAT_Y_START
    ld hl,arthur_y_buffer
    call load_vram

    ld bc,14
    ld de,SAT_XC_START
    ld hl,arthur_xc_buffer
    call load_vram


    ei
    halt
    halt
    xor a
    ld (vblank_counter),a
    ;
    ld a,ENABLED
    call set_display

    ;call object_tests

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
    ;call load_sat
    ;
    ; -------------------------------------------------------------------------
    ; Begin general updating (UPDATE).
    call PSGFrame
    call PSGSFXFrame
    ;call refresh_sat_handler
    ;
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
  ;
  arthur_standing_0_tiles:
    .db $24 $18 $18 $00 $24 $18 $18 $00 $24 $18 $18 $00 $24 $18 $18 $00 $27 $18 $18 $00 $27 $18 $1B $00 $67 $18 $1B $00 $40 $3E $3C $01
    .db $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $E0 $00 $00 $00 $F0 $00 $C0 $00 $F0 $00 $E0 $00 $10 $00 $00 $E0
    .db $DE $18 $3F $18 $86 $00 $7F $00 $9A $18 $7F $18 $D9 $78 $5F $58 $E1 $3D $23 $21 $61 $03 $01 $1D $30 $01 $00 $0E $10 $00 $00 $0F
    .db $F0 $A0 $A0 $A0 $F0 $E0 $E0 $E0 $70 $60 $E0 $60 $30 $00 $C0 $00 $E0 $C0 $C0 $C0 $E0 $C0 $C0 $C0 $60 $80 $00 $00 $40 $00 $00 $80
    .db $10 $0F $00 $00 $10 $08 $00 $07 $30 $08 $08 $07 $27 $18 $18 $00 $65 $00 $18 $00 $CF $00 $30 $00 $FF $00 $00 $00 $7F $00 $00 $00
    .db $C0 $00 $00 $00 $60 $00 $00 $80 $30 $C0 $C0 $00 $10 $E0 $E0 $00 $98 $00 $60 $00 $CC $00 $30 $00 $FC $00 $00 $00 $F8 $00 $00 $00
    .db $00 $00 $00 $00 $18 $00 $00 $00 $24 $18 $18 $00 $24 $18 $18 $00 $24 $18 $18 $00 $24 $18 $18 $00 $24 $18 $18 $00 $24 $18 $18 $00
;
  arthur_standing_0_layout:
    .db 7               ; Number of sprites in metasprite.
    .db -24, -8, 1
    .db -24, 0, 2
    .db -16, -8, 3
    .db -16, 0, 4
    .db -8, -8, 5
    .db -8, 0, 6
    .db -32, -8, 7
  
  arthur_standing_0_y_offsets:
    .db -24, -24, -16, -16, -8, -8, -32
  arthur_standing_0_x_offsets_and_chars:
    .db -8, 1, 0, 2, -8, 3, 0, 4, -8, 5, 0, 6, -8, 7
  


  adventure_awaits:
    .incbin "adventure_awaits_compr.psg"
.ends