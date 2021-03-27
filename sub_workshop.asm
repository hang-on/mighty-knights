  .equ ACTOR_MAX 5 ;***

  .struct actor
    id db
    y db
    x db
  .endst

  .struct frame
    size db
    layout dw
  .endst

  .macro INITIALIZE_ACTOR
    ld hl,init_data_\@
    ld de,\1
    ld bc,3
    ldir
    jp +
      init_data_\@:
        .db \2 \3 \4 
    +:
    ld a,\2
    ld hl,\5
    call set_frame

  .endm

  .ramsection "frame table" slot 3
    ; this table holds up to ACTOR MAX frame structs
    frame_table dsb _sizeof_frame*ACTOR_MAX
  .ends

; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
  
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


  get_frame:
    ; IN: A = Index
    ; OUT: HL = pointer to frame item.
    ld hl,frame_table
    ld b,_sizeof_frame
    call offset_custom_table
  ret

  set_frame:
    ; Copy an frame struct item into the table at index.
    ; IN: A = Index, HL = frame struct
    push hl
      ld hl,frame_table
      ld b,_sizeof_frame
      call offset_custom_table
      ex de,hl
    pop hl
    ld bc,_sizeof_frame
    ldir
  ret

  draw_actor:
    ; HL = Pointer to actor struct
    ld a,(hl) ; get id
    inc hl
    ld d,(hl)
    inc hl
    ld e,(hl)
    call get_frame
    ld b,(hl)
    inc hl
    call get_address
    push hl
    pop ix
    -:
      call add_sprite
      inc ix
      inc ix
      inc ix
    djnz -    
  ret

  draw_frame:
    ; Draw an frame frame (metasprite) to SAT buffer.
    ; IN: IX = actor, IY = frame
    ld a,(sat_buffer_index)  
    ld hl,sat_buffer_y
    call offset_byte_table
    ex de,hl
    ld a,(ix+1)
    ld l,(iy+0)
    ld h,(iy+1)
    call batch_offset_to_DE

    ld a,(sat_buffer_index)  
    ld hl,sat_buffer_xc
    call offset_word_table
    ex de,hl
    ld a,(ix+2)
    ld l,(iy+2)
    ld h,(iy+3)
    call batch_alternating_offset_and_copy_to_DE

    ld l,(iy+0)
    ld h,(iy+1)
    ld a,(hl)
    ld b,a
    ld a,(sat_buffer_index)
    add a,b
    ld (sat_buffer_index),a
    ret
.ends



 
