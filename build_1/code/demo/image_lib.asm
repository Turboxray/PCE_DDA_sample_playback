

LoadImageQueue:

        lda #(BG_OFF|SPR_OFF|VINT_ON|HINT_ON)
        sta vdc_control

        sVDC.reg MAWR, #$800
        sVDC.reg VRWR

        st1 #$00

        ldy #$08
.loop.outer_clear_vram
        clx
.loop_clear_vram

        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00

        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00

        dex
      bne .loop_clear_vram
        dey
      bne .loop.outer_clear_vram

        PUSHBANK.4 MPR2

        sVDC.reg MAWR, #$800
        sVDC.reg VRWR
        ;.........
        ; load tiles
        lda Image.Queue.idx
        asl a
        tay
        MAP_BANK.4 Image.Queue.tile.bank,y , MPR2
            lda Image.Queue.tile.size,y
            sta <D0
            lda Image.Queue.tile.size+1,y
            sta <D0+1
            lda Image.Queue.tile.addr,y
            sta <A0
            lda Image.Queue.tile.addr+1,y
            sta <A0+1

.loop.outer.tile
        cly
.loop.single.tile
        lda [<A0],y
        iny
        sta $0002
        lda [<A0],y
        sta $0003
        iny
        cpy #$20
      bcc .loop.single.tile

        ADD.w #$0020, <A0

        lda <D0.l
        clc
        adc #$ff
        sta <D0.l
        lda <D0.h
        adc #$ff
        sta <D0.h
        ora <D0.l
      beq .do.map

        lda <A0.h
        cmp #$A0
      bcc .loop.outer.tile
        and #$1f
        ora #$40
        sta <A0.h

        tma #$04
        inc a
        tam #$02
        inc a
        tam #$03
        inc a
        tam #$04
        inc a
        tam #$05
      jmp .loop.outer.tile


.do.map
        sVDC.reg MAWR, #$000
        sVDC.reg VRWR
        ;.........
        ; load map
        lda Image.Queue.idx
        asl a
        tay
        MAP_BANK.4 Image.Queue.map.bank,y , MPR2
            lda Image.Queue.map.size,y
            sta <D0
            lda Image.Queue.map.size+1,y
            sta <D0+1
        lsr <D0.h
        ror <D0.l
            lda Image.Queue.map.addr,y
            sta <A0
            lda Image.Queue.map.addr+1,y
            sta <A0+1

.loop.map
        lda [<A0]
        INC.w <A0
        sta $0002
        lda [<A0]
        INC.w <A0
        sta $0003

        lda <D0.l
        clc
        adc #$ff
        sta <D0.l
        lda <D0.h
        adc #$ff
        sta <D0.h
        ora <D0.l
      bne .loop.map



.do.pal
        ;.........
        ; load pal
        lda Image.Queue.idx
        asl a
        tay
        MAP_BANK.4 Image.Queue.pal.bank,y , MPR2
            lda Image.Queue.pal.size,y
            sta <D0
            lda Image.Queue.pal.size+1,y
            sta <D0+1
            lda Image.Queue.pal.addr,y
            sta <A0
            lda Image.Queue.pal.addr+1,y
            sta <A0+1

        stz $402
        stz $403
        lda <D0.l
        lsr <D0.h
        ror a
        tay
.loop.pal
        lda [<A0]
        INC.w <A0
        sta $404
        lda [<A0]
        INC.w <A0
        sta $405
        dey
      bne .loop.pal


        PULLBANK.4 MPR2

        lda #(BG_ON|SPR_OFF|VINT_ON|HINT_ON)
        sta vdc_control

  rts        


