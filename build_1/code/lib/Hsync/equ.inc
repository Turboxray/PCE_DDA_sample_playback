

Hsync.Init  .macro

        clx
        lda #$41
        sta Hsync.temp
        stz Hsync.temp + 1

        cla
.loop
        sta Hsync.tbl0.BXR,x
        sta Hsync.tbl1.BXR,x
        sta Hsync.tbl0.BYR,x
        sta Hsync.tbl1.BYR,x
        inc a
        inx
        cpx #240
      bcc .loop

        clx
.loop2
        lda #$01
        sta Hsync.tbl0.BYR.hi,x
        sta Hsync.tbl1.BYR.hi,x
        inx
        cpx #240
      bcc .loop2

      MOVE.w #Hsync.tbl0.BXR, Hsync.tbl.ptr0
      MOVE.w #Hsync.tbl0.BYR, Hsync.tbl.ptr1
      MOVE.w #Hsync.tbl0.BYR.hi, Hsync.tbl.ptr2

      MOVE.w #$0041, Hsync.RCR
      MOVE.b #$00, Hsync.curTable
      MOVE.b #$00, Hsync.work.idx.0
      MOVE.b #$00, Hsync.work.idx.1

  .endm