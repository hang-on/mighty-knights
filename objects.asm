.section "Actor library" free
  
  .struct actor
    y db
    x db
    size db
    layout dw  
    id db
  .endst

  .macro INITIALIZE_ACTOR
    ld hl,init_data_\@
    ld de,\1
    ld bc,6
    ldir
    jp +
      init_data_\@:
        .db \2 \3 \4 
        .dw \5
        .db \6
    +:
  .endm


  draw_actor:
    ; HL = Pointer to actor struct
    ld d,(hl)
    inc hl
    ld e,(hl)
    inc hl
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



 
