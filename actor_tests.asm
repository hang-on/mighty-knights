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



.section "tests" free
; -----------------------------------------------------------------------------
test_bench:
  call test_size_in_my_frame



jp +  
.dstruct my_frame_1 frame 7 layout_1
layout_1:
    .db -24, -8, 1
    .db -24, 0, 2
    .db -16, -8, 3
    .db -16, 0, 4
    .db -8, -8, 5
    .db -8, 0, 6
    .db -32, -8, 7
+:
  ld hl,my_frame_1
  ld a,1 
  call get_sprite
  ASSERT_HL_EQUALS layout_1 + 3



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
