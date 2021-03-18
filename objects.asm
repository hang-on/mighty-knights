.section "Object library" free
  apply_origin:
    ld a,(hl)
    inc hl
    add a,(hl)
  ret

  apply_origin_with_var:
    add a,(hl)
  ret

  .struct object
    y db
    x db
    size db
    layout dw
  .endst


  .dstruct arthur instanceof object data 100, 100, 7, test_layout

  get_address:
    ; in: Pointer in HL, out: Address pointed to in HL 
    ld a,(hl)
    ld b,a
    inc hl
    ld a,(hl)
    ld l,b
    ld h,a
  ret

  test_layout:
    .db -24, -24, -16, -16, -8, -8, -32 ; y-offsets
    .db -8, 1, 0, 2, -8, 3, 0, 4, -8, 5, 0, 6, -8, 7 ; x-offsets, chars

.ends



 
