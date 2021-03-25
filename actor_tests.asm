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
  call test_size_in_my_frame
  call test_get_first_sprite
  call test_get_sprite_1




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


.dstruct my_frame_0 frame 7 layout_0
layout_0:
    .db -24, -8, 1
    .db -24, 0, 2
    .db -16, -8, 3
    .db -16, 0, 4
    .db -8, -8, 5
    .db -8, 0, 6
    .db -32, -8, 7
test_get_first_sprite:
  ld hl,my_frame_0
  ld a,0 ; first sprite
  call get_sprite
  ASSERT_HL_EQUALS layout_0
ret

.dstruct my_frame_1 frame 7 layout_1
layout_1:
    .db -24, -8, 1
    .db -24, 0, 2
    .db -16, -8, 3
    .db -16, 0, 4
    .db -8, -8, 5
    .db -8, 0, 6
    .db -32, -8, 7
test_get_sprite_1:
  ld hl,my_frame_1
  ld a,1 
  call get_sprite
  ASSERT_HL_EQUALS layout_1 + 3
ret
