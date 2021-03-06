; main.asm
;
.sdsctag 1.0, "Mighty Knights", "Hack n' slash", "hang-on Entertainment"
;
; -----------------------------------------------------------------------------
.include "sms_constants.asm"
; -----------------------------------------------------------------------------
; SOFTWARE DEFINITIONS
; -----------------------------------------------------------------------------
.equ TRUE $ff
.equ FALSE 0
.equ ENABLED $ff
.equ DISABLED 0
.equ FLAG_SET $ff
.equ FLAG_RESET $00
;
; -----------------------------------------------------------------------------
.memorymap
; -----------------------------------------------------------------------------
  defaultslot 0
  slotsize $4000
  slot 0 $0000
  slot 1 $4000
  slot 2 $8000
  slotsize $2000
  slot 3 RAM_START
.endme
.rombankmap ; 128K rom
  bankstotal 8
  banksize $4000
  banks 8
.endro
;        
; -----------------------------------------------------------------------------
.ramsection "main variables" slot 3
; -----------------------------------------------------------------------------
  temp_byte db                  ; Temporary variable - byte.
  temp_word db                  ; Temporary variable - word.
  ;
  VDPStatus db
  vblank_counter db
  hline_counter db
  pause_flag db
  ;
  demosprite_x db
  demosprite_y db
  demosprite_char db
.ends
;
.include "mighty_knights_lib.asm"
  .include "sprite_handler.asm"
;
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
  ;
  call clear_vram
  ;
  jp init
  ;
  initial_memory_control_register_values:
    .db $00,$00,$01,$02
  ;
.ends
;
.org $0038
; ---------------------------------------------------------------------------
.section "!VDP interrupt" force
; ---------------------------------------------------------------------------
  push af
  push hl
    in a,CONTROL_PORT
    bit INTERRUPT_TYPE_BIT,a
    jp z,+
      ; VBlank interrupt.
      ld hl,vblank_counter
      inc (hl)
      jp ++
    +:
      ; H-Line interrupt.
      ld hl,hline_counter
      inc (hl)
    ++:
  pop hl
  pop af
  ei
  reti
.ends
;
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
;
; -----------------------------------------------------------------------------
.section "main" free
; -----------------------------------------------------------------------------
  init:
    ; Run this function once (on game load). 
    ;
    ld a,0
    ld b,demo_palette_end-demo_palette
    ld hl,demo_palette
    call load_cram
    ;
    ld bc,CHARACTER_SIZE
    ld de,SPRITE_BANK_START + CHARACTER_SIZE
    ld hl,c_character
    call load_vram
    ;
    ld a,16
    ld (demosprite_y),a
    ld a,16
    ld (demosprite_x),a
    ld a,1
    ld (demosprite_char),a
    ;
    ei
    halt
    halt
    xor a
    ld (vblank_counter),a
    ;
    ld a,NORMAL_DISPLAY
    ld b,1
    call set_register
    ;
  jp main_loop
  ;
  ; ---------------------------------------------------------------------------
  main_loop:
    ;
    call wait_for_vblank
    ;
    ; -------------------------------------------------------------------------
    ; Begin vblank critical code (DRAW).
    call load_sat
    ;
    ; -------------------------------------------------------------------------
    ; Begin general updating (UPDATE).
    call refresh_sprite_handler
    ;
    ld a,(demosprite_x)
    ld c,a
    ld a,(demosprite_y)
    ld b,a
    ld a,(demosprite_char)
    call add_sprite
    ;
  jp main_loop
  ;
  ; ---------------------------------------------------------------------------
  ;
  ; ---------------------------------------------------------------------------
.ends
;
;
; Data.
.bank 1 slot 1
; -----------------------------------------------------------------------------
.section "Demo assets" free
; -----------------------------------------------------------------------------
  demo_palette:
    .db $00 $18 $12 $18 $06 $15 $2A $3F $13 $0B $0F $0C $38 $26 $27 $2F
    .db $00 $10 $12 $18 $06 $15 $2A $3F $13 $0B $0F $0C $38 $26 $27 $2F
    demo_palette_end:
  ;
  c_character:
    .db $ff $00 $ff $00
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $ff $00 $00
.ends
