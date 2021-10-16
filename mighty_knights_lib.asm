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
.macro SELECT_BANK_IN_REGISTER_A
; -----------------------------------------------------------------------------
  ; Select a bank for slot 2, - put value in register A.
  .ifdef USE_TEST_KERNEL
    ld (test_kernel_bank),a
  .else
    ld (SLOT_2_CONTROL),a
  .endif
.endm

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

  is_button_1_pressed:
    ld a,(input_ports)
    and %00010000
    ret nz            ; Return with carry flag reset
    scf
  ret                 ; Return with carry flag set.

  is_dpad_pressed:
    ld a,(input_ports)
    and %00001111   ; Isolate the dpad bits.
    cpl             ; Invert bits; now 1 = keypress!
    and %00001111   ; Get rid of garbage from cpl in last four bits.
    cp 0            ; Now, is any dpad key preseed?
    ret z           ; No, then return with carry flag reset (by the AND).
    scf             ; Yes, then set carry flag and...
  ret               ; Return with carry flag set.

  is_left_pressed:
    ld a,(input_ports)
    and %00000100
    ret nz          ; Return with carry flag reset
    scf
  ret               ; Return with carry flag set.

  is_right_pressed:
    ld a,(input_ports)
    and %00001000
    ret nz          ; Return with carry flag reset
    scf
  ret               ; Return with carry flag set.

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
    ; Entry: A = Bank
    ;        BC = Number of bytes to load
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
      ld (SLOT_2_CONTROL),a
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

  save_vcounter:
    ; Read the vcounter port and save it's value in a variable and in A.
    ; IN: HL = Pointer to variable in RAM.
    ; OUT: Value of vcounter port in A.
    in a,V_COUNTER_PORT
    ld (hl),a
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

.section "String to stack various stuff" free
  move_bytes_from_string_to_stack:
    ; HL = ptr to string
    ; A = size of string (bytes)
    ex de,hl
    ld hl,2 ; return address
    add hl,sp
    ex de,hl
    ld b,a
    -:
      ld a,(hl)
      ld (de),a
      inc hl
      inc de
    djnz -

  ret

  batch_offset_to_stack:
    ; Create a string on the stack by applying a string of offsets to a 
    ; fixed origin.
    ; A = origin
    ; HL = string length,string w. offsets
    ex de,hl
    ld hl,2 ; return address
    add hl,sp
    ex de,hl  ; now DE points to stack and HL points to parameter
    ;    
    ld c,a
    ld b,(hl)
    inc hl
    -:
      ld a,c
      add a,(hl)
      ld (de),a ;push on stack here...
      inc hl
      inc de
    djnz -
  ret

  batch_offset_to_DE:
    ; Create a string at DE by applying a string of offsets to a 
    ; fixed origin.
    ; A = origin
    ; HL = string length,string w. offsets
    ; DE = Destination in RAM.
    ld c,a
    ld b,(hl)
    inc hl
    -:
      ld a,c
      add a,(hl)
      ld (de),a 
      inc hl
      inc de
    djnz -
  ret

  batch_alternating_offset_and_copy_to_DE:
    ; Create a string at DE.
    ; A = origin to apply offset to.
    ; HL = number of pairs, string w. offsets and raw copy pairs
    ; DE = Destination in RAM.
    ld c,a
    ld b,(hl)
    inc hl
    -:
      ld a,c
      add a,(hl)
      ld (de),a 
      inc hl
      inc de
      ld a,(hl)
      ld (de),a
      inc hl
      inc de
    djnz -
  ret
.ends
       