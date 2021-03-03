.equ BYTES_PER_TILE 32
.equ ONE_TILEMAP_ROW 32*2
.equ END_OF_TABLE $ff

; Font / printing support.
.equ CHARS_IN_ASCII_SET 91
.equ STRING_TERMINATOR 3        ; Terminate strings with #
.equ ASCII_ZERO 16        ; Where in the tilebank is the ASCII zero?
.equ ASCII_ONE 17
.equ ASCII_NINE ASCII_ZERO+9
.equ ASCII_SPACE 0
.equ ASCII_EXCLAMATION 1
.equ ASCII_TABLE_START 0
.asciitable
  map " " to "z" = ASCII_TABLE_START
.enda


; -----------------------------------------------------------------------------
.section "await_frame_interrupt" free
; -----------------------------------------------------------------------------
  ; Await frame interrupt.
  ; Repeatedly test bit 7 of VDPStatus until it is set (by the VDP interrupt
  ; handler). Then reset this bit and return.
  ; Entry: None
  ; Exit: Bit 7 of variable VDPStatus is cleared.
  ; Uses: VDPStatus (1 byte)
  await_frame_interrupt:
    push af
      -:
        ld a,(VDPStatus)
        bit 7,a
      jp z,-
      in a,(V_COUNTER_PORT)
      ; Check this post: http://www.smspower.org/forums/8113-WaitForVBlankSlowerOnNTSCThanPALSystematicProblemWithWaitForVBlankNoInt
      cp FIRST_LINE_OF_VBLANK+1
      jp nz,-
        res 7,a
        ld (VDPStatus),a
    pop af
  ret
.ends
;

; -----------------------------------------------------------------------------
.section "load_vdp_registers" free
; -----------------------------------------------------------------------------
  load_vdp_registers:
    ; Load all 11 vdp registers with preset values.
    ; Entry: HL pointing to init data block (11 bytes).
    xor b
    -:
      ld a,(hl)
      out (CONTROL_PORT),a
      inc hl
      ld a,b
      or REGISTER_WRITE_COMMAND
      out (CONTROL_PORT),a
      cp REGISTER_WRITE_COMMAND|10
      ret z
      inc b
    jr -
  ret
.ends
;
; -----------------------------------------------------------------------------
.section "put_string" free
; -----------------------------------------------------------------------------
  ; Put a string of multiple characters on the nametable with minimum overhead.
  ; Entry: B = Number og characters in string.
  ;        HL = Pointer to string: Nametable address (word), then pairs of
  ;             bytes [char], [flags]
  ; Exit: None
  ; Uses: AF, B, HL
  put_string:
    ld a,(hl)
    out (CONTROL_PORT),a
    inc hl
    ld a,(hl)
    or VRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
    -:
      inc hl
      ld a,(hl)
      out (DATA_PORT),a
      inc hl
      ld a,(hl)
      out (DATA_PORT),a             ; Write 2nd byte to name table.
    djnz -
  ret
.ends
;
; -----------------------------------------------------------------------------
.section "set_vram_address" free
; -----------------------------------------------------------------------------
  ; Set vram address.
  ; Entry: HL = Address.
  ; Exit:
  ; Uses:
  set_vram_address:
    ld a,l
    out (CONTROL_PORT),a
    ld a,h
    or VRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
  ret
.ends

; =============================================================================
; E X T E N D E D  F U N C T I O N S                        (grouped in themes)
; =============================================================================
; -----------------------------------------------------------------------------
.ramsection "extended functions variables" slot 3
; -----------------------------------------------------------------------------
  ;
.ends
;
; -----------------------------------------------------------------------------
.section "tilemap / name table editing" free
; -----------------------------------------------------------------------------
  copy_tilemap_rect_to_buffer:
    ; Copy the tilemap words under a rectangle to a buffer.
    ; A = Rect width.
    ; B = Rect height.
    ; HL = Top left tile (address) of rectangle to copy.
    ; DE = Destination buffer.
    ; All registers are preserved.
    SAVE_REGISTERS
    add a,a                 ; Double width - the table elements are words.
    ld c,a                  ; Save width in C for counting.
    ; For each 'rect-height' do the following...
    --:
      ld a,l
      out (CONTROL_PORT),a
      ld a,h
      or VRAM_READ_COMMAND
      out (CONTROL_PORT),a
      push de
        ld de,ONE_TILEMAP_ROW
        add hl,de
      pop de
      push bc               ; Save rect width*2.
      ; For each 'rect-width*2' do the following...
        -:
          in a,(DATA_PORT)  ; Get byte from tilemap.
          ld (de),a         ; Store it in the buffer.
          inc de            ; Update buffer pointer.
          dec c             ; Decrement 'for counter'.
          xor a             ; Do the rect-width*2 for-loop logic...
          cp c
        jp nz,-
      pop bc                ; Restore rect-width*2.
    djnz --                 ; The rect-height for-loop.
    RESTORE_REGISTERS
  ret
  ; ---------------------------------------------------------------------------
  copy_buffer_to_tilemap_rect:
    ; Reverse of copy_tilemap_rect_to_buffer.
    ; A = Rect width.
    ; B = Rect height.
    ; HL = Base address of buffer.
    ; DE = Address of top left tile of tilemap rectangle.
    ; Preserves all registers used.
    ; Time: 11 lines.
    SAVE_REGISTERS
    add a,a                 ; Double width - the table elements are words.
    ld c,a                  ; Save width in C for counting.
    ; For each 'rect-height' do the following...
    --:
      ld a,e
      out (CONTROL_PORT),a
      ld a,d
      or VRAM_WRITE_COMMAND
      out (CONTROL_PORT),a
      push hl
        ld hl,ONE_TILEMAP_ROW
        add hl,de
        ex de,hl
      pop hl
      push bc               ; Save rect width*2.
      ; For each 'rect-width*2' do the following...
        -:
          ld a,(hl)
          out (DATA_PORT),a
          inc hl
          dec c             ; Decrement 'for counter'.
          xor a             ; Do the rect-width*2 for-loop logic...
          cp c
        jp nz,-
      pop bc                ; Restore rect-width*2.
    djnz --                 ; The rect-height for-loop.
    RESTORE_REGISTERS
  ret
  ; ---------------------------------------------------------------------------
  blank_tilemap_rect:
    ; Write $0000 to the tilemap words under a rectangle.
    ; A = Rect width.
    ; B = Rect height.
    ; HL = Address of first tile to blank.
    add a,a                 ; Double width - the table elements are words.
    ld c,a                  ; Save width in C for counting.
    ; For each 'rect-height' do the following...
    --:
      ld a,l
      out (CONTROL_PORT),a
      ld a,h
      or VRAM_WRITE_COMMAND
      out (CONTROL_PORT),a
      ld de,ONE_TILEMAP_ROW
      add hl,de
      ld a,$00
      push bc               ; Save rect width*2.
      ; For each 'rect-width*2' do the following...
        -:
          out (DATA_PORT),a
          dec c             ; Decrement 'for counter'.
          cp c              ; A is already $00 = blanked.
        jp nz,-
      pop bc                ; Restore rect-width*2.
    djnz --                 ; The rect-height for-loop.
  ret

  reset_name_table:
    ; Overwrite all name table entries with a specified tile.
    ; Entry: A = Tile index
    ;        B = Bank (1/2) - selects corresponding palette.
    ; Uses: None.
    SAVE_REGISTERS
    push af
    dec b
    jp z,+
      ld b,%00001001
    +:
    ld hl,NAME_TABLE_START
    ld a,l
    out (CONTROL_PORT),a
    ld a,h
    or VRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
    pop af
    ld h,a                                    ; Index of tile.
    ld l,b                                    ; 2nd byte, bank and pal.
    ld de,32*28                               ; 32 columns, 28 rows.
    -:
      ld a,h
      out (DATA_PORT),a                       ; Write 1st word to name table.
      ld a,l
      out (DATA_PORT),a                       ; Write 2nd word to name table.
      dec de
      ld a,e
      or d
    jp nz,-
    RESTORE_REGISTERS
  ret
.ends
;
; -----------------------------------------------------------------------------
.ramsection "bluelib printing variables" slot 3
; -----------------------------------------------------------------------------
  cursor_y db
  cursor_x db
.ends
; -----------------------------------------------------------------------------
.section "Printing" free
  ; Functions for printing ascii chars.
  ; Put this ascii map in header:
  ;   .asciitable
  ;      map " " to "z" = 0
  ;    .enda
  ; ---------------------------------------------------------------------------
  ; Assumes ASCII character set loaded into vram, like this:
  ;   SELECT_BANK FONT_BANK
  ;   ld hl,font_table
  ;   call load_vram_from_table
  ;   .... in footer:
  ;   font_table:
  ;  .dw BACKGROUND_BANK_START
  ;  .dw CHARS_IN_ASCII_SET*BYTES_PER_TILE
  ;  .dw dd_revolution_tiles
  ;   ....
  ;   dd_revolution_tiles:
  ;  .include "bank_2\dd_revolution_tiles.inc"
  ; ---------------------------------------------------------------------------
  batch_print:
    ; Batch print strings at different screen positions. Handy for making a
    ; menu, or for setting up text in various places. Strings and positions are
    ; stored in a table in the following format:
    ; pointer to string (word), row (byte), column (byte).
    ; Entry: IX = pointer to table.
    ;        A = number of strings to print.
    ; Uses: AF, BC, HL.
    ; Depends on print (in bluelib.inc), and on #-terminated strings.
    .equ SIZE_OF_BATCH_PRINT_ITEM 4
    -:
      push af
      ld l,(ix+0)
      ld h,(ix+1)
      ld b,(ix+2)
      ld c,(ix+3)
      call print
      .rept 4
        inc ix
      .endr
      pop af
      dec a
    jp nz,-
  ret
  ;
  print:
    ; Print a string to the name table. Terminate with # (ascii).
    ; N.B. Make sure that this function is not interrupted!
    ; Observes vram writing delays.
    ; Entry:
    ;        B = row, C = column.
    ;        HL = Pointer to string.
    ; Uses: AF, BC, DE, HL
    push hl                       ; Save pointer and string length for later.
    ld hl,NAME_TABLE_START        ; Get ready to calculate destination address.
    ld a,b
    cp 0
    jp z,add_row_offset_end
      ld de,$40                   ; For each row, add $40 to the dest. address.
      -:
        add hl,de
      djnz -
    add_row_offset_end:
    ld a,c
    cp 0
    jp z,add_column_offset_end
      ld b,a
      ld de,2                     ; Each column adds 1 word to dest. address.
      -:
        add hl,de
      djnz -
    add_column_offset_end:
    ld a,l                        ; Setup vram to load bytes at dest. address.
    out (CONTROL_PORT),a
    ld a,h
    or VRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
    ;
    pop hl                          ; Get pointer to string from stack.
    -:
      ld a,(hl)                     ; Get character from string.
      cp STRING_TERMINATOR
      ret z
      out (DATA_PORT),a             ; Write it to name table.
      push ix
      pop ix
      ld a,%00000000                ; Select background palette for this char.
      out (DATA_PORT),a             ; Write 2nd byte to name table.
      push ix
      pop ix
      inc hl                        ; Point to next char.
    djnz -
  ret
  ;
  set_cursor:
    ; Set cursor used by put_char.
    ; Entry: A = cursor_y / row, B = cursor_x / column.
    ; Exit: None. Contents of A and B stay unchanged.
    ; Uses: None.
    push af
      ld (cursor_y),a
      ld a,b
      ld (cursor_x),a
    pop af
  ret
  ;
  put_char:
    ; Put char at cursor y,x and move cursor right.
    ; N.B. Make sure that this function is not interrupted!
    ; Entry: A = tile number (0-255 - in tile bank 1).
    ; Uses: A, B and C, but saves the rest. - is this still true?!
    SAVE_REGISTERS
    push af                       ;
    ld hl,NAME_TABLE_START        ; Get ready to calculate destination address.
    ld a,(cursor_y)
    ld b,a
    cp 0
    jp z,+
      ld de,$40                   ; For each row, add $40 to the dest. address.
      -:
        add hl,de
      djnz -
    +:
    ld a,(cursor_x)
    cp 0
    jp z,+
      ld b,a
      ld de,2                     ; Each column adds 1 word to dest. address.
      -:
        add hl,de
      djnz -
    +:
    inc a
    ld (cursor_x),a               ; Inc cursor x position.
    ld a,l                        ; Setup vram to load bytes at dest. address.
    out (CONTROL_PORT),a
    ld a,h
    or VRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
    ;
    pop af                        ; Get tile.
    out (DATA_PORT),a             ; Write it to name table.
    push ix
    pop ix
    ld a,%00000000                ; Select background palette for this char.
    out (DATA_PORT),a             ; Write 2nd byte to name table.
  RESTORE_REGISTERS
  ret
  ;
  put_string_at_cursor:
    ; Put a string of multiple characters on the nametable with minimum
    ; overhead. Use current cursor position. Does not depend on '#' to
    ; terminate. Use only chars in background bank. Should be pretty interrupt-
    ; safe with di/ei and VDP access delays.
    ; Entry: B = Number of characters in string.
    ;        HL = pointer to string
    ; Exit: None
    ; Uses: None
    SAVE_REGISTERS
    push bc
    push hl                       ;
    ld hl,NAME_TABLE_START        ; Get ready to calculate destination address.
    ld a,(cursor_y)
    ld b,a
    cp 0
    jp z,+
      ld de,$40                   ; For each row, add $40 to the dest. address.
      -:
        add hl,de
      djnz -
    +:
    ld a,(cursor_x)
    cp 0
    jp z,+
      ld b,a
      ld de,2                     ; Each column adds 1 word to dest. address.
      -:
        add hl,de
      djnz -
    +:
    inc a
    ld (cursor_x),a               ; Inc cursor x position.
    ld a,l                        ; Setup vram to load bytes at dest. address.
    di
    out (CONTROL_PORT),a
    ld a,h
    or VRAM_WRITE_COMMAND
    out (CONTROL_PORT),a
    ei
    ;
    pop hl
    pop bc                        ; Get tile.
    -:
      ld a,(hl)
      inc hl
      out (DATA_PORT),a           ; Write it to name table.
      push ix
      pop ix
      ld a,%00000000              ; Select background palette for this char.
      out (DATA_PORT),a           ; Write 2nd byte to name table.
    djnz -
    RESTORE_REGISTERS
  ret
  ;
  print_register_hl:
    ; Print the contents of register HL as 5 ascii digits using put_char at
    ; position cursor (y,x).
    ; Entry: HL = value to print.
    ; Uses AF, BC, HL
  	ld	bc,-10000
  	call	+
  	ld	bc,-1000
  	call	+
    ld	bc,-100
  	call	+
  	ld	c,-10
  	call +
  	ld	c,-1
    +:
      ld	a,ASCII_ZERO-1 ; Maybe 16 here?
      -:
        inc	a
  	    add	hl,bc
  	  jr	c,-
  	sbc	hl,bc
  	call put_char
  ret
  ;
  print_register_a:
    ; Print the contents of register A as 3 ascii digits using put_char at
    ; position cursor (y,x).
    ; Entry: A = value to print.
    ; Uses AF, BC, HL
    ld h,0
    ld l,a
    ld	bc,-100
  	call	+
  	ld	c,-10
  	call +
  	ld	c,-1
    +:
      ld	a,ASCII_ZERO-1 ;
      -:
        inc	a
  	    add	hl,bc
  	  jr	c,-
  	sbc	hl,bc
  	call put_char
  ret
.ends
;
