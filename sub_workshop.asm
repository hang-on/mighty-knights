  .equ ACTOR_MAX 5 ;***
  
  .equ VJOB_MAX 8 ; amount of video jobs the table can hold 
  .struct actor
    id db
    y db
    x db
  .endst

  .macro INITIALIZE_ACTOR
    ld hl,init_data_\@
    ld de,\1
    ld bc,3
    ldir
    jp +
      init_data_\@:
        .db \2 \3 \4 
    +:
    ld a,\2
    ld hl,\5
    call set_frame

  .endm
  .ramsection "Test kernel" slot 3
    ; For faking writes to vram.
    ; 7 bytes! - update RESET macro if this changes!
      test_kernel_source dw
      test_kernel_bank db
      test_kernel_destination dw
      test_kernel_bytes_written dw
  .ends

.macro RESET_TEST_KERNEL
  ld hl,test_kernel_source
  ld a,0
  .rept 7
    ld (hl),a
    inc hl
  .endr
.endm


.macro SELECT_BANK_IN_REGISTER_A
  ; Select a bank for slot 2, - put value in register A.
  .ifdef USE_TEST_KERNEL
    ld (test_kernel_bank),a
  .else
    ld (SLOT_2_CONTROL),a
  .endif
.endm
; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------




.ends


; -----------------------------------------------------------------------------
; Handling vram loading via a video job format
; -----------------------------------------------------------------------------
.struct vjob
  bank db
  source dw
  size dw
  destination dw
.endst
.ramsection "Vjob RAM" slot 3
  vjobs db
  vjob_table dsb 2*VJOB_MAX ; up to 10 video jobs, ptrs to video jobs
.ends
.section "Video jobs" free
  initialize_vjobs:
    ; Does not take any parameters
    xor a
    ld (vjobs),a
  ret
  
  add_vjob:
    ; HL: Video job to add to table
    ld a,(vjobs)
    cp VJOB_MAX
    ret z                       ; Protect against overflow..
    ;
    ld b,l
    ld c,h
    push bc
      ld a,(vjobs)
      ld hl,vjob_table
      call offset_word_table
    pop bc
    ld (hl),b
    inc hl
    ld (hl),c
    ;
    ld hl,vjobs
    inc (hl)
  ret
  
  process_vjobs:
    ; Does not take any parameters
    ld a,(vjobs)
    cp 0
    ret z
    ld b,0
    ld c,a
    -:
        push bc
          ld a,b
          ld hl,vjob_table
          call offset_word_table
          call get_word
          call run_vjob
        pop bc
      inc b
      ld a,c
      cp b
    jp nz,-
    ;
    xor a
    ld (vjobs),a
  ret

  run_vjob:
    ; HL: Pointer to video job to run.
    push hl
    pop ix
    ld a,(ix+0)
    SELECT_BANK_IN_REGISTER_A
    ld l,(ix+1)
    ld h,(ix+2)
    ld c,(ix+3)
    ld b,(ix+4)
    ld e,(ix+5)
    ld d,(ix+6)
    call load_vram
  ret
.ends
