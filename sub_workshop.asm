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

.struct animation
  ; Keeps track of current frame and the timer that counts down to
  ; when the current frame expires. Also points to the script that
  ; maps the frames and durations in the animation. 
  current_frame db
  timer db
  script dw
.endst
  ; Example_anim_script of a two-frame walking animation.
  ; my_anim_script:
  ;  .db 1                       ; Max frame (= 2 frames in total, 0-2)
  ;  .db TRUE                    ; Loop when last frame expires?
  ;  .db 10,                     ; Ticks to display frame.
  ;  .dw cody_walking_0          ; Frame.
  ;  .db 10                      ; etc...
  ;  .dw cody_walking_2

.struct frame
  ; Referenced by draw_actor, it controls how the current frame is manifested
  ; as offset y, x and char data, in the SAT buffer each frame.
  size db                       ; Amount of tiles / chars.
  layout dw                     ; Map with y,x-offsets and chars.
.endst
  ; Example frame struct and layout.
  ; .dstruct cody_walking_0 frame 4,layout_2x2
  ;  layout_2x2:
  ;  .db -32, -8, 1
  ;  .db -32, 0, 2
  ;  .db -24, -8, 3
  ;  .db -24, 0, 4

.struct frame_video_job
  ; For each frame in current animation, a three-byte entry. Can be used when
  ; a new frame is set, to load new tiles during the next vblank.
  perform_video_job db          ; TRUE or FALSE.
  video_job dw                  ; If TRUE, then add the job pointed to here.
.endst

.ramsection "Animation control matrix" slot 3
  ; Animation, frame and video jobs are rows indexed by columns of actor index.
  animation_table_index db
  animation_table dsb _sizeof_animation*ACTOR_MAX
  frame_table dsb _sizeof_frame*ACTOR_MAX
  frame_video_job_table dsb _sizeof_frame_video_job*ACTOR_MAX
.ends
; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------
  init_animation_table:
    xor a
    ld (animation_table_index),a
  ret

  get_animation_table_index:
    ld a,(animation_table_index)
  ret

  set_animation:
    ; IN: A = Animation table index.
    ;     HL = Pointer to animation struct.
    ; TODO: Test to see if limit reached, then abort!
    ex de,hl
    ld b,_sizeof_animation
    ld hl,animation_table
    call offset_custom_table
    ex de,hl
    ld bc,_sizeof_animation
    ldir
    ld hl,get_animation_table_index
    inc (hl)
  ret

  get_frame_video_job:
    ; Given a frame video job list and a frame number, get the information
    ; regarding video job for this frame
    ; IN: HL = Pointer to frame video job list
    ;     A = frame number
    ; OUT: A = Video job TRUE / FALSE, HL = Video job or undefined
    ld b,_sizeof_frame_video_job
    call offset_custom_table
    ld a,(HL)
    push af ; preserve the TRUE/FALSE
      inc hl
      call get_word
    pop af
  ret
  
  get_ticks_and_frame_pointer:
  ; Use the current_frame property of a given animation struct to look up
  ; it's associated script and return the scripted ticks and pointer to 
  ; frame struct. Used when setting new frame.
  ; IN: HL = Animation struct.
  ; OUT: A = Tick, HL = Pointer to frame.
    ld a,(hl)                   ; Get current frame from anim. struct.
    ld c,a                      ; Save it in c.
    inc hl                      ; Forward to pointer to script.
    inc hl                      ; ...
    call get_word               ; Load script pointer into HL.
    inc hl                      ; Forward past the script header.
    inc hl                      ; ...
    ld a,c                      ; Retrieve current frame. 
    ld b,3                      ; This script section consists of 3 byte items.
    call offset_custom_table    ; Offset to script item for current frame.
    ld a,(hl)                   ; Read ticks into A.
    inc hl                      ; Foward to frame pointer.
    ld b,a                      ; Save the ticks in B.
    call get_word               ; Load script pointer into HL.
    ld a,b                      ; Return ticks to A.
  ret

  get_next_frame:
    ; Use the current frame and script of with a given animation to determine
    ; the next frame of that animation. 
    ; IN: HL = Animation struct
    ; OUT: A = next frame index.
    ld a,(hl)             ; Get current frame as per animation struct.
    push af               ; Save it in ix.
    pop ix
    inc hl                ; Forward HL past the animation timer to the script.
    inc hl                ; HL now points to the animation script item.
    call get_word         ; Make HL point to the actual script.
    ld a,(hl)             ; Get max frame from script.
    ld b,a                ; Save it in b.
    push ix               ; Retrieve current frame from ix. 
    pop af
    cp b                  ; Is current frame == max frame?
    jp z,+                ; Yes? - Jump forward to handle loop or still.
      inc a               ; No? - Just increment the frame counter.
      ret                 ; And return.
    +:               
      ; This is last (max) frame, what to do...?
      inc hl              ; Point HL to looping (true/false).
      ld a,(hl)           ; Get loop state.
      cp TRUE             ; Should we loop back to frame 0?
      jp z, +
        ld a,b            ; No - set the current frame as the next frame.
        ret               ; This keeps the animation still at the last frame.
      +:
        xor a             ; Yes - loop back to frame 0.
        ret               ; And return.
  
  .equ ANIM_TIMER_UP $ff
  tick_animation:
    ; Tick (decrement timer) of a given animation.
    ; IN: HL = Pointer to animation table item.
    ; OUT: A = New timer value or $ff for time up!
    ld de,animation.timer   ; Offset HL to animation timer.
    add hl,de               ;
    ld a,(hl)               ; Get current timer value.
    cp 0                    ; Is it 0?
    jp nz,+                 
      ld a,$ff              ; Timer is expired. Return special value.
      ret                   ; And return.
    +:
      dec a                 ; Timer not expired. Just decrement it.
  ret                       ; And return.


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


 
