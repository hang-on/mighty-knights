  .equ ACTOR_MAX 5 ;***
  .equ VIDEO_JOB_MAX 10 ; amount of video jobs the table can hold 
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


.macro SELECT_BANK_IN_REGISTER_A
  ; Select a bank for slot 2, - put value in register A.
  .ifdef USE_TEST_KERNEL
    ld (test_kernel_bank),a
  .else
    ld (SLOT_2_CONTROL),a
  .endif
.endm

.struct animation ; placeholder p.t.
  current_frame db
  timer db
  script dw
.endst

; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------
  get_next_frame:
    ; HL: Animation struct
    ; return next frame in A
    ld a,(hl) ; current frame
    push af
    pop ix
    inc hl
    inc hl
    call get_word ; now HL points to te script
    ld a,(hl) ; get max frame
    ld b,a
    push ix
    pop af
    cp b
    jp nz,+
      ; if frame = max frame...
      jp ++
    +:
      inc a
    ++:
  ret
  
  .equ ANIM_TIMER_UP $ff
  tick_animation:
    ; Tick (decrement timer) animation in HL
    ; Return new timer value of $ff for time up!
    ; HL: Animation struct
    ld de,animation.timer
    add hl,de
    ld a,(hl)
    cp 0
    jp nz,+
      ld a,$ff
      jp ++
    +:
      dec a
    ++:
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
; Handling vram loading via a video job format
; -----------------------------------------------------------------------------
.struct video_job
  bank db
  source dw
  size dw
  destination dw
.endst
.ramsection "Video job RAM" slot 3
  video_jobs db
  video_job_table dsb 2*VIDEO_JOB_MAX ; up to 10 video jobs, ptrs to video jobs
.ends
.section "Video jobs" free
  initialize_video_job_table:
    ; Does not take any parameters
    xor a
    ld (video_jobs),a
  ret
  
  add_video_job:
    ; HL: Video job to add to table
    ld a,(video_jobs)
    cp VIDEO_JOB_MAX
    ret z                       ; Protect against overflow..
    ;
    ld b,l
    ld c,h
    push bc
      ld a,(video_jobs)
      ld hl,video_job_table
      call offset_word_table
    pop bc
    ld (hl),b
    inc hl
    ld (hl),c
    ;
    ld hl,video_jobs
    inc (hl)
  ret
  
  process_video_job_table:
    ; Does not take any parameters
    ld a,(video_jobs)
    cp 0
    ret z
    ld b,0
    ld c,a
    -:
        push bc
          ld a,b
          ld hl,video_job_table
          call offset_word_table
          call get_word
          call run_video_job
        pop bc
      inc b
      ld a,c
      cp b
    jp nz,-
    ;
    xor a
    ld (video_jobs),a
  ret

  run_video_job:
    ; HL: Pointer to video job to run.
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
.ends


; -----------------------------------------------------------------------------
; Drawing and animating actors
; -----------------------------------------------------------------------------
; FIXME: have a animation processing per frame - the anim controls
; the frames, not directly set (so chance init actor macro).

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


 
