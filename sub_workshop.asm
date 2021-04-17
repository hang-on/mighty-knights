  .equ ACTOR_MAX 5 ;***
  
  .struct actor
    id db
    y db
    x db
    state db         ; A bitfield of tags for states
    hspeed db
    vspeed db
  .endst

; State format:
;  00000000
;  |||||||`- is_facing_left
;  ||||||`-- is_walking
;  |||||`--- is_jumping
;  ||||`---- is_hurting
;  |||`----- is_attacking
;  ||`------ is_killed
;  |`------- (reserved)
;  `-------- (reserved)

  .equ ACTOR_WALKING %00000010
  .equ ACTOR_FACING_LEFT %00000001


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

  .ramsection "Test kernel" slot 3
    ; For faking writes to vram.
    ; 7 bytes! - update RESET macro if this changes!
      test_kernel_source dw
      test_kernel_bank db
      test_kernel_destination dw
      test_kernel_bytes_written dw
  .ends

.macro RESET_TEST_KERNEL
  ld hl,test_kernel_source
  ld a,0
  .rept 7
    ld (hl),a
    inc hl
  .endr
.endm


.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------
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



  get_actor_state:
    ; IN: Actor in HL
    ; OUT: State byte in A.
    ld de,actor.state
    add hl,de
    ld a,(hl)
  ret

  set_actor_state:
    ; IN: Actor in HL
    ; A: Byte containing bits to be set
    ; OUT: A = updated states.
    ld de,actor.state
    add hl,de
    ld b,(hl)
    or b
    ld (hl),a
  ret

  reset_actor_state:
    ; IN: Actor in HL
    ; A: Byte containing bits to be reset
    ; OUT: A = updated states.
    ld b,%11111111
    xor b
    ld b,a
    ld de,actor.state
    add hl,de
    ld a,(hl)
    and b
    ld (hl),a
  ret

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

.ends

