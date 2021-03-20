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

  get_animation:
    ; IN: A = Index
    ; OUT: HL = pointer to animation item.
    .ifdef TEST_MODE
      ld hl,fake_animation_table
    .else
      ld hl,animation_table
    .endif
    cp 0
    ret z    
    ld b,a
    ld de,_sizeof_animation
    -:
      add hl,de
    djnz -
  ret

  set_animation:
    ; Index in animation table in A
    ; HL = pointer to datablock

    ;...
    ld de,animation_table ; fix me, correct offset
    ld bc,_sizeof_actor
    ldir
  ret

  draw_actor:
    ; HL = Pointer to actor struct
    ; FIXME - this will not work with reworked get/set anim.!!
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



 
