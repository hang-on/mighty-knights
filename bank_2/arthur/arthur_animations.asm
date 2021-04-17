  .macro TILEBLAST ARGS TILES
      .db PLAYER_TILE_BANK
      .dw TILES
      .dw ADDRESS_OF_PLAYER_FIRST_TILE
      .db XLARGE_BLAST
  .endm

  .equ PLAYER_TILE_BANK 2
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
      .dw arthur_standing_blast       ; Pointer to tileblast.
      .db 14                          ; Size.
      .db INDEX_OF_PLAYER_FIRST_TILE  ; Index of first tile.
      .dw arthur_standing_layout      ; Pointer to layout.

    arthur_standing_blast:
      TILEBLAST arthur_standing_tiles
    arthur_standing_tiles:
      .include "bank_2/arthur/standing/arthur_standing_tiles.asm"

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

  arthur_walking:
    ; Table of contents:
    .dw @header, @frame_0, @frame_1, @frame_2, @frame_3
    @header:
      .db 3                           ; Max frame.
      .db TRUE                        ; Looping.
    @frame_0:
      .db 8                           ; Duration.
      .db TRUE                        ; Require tileblast?
      .dw arthur_walking_0_blast      ; Pointer to tileblast.
      .db 13                          ; Size.
      .db INDEX_OF_PLAYER_FIRST_TILE  ; Index of first tile.
      .dw arthur_walking_layout_0     ; Pointer to layout.
    @frame_1:
      .db 8                       
      .db TRUE                   
      .dw arthur_walking_1_blast                   
      .db 14                       
      .db INDEX_OF_PLAYER_FIRST_TILE                        
      .dw arthur_walking_layout_1          
    @frame_2:
      .db 8                       
      .db TRUE                   
      .dw arthur_walking_2_blast                   
      .db 12                       
      .db INDEX_OF_PLAYER_FIRST_TILE                        
      .dw arthur_walking_layout_2          
    @frame_3:
      .db 8                       
      .db TRUE                   
      .dw arthur_walking_3_blast                   
      .db 14                       
      .db INDEX_OF_PLAYER_FIRST_TILE                        
      .dw arthur_walking_layout_3          

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

  arthur_walking_0_blast:
    TILEBLAST arthur_walking_0_tiles
  arthur_walking_1_blast:
    TILEBLAST arthur_walking_1_tiles
  arthur_walking_2_blast:
    TILEBLAST arthur_walking_2_tiles
  arthur_walking_3_blast:
    TILEBLAST arthur_walking_3_tiles
  
  arthur_walking_0_tiles:
    .include "bank_2/arthur/walking/arthur_walking_0_tiles_optm.asm"
  arthur_walking_1_tiles:
    .include "bank_2/arthur/walking/arthur_walking_1_tiles_optm.asm"
  arthur_walking_2_tiles:
    .include "bank_2/arthur/walking/arthur_walking_2_tiles_optm.asm"
  arthur_walking_3_tiles:
    .include "bank_2/arthur/walking/arthur_walking_3_tiles_optm.asm"