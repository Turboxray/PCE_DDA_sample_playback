

Hsync.ISR:
          pha
.VDC.hsync

        st0 #BXR
        lda [<Hsync.tbl.ptr0]
        sta $0002

        st0 #BYR
        lda [<Hsync.tbl.ptr1]
        sta $0002
        lda [<Hsync.tbl.ptr2]
        sta $0003

        st0 #RCR
        lda <Hsync.RCR
        sta $0002
        lda <Hsync.RCR + 1
        sta $0003

        INC.w <Hsync.tbl.ptr0
        INC.w <Hsync.tbl.ptr1
        INC.w <Hsync.tbl.ptr2
        INC.w <Hsync.RCR

        lda <vdc_reg
        sta $0000

        lda IRQ.ackVDC
        sta <vdc_status
        bit #$20
        bne .VDC.vsync
          pla
  rti


.VDC.vsync

        st0 #BXR
        lda _BXR
        sta $0002
        lda _BXR+1
        sta $0003

        st0 #BYR
        lda _BYR
        sta $0002
        lda _BYR+1
        sta $0003

        st0 #RCR
        lda #$40
        sta $0002
        inc a
        sta <Hsync.RCR
        st2 #$00
        stz <Hsync.RCR + 1

        lda Hsync.curTable
      beq .0
.1
      MOVE.w #Hsync.tbl1.BXR, Hsync.tbl.ptr0
      MOVE.w #Hsync.tbl1.BYR, Hsync.tbl.ptr1
      MOVE.w #Hsync.tbl1.BYR.hi, Hsync.tbl.ptr2
    jmp .out
.0
      MOVE.w #Hsync.tbl0.BXR, Hsync.tbl.ptr0
      MOVE.w #Hsync.tbl0.BYR, Hsync.tbl.ptr1
      MOVE.w #Hsync.tbl0.BYR.hi, Hsync.tbl.ptr2
.out

        st0 #CR
        lda vdc_control
        sta $0002

        lda <vdc_reg
        sta $0000

.VDC.rtn
        pla
      stz __vblank
  rti
