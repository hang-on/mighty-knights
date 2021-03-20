  
  .equ ACTOR_MAX 5 ;***

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
  .endst

  .ramsection "Animation table" slot 3
    ; this table holds up to ACTOR MAX active animations
    animation_table dsb _sizeof_animation*ACTOR_MAX
  .ends


.section "Actor library" free

  get_animation:
    ; Index in animation table in A
    ; HL = pointer to datablock
    cp 0
    jp nz,exit_with_failure ; should jump to correct offset in table
    ld hl,animation_table
  ret

  set_animation:
    ; Index in animation table in A
    ; HL = pointer to datablock
    cp 0
    jp nz,exit_with_failure ; should jump to correct offset in table

    ;...
    ld de,animation_table ; fix me, correct offset
    ld bc,_sizeof_actor
    ldir
  ret


  .macro INITIALIZE_ACTOR
    ld hl,init_data_\@
    ld de,\1
    ld bc,3
    ldir
    jp +
      init_data_\@:
        .db \2 \3 \4 
    +:
  .endm


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



 
