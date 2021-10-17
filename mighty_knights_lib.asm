; Mighty Knights Library


; -----------------------------------------------------------------------------
.section "Misc. routines sorted alphabetically" free
; -----------------------------------------------------------------------------


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
       