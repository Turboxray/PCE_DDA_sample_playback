;////////////////////////////////////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////////////////////////////////////
;// DDA Playback                                                                                            /
;////////////////////////////////////////////////////////////////////////////////////////////////////////////
;# ISR_routine

;##############################################################################
;##############################################################################

DDA.timerISR:

    ;
        stz IRQ.ackTIRQ                 ;5
        bit <DDA.process                ;4      ISR lock
      bvs .in_progress                  ;2
        cli                             ;2
      bmi .DDA.disabled                 ;2

          pha
        inc  <DDA.process               ;6

.DDA
        tma #$03                        ;4
          pha                           ;3 = 33

        lda <DDA.bank                   ;4
        tam #$03                        ;5

        lda [DDA.ptr]                   ;7
      bmi .control_flag                 ;2

          sei
        stz WSG.ChannelSelect           ;5
        sta WSG.DDAport                 ;5
          cli

        inc <DDA.ptr                    ;6
      beq .overflow                     ;2

.finished
          pla                           ;4
        tam #$03                        ;5
          pla                           ;4
        dec <DDA.process                ;6
.DDA.disabled

.in_progress
    rti                                 ;7 = 30


.control_flag
          pla
        tam #$03 
          pla
        lda #($80+$3f)
        sta <DDA.process
  rti

.overflow
        inc <DDA.ptr + 1
      bpl .finished
        lda #$60
        sta <DDA.ptr + 1
        inc <DDA.bank
      bra .finished