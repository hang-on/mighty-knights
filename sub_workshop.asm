  .equ ACTOR_MAX 5 ;***
  
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

.equ ACM_SLOTS 8
.ramsection "Animation Control Matrix (ACM)" slot 3
  acm_enabled dsb ACM_SLOTS
  acm_frame dsb ACM_SLOTS
  acm_timer dsb ACM_SLOTS
  acm_label dsb ACM_SLOTS*2
.ends

.equ TBM_SLOTS 8
.ramsection "Tile Blaster Matrix (TBM)" slot 3 
  tileblaster_tasks db
  tbm_bank dsb TBM_SLOTS
  tbm_source dsb TBM_SLOTS*2
  tbm_destination dsb TBM_SLOTS*2
  tbm_size dsb TBM_SLOTS
.ends

.struct tileblaster_task
  bank db
  source dw
  destination dw
  size db
.endst

.section "Tileblasting OUTI" free
  .ifdef USE_TEST_KERNEL
      .equ SMALL_BLAST_SIZE_IN_BYTES CHARACTER_SIZE*4
      .equ MEDIUM_BLAST_SIZE_IN_BYTES CHARACTER_SIZE*8
      .equ LARGE_BLAST_SIZE_IN_BYTES CHARACTER_SIZE*12
      small_blast:
      medium_blast:
      large_blast:
      push hl
      pop ix ; save HL
      
      ; A holds the size
      cp SMALL_BLAST
      jp nz,+
        ld bc,SMALL_BLAST_SIZE_IN_BYTES
        jp ++
      +:
      cp MEDIUM_BLAST
      jp nz,+
        ld bc,MEDIUM_BLAST_SIZE_IN_BYTES
        jp ++
      +:
      cp LARGE_BLAST
      jp nz,++
        ld bc,LARGE_BLAST_SIZE_IN_BYTES
      ++:
      ld hl,test_kernel_bytes_written
      ld (hl),c
      inc hl
      ld (hl),b

      ld hl,test_kernel_destination
      ld (hl),e
      inc hl
      ld (hl),d
      ld hl,test_kernel_source
      push ix
      pop de
      ld (hl),e
      inc hl
      ld (hl),d

  .else
    large_blast:
      .rept CHARACTER_SIZE * 4
        outi
      .endr
    medium_blast:
      .rept CHARACTER_SIZE * 4
        outi
      .endr
    small_blast:
      .rept CHARACTER_SIZE * 4
        outi
      .endr
  .endif
  ret ; We are in the tileblasting subroutine here...
.ends


; -----------------------------------------------------------------------------
.section "Subroutine workshop" free
; -----------------------------------------------------------------------------
  .equ SMALL_BLAST 2
  .equ MEDIUM_BLAST 4
  .equ LARGE_BLAST 6

  add_tileblaster_task:
    ; IN: HL = Tileblaster task struct.
    ; Note: No overflow protection!
    push hl
    pop ix

    ld a,(tileblaster_tasks)
    ld hl,tbm_bank
    call offset_byte_table
    ld a,(ix+0)
    ld (hl),a

    ld a,(tileblaster_tasks)
    ld hl,tbm_size
    call offset_byte_table
    ld a,(ix+5)
    ld (hl),a
    
    ld a,(tileblaster_tasks)
    ld hl,tbm_destination
    call offset_word_table
    ld a,(ix+3)
    ld (hl),a
    inc hl
    ld a,(ix+4)
    ld (hl),a

    ld a,(tileblaster_tasks)
    ld hl,tbm_source
    call offset_word_table
    ld a,(ix+1)
    ld (hl),a
    inc hl
    ld a,(ix+2)
    ld (hl),a


    ld hl,tileblaster_tasks
    inc (hL)
  ret

  blast_tiles:
    .rept TBM_SLOTS
      ld a,(tileblaster_tasks)
      cp 0
      jp z,_tileblasting_finished

      ; OK, still jobs to process.
      dec a
      ld (tileblaster_tasks),a
      ld hl,tbm_bank
      call offset_byte_table
      ld a,(hl)
      SELECT_BANK_IN_REGISTER_A

      ld a,(tileblaster_tasks)
      ld hl,tbm_destination
      call offset_word_table
      call get_word ; HL now holds destination...
      call setup_vram_write

      ld a,(tileblaster_tasks)
      ld hl,tbm_source
      call offset_word_table
      call get_word ; HL now holds source...
      push hl
        ld a,(tileblaster_tasks)
        ld hl,tbm_size
        call offset_byte_table
        ld a,(hl)
        ld c,DATA_PORT
      pop hl
      cp SMALL_BLAST
      jp nz,+
        call small_blast
        jp ++
      +
      cp MEDIUM_BLAST
      jp nz,+
        call medium_blast
        jp ++
      +:
      cp LARGE_BLAST
      jp nz,+
        call large_blast
        jp ++
      ++:
    .endr


    _tileblasting_finished:
  ret
  



  get_vcounter:
    ; Read the vcounter port and store it's value in a variable and in A.
    ; IN: HL = Pointer to variable in RAM.
    ; OUT: Value of vcounter port in A.
    in a,V_COUNTER_PORT
    ld (hl),a
  ret
  
  draw_actor:
    ; An actor can take different forms depending on which animation it is
    ; linked with. This is set (and thus can vary) on a frame-by-frame basis.
    ; draw_actor uses "add_sprite" to move sprites into the SAT buffer.
    ; IN: A  = Animation slot to use for drawing.
    ;     HL = Actor.
    inc hl                ; Move past index.
    ld d,(hl)             ; Get actor origin Y into D. 
    inc hl
    ld e,(hl)             ; Get actor origin X into D.
    call get_layout       ; Sets A (first char), B (num. chars) and HL (label).
    push hl               ; Add sprite needs the offset data in IX.
    pop ix
    ld c,a                ; Save index of first char.
    -:
      call add_sprite     ; This does not alter B and C! 
      inc c               ; Next char
      inc ix              ; Next y,x-offset pair.
      inc ix
    djnz -                ; Loop through all chars in frame.
  ret

  get_layout:
    ; Look up animation file to get layout of current frame
    ; IN: A = animation slot number in ACM.
    ; OUT: HL = Base address of layout.
    ;      B = Size of layout (in tiles).
    ;      A = Index of first char.
    ld (temp_byte),a
    ld hl,acm_label               ; HL = Start of pointer table.
    call offset_word_table        ; HL = Item holding ptr. to animation file.
    call get_word                 ; HL = Start (at t.o.c.) of animation file. 
    push hl                       ; Save base address of t.o.c.
      ld a,(temp_byte)
      call get_frame
    pop hl
    inc a                         ; Index past header.
    call offset_word_table
    call get_word                 ; Now HL is at the base of the current frame      
    push hl
    pop ix
    ld b,(ix+4)                     ; Size    
    ld a,(ix+5)                     ; First char
    ld l,(ix+6)
    ld h,(ix+7)
  ret


  get_animation_label:
    ; Get the label of the animation file connected to the given slot.
    ; IN:  A = Slot number in ACM
    ; OUT: HL = Label of animation file linked to the given slot.
    ld hl,acm_label
    call offset_word_table
    call get_word
  ret

  set_animation:
    ; Setup a given animation in a specified slot in the ACM.
    ; IN: A = Slot.
    ;     HL = Animation label
    ld (temp_byte),a
    push hl                     ; Save the label for later.
    pop ix
    ld a,(temp_byte)
    call enable_animation
    ld a,(temp_byte)
    ld hl,acm_label
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

  add_vjob_if_required: ; FIXME: vjobs replaced with tile blasts.
    ; IN: A = animation slot number in ACM.
    ld (temp_byte),a
    ld hl,acm_label             ; HL = Start of pointer table.
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
      ;call add_vjob
      call add_tileblaster_task
  ret
  
  
  is_vjob_required::
    ; Look up animation file to check whether a vjob is required for the 
    ; current frame.
    ; IN: A = animation slot number in ACM.
    ; OUT: A = TRUE/FALSE
    ld (temp_byte),a
    ld hl,acm_label             ; HL = Start of pointer table.
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
    ld hl,acm_label             ; HL = Start of pointer table.
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

  enable_animation:
    ; IN:  A = Slot number in ACM
    ld hl,acm_enabled
    call offset_byte_table
    ld a,TRUE
    ld (hl),a
  ret
  
  is_animation_at_max_frame:
    ; IN:  A = Slot number in ACM
    ; OUT: A = TRUE or FALSE.
    ld (temp_byte),a              ; Save the slot number.
    ld hl,acm_label             ; HL = Start of pointer table.
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
    ld hl,acm_label             ; HL = Start of pointer table.
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

