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

  ; ----------------------------------------------------------
  jp +
    arthur_standing_0_y:
      .db -24, -24, -16, -16, -8, -8, -32

    arthur_standing_0_xc:
      .db  -8, 1, 0, 2, -8, 3, 0, 4, -8, 5, 0, 6, -8, 7
  +:

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








.ends
