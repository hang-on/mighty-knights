; Mighty Knights Library

; -----------------------------------------------------------------------------
.macro FILL_MEMORY args value
; -----------------------------------------------------------------------------
;  Fills work RAM ($C001 to $DFF0) with the specified value.
  ld    hl, $C001
  ld    de, $C002
  ld    bc, $1FEE
  ld    (hl), value
  ldir
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
.equ PRIORITY_SPRITES 1         ; Number of tiles not part of asc/desc flicker.
.equ ASCENDING 0
.equ DESCENDING $ff
; -----------------------------------------------------------------------------
.ramsection "SAT Handler Variables" slot 3
; -----------------------------------------------------------------------------
  sat_buffer_y dsb HARDWARE_SPRITE_MAX
  sat_buffer_xc dsb HARDWARE_SPRITE_MAX*2
  sat_buffer_index db
  load_mode db             ; Ascending or descending - for flickering.
.ends
; -----------------------------------------------------------------------------
.section "SAT Handler" free
; -----------------------------------------------------------------------------   
  add_sprite:
    ; Add a sprite of size = 1 character to the SAT.
    ; Entry: IX = Pointer to 3 bytes: Y X C
    ; Exit: None
    ; Uses: A, HL, IX.
    ;
    ; Test for sprite overflow (more than 64 hardware sprites at once).
    ld a,(sat_buffer_index)
    cp HARDWARE_SPRITE_MAX
    jp nc,exit_add_sprite
    ;
    ; Point DE to sat_buffer_y[sat_buffer_index].
    ld hl,sat_buffer_y
    call offset_byte_table
    ;
    ; Retrieve Y and X coords.
    ld a,(ix+0)
    ld (hl),a               ; Write the Y to the sprite buffer.
   ; inc hl
   ; ld a,SPRITE_TERMINATOR
   ; ld (hl),a
    ;
    ; Point DE to sat_buffer_xc[sat_buffer_index].
    ld a,(sat_buffer_index)
    ld hl,sat_buffer_xc
    call offset_word_table
    ;
    ld a,(ix+1)                ; Get the x-pos.
    ld (hl),a             ; Write it to the buffer.
    ld a,(ix+2)
    inc hl
    ld (hl),a             ; Write it to the buffer
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
      .rept HARDWARE_SPRITE_MAX
        outi
      .endr
      jp ++
    +:
      .rept PRIORITY_SPRITES
        outi
      .endr
      ld hl,sat_buffer_y+HARDWARE_SPRITE_MAX-1  ; Point to last y-value in buffer.
      .rept HARDWARE_SPRITE_MAX-PRIORITY_SPRITES
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
      .rept 128
        outi
      .endr
      jp ++
    +:
      .rept PRIORITY_SPRITES
        outi
        outi
      .endr
      ;
      ld hl,sat_buffer_xc+126
      ld de,-4
      .rept HARDWARE_SPRITE_MAX-PRIORITY_SPRITES
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
    ld bc,HARDWARE_SPRITE_MAX
    ldir
    ;
  ret
  clean_buffer:                       ; Data for a clean sat Y buffer.
    .rept HARDWARE_SPRITE_MAX
      .db $00
    .endr
.ends
; -----------------------------------------------------------------------------
; Misc. routines sorted alphabetically
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
.section "Offset table" free
; -----------------------------------------------------------------------------
  ; Offset base address (in HL) of a table of bytes or words. 
  ; Entry: A  = Offset to apply.
  ;        HL = Pointer to table of values (bytes or words).  
  ; Exit:  HL = Offset table address.
  ; Uses:  A, HL
  offset_byte_table:
    add a,l
    ld l,a
    ld a,0
    adc a,h
    ld h,a
  ret
  ;
  offset_word_table:
    add a,a              
    add a,l
    ld l,a
    ld a,0
    adc a,h
    ld h,a
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
.section "Setup for VRAM Write Operation" free
; -----------------------------------------------------------------------------
  ; hl = address in vram
  setup_vram_write:
    ld a,l
    out (CONTROL_PORT),a
    ld a,h
    or VRAM_WRITE_COMMAND
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

