


DoVCEDMA        .macro
        inc enableColorDMA
        jsr DmaPCEpal
    .endm

DDA.initialize  .macro
        ; Disable playback of samples
        lda #$80+$3f
        sta DDA.process

        ldx #$05
        lda #$80
.loop_\@
        sta DDA.bank,x
        dex
      bpl .loop_\@

    .endm

WSG.reg.safe    .macro
          php
          sei
        lda \3
        sta $800
        MOVE.b \1, \2
          plp
    .endm

DDA.enable      .macro
        rmb7 <DDA.process
    .endm

DDA.AddToQueue      .macro
        ldx DDA.QueueLen
        lda #low(\1)
        sta DDA.queue.lo,x
        lda #high(\1)
        sta DDA.queue.hi,x
        lda #bank(\1)
        sta DDA.queue.bank,x
        inc DDA.QueueLen
    .endm

DDA.PlayQueue      .macro
        ldx \1
        lda DDA.queue.lo,x
        sta DDA.ptr
        lda DDA.queue.hi,x
        sta DDA.ptr + 1
        lda DDA.queue.bank,x
        sta DDA.bank
        lda #$3f
        sta <DDA.process
    .endm

DDA.chan0 = 0
DDA.chan1 = 1
DDA.chan2 = 2
DDA.chan3 = 3
DDA.chan4 = 4
DDA.chan5 = 5

QueueImage      .macro
    lda Image.Queue.len
    asl a
    tay

    ; Tile
    lda #low(\1.cell)
    sta Image.Queue.tile.addr,y
    lda #high(\1.cell)
    sta Image.Queue.tile.addr + 1,y
    lda #bank(\1.cell)
    sta Image.Queue.tile.bank,y
    lda #low(\1.cell.size)
    sta Image.Queue.tile.size,y
    lda #high(\1.cell.size)
    sta Image.Queue.tile.size+1,y

    ; Map
    lda #low(\1.map)
    sta Image.Queue.map.addr,y
    lda #high(\1.map)
    sta Image.Queue.map.addr + 1,y
    lda #bank(\1.map)
    sta Image.Queue.map.bank,y
    lda #low(\1.map.size)
    sta Image.Queue.map.size,y
    lda #high(\1.map.size)
    sta Image.Queue.map.size+1,y

    ; Pal
    lda #low(\1.pal)
    sta Image.Queue.pal.addr,y
    lda #high(\1.pal)
    sta Image.Queue.pal.addr + 1,y
    lda #bank(\1.pal)
    sta Image.Queue.pal.bank,y
    lda #low(\1.pal.size)
    sta Image.Queue.pal.size,y
    lda #high(\1.pal.size)
    sta Image.Queue.pal.size+1,y

    inc Image.Queue.len

    .endm