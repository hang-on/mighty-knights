

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

  fake_video_job_table: 
    .dw video_job_0
    .dw video_job_1
  fake_video_job_table_index:
    .db 0
  
  .dstruct video_job_0 instanceof video_job 2, multicolor_c, multicolor_c_size, $1234
  .dstruct video_job_1 instanceof video_job 2, multicolor_c, multicolor_c_size, $5678
  
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
  jp +
    fake_index:
      .db 0
    fake_job_table:
      .dw video_job_0
      .dw video_job_1
  +:
  ld a,(fake_index)
  ld hl,fake_job_table
  call offset_word_table
  call get_word
  ASSERT_HL_EQUALS video_job_0

  jp +
    fake_index_1:
      .db 1
    fake_job_table_1:
      .dw video_job_0
      .dw video_job_1
  +:
  ld a,(fake_index_1)
  ld hl,fake_job_table_1
  call offset_word_table
  call get_word
  ASSERT_HL_EQUALS video_job_1

  jp +
    .dstruct video_job_2 video_job 2, multicolor_c, multicolor_c_size, $1234
  +:
  RESET_TEST_KERNEL
  ld hl,video_job_2
  call run_video_job
  ld a,(test_kernel_bank)
  ASSERT_A_EQUALS 2
  ld hl,test_kernel_destination
  call get_word
  ASSERT_HL_EQUALS $1234
  ld hl,test_kernel_bytes_written
  call get_word ;more like get value, or ptr2value16
  ASSERT_HL_EQUALS multicolor_c_size
  ld hl,test_kernel_source
  call get_word
  ASSERT_HL_EQUALS multicolor_c

  jp +
    fake_index_2:
      .db 1
    fake_job_table_2:
      .dw video_job_0
  +:
  RESET_TEST_KERNEL
  ld a,(fake_index_2)
  ld b,a
  -:
    push bc
      ld a,b
      dec a
      ld hl,fake_job_table_2
      call offset_word_table
      call get_word
      call run_video_job
    pop bc
  djnz -
  ld hl,test_kernel_destination
  call get_word
  ASSERT_HL_EQUALS $1234

  jp +
    fake_video_jobs_3:
      .db 2
    fake_job_table_3:
      .dw video_job_0
      .dw video_job_1
  +:
  RESET_TEST_KERNEL
  ld a,(fake_video_jobs_3)
  ; todo: test if no jobs...
  -:
    push bc
      ld a,b
      ld hl,fake_job_table_3
      call offset_word_table
      call get_word
      call run_video_job
    pop bc
  dec b
  jp nz,-
  ld hl,test_kernel_destination
  call get_word
  ASSERT_HL_EQUALS $5678

  jp +
    fake_video_jobs_4:
      .db 2
    fake_job_table_4:
      .dw video_job_0
      .dw video_job_1
  +:
  RESET_TEST_KERNEL
  ; load the test data into the correct memory position (set up parameters)...
  ld a,(fake_video_jobs_4)
  ld (video_jobs),a
  ld bc, 4
  ld hl,fake_job_table_4
  ld de,video_job_table
  ldir
  ;
  call process_video_job_table
  ld hl,test_kernel_destination
  call get_word
  ASSERT_HL_EQUALS $5678



  
  ; Test reset test kernel
  RESET_TEST_KERNEL
  ld hl,test_kernel_destination
  call get_word
  ASSERT_HL_EQUALS $0000


  .macro SETUP_VIDEO_JOB_TEST
    RESET_TEST_KERNEL
    ; Provide number of jobs, and job items in table
    ld a,\1
    ld (video_jobs),a
    ld bc, 2*(NARGS-1)
    jp +
      table_\@:
      .rept NARGS-1
        .shift
        .dw \1  
      .endr
    +:
    ld hl,table_\@
    ld de,video_job_table
    ldir
  .endm

  SETUP_VIDEO_JOB_TEST 2, video_job_0, video_job_1
  call process_video_job_table
  ld hl,test_kernel_destination
  call get_word
  ASSERT_HL_EQUALS $5678

  ; Test no jobs
  SETUP_VIDEO_JOB_TEST 0, video_job_0, video_job_1
  call process_video_job_table
  ld hl,test_kernel_destination
  call get_word
  ASSERT_HL_EQUALS $0000

  ; Test job 1 of two
  SETUP_VIDEO_JOB_TEST 1, video_job_0, video_job_1
  call process_video_job_table
  ld hl,test_kernel_destination
  call get_word
  ASSERT_HL_EQUALS $1234

  jp +
    .dstruct video_job_3 video_job 2, multicolor_c, multicolor_c_size, $1111
  +:

  ; Test job 1 of three
  SETUP_VIDEO_JOB_TEST 1, video_job_0, video_job_1, video_job_3
  call process_video_job_table
  ld hl,test_kernel_destination
  call get_word
  ASSERT_HL_EQUALS $1234

  ; Test job three of three
  SETUP_VIDEO_JOB_TEST 3, video_job_0, video_job_1, video_job_3
  call process_video_job_table
  ld hl,test_kernel_destination
  call get_word
  ASSERT_HL_EQUALS $1111

  ; Test no jobs, but three (old) items on the list
  SETUP_VIDEO_JOB_TEST 0, video_job_0, video_job_1, video_job_3
  call process_video_job_table
  ld hl,test_kernel_destination
  call get_word
  ASSERT_HL_EQUALS $0000

  ; Full test of last of two jobs, but three (old) items on the list
  SETUP_VIDEO_JOB_TEST 2, video_job_0, video_job_1, video_job_3
  call process_video_job_table
  ld a,(test_kernel_bank)
  ASSERT_A_EQUALS 2
  ld hl,test_kernel_destination
  call get_word
  ASSERT_HL_EQUALS $5678
  ld hl,test_kernel_bytes_written
  call get_word ;
  ASSERT_HL_EQUALS multicolor_c_size
  ld hl,test_kernel_source
  call get_word
  ASSERT_HL_EQUALS multicolor_c

  jp +
    .dstruct video_job_4 video_job 2, multicolor_c, multicolor_c_size, $4444
  +:

  ; Test video job table format
  SETUP_VIDEO_JOB_TEST 1, video_job_0
  ld hl,video_job_table
  call get_word
  ASSERT_HL_EQUALS video_job_0

  ; Test video job table format - with three jobs
  SETUP_VIDEO_JOB_TEST 3, video_job_0, video_job_1, video_job_2
  ld a,(video_jobs)
  dec a ; take it back to the last of the existing entries
  ld hl,video_job_table
  call offset_word_table
  call get_word
  ASSERT_HL_EQUALS video_job_2

  ; Test add video job - with three jobs
  SETUP_VIDEO_JOB_TEST 3, video_job_0, video_job_1, video_job_2
  ld hl,video_job_4
  call add_video_job

  ld a,(video_jobs)
  dec a ; take it back to the last of the existing entries
  ld hl,video_job_table
  call offset_word_table
  call get_word
  ASSERT_HL_EQUALS video_job_4


  ; Test add video job - with 0 jobs but filled table
  SETUP_VIDEO_JOB_TEST 0, video_job_0, video_job_1, video_job_2
  ld hl,video_job_4
  call add_video_job
  ;
  ld a,(video_jobs)
  dec a ; take it back to the last of the existing entries
  ld hl,video_job_table
  call offset_word_table
  call get_word
  ASSERT_HL_EQUALS video_job_4

  ; Test add video job - prevent overflow
  SETUP_VIDEO_JOB_TEST 10, video_job_0, video_job_1, video_job_2, video_job_0, video_job_1, video_job_2, video_job_0, video_job_1, video_job_2, video_job_0
  ld hl,video_job_4
  call add_video_job
  ;
  ld a,(video_jobs)
  dec a ; take it back to the last of the existing entries
  ld hl,video_job_table
  call offset_word_table
  call get_word
  ASSERT_HL_EQUALS video_job_0

  jp +
    .dstruct arthur_standing_0_job video_job 2, arthur_standing_0_tiles, CHARACTER_SIZE*7, SPRITE_BANK_START + CHARACTER_SIZE
  +:
  ; Test add video job - real arthur
  SETUP_VIDEO_JOB_TEST 0
  ld hl,arthur_standing_0_job
  call add_video_job
  ;
  ld a,(video_jobs)
  dec a ; take it back to the last of the existing entries
  ld hl,video_job_table
  call offset_word_table
  call get_word
  ASSERT_HL_EQUALS arthur_standing_0_job

    ; Full test of arthur job
  SETUP_VIDEO_JOB_TEST 1, arthur_standing_0_job
  call process_video_job_table
  ld a,(test_kernel_bank)
  ASSERT_A_EQUALS 2
  ld hl,test_kernel_destination
  call get_word
  ASSERT_HL_EQUALS SPRITE_BANK_START + CHARACTER_SIZE
  ld hl,test_kernel_bytes_written
  call get_word ;
  ASSERT_HL_EQUALS CHARACTER_SIZE*7
  ld hl,test_kernel_source
  call get_word
  ASSERT_HL_EQUALS arthur_standing_0_tiles


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
