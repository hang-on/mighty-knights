  .equ ACTOR_MAX 5 ;***

  .struct actor
    id db
    y db
    x db
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
  .ramsection "Test kernel" slot 3
    ; For faking writes to vram.
    test_kernel_source dw
    test_kernel_bank db
    test_kernel_destination dw
    test_kernel_bytes_written dw
  .ends



.macro SELECT_BANK_IN_REGISTER_A
  ; Select a bank for slot 2, - put value in register A.
  .ifdef USE_TEST_KERNEL
    ld (test_kernel_bank),a
  .else
    ld (SLOT_2_CONTROL),a
  .endif
.endm


; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------

  run_video_job:
    ; HL points to video job
    push hl
    pop ix
    ld a,(ix+0)
    SELECT_BANK_IN_REGISTER_A
    ld l,(ix+1)
    ld h,(ix+2)
    ld c,(ix+3)
    ld b,(ix+4)
    ld e,(ix+5)
    ld d,(ix+6)
    call load_vram
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

; -----------------------------------------------------------------------------
; Drawing and animating actors
; -----------------------------------------------------------------------------
; FIXME: have a animation processing per frame - the anim controls
; the frames, not directly set (so chance init actor macro).
.struct animation ; placeholder p.t.
  current_frame db
  timer db
  frames_total db
  looping db
  script dw
.endst
.struct frame
  size db
  layout dw ; FIXME: Add a ptr to tiles?
.endst
.ramsection "Animation control tables" slot 3
  animation_table dsb _sizeof_animation*ACTOR_MAX
  frame_table dsb _sizeof_frame*ACTOR_MAX
.ends
.section "Drawing and animating actors" free
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
    ; Put the current frame of a given actor into the SAT buffer. 
    ; HL = Pointer to actor struct
    ld a,(hl) ; get id
    inc hl
    ld d,(hl)
    inc hl
    ld e,(hl)
    call get_frame
    ld b,(hl)
    inc hl
    call get_word
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


 
