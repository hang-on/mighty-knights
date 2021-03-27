.equ TEST_MODE

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

.ramsection "Fake RAM stuff" slot 3
  fake_sat_y dsb 64
  fake_sat_xc dsb 128
.ends

; -----------------------------------------------------------------------------
.section "tests" free
test_bench:

  jp +
  batch_offset_input_0:
    .db 7, -24, -24, -16, -16, -8, -8, -32
  batch_offset_output_0:
    .db  126, 126, 134, 134, 142, 142, 118
  alternating_batch_offset_input_1:
    .db 7, -8, 1, 0, 2, -8, 3, 0, 4, -8, 5, 0, 6, -8, 7 ; pairs
  alternating_batch_offset_output_1:
    .db 142, 1, 150, 2, 142, 3, 150, 4, 142, 5, 150, 6, 142, 7
    ; fix?: let chars be a counter from x to x + size...?
  +:
  dec sp
  dec sp
  ld a,150
  ld hl,batch_offset_input_0
  call batch_offset_to_stack
  ASSERT_TOP_OF_STACK_EQUALS_STRING 7,batch_offset_output_0
  CLEAN_STACK 7

  ld a,150
  ld hl,batch_offset_input_0
  ld de,fake_sat_y
  call batch_offset_to_DE
  ld hl,fake_sat_y
  ASSERT_HL_EQUALS_STRING 7, batch_offset_output_0

  ld a,150
  ld hl,alternating_batch_offset_input_1
  ld de,fake_sat_xc
  call batch_alternating_offset_and_copy_to_DE
  ld hl,fake_sat_xc
  ASSERT_HL_EQUALS_STRING 14, alternating_batch_offset_output_1

  jp +
    arthur_standing_0_y:
      .db -24, -24, -16, -16, -8, -8, -32

    arthur_standing_0_xc:
      .db  -8, 1, 0, 2, -8, 3, 0, 4, -8, 5, 0, 6, -8, 7
  +:


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
