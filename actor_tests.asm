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

dummy_animation:
  .db 4
  .dw $1111
  .db 9
  .db 9

ctable1:
  ; item 0
  .db 4
  .dw $1111
  .db 9
  .db 9
  ; item 1
  .db 5
  .dw $2222
  .db 10
  .db 10



test_bench:


call test_get_animation_0
call test_get_animation_1
call test_macro
call test_offset_custom_table_0_ctable1
call test_offset_custom_table_1_ctable1

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

test_macro:
  ld hl,$1234
  ASSERT_HL_EQUALS $1234
ret

test_offset_custom_table_0_ctable1
  ld a,0
  ld b,5
  ld hl,ctable1
  call offset_custom_table
  ASSERT_HL_EQUALS ctable1
ret

test_offset_custom_table_1_ctable1
  ld a,1
  ld b,5
  ld hl,ctable1
  call offset_custom_table
  ASSERT_HL_EQUALS ctable1+5
  ld a,(hl)
  ASSERT_A_EQUALS 5
ret
