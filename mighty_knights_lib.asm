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
    ; Entry: D = Y origin.
    ;        E = X origin.
    ;        IX = Pointer to offset + tile block.
    ; Exit: None
    ; Uses: A, DE, HL, IX (Warning: Do not use B!, as it is used by 
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
    ld a,e                ; Get the x-pos.
    add a,(ix+1)             ; Write it to the buffer.
    ld (hl),a
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
; -----------------------------------------------------------------------------
; VDP Register Handler
; -----------------------------------------------------------------------------
  .equ MODE_0 0
  .equ MODE_1 1
  .equ BORDER_COLOR 7
  .equ HSCROLL 8
  .equ VSCROLL 9
  .equ LINE_INTERRUPT 10
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
.ramsection "VDP Register Variables" slot 3
; -----------------------------------------------------------------------------
  vdp_registers dsb 11
.ends
; -----------------------------------------------------------------------------
.section "VDP Register Handler" free
; -----------------------------------------------------------------------------
  initialize_vdp_registers:
    ; Load 11 bytes of init values into the 11 VDP registers and the RAM mirror.
    ; Entry: HL = Pointer to initialization data (11 bytes).
    ; Exit:  None
    ; Uses:  A, BC, DE, HL
    ld de,vdp_registers
    ld b,11
    ld c,0
    -:
      ld a,(hl)
      ld (de),a
      out (CONTROL_PORT),a
      ld a,REGISTER_WRITE_COMMAND
      or c
      out (CONTROL_PORT),a
      inc hl
      inc de
      inc c
    djnz -
  ret
  ;
  set_display:
    ; Use value passed in A to either set or reset the display bit of vdp
    ; register 1 mirror. Then load the whole mirror into the actual register.
    ; Entry: A = $ff = enable display, else disable display.
    ; Uses: A, B, HL 
    ld hl,vdp_registers+1
    cp $ff
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
  ;
  set_register:
    ; Write to target register and register mirror.
    ; Entry: A = byte to be loaded into vdp register.
    ;        B = target register 0-10.
    ; Uses: AF, B, DE, HL
    ld hl,vdp_registers
    ld d,0
    ld e,b
    add hl,de
    ld (hl),A
    out (CONTROL_PORT),a
    ld a,REGISTER_WRITE_COMMAND
    or b
    out (CONTROL_PORT),a
  ret
.ends
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
.section "Misc. routines sorted alphabetically" free
; -----------------------------------------------------------------------------
  clear_vram:
    ; Write 00 to all vram addresses.
    ; Uses AF, BC
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

  get_word:
    ; In: Pointer in HL. Out: Word pointed to in HL.
    ; Uses A, HL
    ld a,(hl)
    push af
      inc hl
      ld a,(hl)
      ld h,a    
    pop af  
    ld l,a
  ret


  load_cram:
    ; Consecutively load a number of color values into color ram (CRAM), given a
    ; destination color to write the first value.
    ; Entry: A = Destination color in color ram (0-31)
    ;        B = Number of color values to load
    ;        HL = Base address of source data (color values are bytes = SMS)
    ; Uses: AF, BC, HL
    ; Assumes blanked display and interrupts off.
    out (CONTROL_PORT),a
    ld a,CRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
    -:
      ld a,(hl)
      out (DATA_PORT),a
      inc hl
    djnz -
  ret

  load_vram:
    ; Load a number of bytes from a source address into vram.
    ; Entry: BC = Number of bytes to load
    ;        DE = Destination address in vram
    ;        HL = Source address
    ; Exit:  DE = Next free byte in vram.
    ; Uses: AF, BC, DE, HL,
    .ifdef USE_TEST_KERNEL
      push hl
      pop ix ; save HL
      ld hl,test_kernel_destination
      ld (hl),e
      inc hl
      ld (hl),d
      ld hl,test_kernel_bytes_written
      ld (hl),c
      inc hl
      ld (hl),b
      ld hl,test_kernel_source
      push ix
      pop de
      ld (hl),e
      inc hl
      ld (hl),d
    .else
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
    .endif
  ret


  offset_byte_table:
    ; Offset base address (in HL) of a table of bytes or words. 
    ; Entry: A  = Offset to apply.
    ;        HL = Pointer to table of values (bytes or words).  
    ; Exit:  HL = Offset table address.
    ; Uses:  A, HL
    add a,l
    ld l,a
    ld a,0
    adc a,h
    ld h,a
  ret
  

  offset_word_table:
    add a,a              
    add a,l
    ld l,a
    ld a,0
    adc a,h
    ld h,a
  ret

  offset_custom_table:
    ; IN: A = Table index, HL = Base address of table, 
    ;     B = Size of table item.
    ; OUT: HL = Address of item at specified index.
    cp 0
    ret z    
    ld d,0
    ld e,b
    ld b,a
    -:
      add hl,de
    djnz -

  ret


  setup_vram_write:
    ; HL = Address in vram
    ld a,l
    out (CONTROL_PORT),a
    ld a,h
    or VRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
  ret

  wait_for_vblank:
    ; Wait until vblank interrupt > 0.
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

       