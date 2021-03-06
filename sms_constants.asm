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