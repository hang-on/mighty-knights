.equ TEST_MODE

.macro ASSERT_A_EQUALS
  cp \1
  jp nz,exit_with_failure
  nop
.endm


.org $1234
fake_animation_table:
    .db 7,
    .dw $1234,
    .db 0
    .db 0

    .db 6,
    .dw $5678,
    .db 0
    .db 0

test_bench:


call test_get_animation_0
call test_get_animation_1

; ------- end of tests ------
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

ret


test_get_animation_0:
  ld a,0
  call get_animation
  ld a,l
  ASSERT_A_EQUALS $34
ret

test_get_animation_1:
  ld a,1
  call get_animation
  ld a,l
  ASSERT_A_EQUALS $34+$5
ret
