; main.asm
;
.sdsctag 1.0, "Mighty Knights", "Hack n' slash", "hang-on Entertainment"



;
; Declare constants, global variables etc.
; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; HARDWARE DEFINITIONS
; -----------------------------------------------------------------------------
; Video memory and initialization:
.equ NAME_TABLE_START $3800
.equ VISIBLE_NAME_TABLE_SIZE 2*32*24
.equ FULL_NAME_TABLE_SIZE 2*32*28
.equ SPRITE_BANK_START $0000
.equ BACKGROUND_BANK_START $2000
.equ CHARACTER_SIZE 32
;
.equ COLOR_0 0
.equ COLOR_1 1
.equ COLOR_2 2
.equ COLOR_3 3
.equ COLOR_4 4
.equ COLOR_5 5
.equ COLOR_6 6
.equ COLOR_7 7
.equ COLOR_8 8
.equ COLOR_9 9
.equ COLOR_10 10
.equ COLOR_11 11
.equ COLOR_12 12
.equ COLOR_13 13
.equ COLOR_14 14
.equ COLOR_15 15
.equ COLOR_16 16
.equ COLOR_17 17
.equ COLOR_18 18
.equ COLOR_19 19
.equ COLOR_20 20
.equ COLOR_21 21
.equ COLOR_22 22
.equ COLOR_23 23
.equ COLOR_24 24
.equ COLOR_25 25
.equ COLOR_26 26
.equ COLOR_27 27
.equ COLOR_28 28
.equ COLOR_29 29
.equ COLOR_30 30
.equ COLOR_31 31
;
.equ SAT_Y_START $3f00
.equ SAT_XC_START SAT_Y_START+64+64
.equ SPRITE_TERMINATOR $d0
.equ NTSC 0
.equ PAL 1
.equ FIRST_LINE_OF_VBLANK 192
;
.equ PLAYER_SIZE 4          ; Number of tiles not part of asc/desc flicker.
.equ ASCENDING 0
.equ DESCENDING $ff
;
;
.equ INTERRUPT_TYPE_BIT 7
;
.equ REGISTER_0 0
.equ REGISTER_1 1
.equ REGISTER_2 2
.equ REGISTER_3 3
.equ REGISTER_4 4
.equ REGISTER_5 5
.equ REGISTER_6 6
.equ REGISTER_7 7
.equ REGISTER_8 8
.equ REGISTER_9 9
.equ REGISTER_10 10
;
; The following register constants are named based on how they differ from the
; standard values initialized by the hardware.
.equ NORMAL_DISPLAY %11100000
;
; Memory map and initialization:
.equ RAM_START $c000
.equ INITIAL_STACK_ADDRESS $dff0

; Port communication and control:
.equ SYSTEM_CONTROL_PORT $00          ; GG: start, region, ntsc/pal.
.equ START_BUTTON_BIT %10000000       ; 0 = Switch is on!
.equ INPUT_PORT_1 $dc
.equ INPUT_PORT_2 $dd
.equ PSG_PORT $7f
.equ V_COUNTER_PORT $7e
.equ CONTROL_PORT $BF
.equ DATA_PORT $BE
.equ VRAM_WRITE_COMMAND %01000000
.equ VRAM_READ_COMMAND %00000000
.equ REGISTER_WRITE_COMMAND %10000000
.equ CRAM_WRITE_COMMAND %11000000
.equ VRAM_SIZE $4000                  ; 16K
;
.equ HORIZONTAL_SCROLL_REGISTER 8
.equ VERTICAL_SCROLL_REGISTER 9
.equ RASTER_INTERRUPT_REGISTER 10

; Banks / ROM / External RAM control:
.equ SET_EXTRAM_BIT %00001000
.equ RESET_EXTRAM_BIT %11110111
.equ EXTRAM_START $8000
.equ EXTRAM_SIZE $4000
.equ SLOT_2_CONTROL $ffff
.equ BANK_CONTROL $fffc

; CRT screen values:
.equ CRT_LEFT_BORDER 0
.equ CRT_RIGHT_BORDER 255
.equ CRT_TOP_BORDER 0
.equ CRT_BOTTOM_BORDER 191

; LCD screen values:
.equ LCD_RIGHT_BORDER (6*8)+(20*8)
.equ LCD_LEFT_BORDER 6*8
.equ LCD_TOP_BORDER 3*8
.equ LCD_BOTTOM_BORDER (3*8)+(18*8)
.equ LCD_WIDTH 20*8
.equ LCD_HEIGHT 18*8

; Invisible area:
.equ INVISIBLE_AREA_TOP_BORDER 192
.equ INVISIBLE_AREA_BOTTOM_BORDER 224
; -----------------------------------------------------------------------------
; SOFTWARE DEFINITIONS
; -----------------------------------------------------------------------------
.equ TRUE $ff
.equ FALSE 0
.equ ENABLED $ff
.equ DISABLED 0
.equ FLAG_SET $ff
.equ FLAG_RESET $00
.equ PAUSE_FLAG_RESET $00
.equ PAUSE_FLAG_SET $ff
.equ UNUSED_BYTE $0
.equ UNUSED_WORD $0000
.equ PERCENT_CHANCE_50 128
.equ PERCENT_CHANCE_100 255
;
; =============================================================================
; M A C R O S
; =============================================================================
; -----------------------------------------------------------------------------
.macro SELECT_EXTRAM
; -----------------------------------------------------------------------------
  ; Select external RAM: Now memory addresses from $8000 - $c000 (slot 2)
  ; are mapped to the battery-backed RAM, and thus its contents are saved
  ; between sessions.
  push af
  ld a,(BANK_CONTROL)
  or SET_EXTRAM_BIT
  ld (BANK_CONTROL),a
  pop af
.endm
; -----------------------------------------------------------------------------
.macro SELECT_ROM
; -----------------------------------------------------------------------------
  ; Select ROM: Used to switch mapping in slot 2 ($8000 - $c000) back to ROM
  ; if external RAM was selected.
  push af
  ld a,(BANK_CONTROL)
  and RESET_EXTRAM_BIT
  ld (BANK_CONTROL),a
  pop af
.endm
; -----------------------------------------------------------------------------
.macro SELECT_BANK
; -----------------------------------------------------------------------------
  ; Select a bank for slot 2, i.e. SELECT_BANK 4.
  push af
  ld a,\1
  ld (SLOT_2_CONTROL),a
  pop af
.endm
; -----------------------------------------------------------------------------
.macro SELECT_BANK_IN_REGISTER_A
; -----------------------------------------------------------------------------
  ; Select a bank for slot 2, - put value in register A.
  ld (SLOT_2_CONTROL),a
.endm
; -----------------------------------------------------------------------------
.macro SAVE_REGISTERS
; -----------------------------------------------------------------------------
  ; Save all registers, except IX and IY
  push af
  push bc
  push de
  push hl
  push ix
  push iy
.endm
; -----------------------------------------------------------------------------
.macro RESTORE_REGISTERS
; -----------------------------------------------------------------------------
  ; Restore all registers, except IX and IY
  pop iy
  pop ix
  pop hl
  pop de
  pop bc
  pop af
.endm
;
; -----------------------------------------------------------------------------
.memorymap
; -----------------------------------------------------------------------------
  defaultslot 0
  slotsize $4000
  slot 0 $0000
  slot 1 $4000
  slot 2 $8000
  slotsize $2000
  slot 3 RAM_START
.endme
.rombankmap ; 128K rom
  bankstotal 8
  banksize $4000
  banks 8
.endro


;        
; -----------------------------------------------------------------------------
.ramsection "main variables" slot 3
; -----------------------------------------------------------------------------
  temp_byte db                  ; Temporary variable - byte.
  temp_word db                  ; Temporary variable - word.
  ;
  VDPStatus db
  vblank_counter db
  hline_counter db
  pause_flag db
  input_ports dw
  ;
  SpriteBufferY dsb 64
  SpriteBufferXC dsb 128
  NextFreeSprite db
  SATLoadMode db             ; Ascending or descending - for flickering.
  ;
  demosprite_x db
  demosprite_y db
  demosprite_char db
.ends
;
.include "mighty_knights_lib.asm"
;.include "bluelib.asm"        ; General library with foundation stuff.


.org 0
.bank 0 slot 0
; -----------------------------------------------------------------------------
.section "Boot" force
; -----------------------------------------------------------------------------
  boot:
  di
  im 1
  ld sp,INITIAL_STACK_ADDRESS
  ;
  ; Initialize the memory control registers.
  ld de,$fffc
  ld hl,initial_memory_control_register_values
  ld bc,initial_memory_control_register_values_end-initial_memory_control_register_values
  ldir
  ;
  ;
  ;call clear_vram
  ;
  jp init
  ;
  initial_memory_control_register_values:
    .db $00,$00,$01,$02
    initial_memory_control_register_values_end:
  ;
.ends


.org $0038
; ---------------------------------------------------------------------------
.section "!VDP interrupt" force
; ---------------------------------------------------------------------------
  push af
  push hl
    in a,CONTROL_PORT
    bit INTERRUPT_TYPE_BIT,a
    jp z,+
      ; VBlank interrupt.
      ld hl,vblank_counter
      inc (hl)
      jp ++
    +:
      ; H-Line interrupt.
      ld hl,hline_counter
      inc (hl)
    ++:
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
    ; Run this function once (on game load). Assume we come here from bluelib
    ; boot code with initialized vram and memory control registers (INIT).
    ;
    ld a,COLOR_0
    ld b,demo_palette_end-demo_palette
    ld hl,demo_palette
    call load_cram
    ;
    ld bc,CHARACTER_SIZE
    ld de,SPRITE_BANK_START + CHARACTER_SIZE
    ld hl,c_character
    call load_vram
    ;
    ld a,16
    ld (demosprite_y),a
    ld a,16
    ld (demosprite_x),a
    ld a,1
    ld (demosprite_char),a
    ;
    ei
    halt
    halt
    xor a
    ld (vblank_counter),a
    ;
    ld a,NORMAL_DISPLAY
    ld b,1
    call set_register
    ;
  jp main_loop
  ;
  ; ---------------------------------------------------------------------------
  main_loop:
    ;
    ; Wait until vblank interrupt handler increments counter.
    ld hl,vblank_counter
    -:
      ld a,(hl)
      cp 0
    jp z,-
    ; Reset counter.
    xor a
    ld (hl),a
    ;
    ; -------------------------------------------------------------------------
    ; Begin vblank critical code (DRAW).
    call bluelib_utilize_vblank
    ;
    ; -------------------------------------------------------------------------
    ; Begin general updating (UPDATE).
    ;call bluelib_update_framework
    call start_sat_manager
    ;
    ld a,(demosprite_x)
    ld c,a
    ld a,(demosprite_y)
    ld b,a
    ld a,(demosprite_char)
    call add_sprite
    ;
  jp main_loop
  ;
  ; ---------------------------------------------------------------------------
  ;
  ; ---------------------------------------------------------------------------
.ends
;
;
; Data.
.bank 1 slot 1
; -----------------------------------------------------------------------------
.section "Demo assets" free
; -----------------------------------------------------------------------------
  demo_palette:
    .db $00 $18 $12 $18 $06 $15 $2A $3F $13 $0B $0F $0C $38 $26 $27 $2F
    .db $00 $10 $12 $18 $06 $15 $2A $3F $13 $0B $0F $0C $38 $26 $27 $2F
    demo_palette_end:
  ;
  c_character:
    .db $ff $00 $ff $00
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $00 $c0 $c0
    .db $00 $ff $00 $00
.ends
