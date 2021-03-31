; main.asm
;.sdsctag 1.0, "Mighty Knights", "Hack n' slash", "hang-on Entertainment"
; -----------------------------------------------------------------------------
; GLOBAL DEFINITIONS
; -----------------------------------------------------------------------------
.include "sms_constants.asm"
.equ ENABLED $ff
.equ DISABLED 0
.equ TRUE $ff
.equ FALSE 0

; Remove comment to enable unit testing
;.equ TEST_MODE
.ifdef TEST_MODE
  .equ USE_TEST_KERNEL
.endif

; -----------------------------------------------------------------------------
.memorymap
; -----------------------------------------------------------------------------
  defaultslot 0
  slotsize $4000
  slot 0 $0000
  slot 1 $4000
  slot 2 $8000
  slotsize $2000
  slot 3 $c000
.endme
.rombankmap ; 128K rom
  bankstotal 8
  banksize $4000
  banks 8
.endro
;
.include "psglib.inc"
.include "mighty_knights_lib.asm"
.include "sub_workshop.asm"
.include "sub_tests.asm"        
; -----------------------------------------------------------------------------
.ramsection "main variables" slot 3
; -----------------------------------------------------------------------------
  temp_byte db                  ; Temporary variable - byte.
  temp_word db                  ; Temporary variable - word.
  ;
  vblank_counter db
  hline_counter db
  pause_flag db
  ;
  cody instanceof actor
  cody_animation instanceof animation ; eventually put in table

.ends
.org 0
.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Boot" force
; -----------------------------------------------------------------------------
  boot:
  di
  im 1
  ld sp,$dff0
  ;
  ; Initialize the memory control registers.
  ld de,$fffc
  ld hl,initial_memory_control_register_values
  ld bc,4
  ldir
  FILL_MEMORY $00
  ;
  jp init
  ;
  initial_memory_control_register_values:
    .db $00,$00,$01,$02
.ends
.org $0038
; ---------------------------------------------------------------------------
.section "!VDP interrupt" force
; ---------------------------------------------------------------------------
  push af
  push hl
    in a,CONTROL_PORT
    bit INTERRUPT_TYPE_BIT,a  ; HLINE or VBLANK interrupt?
    jp z,+
      ld hl,vblank_counter
      jp ++
    +:
      ld hl,hline_counter
    ++:
  inc (hl)
  pop hl
  pop af
  ei
  reti
.ends
.org $0066
; ---------------------------------------------------------------------------
.section "!Pause interrupt" force
; ---------------------------------------------------------------------------
  push af
    ld a,(pause_flag)
    cpl
    ld (pause_flag),a
  pop af
  retn
.ends
; -----------------------------------------------------------------------------
.section "main" free
; -----------------------------------------------------------------------------
  init:
  ; Run this function once (on game load/reset). 
    ;
    call PSGInit
    ld hl,adventure_awaits
    ;call PSGPlay
    ;
    call clear_vram
    ld hl,vdp_register_init
    call initialize_vdp_registers
    ;
    ld a,5
    ld b,BORDER_COLOR
    call set_register
    ;
    ld a,0
    ld b,demo_palette_end-demo_palette
    ld hl,demo_palette
    call load_cram

    call initialize_video_job_table
    ;
    ld hl,mockup_tiles_job
    call add_video_job
    ld hl,mockup_tilemap_job
    call add_video_job
    call process_video_job_table
    
    INITIALIZE_ACTOR cody, 0, 160, 70, cody_walking_0

    .ifdef TEST_MODE
      jp test_bench
    .endif

    jp +
      cody_anim_init:
      .db 0, 10
      .dw cody_walking_anim_script
    +:
    ld hl,cody_anim_init
    ld de,cody_animation
    call initialize_animation


    ei
    halt
    halt
    xor a
    ld (vblank_counter),a
    ;
    ld a,ENABLED
    call set_display
    ;
  jp main_loop
    vdp_register_init:
    .db %00100110  %10100000 $ff $ff $ff
    .db $ff $fb $f0 $00 $00 $ff
  ; ---------------------------------------------------------------------------
  main_loop:
    call wait_for_vblank
    ; -------------------------------------------------------------------------
    ; Begin vblank critical code (DRAW).
    call load_sat
    call process_video_job_table
    ;
    ; -------------------------------------------------------------------------
    ; Begin general updating (UPDATE).
    call PSGFrame
    call PSGSFXFrame
    call refresh_sat_handler


    ; FIXME: This needs to loop through all possible animations.
    ld hl,cody_animation
    call tick_animation
    ld (cody_animation.timer),a
    cp ANIM_TIMER_UP
    jp nz,+
      ld hl,cody_animation
      call get_next_frame
      ld (cody_animation.current_frame),a ; next frame
      ld hl,cody_animation
      call get_ticks_and_frame_pointer
      ld (cody_animation.timer),a
      ld a,0 ; hardcoded index in frame table (must be same as anim. index? - parallel)
      call set_frame
      
      ld a,(cody_animation.current_frame)
      ld hl,cody_walking_frame_video_job_list ; FIXME: Where do we know this from?
      call get_frame_video_job                ; Parallel 
      cp TRUE
      jp nz,+
        call add_video_job
    +:


    ld hl,cody
    call draw_actor

  jp main_loop
.ends
.bank 2 slot 2
 ; ----------------------------------------------------------------------------
.section "Demo assets" free
; -----------------------------------------------------------------------------
  .dstruct cody_walking animation 0, 10, cody_walking_anim_script
  
  cody_walking_anim_script:
    .db 3                       ; Max frame
    .db TRUE                    ; Looping
    .db 10                      ; Ticks to display frame
    .dw cody_walking_0          ; Frame
    .db 10    
    .dw cody_walking_1_and_3
    .db 10    
    .dw cody_walking_2
    .db 10    
    .dw cody_walking_1_and_3 

  cody_walking_frame_video_job_list:          
    .db TRUE                        ; Perform video job?
    .dw cody_walking_0_tiles_job    ; Pointer to video job or $0000 if FALSE
    .db TRUE
    .dw cody_walking_1_and_3_tiles_job
    .db TRUE
    .dw cody_walking_2_tiles_job
    .db TRUE
    .dw cody_walking_1_and_3_tiles_job
  
  
  demo_palette:
    .db $00 $20 $12 $08 $06 $15 $2A $3F $13 $0B $0F $0C $38 $25 $3B $1B
    .db $23 $10 $12 $18 $06 $15 $2A $3F $13 $0B $0F $0C $38 $26 $27 $2F
    demo_palette_end:

  layout_2x4:
    .db -32, -8, 1
    .db -32, 0, 2
    .db -24, -8, 3
    .db -24, 0, 4
    .db -16, -8, 5
    .db -16, 0, 6
    .db -8, -8, 7
    .db -8, 0, 8

  cody_walking_0_tiles:
    .include "bank_2/cody_walking_0_tiles.asm"
  cody_walking_1_and_3_tiles:
    .include "bank_2/cody_walking_1_and_3_tiles.asm"
  cody_walking_2_tiles:
    .include "bank_2/cody_walking_2_tiles.asm"

  .equ PLAYER_TILE_BANK 2
  .equ PLAYER_FIRST_TILE SPRITE_BANK_START + CHARACTER_SIZE
  .macro PLAYER_VIDEO_JOB ARGS TILES, AMOUNT
    .db PLAYER_TILE_BANK
    .dw TILES
    .dw CHARACTER_SIZE*AMOUNT
    .dw PLAYER_FIRST_TILE
  .endm
  
  cody_walking_0_tiles_job:
    PLAYER_VIDEO_JOB cody_walking_0_tiles, 8
  cody_walking_1_and_3_tiles_job:
    PLAYER_VIDEO_JOB cody_walking_1_and_3_tiles, 8
  cody_walking_2_tiles_job:
    PLAYER_VIDEO_JOB cody_walking_2_tiles, 8

  .dstruct cody_walking_0 frame 8,layout_2x4
  .dstruct cody_walking_1_and_3 frame 8,layout_2x4
  .dstruct cody_walking_2 frame 8,layout_2x4

  ; Mockup background of Village on Fire:
  .include "mockup_background_tilemap.asm"
    mockup_tilemap_job:
      .db 2
      .dw mockup_background_tilemap
      .dw VISIBLE_NAME_TABLE_SIZE
      .dw NAME_TABLE_START

  .include "mockup_background_tiles.asm"
    mockup_tiles_job:
      .db 2
      .dw mockup_background_tiles
      .dw 96*CHARACTER_SIZE
      .dw BACKGROUND_BANK_START

  adventure_awaits:
    .incbin "adventure_awaits_compr.psg"

.ends