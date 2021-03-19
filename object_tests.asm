.macro ASSERT_A_EQUALS
  cp \1
  jp nz,exit_with_failure
  nop
.endm



.section "Unit testing" free

  object_tests:

  
 

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