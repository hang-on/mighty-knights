.macro ASSERT_A_EQUALS
  cp \1
  jp nz,exit_with_failure
  nop
.endm

.section "Unit testing" free

  object_tests:

  jp +
    y_100_o_m24:
      .db 100, -24
  +:
  ld hl,y_100_o_m24
  call apply_origin
  ASSERT_A_EQUALS 76 
  
  jp +
    y_100_o_m16:
      .db 100, -16
  +:
  ld hl,y_100_o_m16
  call apply_origin
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