  load_sat_old:
    ; Load the vram sat with the SatY and SatXC buffers.
    ; Sonic 2 inspired flicker engine is in place: Flicker sprites by loading the
    ; SAT in ascending/descending order every other frame.
    ld a,(load_mode)
    cp DESCENDING
    jp z,_descending_load
      ; If not descending, then fall through to ascending load mode.
      ;
      ; Load y-coordinates.
      ld hl,SAT_Y_START
      call setup_vram_write
      ld hl,sat_buffer_y
      ld c,DATA_PORT
      .rept 64
        outi
      .endr
      ;
      ; Load x-coordinates and character codes.
      ld hl,SAT_XC_START
      call setup_vram_write
      ld hl,sat_buffer_xc
      ld c,DATA_PORT
      .rept 128
        outi
      .endr
  ret
    ;
    _descending_load:
      ; Load y-coordinates.
      ld hl,SAT_Y_START
      call setup_vram_write
      ld c,DATA_PORT
      ld hl,sat_buffer_y
      .rept PRIORITY_SPRITES
        outi
      .endr
      ;
      ld hl,sat_buffer_y+63    ; Point to last y-value in buffer.
      .rept 64-PRIORITY_SPRITES
        outd                    ; Output and decrement HL, thus going
      .endr                     ; backwards (descending) through the buffer.
      ;
      ; Load x-coordinates and character codes
      ld hl,SAT_XC_START
      call setup_vram_write
      ld c,DATA_PORT
      ld hl,sat_buffer_xc
      .rept PRIORITY_SPRITES
        outi
        outi
      .endr
      ;
      ld hl,sat_buffer_xc+126
      ld de,-4
      .rept 64-PRIORITY_SPRITES
        outi
        outi
        add hl,de
      .endr
  ret