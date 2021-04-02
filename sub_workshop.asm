  .equ ACTOR_MAX 5 ;***
  
  .struct actor
    id db
    y db
    x db
  .endst


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

.equ ACM_SLOTS 8
.ramsection "Animation Control Matrix (ACM)" slot 3 align 256 
  acm_enabled dsb ACM_SLOTS
  acm_frame dsb ACM_SLOTS
  acm_timer dsb ACM_SLOTS
  acm_pointer dsb ACM_SLOTS*2
.ends

; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------
  tick_enabled_animations:
      ld hl,acm_enabled
      ld de,acm_timer
    .rept ACM_SLOTS
      ld a,(hl)
      cp TRUE
      jp nz,+
        ld a,(de)
        cp 0
        jp z,+
          dec a
          ld (de),a
      +:
      inc hl
      inc de
    .endr
  ret
  
  is_animation_enabled:
    ; IN:  A = Slot number in ACM
    ; OUT: A = TRUE or FALSE.
    ld hl,acm_enabled
    call offset_byte_table
    ld a,(hl)
  ret

  get_frame:
    ; IN:  A = Slot number in ACM
    ; OUT: A = Number of the frame currently playing (0..x).
    ld hl,acm_frame
    call offset_byte_table
    ld a,(hl)
  ret

  get_timer:
    ; IN:  A = Slot number in ACM
    ; OUT: A = The time remaining for the current frame.
    ld hl,acm_timer
    call offset_byte_table
    ld a,(hl)
  ret

  is_animation_looping:
    ; IN:  A = Slot number in ACM
    ; OUT: A = TRUE or FALSE.
    ld hl,acm_pointer             ; HL = Start of pointer table.
    call offset_word_table        ; HL = Item holding ptr. to animation file.
    call get_word                 ; HL = Start (at t.o.c.) of animation file. 
    call get_word                 ; HL = Header section in animation file.
    inc hl                        ; Go past max frame to looping (bool).
    ld a,(hl)                     ; Load into A and return.
  ret


  initialize_acm:
    ; Turn off all animation slots in the matrix.
    ld a,FALSE
    ld b,ACM_SLOTS
    ld hl,acm_enabled
    -:
      ld (hl),a
      inc hl
    djnz -
  ret


.ends

