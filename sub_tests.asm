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
    ;inc sp                    ; clean stack as we proceed.
    .SHIFT
  .endr
.endm

.macro ASSERT_TOP_OF_STACK_EQUALS_STRING ARGS LEN, STRING
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
  ;.rept LEN                   ; Clean stack to leave no trace on the system.
  ;  inc sp        
  ;.endr
.endm

.macro ASSERT_HL_EQUALS_STRING ARGS LEN, STRING
  ; Parameters: Pointer to string, string length. 
  ld de,STRING                ; Comparison string in DE
  .rept LEN                   ; Loop through given number of bytes.
    ld a,(hl)                 ; Get byte
    ld b,a                    ; Store it.
    ld a,(de)                 ; Get comparison byte.
    cp b                      
    jp nz,exit_with_failure   ; Fail if not equal.
    inc hl                    ; Point to next byte.
    inc de                    ; Point to next comparison byte.
  .endr
.endm



.macro CLEAN_STACK
  .rept \1
    inc sp
  .endr
.endm

.ramsection "Fake RAM stuff" slot 3
  fake_sat_y dsb 64
  fake_sat_xc dsb 128
.ends




.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "tests" free

jp +
  .struct load
    bank db
    source dw
    size dw
    destination dw
  .endst
  fake_load_que: ; FIXME: No fancy ques, just simple array of ptrs to loads
    .dw load_0
    .dw load_1
    .dw $0000


  .dstruct load_0 instanceof load 2, multicolor_c, multicolor_c_size, $1234
  .dstruct load_1 instanceof load 2, multicolor_c, multicolor_c_size, $1234
  
  multicolor_c:
    .db $ff $00 $ff $00
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $ff $00 $00
  multicolor_c_size:
    .dw 32
+:

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
.ends
