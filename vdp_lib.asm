; VDP lib.
; Generic, low level VDP routines.
;
; Contents:
; * SAT handler

; -----------------------------------------------------------------------------
; SAT Handler
; -----------------------------------------------------------------------------
.equ PRIORITY_SPRITES 6         ; Number of tiles not part of asc/desc flicker.
.equ ASCENDING 0
.equ DESCENDING $ff
.equ SAT_Y_SIZE HARDWARE_SPRITES
.equ SAT_XC_SIZE HARDWARE_SPRITES*2
; -----------------------------------------------------------------------------
.ramsection "SAT Handler Variables" slot 3
; -----------------------------------------------------------------------------
  sat_buffer_y dsb HARDWARE_SPRITES
  sat_buffer_xc dsb HARDWARE_SPRITES*2
  sat_buffer_index db
  load_mode db             ; Ascending or descending - for flickering.
.ends
; -----------------------------------------------------------------------------
.section "SAT Handler" free
; -----------------------------------------------------------------------------   
  add_sprite:
    ; Add a sprite of size = 1 character to the SAT.
    ; Entry: C = Char.
    ;        D = Y origin.
    ;        E = X origin.
    ;        IX = Pointer to offset pair Y,X
    ; Exit: None
    ; Uses: A, DE, HL, IX (Warning: Do not use B or C, as it is used by 
    ; add_meta_sprite).
    ;
    ; Test for sprite overflow (more than 64 hardware sprites at once).
    ld a,(sat_buffer_index)
    cp HARDWARE_SPRITES
    jp nc,exit_add_sprite
    ;
    ; Point DE to sat_buffer_y[sat_buffer_index].
    ld hl,sat_buffer_y
    call offset_byte_table
    ;
    ld a,d
    add a,(ix+0)
    ld (hl),a          
    ;
    ; Point DE to sat_buffer_xc[sat_buffer_index].
    ld a,(sat_buffer_index)
    ld hl,sat_buffer_xc
    call offset_word_table
    ;
    ld a,e                  ; Get the x-pos.
    add a,(ix+1)            ; Write it to the buffer.
    ld (hl),a
    inc hl
    ld (hl),c             ; Write the char (it should still be there)
    ;
    ld hl,sat_buffer_index
    inc (hl)
    ;
    exit_add_sprite:
  ret
  ;
  load_sat:
    ; Load the vram sat with the SatY and SatXC buffers.
    ; Sonic 2 inspired flicker engine is in place: Flicker sprites by loading the
    ; SAT in ascending/descending order every other frame.
    ;
    ld hl,SAT_Y_START           ; Load the sprite Y-positions into the SAT.
    call setup_vram_write
    ld hl,sat_buffer_y
    ld c,DATA_PORT
    ;
    ld a,(load_mode)
    cp DESCENDING
    jp z,+
      .rept SAT_Y_SIZE
        outi
      .endr
      jp ++
    +:
      .rept PRIORITY_SPRITES
        outi
      .endr
      ld hl,sat_buffer_y+SAT_Y_SIZE-1  ; Point to last y-value in buffer.
      .rept HARDWARE_SPRITES-PRIORITY_SPRITES
        outd                    ; Output and decrement HL, thus going
      .endr                     ; backwards (descending) through the buffer.
    ++:
    ;                           
    ld hl,SAT_XC_START          ; Load the X-position and character code pairs
    call setup_vram_write       ; of the sprites into the SAT.
    ld hl,sat_buffer_xc
    ld c,DATA_PORT
    ;
    ld a,(load_mode)
    cp DESCENDING
    jp z,+
      .rept SAT_XC_SIZE
        outi
      .endr
      jp ++
    +:
      .rept PRIORITY_SPRITES
        outi
        outi
      .endr
      ;
      ld hl,sat_buffer_xc+SAT_XC_SIZE-2
      ld de,-4
      .rept HARDWARE_SPRITES-PRIORITY_SPRITES
        outi
        outi
        add hl,de
      .endr
    ++:
    ld a,(load_mode)
    cpl
    ld (load_mode),a
  ret
  ;
  refresh_sat_handler:
    ; Clear SAT buffer (Y), buffer index and toggle load mode.
    ; Entry: None
    ; Exit:
    ; Uses: A
    xor a
    ld (sat_buffer_index),a
    ; Toggle descending load mode on/off
    ld a,(load_mode)
    cp DESCENDING
    jp z,+
      ld a,DESCENDING
      jp ++
    +:
      cpl
    ++:
    ld (load_mode),a
    ld a,(load_mode)
    cpl
    ld (load_mode),a
    ;
    ld hl,clean_buffer
    ld de,sat_buffer_y
    ld bc,HARDWARE_SPRITES
    ldir
    ;
  ret
  clean_buffer:                       ; Data for a clean sat Y buffer.
    .rept HARDWARE_SPRITES
      .db 192
    .endr
.ends
