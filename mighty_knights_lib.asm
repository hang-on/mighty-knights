; Mighty Knights Library
; 
; =============================================================================
; M A C R O S
; =============================================================================
; -----------------------------------------------------------------------------
.macro SELECT_EXTRAM
; -----------------------------------------------------------------------------
  ; Select external RAM: Now memory addresses from $8000 - $c000 (slot 2)
  ; are mapped to the battery-backed RAM, and thus its contents are saved
  ; between sessions.
  push af
  ld a,(BANK_CONTROL)
  or SET_EXTRAM_BIT
  ld (BANK_CONTROL),a
  pop af
.endm
; -----------------------------------------------------------------------------
.macro SELECT_ROM
; -----------------------------------------------------------------------------
  ; Select ROM: Used to switch mapping in slot 2 ($8000 - $c000) back to ROM
  ; if external RAM was selected.
  push af
  ld a,(BANK_CONTROL)
  and RESET_EXTRAM_BIT
  ld (BANK_CONTROL),a
  pop af
.endm
; -----------------------------------------------------------------------------
.macro SELECT_BANK
; -----------------------------------------------------------------------------
  ; Select a bank for slot 2, i.e. SELECT_BANK 4.
  push af
  ld a,\1
  ld (SLOT_2_CONTROL),a
  pop af
.endm
; -----------------------------------------------------------------------------
.macro SELECT_BANK_IN_REGISTER_A
; -----------------------------------------------------------------------------
  ; Select a bank for slot 2, - put value in register A.
  ld (SLOT_2_CONTROL),a
.endm
; -----------------------------------------------------------------------------
.macro SAVE_REGISTERS
; -----------------------------------------------------------------------------
  ; Save all registers, except IX and IY
  push af
  push bc
  push de
  push hl
  push ix
  push iy
.endm
; -----------------------------------------------------------------------------
.macro RESTORE_REGISTERS
; -----------------------------------------------------------------------------
  ; Restore all registers, except IX and IY
  pop iy
  pop ix
  pop hl
  pop de
  pop bc
  pop af
.endm
;
;
; -----------------------------------------------------------------------------
.section "start_sat_manager" free
; -----------------------------------------------------------------------------
  ; Entry: None
  ; Exit:
  ; Uses: A
start_sat_manager:
  xor a
  ld (NextFreeSprite),a
  ; Cancel sprite drawing from sprite 0.
  ld a,SPRITE_TERMINATOR
  ld (SpriteBufferY),a
  ; Toggle descending load mode on/off
  ld a,(SATLoadMode)
  cp DESCENDING
  jp z,+
    ld a,DESCENDING
    jp ++
  +:
    cpl
  ++:
  ld (SATLoadMode),a
  ld a,(SATLoadMode)
  cpl
  ld (SATLoadMode),a
  ;
  ld a,SPRITE_TERMINATOR
  ld (SpriteBufferY),a
  ;
ret
;
.ends
;
; -----------------------------------------------------------------------------
.section "bluelib_utilize vblank" free
; -----------------------------------------------------------------------------
  bluelib_utilize_vblank:
  ; Load the vram sat with the SatY and SatXC buffers.
  ; Sonic 2 inspired flicker engine is in place: Flicker sprites by loading the
  ; SAT in ascending/descending order every other frame.
  ld a,(SATLoadMode)
  cp DESCENDING
  jp z,_DescendingLoad
    ; If not descending, then fall through to ascending load mode.

    ; Load y-coordinates.
    ld hl,SAT_Y_START
    ld a,l
    out (CONTROL_PORT),a
    ld a,h
    or VRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
    ld hl,SpriteBufferY
    ld c,DATA_PORT
    .rept 64
      outi
    .endr
    ;
    ; Load x-coordinates and character codes.
    ld hl,SAT_XC_START
    ld a,l
    out (CONTROL_PORT),a
    ld a,h
    or VRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
    ld hl,SpriteBufferXC
    ld c,DATA_PORT
    .rept 128
      outi
    .endr
  jp update_sat_end
  ;
  _DescendingLoad:
    ; Load y-coordinates.
    ld hl,SAT_Y_START
    ld a,l
    out (CONTROL_PORT),a
    ld a,h
    or VRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
    ld c,DATA_PORT
    ld hl,SpriteBufferY
    .rept PLAYER_SIZE
      outi
    .endr
    ;
    ld hl,SpriteBufferY+63    ; Point to last y-value in buffer.
    .rept 64-PLAYER_SIZE
      outd                    ; Output and decrement HL, thus going
    .endr                     ; backwards (descending) through the buffer.
    ;
    ; Load x-coordinates and character codes
    ld hl,SAT_XC_START
    ld a,l
    out (CONTROL_PORT),a
    ld a,h
    or VRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
    ld c,DATA_PORT
    ld hl,SpriteBufferXC
    .rept PLAYER_SIZE
      outi
      outi
    .endr
    ;
    ld hl,SpriteBufferXC+126
    ld de,-4
    .rept 64-PLAYER_SIZE
      outi
      outi
      add hl,de
    .endr
  update_sat_end:
  ret
  ;
.ends

; -----------------------------------------------------------------------------
.section "load_cram" free
; -----------------------------------------------------------------------------
  ; Consecutively load a number of color values into color ram (CRAM), given a
  ; destination color to write the first value.
  ; Entry: A = Destination color in color ram (0-31)
  ;        B = Number of color values to load
  ;        HL = Base address of source data (color values are bytes = SMS)
  ; Uses: AF, BC, HL
  ; Assumes blanked display and interrupts off.
  load_cram:
    out (CONTROL_PORT),a
    ld a,CRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
    -:
      ld a,(hl)
      out (DATA_PORT),a
      inc hl
    djnz -
  ret
.ends

; -----------------------------------------------------------------------------
.section "load_vram" free
; -----------------------------------------------------------------------------
  ; Load a number of bytes from a source address into vram.
  ; Entry: BC = Number of bytes to load
  ;        DE = Destination address in vram
  ;        HL = Source address
  ; Exit:  DE = Next free byte in vram.
  ; Uses: AF, BC, DE, HL,
  load_vram:
    ld a,e
    out (CONTROL_PORT),a
    ld a,d
    or VRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
    -:
      ld a,(hl)
      out (DATA_PORT),a
      inc hl
      dec bc
      ld a,c
      or b
    jp nz,-
  ret
.ends

; -----------------------------------------------------------------------------
.section "Set register (vdp)" free
; -----------------------------------------------------------------------------
  ; Write to target register.
  ; Entry: A = byte to be loaded into vdp register.
  ;        B = target register 0-10.
  ; Uses: AF, B
  set_register:
    out (CONTROL_PORT),a
    ld a,REGISTER_WRITE_COMMAND
    or b
    out (CONTROL_PORT),a
  ret
.ends

; -----------------------------------------------------------------------------
.section "add_sprite" free
; -----------------------------------------------------------------------------
  ; Add a sprite of size = 1 character to the SAT.
  ; Entry: A = Character code.
  ;        B = vertical position, C = horizontal position.
  ; Exit:
  ; Uses: None - all registers saved
  add_sprite:
    ; Test for sprite overflow (more than 64 hardware sprites at once).
    SAVE_REGISTERS
    ld d,a                    ; Save the tile in unused register.
    ld a,(NextFreeSprite)
    inc a
    cp 65
    jp nc,exit_add_sprite
    ld a,d                    ; Restore tile in A.
    ;
    push af
    push bc
    ; Point DE to SpriteBufferY[NextFreeSprite].
    ld a,(NextFreeSprite)
    ld de,SpriteBufferY
    add a,e
    ld e,a
    ld a,0
    adc a,d
    ld d,a

    ; Retrieve Y and X coords.
    pop bc
    ld a,b
    ld (de),a               ; Write the Y to the sprite buffer.
    ; **
    inc de
    ld a,SPRITE_TERMINATOR
    ld (de),a
    ; **
    ;
    ; Point DE to SpriteBufferXC[NextFreeSprite].
    ld a,(NextFreeSprite)
    add a,a               ; Table elements are words!
    ld de,SpriteBufferXC
    add a,e
    ld e,a
    ld a,0
    adc a,d
    ld d,a
    ;
    ld a,c                ; Get the x-pos.
    ld (de),a             ; Write it to the buffer.
    inc de
    pop af                ; Retrieve the charcode.
    ld (de),a             ; Write it to the buffer

    ld hl,NextFreeSprite
    inc (hl)
    ;
    exit_add_sprite:
    RESTORE_REGISTERS
  ret

.ends
; -----------------------------------------------------------------------------
.section "clear_vram" free
; -----------------------------------------------------------------------------
  ; Write 00 to all vram addresses.
  ; Uses AF, BC
  clear_vram:
    xor a
    out (CONTROL_PORT),a
    or VRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
    ld bc,VRAM_SIZE
    -:
      xor a
      out (DATA_PORT),a
      dec bc
      ld a,b
      or c
    jp nz,-
  ret
.ends