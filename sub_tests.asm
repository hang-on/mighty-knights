

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

  .macro LOAD_ACM
    ld hl,\1
    ld de,acm_enabled
    ld bc,fake_acm_data_end-fake_acm_data
    ldir
  .endm


  .equ PLAYER_TILE_BANK 2
  .equ PLAYER_FIRST_TILE SPRITE_BANK_START + CHARACTER_SIZE
  .macro PLAYER_VJOB ARGS TILES, AMOUNT
    .db PLAYER_TILE_BANK
    .dw TILES
    .dw CHARACTER_SIZE*AMOUNT
    .dw PLAYER_FIRST_TILE
  .endm
  
  cody_walking_0_vjob:
    PLAYER_VJOB cody_walking_0_tiles, 8
  cody_walking_1_and_3_vjob:
    PLAYER_VJOB cody_walking_1_and_3_tiles, 8
  cody_walking_2_vjob:
    PLAYER_VJOB cody_walking_2_tiles, 8  
  
  layout_2x4:
    ; Y and X offsets to apply to the origin of an actor.
    .db -32, -8
    .db -32, 0
    .db -24, -8
    .db -24, 0
    .db -16, -8
    .db -16, 0
    .db -8, -8
    .db -8, 0

  ; Animation file:
  cody_walking:
    ; Table of contents:
    .dw @header, @frame_0, @frame_1, @frame_2, @frame_3
    @header:
      .db 3                       ; Max frame.
      .db TRUE                    ; Looping.
    @frame_0:
      .db 10                      ; Duration.
      .db TRUE                    ; Require vjob?
      .dw cody_walking_0_vjob     ; Pointer to vjob.
      .db 8                       ; Size.
      .db 1                       ; Index of first tile.
      .dw layout_2x4              ; Pointer to layout.
    @frame_1:
      .db 10                      
      .db TRUE                    
      .dw cody_walking_1_and_3_vjob 
      .db 8                       
      .db 1                       
      .dw layout_2x4              
    @frame_2:
      .db 10                      
      .db TRUE                    
      .dw cody_walking_2_vjob 
      .db 8                       
      .db 1                       
      .dw layout_2x4              
    @frame_3:
      .db 10                      
      .db TRUE                    
      .dw cody_walking_1_and_3_vjob 
      .db 8                       
      .db 1                       
      .dw layout_2x4              


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

.ends

.section "tests" free


  test_bench:
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
