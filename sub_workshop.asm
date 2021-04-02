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
  get_animation_label:
    ; IN:  A = Slot number in ACM
    ; OUT: HL = Label of animation file linked to the given slot.
    ld hl,acm_pointer
    call offset_word_table
    call get_word
  ret

  set_animation:
    ; 
    ; IN: A = Slot.
    ;     HL = Animation label
    .equ ERROR_SLOT_ENABLED $ff
    .equ OPERATION_SUCCESFUL $00
    ld (temp_byte),a
    push hl                     ; Save the label for later.
    pop ix
    call is_animation_enabled
    cp TRUE
    jp nz,+
      ; Slot is already in use! Abort with error message.
      ld a,ERROR_SLOT_ENABLED
      ret
    +:
      ld a,(temp_byte)
      ld hl,acm_pointer
      call offset_word_table    ; HL points to the label/pointer item.
      push ix                   ; Retrieve the animation label.
      pop bc
      ld (hl),c
      inc hl
      ld (hl),b
      ; Use the animation label to fill the other fields in the slot.
      ld a,(temp_byte)          ; This behavior is similar to when an animation
      ld b,FRAME_RESET          ; loops back to the first frame (0).
      call set_new_frame
      ld a,OPERATION_SUCCESFUL
  ret
  


  process_animations:      
    .redefine COUNT 0
    ld a,COUNT
    call tick_enabled_animations

    .rept ACM_SLOTS index COUNT
      ld a,COUNT
      call is_animation_enabled
      cp TRUE
      jp nz,++++
        ld a,COUNT
        call get_timer
        cp 0
        jp nz,++++
          ; OK, animation is enabled and time is up. What to do..?
          ld a,COUNT
          call is_animation_at_max_frame
          cp TRUE
          jp z,+
            ; Not at max frame >> frame forward all inclusive...
            ld a,COUNT
            ld b,FRAME_FORWARD
            call set_new_frame
            jp ++++
          +:
            ; Do stuff that either loops or disables animation.
            ld a,COUNT
            call is_animation_looping
            cp TRUE
            jp nz,++
              ; Looping, just go back to frame 0 and reset timer, load vjobs.
              ld a,COUNT
              ld b,FRAME_RESET
              call set_new_frame
              jp ++++
            ++:
              ; Not looping, just disable animation
              ld a,COUNT
              call disable_animation
      ++++:
    .endr
  ret

  .equ FRAME_FORWARD $ff
  .equ FRAME_RESET 0
  
  set_new_frame:
    ; IN: A = Slot number.
    ;     B = Frame number or command (FRAME_FORWARD or FRAME_RESET (=0)).
    ld (temp_byte),a
    ld a,b
    cp FRAME_FORWARD
    jp z,@inc_frame
      ; Not frame forward. Then just set frame to the given number.
      push af
        ld a,(temp_byte)
        ld hl,acm_frame
        call offset_byte_table
      pop af
      ld (hl),a
      jp +
    @inc_frame:
      ld a,(temp_byte)
      ld hl,acm_frame
      call offset_byte_table
      ld a,(hl)
      inc a
      ld (hl),a
    +:
    ld a,(temp_byte)
    call reset_timer
    ld a,(temp_byte)
    call add_vjob_if_required
  ret

  add_vjob_if_required:
    ; IN: A = animation slot number in ACM.
    ld (temp_byte),a
    ld hl,acm_pointer             ; HL = Start of pointer table.
    call offset_word_table        ; HL = Item holding ptr. to animation file.
    call get_word                 ; HL = Start (at t.o.c.) of animation file. 
    push hl                       ; Save base address of t.o.c.
      ld a,(temp_byte)
      call get_frame
    pop hl
    inc a                         ; Index past header.
    call offset_word_table
    call get_word                 ; Now HL is at the base of the current frame      
    inc hl                        ; Move past duration byte.
    ld a,(hl)                     ; Read true or false.
    cp FALSE
    ret z
      inc hl                      ; HL is at first byte of vjob pointer
      call get_word               ; HL is now the address of the vjob.
      call add_vjob
  ret
  
  
  is_vjob_required::
    ; Look up animation file to check whether a vjob is required for the 
    ; current frame.
    ; IN: A = animation slot number in ACM.
    ; OUT: A = TRUE/FALSE
    ld (temp_byte),a
    ld hl,acm_pointer             ; HL = Start of pointer table.
    call offset_word_table        ; HL = Item holding ptr. to animation file.
    call get_word                 ; HL = Start (at t.o.c.) of animation file. 
    push hl                       ; Save base address of t.o.c.
      ld a,(temp_byte)
      call get_frame
    pop hl
    inc a                         ; Index past header.
    call offset_word_table
    call get_word                 ; Now HL is at the base of the current frame      
    inc hl                        ; Move past duration byte.
    ld a,(hl)                     ; Read true or false, and return it in A.
  ret

  get_duration:
    ; Look up animation file to get duration of current frame
    ; IN: A = animation slot number in ACM.
    ; OUT: A = duration of current frame.
    ld (temp_byte),a
    ld hl,acm_pointer             ; HL = Start of pointer table.
    call offset_word_table        ; HL = Item holding ptr. to animation file.
    call get_word                 ; HL = Start (at t.o.c.) of animation file. 
    push hl                       ; Save base address of t.o.c.
      ld a,(temp_byte)
      call get_frame
    pop hl
    inc a                         ; Index past header.
    call offset_word_table
    call get_word                 ; Now HL is at the base of the current frame      
    ld a,(hl)                     ; This is where the duration is stored
  ret

  reset_timer:
    ; Reset timer to duration specified in file.
    ; IN: A = animation slot number in ACM.
    ld (temp_byte),a
    call get_duration
    push af
      ld a,(temp_byte)
      ld hl,acm_timer
      call offset_byte_table
    pop af
    ld (hl),a
  ret

  disable_animation:
    ; IN:  A = Slot number in ACM
    ld hl,acm_enabled
    call offset_byte_table
    ld a,FALSE
    ld (hl),a
  ret
  
  is_animation_at_max_frame:
    ; IN:  A = Slot number in ACM
    ; OUT: A = TRUE or FALSE.
    ld (temp_byte),a              ; Save the slot number.
    ld hl,acm_pointer             ; HL = Start of pointer table.
    call offset_word_table        ; HL = Item holding ptr. to animation file.
    call get_word                 ; HL = Start (at t.o.c.) of animation file. 
    call get_word                 ; HL = Header section in animation file.
    ld a,(hl)                     ; Load max frame into A.
    push af                       ; Save max frame.
      ld a,(temp_byte)            ; Get current frame of animation.
      call get_frame
      ld b,a                      ; Save it in B.
    pop af                        ; Retrieve the max frame.
    cp b                          ; Is current frame == max frame?
    jp nz,+
      ld a,TRUE
      ret
    +:
      ld a,FALSE
  ret

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

