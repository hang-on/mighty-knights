; Mighty Knights Library
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
; SAT Handler
; -----------------------------------------------------------------------------
; Definitions:
.equ PRIORITY_SPRITES 4          ; Number of tiles not part of asc/desc flicker.
.equ ASCENDING 0
.equ DESCENDING $ff
; -----------------------------------------------------------------------------
.ramsection "SAT Handler Variables" slot 3
; -----------------------------------------------------------------------------
  sat_buffer_y dsb 64
  sat_buffer_xc dsb 128
  sat_buffer_index db
  load_mode db             ; Ascending or descending - for flickering.
.ends
; -----------------------------------------------------------------------------
.section "SAT Handler" free
; -----------------------------------------------------------------------------   
  add_sprite:
    ; Add a sprite of size = 1 character to the SAT.
    ; Entry: A = Character code.
    ;        B = vertical position, C = horizontal position.
    ; Exit:
    ; Uses: None - all registers saved
    ;
    ; Test for sprite overflow (more than 64 hardware sprites at once).
    SAVE_REGISTERS
    ld d,a                    ; Save the tile in unused register.
    ld a,(sat_buffer_index)
    inc a
    cp 65
    jp nc,exit_add_sprite
    ld a,d                    ; Restore tile in A.
    ;
    push af
    push bc
    ; Point DE to sat_buffer_y[sat_buffer_index].
    ld a,(sat_buffer_index)
    ld de,sat_buffer_y
    add a,e
    ld e,a
    ld a,0
    adc a,d
    ld d,a
    ;
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
    ; Point DE to sat_buffer_xc[sat_buffer_index].
    ld a,(sat_buffer_index)
    add a,a               ; Table elements are words!
    ld de,sat_buffer_xc
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
    ;
    ld hl,sat_buffer_index
    inc (hl)
    ;
    exit_add_sprite:
    RESTORE_REGISTERS
  ret
  ;
  load_sat:
    ; Load the vram sat with the SatY and SatXC buffers.
    ; Sonic 2 inspired flicker engine is in place: Flicker sprites by loading the
    ; SAT in ascending/descending order every other frame.
    ld a,(load_mode)
    cp DESCENDING
    jp z,_descending_load
      ; If not descending, then fall through to ascending load mode.
      ;
      ; Load y-coordinates.
      ld hl,SAT_Y_START
      ld a,l
      out (CONTROL_PORT),a
      ld a,h
      or VRAM_WRITE_COMMAND
      out (CONTROL_PORT),a
      ld hl,sat_buffer_y
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
      ld hl,sat_buffer_xc
      ld c,DATA_PORT
      .rept 128
        outi
      .endr
  ret
    ;
    _descending_load:
      ; Load y-coordinates.
      ld hl,SAT_Y_START
      ld a,l
      out (CONTROL_PORT),a
      ld a,h
      or VRAM_WRITE_COMMAND
      out (CONTROL_PORT),a
      ld c,DATA_PORT
      ld hl,sat_buffer_y
      .rept PRIORITY_SPRITES
        outi
      .endr
      ;
      ld hl,sat_buffer_y+63    ; Point to last y-value in buffer.
      .rept 64-PRIORITY_SPRITES
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
      ld hl,sat_buffer_xc
      .rept PRIORITY_SPRITES
        outi
        outi
      .endr
      ;
      ld hl,sat_buffer_xc+126
      ld de,-4
      .rept 64-PRIORITY_SPRITES
        outi
        outi
        add hl,de
      .endr
  ret
  ;
  refresh_sat_handler:
    ; Clear buffer index and toggle load mode.
    ; Entry: None
    ; Exit:
    ; Uses: A
    xor a
    ld (sat_buffer_index),a
    ; Cancel sprite drawing from sprite 0.
    ld a,SPRITE_TERMINATOR
    ld (sat_buffer_y),a
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
    ld a,SPRITE_TERMINATOR
    ld (sat_buffer_y),a
    ;
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
.section "set_display" free
; -----------------------------------------------------------------------------
  set_display:
    ; Use value passed in A to either set or reset the display bit of vdp
    ; register 1 mirror. Then load the whole mirror into the actual register.
    ; Entry: A = ENABLED/DISABLED (assuming these constants are defined).
    ; Assumes the presence of variable: vpd_register_1.
    ld hl,vdp_register_1
    cp ENABLED
    jp z,+
      res 6,(hl)
      jp ++
    +:
      set 6,(hl)
    ++:
    ld a,(hl)
    ld b,1
    call set_register
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
.section "wait_for_vblank" free
; -----------------------------------------------------------------------------
  ; Wait until vblank interrupt > 0.
  wait_for_vblank:
    ld hl,vblank_counter
    -:
      ld a,(hl)
      cp 0
    jp z,-
    ; Reset counter.
    xor a
    ld (hl),a
  ret
.ends
;

