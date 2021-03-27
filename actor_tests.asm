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
    inc sp                    ; clean stack as we proceed.
    .SHIFT
  .endr
.endm

.macro ASSERT_TOP_OF_STACK_EQUALS_BYTES_AT
  ; Parameters: Number of bytes, pointer to expected data. 
  ld de,\2                    ; Comparison string in DE
  ld hl,0                     ; HL points to top of stack.
  add hl,sp       
  .rept \1                    ; Loop through given number of bytes.
    ld a,(hl)                 ; Get byte from stack.
    ld b,a                    ; Store it.
    ld a,(de)                 ; Get comparison byte.
    cp b                      ; Compare byte on stack with comparison byte.
    jp nz,exit_with_failure   ; Fail if not equal.
    inc hl                    ; Point to next byte in stack.
    inc de                    ; Point to next comparison byte.
  .endr
  .rept \1                    ; Clean stack to leave no trace on the system.
    inc sp        
  .endr
.endm

.macro ASSERT_TOP_OF_STACK_EQUALS_STRING ARGS STRING, LEN
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
  .rept LEN                   ; Clean stack to leave no trace on the system.
    inc sp        
  .endr
.endm




.section "tests" free
; -----------------------------------------------------------------------------
test_bench:
  jp +
    my_input_1_120_10_1234:
      .db 1, 120, 10
      .dw $1234
  +:
  ld hl,my_input_1_120_10_1234
  call batch_offset
  ASSERT_A_EQUALS 130

  jp +
    my_input_1_120_20_1234:
      .db 1, 120, 20
      .dw $1234
  +:
  ld hl,my_input_1_120_20_1234
  call batch_offset
  ASSERT_A_EQUALS 140

  jp +
    my_input_2_120_20_30_1234:
      .db 2, 120, 20, 30
      .dw $1234
  +:
  ld hl,my_input_2_120_20_30_1234
  call batch_offset
  ASSERT_A_EQUALS 150

  ; Pass 16 bit and 8 bit parameter in stack
  ; And get 16 bit result from subroutine.
  ld hl,-2
  add hl,sp
  ld sp,hl
  ld hl,$1234
  push hl
  ld a,$56
  push af
  inc sp
  call my_sub
  ld hl,3
  add hl,sp
  ld sp,hl
  ASSERT_TOP_OF_STACK_EQUALS $12 $34
  ;pop hl

  ; And get 16 bit result from subroutine.
  jp +
    my_data:
      .db $12, $34
    my_other_data:
      .db $12, $35, $56
  +:
  ld hl,-2
  add hl,sp
  ld sp,hl
  ld hl,my_data
  call my_sub_gets_hl
  ASSERT_TOP_OF_STACK_EQUALS_BYTES_AT 2 my_data

  ld hl,2
  ld a,l
  ASSERT_A_EQUALS 2

  jp +
    my_string:
      .db $12, $34, $56, $78, $9A
    my_zero_string:
      .db $00, $00, $00, $00, $00
  +:
  .macro EVALUATE_BYTE_MOVER
    ld hl,-2 ; return address
    add hl,sp
    ld sp,hl
    ld a,\1
    ld hl,\2
    call move_bytes_from_string_to_stack
  .endm

  EVALUATE_BYTE_MOVER 3, my_string
  ASSERT_TOP_OF_STACK_EQUALS_BYTES_AT 3 my_string

  EVALUATE_BYTE_MOVER 4, my_zero_string
  ASSERT_TOP_OF_STACK_EQUALS_BYTES_AT 4 my_zero_string

  EVALUATE_BYTE_MOVER 5, my_string
  ASSERT_TOP_OF_STACK_EQUALS_STRING my_string, 5


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

.dstruct my_frame frame 7 arthur_standing_0_layout
test_size_in_my_frame:
  ld a,(my_frame.size)
  ASSERT_A_EQUALS 7
ret






.ends
