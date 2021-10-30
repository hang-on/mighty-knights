arthur_animations:
  .dw arthur_idle

  .equ PLAYER_TILE_BANK :arthur_animations
  .equ ADDRESS_OF_PLAYER_FIRST_TILE SPRITE_BANK_START + CHARACTER_SIZE
  .equ INDEX_OF_PLAYER_FIRST_TILE ADDRESS_OF_PLAYER_FIRST_TILE/CHARACTER_SIZE

  arthur_idle:
    ; Table of contents:
    .dw @header, @frame_0
    @header:
      .db 0                           ; Max frame.
      .db FALSE                       ; Looping.
    @frame_0:
      .db 7                           ; Duration.
      .db TRUE                        ; Require tileblast?
      .db PLAYER_TILE_BANK            ; Blast: Tile bank.
      .dw arthur_idle_tiles       ; Blast: Tiles.
      .dw ADDRESS_OF_PLAYER_FIRST_TILE; Blast: Addx of first tile in tile bank.
      .db XXXLARGE_BLAST                ; Blast: Blast size.
      .db 18                          ; Size (number of tiles in frame).
      .db INDEX_OF_PLAYER_FIRST_TILE  ; Index of first tile.
      .dw arthur_idle_layout      ; Pointer to layout.


    .include "bank_2/arthur/arthur_layouts.asm"
    arthur_idle_tiles:
    .include "bank_2/arthur/idle/arthur_idle_tiles.inc"



