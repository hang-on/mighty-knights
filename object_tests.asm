.macro ASSERT_A_EQUALS
  cp \1
  jp nz,exit_with_failure
  nop
.endm

.macro EVALUATE_POSITION
  jp +
    position\@:
      .db \2 \3
  +:
  ld hl,position\@
  call \1
.endm

.section "Unit testing" free

  object_tests:

  EVALUATE_POSITION apply_origin, 100, -24
  ASSERT_A_EQUALS 76 

  EVALUATE_POSITION apply_origin, 100, -16
  ASSERT_A_EQUALS 84 

  jp +
    ram_origin_y_100:
      .db 100
    offset_m24:
      .db -24
  +:
  ld a,(ram_origin_y_100)
  ld hl,offset_m24
  call apply_origin_with_var
  ASSERT_A_EQUALS 76  

  jp +
    ram_origin_y_100_1:
      .db 100
    offset_m16_1:
      .db -16
  +:
  ld a,(ram_origin_y_100_1)
  ld hl,offset_m16_1
  call apply_origin_with_var
  ASSERT_A_EQUALS 84  
 

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



.ends