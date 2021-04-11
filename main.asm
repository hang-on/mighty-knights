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
.include "animations_lib.asm"
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
  
  critical_routines_finish_at db

  arthur instanceof actor

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

    ld a,2
    ld hl,test_background_tiles
    ld de,BACKGROUND_BANK_START
    ld bc,test_background_tiles_end - test_background_tiles
    call load_vram

    ld a,2
    ld hl,test_background_tilemap
    ld de,NAME_TABLE_START
    ld bc,VISIBLE_NAME_TABLE_SIZE
    call load_vram



    call initialize_acm
    INITIALIZE_ACTOR arthur, 0, 130, 50


    ld a,0
    ld hl,arthur_standing
    call set_animation

    ld a,2
    ld hl,arthur_standing_tiles
    ld de,ADDRESS_OF_PLAYER_FIRST_TILE
    ld bc, 16*CHARACTER_SIZE
    call load_vram

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
    call blast_tiles
    
    ld hl,critical_routines_finish_at
    call get_vcounter
    ;
    ; -------------------------------------------------------------------------
    ; Begin general updating (UPDATE).
    call PSGFrame
    call PSGSFXFrame
    call refresh_sat_handler

    call process_animations

    ld a,0
    ld hl,arthur
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

  .equ PLAYER_TILE_BANK 2
  .equ ADDRESS_OF_PLAYER_FIRST_TILE SPRITE_BANK_START + CHARACTER_SIZE
  .equ INDEX_OF_PLAYER_FIRST_TILE ADDRESS_OF_PLAYER_FIRST_TILE/CHARACTER_SIZE

  arthur_standing_tiles:
    .include "bank_2/arthur_standing_tiles.asm"

  test_background_tiles:
    .include "bank_2/test_background_tiles.asm"
  test_background_tiles_end:    
  test_background_tilemap:
  .include "bank_2/test_background_tilemap.asm"
  test_background_tilemap_end:
  

  adventure_awaits:
    .incbin "adventure_awaits_compr.psg"

.ends