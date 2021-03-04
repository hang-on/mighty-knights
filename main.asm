; main.asm
; Main code for testing/demoing bluelib
;
.sdsctag 1.0, "bluelib", "SMS/GG library", "hang-on Entertainment"
;
.include "bluelib.inc"        ; General library with foundation stuff.
;
.include "header.inc"         ; Constants and struct instantiations.
;
;
;
; -----------------------------------------------------------------------------
.section "main" free
; -----------------------------------------------------------------------------
  init:
    ; Run this function once (on game load). Assume we come here from bluelib
    ; boot code with initialized vram and memory control registers (INIT).
    ;
    ld a,COLOR_0
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
    ; Wait until vblank interrupt handler increments counter.
    ld hl,vblank_counter
    -:
      ld a,(hl)
      cp 0
    jp z,-
    ; Reset counter.
    xor a
    ld (hl),a
    ;
    ; -------------------------------------------------------------------------
    ; Begin vblank critical code (DRAW).
    call bluelib_utilize_vblank
    ;
    ; -------------------------------------------------------------------------
    ; Begin general updating (UPDATE).
    call bluelib_update_framework
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
