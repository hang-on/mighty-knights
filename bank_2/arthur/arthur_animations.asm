arthur_animations:

  .equ PLAYER_TILE_BANK :arthur_animations
  .equ ADDRESS_OF_PLAYER_FIRST_TILE SPRITE_BANK_START + CHARACTER_SIZE
  .equ INDEX_OF_PLAYER_FIRST_TILE ADDRESS_OF_PLAYER_FIRST_TILE/CHARACTER_SIZE

  arthur_standing:
    ; Table of contents:
    .dw @header, @frame_0
    @header:
      .db 0                           ; Max frame.
      .db FALSE                       ; Looping.
    @frame_0:
      .db 7                           ; Duration.
      .db TRUE                        ; Require tileblast?
      .db PLAYER_TILE_BANK            ; Blast: Tile bank.
      .dw arthur_standing_tiles       ; Blast: Tiles.
      .dw ADDRESS_OF_PLAYER_FIRST_TILE; Blast: Addx of first tile in tile bank.
      .db XLARGE_BLAST                ; Blast: Blast size.
      .db 14                          ; Size (number of tiles in frame).
      .db INDEX_OF_PLAYER_FIRST_TILE  ; Index of first tile.
      .dw arthur_standing_layout      ; Pointer to layout.

  arthur_standing_left:
    ; Table of contents:
    .dw @header, @frame_0
    @header:
      .db 0                           ; Max frame.
      .db FALSE                       ; Looping.
    @frame_0:
      .db 7                           ; Duration.
      .db TRUE                        ; Require tileblast?
      .db PLAYER_TILE_BANK            ; Blast: Tile bank.
      .dw arthur_standing_left_tiles  ; Blast: Tiles.
      .dw ADDRESS_OF_PLAYER_FIRST_TILE; Blast: Addx of first tile in tile bank.
      .db XLARGE_BLAST                ; Blast: Blast size.
      .db 14                          ; Size (number of tiles in frame).
      .db INDEX_OF_PLAYER_FIRST_TILE  ; Index of first tile.
      .dw arthur_standing_left_layout ; Pointer to layout.


    .include "bank_2/arthur/standing/tiles.asm"

    arthur_standing_layout:
      .db -56, -8      
      .db -48, -8      
      .db -40, -12     
      .db -40, -4      
      .db -32, -12     
      .db -32, -4       
      .db -24, -12
      .db -24, -4
      .db -16, -12
      .db -16, -4
      .db -16, 4
      .db -8, -12
      .db -8, -4
      .db -8, 4

    arthur_standing_left_layout:
      .db -56, 0      
      .db -48, 0      
      .db -40, -4     
      .db -40, 4      
      .db -32, -4     
      .db -32, 4       
      .db -24, -4
      .db -24, 4
      .db -16, -12
      .db -16, -4
      .db -16, 4
      .db -8, -12
      .db -8, -4
      .db -8, 4


  arthur_walking:
    ; Table of contents:
    .dw @header, @frame_0, @frame_1, @frame_2, @frame_3
    @header:
      .db 3                           ; Max frame.
      .db TRUE                        ; Looping.
    @frame_0:
      .db 7                           ; Duration.
      .db TRUE                        ; Require tileblast?
      .db PLAYER_TILE_BANK            ; Blast: Tile bank.
      .dw arthur_walking_0_tiles      ; Blast: Tiles.
      .dw ADDRESS_OF_PLAYER_FIRST_TILE; Blast: Addx of first tile in tile bank.
      .db XLARGE_BLAST                ; Blast: Blast size.
      .db 13                          ; Size.
      .db INDEX_OF_PLAYER_FIRST_TILE  ; Index of first tile.
      .dw arthur_walking_layout_0     ; Pointer to layout.
    @frame_1:
      .db 8                       
      .db TRUE                   
      .db PLAYER_TILE_BANK            ; Blast: Tile bank.
      .dw arthur_walking_1_tiles      ; Blast: Tiles.
      .dw ADDRESS_OF_PLAYER_FIRST_TILE; Blast: Addx of first tile in tile bank.
      .db XLARGE_BLAST                ; Blast: Blast size.
      .db 14                       
      .db INDEX_OF_PLAYER_FIRST_TILE                        
      .dw arthur_walking_layout_1          
    @frame_2:
      .db 7                       
      .db TRUE                   
      .db PLAYER_TILE_BANK            ; Blast: Tile bank.
      .dw arthur_walking_2_tiles      ; Blast: Tiles.
      .dw ADDRESS_OF_PLAYER_FIRST_TILE; Blast: Addx of first tile in tile bank.
      .db XLARGE_BLAST                ; Blast: Blast size.
      .db 12                       
      .db INDEX_OF_PLAYER_FIRST_TILE                        
      .dw arthur_walking_layout_2          
    @frame_3:
      .db 8                       
      .db TRUE                   
      .db PLAYER_TILE_BANK            ; Blast: Tile bank.
      .dw arthur_walking_3_tiles      ; Blast: Tiles.
      .dw ADDRESS_OF_PLAYER_FIRST_TILE; Blast: Addx of first tile in tile bank.
      .db XLARGE_BLAST                ; Blast: Blast size.
      .db 14                       
      .db INDEX_OF_PLAYER_FIRST_TILE                        
      .dw arthur_walking_layout_3          
    
    .include "bank_2/arthur/walking/tiles.asm"

    arthur_walking_layout_0:
      .db -56, -11      
      .db -48, -11
      .db -48, -3      
      .db -40, -11     
      .db -40, -3     
      .db -32, -11     
      .db -32, -3       
      .db -24, -11
      .db -24, -3
      .db -16, -11
      .db -16, -3
      .db -8, -11
      .db -8, -3

    arthur_walking_layout_1:
      .db -56, -11      
      .db -48, -11
      .db -48, -3      
      .db -40, -11     
      .db -40, -3     
      .db -32, -11     
      .db -32, -3       
      .db -24, -11
      .db -24, -3
      .db -16, -11
      .db -16, -3
      .db -8, -11
      .db -8, -3
      .db -8, 5

    arthur_walking_layout_2:
      .db -56, -7      
      .db -48, -7
      .db -40, -11     
      .db -40, -3     
      .db -32, -11     
      .db -32, -3       
      .db -24, -11
      .db -24, -3
      .db -16, -11
      .db -16, -3
      .db -8, -11
      .db -8, -3

    arthur_walking_layout_3:
      .db -56, -7      
      .db -48, -7
      .db -40, -11     
      .db -40, -3     
      .db -32, -11     
      .db -32, -3       
      .db -24, -11
      .db -24, -3
      .db -16, -11
      .db -16, -3
      .db -16, 5
      .db -8, -11
      .db -8, -3
      .db -8, 5