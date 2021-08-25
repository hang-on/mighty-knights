; Actors library
  .equ ACTOR_MAX 5 ;***
  
  .struct actor
    id db
    y db
    x db
    reserved_byte db         ; 
    hspeed db
    vspeed db
    ; states
    face db                   ; Left or right
    legs db                   ; standing, walking, jumping
    weapon db                 ; idle, slash (comboing?)
    form db                   ; OK, hurting, dead (+ maybe immortal)
    reserved_state db
    ; misc
    health db
    attack_damage db
    reserved_misc db
  .endst

  .macro INITIALIZE_ACTOR
    ld hl,init_data_\@
    ld de,\1
    ld bc,6
    ldir
    jp +
      init_data_\@:
        .db \2 \3 \4 0 0 0
    +:
  .endm

.bank 0 slot 0
.section "Actors: Subroutines" free 

  draw_actor:
    ; An actor can take different forms depending on which animation it is
    ; linked with. This is set (and thus can vary) on a frame-by-frame basis.
    ; draw_actor uses "add_sprite" to move sprites into the SAT buffer.
    ; IN: A  = Animation slot to use for drawing.
    ;     HL = Actor.
    inc hl                ; Move past index.
    ld d,(hl)             ; Get actor origin Y into D. 
    inc hl
    ld e,(hl)             ; Get actor origin X into D.
    call get_layout       ; Sets A (first char), B (num. chars) and HL (label).
    push hl               ; Add sprite needs the offset data in IX.
    pop ix
    ld c,a                ; Save index of first char.
    -:
      call add_sprite     ; This does not alter B and C! 
      inc c               ; Next char
      inc ix              ; Next y,x-offset pair.
      inc ix
    djnz -                ; Loop through all chars in frame.
  ret
  
  move_actor:
    ; IN: Actor in HL
    push hl
    pop ix
    ld a,(ix+actor.hspeed)
    add a,(ix+actor.x)
    ld (ix+actor.x),a
    ld a,(ix+actor.vspeed)
    add a,(ix+actor.y)
    ld (ix+actor.y),a
  ret

  set_actor_hspeed:
    ; IN: Actor in HL
    ld de,actor.hspeed
    add hl,de
    ld (hl),a
  ret




.ends