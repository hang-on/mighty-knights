

.macro ASSERT_A_EQUALS
  cp \1
  jp nz,exit_with_failure
  nop
.endm

.macro ASSERT_A_EQUALS_NOT
  cp \1
  jp z,exit_with_failure
  nop
.endm

.macro ASSERT_HL_EQUALS ; (value)
  push de
  push af
  ld de,\1
  ld a,d
  cp h
  jp nz,exit_with_failure
  ld a,e
  cp l
  jp nz,exit_with_failure
  pop af
  pop de
.endm

.macro ASSERT_TOP_OF_STACK_EQUALS ; (list of bytes to test)
  ld hl,0
  add hl,sp
  .rept NARGS
    ld a,(hl)
    cp \1
    jp nz,exit_with_failure
    inc hl
    ;inc sp                    ; clean stack as we proceed.
    .SHIFT
  .endr
.endm

.macro ASSERT_TOP_OF_STACK_EQUALS_STRING ARGS LEN, STRING
  ; Parameters: Pointer to string, string length. 
  ld de,STRING                ; Comparison string in DE
  ld hl,0                     ; HL points to top of stack.
  add hl,sp       
  .rept LEN                   ; Loop through given number of bytes.
    ld a,(hl)                 ; Get byte from stack.
    ld b,a                    ; Store it.
    ld a,(de)                 ; Get comparison byte.
    cp b                      ; Compare byte on stack with comparison byte.
    jp nz,exit_with_failure   ; Fail if not equal.
    inc hl                    ; Point to next byte in stack.
    inc de                    ; Point to next comparison byte.
  .endr
  ;.rept LEN                   ; Clean stack to leave no trace on the system.
  ;  inc sp        
  ;.endr
.endm

.macro ASSERT_HL_POINTS_TO_STRING ARGS LEN, STRING
  ; Parameters: Pointer to string, string length. 
  ld de,STRING                ; Comparison string in DE
  .rept LEN                   ; Loop through given number of bytes.
    ld a,(hl)                 ; Get byte
    ld b,a                    ; Store it.
    ld a,(de)                 ; Get comparison byte.
    cp b                      
    jp nz,exit_with_failure   ; Fail if not equal.
    inc hl                    ; Point to next byte.
    inc de                    ; Point to next comparison byte.
  .endr
.endm


.macro CLEAN_STACK
  .rept \1
    inc sp
  .endr
.endm

.ramsection "Fake VRAM stuff" slot 3
  fake_sat_y dsb 64
  fake_sat_xc dsb 128
.ends

.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Test data" free
  fake_acm_data:
    ; acm_enabled:
    .db TRUE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE       
    ; acm_frame:
    .db 0 0 1 0 0 0 0 8
    ; acm_timer:
    .db 9 0 0 0 0 0 0 9
    ; acm_pointer:
    .dw cody_walking $0000 dummy_anim dummy_anim $0000 $0000 $0000 $0000
  fake_acm_data_end:
  .equ FULL_ACM fake_acm_data_end-fake_acm_data 

  fake_acm_data_2:
    ; acm_enabled:
    .db TRUE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE       
    ; acm_frame:
    .db 0 0 1 0 0 0 0 8
    ; acm_timer:
    .db 9 0 1 3 0 0 0 9
    ; acm_pointer:
    .dw cody_walking $0000 dummy_anim dummy_anim $0000 $0000 $0000 $0000
  fake_acm_data_2_end:

  fake_acm_data_3: ;(includes the looping dummy anim)
    ; acm_enabled:
    .db TRUE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, TRUE       
    ; acm_frame:
    .db 0 0 0 0 0 0 0 1
    ; acm_timer:
    .db 9 0 1 3 0 0 0 1
    ; acm_pointer:
    .dw cody_walking $0000 dummy_anim dummy_anim $0000 $0000 $0000 looping_dummy_anim


  .macro LOAD_ACM
    ld hl,\1
    ld de,acm_enabled
    ld bc,FULL_ACM
    ldir
  .endm

  .macro CLEAR_VJOBS
    ld a,0
    ld hl,vjobs
    .rept 1+(2*VJOB_MAX)
      ld (hl),a
      inc hl
    .endr
  .endm
  


  ; Animation file:
  dummy_anim:
    ; Table of contents:
    .dw @header, @frame_0, @frame_1
     @header:
      .db 1                       ; Max frame.
      .db FALSE                   ; Looping.
    @frame_0:
      .db 5                       ; Duration.
      .db FALSE                   ; Require vjob?
      .dw $0000                   ; Pointer to vjob.
      .db 8                       ; Size.
      .db 10                      ; Index of first tile.
      .dw layout_2x4              ; Pointer to layout.
    @frame_1:
      .db 7                      
      .db FALSE                    
      .dw $0000 
      .db 8                       
      .db 18                       
      .dw layout_2x4              

  looping_dummy_anim:
    ; Table of contents:
    .dw @header, @frame_0, @frame_1
     @header:
      .db 1                       ; Max frame.
      .db TRUE                   ; Looping.
    @frame_0:
      .db 3                       ; Duration.
      .db FALSE                   ; Require vjob?
      .dw $0000                   ; Pointer to vjob.
      .db 8                       ; Size.
      .db 10                      ; Index of first tile.
      .dw layout_2x4              ; Pointer to layout.
    @frame_1:
      .db 3                      
      .db FALSE                    
      .dw $0000 
      .db 8                       
      .db 18                       
      .dw layout_2x4      

.ends

.section "tests" free


  test_bench:
    ; These are the animation tests:
    
    call initialize_acm
    
    ; Test to get ENABLED staus from the anim in slot 0.
    LOAD_ACM fake_acm_data
    ld a,0
    call is_animation_enabled
    ASSERT_A_EQUALS TRUE

    ; Test to get DISABLED staus from the anim in slot 1.
    LOAD_ACM fake_acm_data
    ld a,1
    call is_animation_enabled
    ASSERT_A_EQUALS FALSE

    ; Test simple getters:
    LOAD_ACM fake_acm_data
    ld a,0
    call get_frame
    ASSERT_A_EQUALS 0
    ld a,2
    call get_frame
    ASSERT_A_EQUALS 1
    ld a,0
    call get_timer
    ASSERT_A_EQUALS 9
    ld a,2
    call get_timer
    ASSERT_A_EQUALS 0

    ; Test getting data from the animation file:
    LOAD_ACM fake_acm_data
    ld a,0
    call is_animation_looping
    ASSERT_A_EQUALS TRUE

    ; Test btach ticking of enabled animations
    LOAD_ACM fake_acm_data
    call tick_enabled_animations
    ld a,0
    call get_timer
    ASSERT_A_EQUALS 8
    ld a,2
    call get_timer
    ASSERT_A_EQUALS 0
    ld a,7
    call get_timer
    ASSERT_A_EQUALS 9 

    ; Test max frame
    LOAD_ACM fake_acm_data
    ld a,0
    call is_animation_at_max_frame
    ASSERT_A_EQUALS FALSE
    ld a,2
    call is_animation_at_max_frame
    ASSERT_A_EQUALS TRUE

    ; Test disable non-looping animation at max frame:
    LOAD_ACM fake_acm_data
    ld a,2
    call is_animation_at_max_frame
    cp TRUE
    jp nz,+
      ld a,2
      call is_animation_looping
      cp FALSE
      jp nz,+
        ld a,2
        call disable_animation
    +:
    ld a,2
    call is_animation_enabled
    ASSERT_A_EQUALS FALSE

    ; Test getting info about current frame from file
    LOAD_ACM fake_acm_data
    ld a,0
    call get_duration
    ASSERT_A_EQUALS 10

    ; Test getting info about current frame from file
    LOAD_ACM fake_acm_data
    ld a,2
    call get_duration
    ASSERT_A_EQUALS 7
    ld a,0
    call get_duration
    ASSERT_A_EQUALS 10

    ; Test getting info about current frame from file
    LOAD_ACM fake_acm_data
    ld a,0
    call is_vjob_required
    ASSERT_A_EQUALS TRUE
    ld a,2
    call is_vjob_required
    ASSERT_A_EQUALS FALSE

    ; Test adding a vjob if the current frame requires it.
    LOAD_ACM fake_acm_data
    CLEAR_VJOBS
    ld a,2
    call add_vjob_if_required
    ld a,(vjobs)
    ASSERT_A_EQUALS 0

    ; Test adding a vjob if the current frame requires it.
    LOAD_ACM fake_acm_data
    CLEAR_VJOBS
    ld a,0
    call add_vjob_if_required
    ld a,(vjobs)
    ASSERT_A_EQUALS 1
    ld hl,vjob_table
    call get_word
    ASSERT_HL_EQUALS cody_walking_0_vjob

    ; Test adding a vjob if the current frame requires it.
    LOAD_ACM fake_acm_data
    CLEAR_VJOBS
    ld a,2
    call add_vjob_if_required
    ld a,(vjobs)
    ASSERT_A_EQUALS 0
    ld hl,vjob_table
    call get_word
    ASSERT_HL_EQUALS $0000

    ; Roll out the big batch tests:
    LOAD_ACM fake_acm_data_2
    CLEAR_VJOBS
    call process_animations
      ; Are timers handled as expected?
      ld a,0
      call get_timer
      ASSERT_A_EQUALS 8
      jp +
        timers_ticked_once:
          .db 8 0 0 2 0 0 0 9
      +:
      ld hl,acm_timer
      ASSERT_HL_POINTS_TO_STRING ACM_SLOTS timers_ticked_once

    ; Test incrementing frame
    LOAD_ACM fake_acm_data_2
    CLEAR_VJOBS
    call process_animations
    ld a,2
    call get_frame
    ASSERT_A_EQUALS 1
    
    ; Test looping, part one
    LOAD_ACM fake_acm_data_3
    CLEAR_VJOBS
    call process_animations
    ld a,7
    call get_frame
    ASSERT_A_EQUALS_NOT 2

    ; Further testing incrementing frame
    LOAD_ACM fake_acm_data_3
    CLEAR_VJOBS
    call process_animations
    ld a,2
    call get_frame
    ASSERT_A_EQUALS 1
    ld a,2
    call get_duration
    ASSERT_A_EQUALS 7
    ld a,2
    call get_timer
    ASSERT_A_EQUALS 7

  ; Test looping, part two
    LOAD_ACM fake_acm_data_3
    CLEAR_VJOBS
    call process_animations
    ld a,7
    call get_frame
    ASSERT_A_EQUALS 0

  ; Test looping, part three - no loop, just disable
    LOAD_ACM fake_acm_data_2
    CLEAR_VJOBS
    call process_animations
    ld a,2
    call get_frame
    ASSERT_A_EQUALS 1

    ; This is going well...!


    ; Test get animation label.
    LOAD_ACM fake_acm_data_3
    CLEAR_VJOBS
    ld a,0
    call get_animation_label
    ASSERT_HL_EQUALS cody_walking

    ; Test adding an animation, the pointer.
    LOAD_ACM fake_acm_data_3
    CLEAR_VJOBS
    ld a,1
    call get_animation_label
    ASSERT_HL_EQUALS $0000
    ld a,1
    ld hl,cody_walking
    call set_animation
    ld a,1
    call get_animation_label
    ASSERT_HL_EQUALS cody_walking
    ld a,1
    call get_timer
    ASSERT_A_EQUALS 10
    ld a,1
    call is_vjob_required
    ASSERT_A_EQUALS TRUE

    ld a,0
    call get_layout
    ASSERT_A_EQUALS 1
    ld a,b
    ASSERT_A_EQUALS 8
    ASSERT_HL_EQUALS layout_2x4
    ld a,(hl)
    ASSERT_A_EQUALS -32
    ASSERT_HL_POINTS_TO_STRING 8,layout_2x4



    .macro CLEAR_SAT_BUFFER
      ld a,0
      ld (sat_buffer_index),a
      ld hl,sat_buffer_y
      .rept 64
        ld (hl),a
        inc hl
      .endr
      ld hl,sat_buffer_xc
      .rept 128
        ld (hl),a
        inc hl
      .endr
    .endm

    jp +
      .dstruct fake_actor actor 0, 100, 100
    +:
    jp +
      offset_fake_actor:
        .db 68 68 76 76 84 84 92 92
      offset_fake_actor_xc:
        .db 92, 1, 100, 2, 92, 3, 100, 4
    +:

    ; Test sat y buffer.
    CLEAR_SAT_BUFFER
    LOAD_ACM fake_acm_data_3
    CLEAR_VJOBS
    ld a,0  ; use frame currently displaying in slot 0.
    ld hl,fake_actor
    call draw_actor
    ld hl,sat_buffer_y
    ASSERT_HL_POINTS_TO_STRING 8, offset_fake_actor

  ; Test sat xc buffer.
    CLEAR_SAT_BUFFER
    LOAD_ACM fake_acm_data_3
    CLEAR_VJOBS
    ld a,0  ; use frame currently displaying in slot 0.
    ld hl,fake_actor
    call draw_actor
    ld hl,sat_buffer_xc
    ld a,(hl)
    ASSERT_A_EQUALS 92
    ASSERT_HL_POINTS_TO_STRING 6, offset_fake_actor_xc



  ; ------- end of tests --------------------------------------------------------
  exit_with_succes:
    ld a,11
    ld b,BORDER_COLOR
    call set_register
  -:
    nop
  jp -

  exit_with_failure:
    ld a,8
    ld b,BORDER_COLOR
    call set_register
  -:
    nop
  jp -
.ends
