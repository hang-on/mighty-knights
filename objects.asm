.section "Object library" free
  apply_origin:
    ld a,(hl)
    inc hl
    add a,(hl)
  ret
.ends