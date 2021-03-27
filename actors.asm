  .equ ACTOR_MAX 5 ;***
  
  .struct frame
    size db
    layout dw
  .endst



  .struct actor
    id db
    y db
    x db
  .endst

  .struct animation
    size db
    layout dw
    frame db    
    timer db
    script dw
    tiles dw
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
    call set_animation

  .endm


  .ramsection "Animation table" slot 3
    ; this table holds up to ACTOR MAX animation structs
    animation_table dsb _sizeof_animation*ACTOR_MAX
  .ends


.section "Actor library" free
  
  my_sub:
    ld hl,2
    add hl,sp
    ld a,(hl)
    inc hl
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ; results , 2 bytes
    ld a,$12
    ld (hl),a
    inc hl
    ld a,$34
    ld (hl),a
    inc hl
  ret

  my_sub_gets_hl:
    ex de,hl
    ld hl,2
    add hl,sp
    ; results
    ld a,(de)
    ld (hl),a
    inc de
    inc hl
    ld a,(de)
    ld (hl),a
    inc de
    inc hl
  ret

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


  batch_offset: ; misleading name right now, not batching
    ; hl points to data: count, origin, offsets..., destination? (word)
    ; should reorganize data format, header, then data...
    ld b,(hl)
    inc hl
    ld c,(hl)
    inc hl
    -:
      ld a,c
      add a,(hl)
      ; put this byte on the stack..
      inc hl
    djnz -
  ret

  get_sprite:
    ; A = index of sprite in layout
    ; HL = ptr to frame
    push af
      inc hl ; go past size
      call get_address
    pop af
    ld b,3
    call offset_custom_table

  ret

  get_animation:
    ; IN: A = Index
    ; OUT: HL = pointer to animation item.
    ld hl,animation_table
    ld b,_sizeof_animation
    call offset_custom_table
  ret

  set_animation:
    ; Copy an animation struct item into the table at index.
    ; IN: A = Index, HL = animation struct
    
    push hl
      ld hl,animation_table
      ld b,_sizeof_animation
      call offset_custom_table
      ex de,hl
    pop hl
    ld bc,_sizeof_animation
    ldir
  ret

  draw_actor:
    ; HL = Pointer to actor struct
    ld a,(hl) ; get id
    inc hl
    ld d,(hl)
    inc hl
    ld e,(hl)
    call get_animation
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


.ends



 
