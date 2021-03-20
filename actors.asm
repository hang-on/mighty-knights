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
    ; IN: A = Index, HL = animation struct
    ; FIXME - test this
    ; FIXE: Use offset table routine and test that
    ; FIXE: Make assert_HL_equals..
    push hl
      ld hl,animation_table
      cp 0
      jp z,+    
        ld b,a
        ld de,_sizeof_animation
        -:
          add hl,de
        djnz -
      +:
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



 
