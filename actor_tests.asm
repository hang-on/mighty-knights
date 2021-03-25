;.equ TEST_MODE

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

.org $1234
fake_animation_table:
    .db 7,
    .dw $1234,
    .db 0
    .db 0
    .dw $0123
    .dw $4567

    .db 6,
    .dw $5678,
    .db 0
    .db 0
    .dw $0123
    .dw $4567


; -----------------------------------------------------------------------------
test_bench:



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

