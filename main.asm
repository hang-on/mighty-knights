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
  arthur instanceof actor
  arthur_clone_1 instanceof actor
  arthur_clone_2 instanceof actor
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

    .ifdef TEST_MODE
      jp test_bench
    .endif

    call initialize_vjobs
    call initialize_acm
    INITIALIZE_ACTOR cody, 0, 100, 100
    INITIALIZE_ACTOR arthur, 1, 130, 50
    INITIALIZE_ACTOR arthur_clone_1, 2, 130, 90
    INITIALIZE_ACTOR arthur_clone_2, 3, 130, 170

    ld a,0
    ld hl,cody_walking
    call set_animation

    ld a,1
    ld hl,arthur_walking
    call set_animation

    ld hl,arthur_walking_vjob
    call add_vjob

    
    call process_vjobs
    ;
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
    
    call process_vjobs
    
    ;
    ; -------------------------------------------------------------------------
    ; Begin general updating (UPDATE).
    call PSGFrame
    call PSGSFXFrame
    call refresh_sat_handler

    call process_animations

    ld a,0
    ld hl,cody
    call draw_actor

    ld a,1
    ld hl,arthur
    call draw_actor
    ld a,1
    ld hl,arthur_clone_1
    call draw_actor
    ld a,1
    ld hl,arthur_clone_2
    call draw_actor

  jp main_loop
.ends
.bank 2 slot 2
 ; ----------------------------------------------------------------------------
.section "Demo assets" free
; -----------------------------------------------------------------------------

  demo_palette:
    .db $00 $20 $12 $08 $06 $15 $2A $3F $13 $0B $0F $0C $38 $25 $3B $1B
    .db $23 $10 $12 $18 $06 $15 $2A $3F $13 $0B $0F $0C $38 $26 $27 $2F
    demo_palette_end:

  cody_walking_0_tiles:
    .include "bank_2/cody_walking_0_tiles.asm"
  cody_walking_1_and_3_tiles:
    .include "bank_2/cody_walking_1_and_3_tiles.asm"
  cody_walking_2_tiles:
    .include "bank_2/cody_walking_2_tiles.asm"


  .equ PLAYER_TILE_BANK 2
  .equ PLAYER_FIRST_TILE SPRITE_BANK_START + CHARACTER_SIZE
  .macro PLAYER_VJOB ARGS TILES, AMOUNT
    .db PLAYER_TILE_BANK
    .dw TILES
    .dw CHARACTER_SIZE*AMOUNT
    .dw PLAYER_FIRST_TILE
  .endm

  cody_walking_0_vjob:
    PLAYER_VJOB cody_walking_0_tiles, 8
  cody_walking_1_and_3_vjob:
    PLAYER_VJOB cody_walking_1_and_3_tiles, 8
  cody_walking_2_vjob:
    PLAYER_VJOB cody_walking_2_tiles, 8  
  
  layout_2x4:
    ; Y and X offsets to apply to the origin of an actor.
    .db -32, -8     ; XX
    .db -32, 0      ; XX
    .db -24, -8     ; XX
    .db -24, 0      ; XX
    .db -16, -8
    .db -16, 0
    .db -8, -8
    .db -8, 0

  layout_2x3_1b:
    .db -24, -8     ; XX
    .db -24, 0      ; XX
    .db -16, -8     ; XXX
    .db -16, 0
    .db -8, -8
    .db -8, 0
    .db -8, 8

  ; Animation file:
  cody_walking:
    ; Table of contents:
    .dw @header, @frame_0, @frame_1, @frame_2, @frame_3
    @header:
      .db 3                       ; Max frame.
      .db TRUE                    ; Looping.
    @frame_0:
      .db 10                      ; Duration.
      .db TRUE                    ; Require vjob?
      .dw cody_walking_0_vjob     ; Pointer to vjob.
      .db 8                       ; Size.
      .db 1                       ; Index of first tile.
      .dw layout_2x4              ; Pointer to layout.
    @frame_1:
      .db 10                      
      .db TRUE                    
      .dw cody_walking_1_and_3_vjob 
      .db 8                       
      .db 1                       
      .dw layout_2x4              
    @frame_2:
      .db 10                      
      .db TRUE                    
      .dw cody_walking_2_vjob 
      .db 8                       
      .db 1                       
      .dw layout_2x4              
    @frame_3:
      .db 10                      
      .db TRUE                    
      .dw cody_walking_1_and_3_vjob 
      .db 8                       
      .db 1                       
      .dw layout_2x4              


  arthur_walking_0_tiles:
    .include "bank_2/arthur_walking_0_tiles.asm"
  arthur_walking_1_and_3_tiles:
    .include "bank_2/arthur_walking_1_and_3_tiles.asm"
  arthur_walking_2_tiles:
    .include "bank_2/arthur_walking_2_tiles.asm"

  arthur_walking_vjob:
    .db 2
    .dw arthur_walking_0_tiles
    .dw 7 * CHARACTER_SIZE * 3
    .dw 10*CHARACTER_SIZE ; Load into position 10

  ; Animation file:
  arthur_walking:
    ; Table of contents:
    .dw @header, @frame_0, @frame_1, @frame_2, @frame_3
    @header:
      .db 3                       ; Max frame.
      .db TRUE                    ; Looping.
    @frame_0:
      .db 10                       ; Duration.
      .db FALSE                   ; Require vjob?
      .dw $0000                   ; Pointer to vjob.
      .db 7                       ; Size.
      .db 10                      ; Index of first tile.
      .dw layout_2x3_1b           ; Pointer to layout.
    @frame_1:
      .db 10                       ; Duration.
      .db FALSE                   ; Require vjob?
      .dw $0000                   ; Pointer to vjob.
      .db 7                       ; Size.
      .db 17                      ; Index of first tile.
      .dw layout_2x3_1b           ; Pointer to layout.
    @frame_2:
      .db 10                       ; Duration.
      .db FALSE                   ; Require vjob?
      .dw $0000                   ; Pointer to vjob.
      .db 7                       ; Size.
      .db 24                      ; Index of first tile.
      .dw layout_2x3_1b           ; Pointer to layout.
    @frame_3:
      .db 10                       ; Duration.
      .db FALSE                   ; Require vjob?
      .dw $0000                   ; Pointer to vjob.
      .db 7                       ; Size.
      .db 17                      ; Index of first tile.
      .dw layout_2x3_1b           ; Pointer to layout.




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