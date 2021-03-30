

.macro ASSERT_A_EQUALS
  cp \1
  jp nz,exit_with_failure
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

.macro ASSERT_HL_EQUALS_STRING ARGS LEN, STRING
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
.section "tests" free

  jp +
    ; Data for testing the animations
    fake_anim_script:
      .db 3                       ; Max frame
      .db TRUE                    ; Looping
      .db 10                      ; Ticks to display frame
      .dw cody_walking_0          ; Frame
      .db 10    
      .dw cody_walking_1_and_3
      .db 10    
      .dw cody_walking_2
      .db 10    
      .dw cody_walking_1_and_3
 
     fake_anim_script_no_loop:
      .db 3                       ; Max frame
      .db FALSE                    ; Looping
      .db 10                      ; Ticks to display frame
      .dw cody_walking_0          ; Frame
      .db 10    
      .dw cody_walking_1_and_3
      .db 10    
      .dw cody_walking_2
      .db 10    
      .dw cody_walking_1_and_3
  +:

  test_bench:

  ; Test tick 10 to 9.
  jp +  
    ; Fake RAM structure.
    .dstruct anim_0_10 animation 0, 10, fake_anim_script
  +:
  ld hl,anim_0_10
  call tick_animation
  ASSERT_A_EQUALS 9

  ; Test tick 1 to 0.
  jp +  
    ; Fake RAM structure.
    .dstruct anim_0_1 animation 0, 1, fake_anim_script
  +:
  ld hl,anim_0_1
  call tick_animation
  ASSERT_A_EQUALS 0

  ; Test tick 0 to ANIM_TIMER_UP.
  jp +  
    ; Fake RAM structure.
    .dstruct anim_0_0 animation 0, 0, fake_anim_script
  +:
  ld hl,anim_0_0
  call tick_animation
  ASSERT_A_EQUALS ANIM_TIMER_UP

  ; Test get next frame
  ld hl,anim_0_0
  call get_next_frame
  ASSERT_A_EQUALS 1

  jp +  
    ; Fake RAM structure.
    .dstruct anim_3_0 animation 3, 0, fake_anim_script
  +:
  ; Test get next frame when looping
  ld hl,anim_3_0
  call get_next_frame
  ASSERT_A_EQUALS 0

  jp +  
    ; Fake RAM structure.
    .dstruct anim_3_0_noloop animation 3, 0, fake_anim_script_no_loop
  +:
  ; Test get next frame when looping
  ld hl,anim_3_0_noloop
  call get_next_frame
  ASSERT_A_EQUALS 3

  jp +  
    ; Fake RAM structure.
    .dstruct anim_1_0 animation 1, 0, fake_anim_script
  +:
  ; Test get data for frame 1
  ld hl,anim_1_0
  call get_ticks_and_frame_pointer
  ASSERT_A_EQUALS 10
  ASSERT_HL_EQUALS cody_walking_1_and_3

  jp +  
    ; Fake RAM structure.
    .dstruct anim_2_0 animation 2, 0, fake_anim_script
  +:
  ; Test get data for frame 2
  ld hl,anim_2_0
  call get_ticks_and_frame_pointer
  ASSERT_A_EQUALS 10
  ASSERT_HL_EQUALS cody_walking_2



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
