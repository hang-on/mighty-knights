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

.macro ASSERT_TOP_OF_STACK_EQUALS
  ld hl,0
  add hl,sp
  .rept NARGS
    ld a,(hl)
    cp \1
    jp nz,exit_with_failure
    inc hl
    .SHIFT
  .endr
.endm

.macro ASSERT_TOP_OF_STACK_EQUALS_BYTES_AT
  ld de,\2
  
  ld hl,0
  add hl,sp
  .rept \1
    ld a,(hl)
    ld b,a
    ld a,(de)
    cp b
    jp nz,exit_with_failure
    inc hl
    inc de

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
  pop hl
  ld a,l
  ASSERT_A_EQUALS $12

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
  ASSERT_TOP_OF_STACK_EQUALS $12 $34
  ASSERT_TOP_OF_STACK_EQUALS_BYTES_AT 2 my_data
  pop hl ; two bytes, correspond to size for result (nreslt)

  ld hl,2
  ld a,l
  ASSERT_A_EQUALS 2

  jp +
    my_string:
      .db $12, $34, $56, $78, $9A
    my_zero_string:
      .db $00, $00, $00, $00, $00
  +:
  ld hl,-2 ; return address
  add hl,sp
  ld sp,hl
  ld a,5
  ld hl,my_string
  call move_bytes_from_string_to_stack
  ASSERT_TOP_OF_STACK_EQUALS_BYTES_AT 5 my_string
  .rept 5
    inc sp
  .endr






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
