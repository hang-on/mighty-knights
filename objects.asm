.section "Actor library" free
  
  .struct actor
    y db
    x db
    size db
    layout dw  
  .endst

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



 
