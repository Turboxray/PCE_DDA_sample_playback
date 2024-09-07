;
;
;    {Assemble with PCEAS: ver 3.23 or higher}
;
;   Turboxray '24
;



;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;..............................................................................................................

    list
    mlist

; Uncomment the line below for visual benchmarking.
; DEBUG_BENCHMARK = 1

;..................................................
;                                                 .
;  Logical Memory Map:                            .
;                                                 .
;            $0000 = Hardware bank                .
;            $2000 = Sys Ram                      .
;            $4000 = Subcode                      .
;            $6000 = Data 0 / Cont. of Subcode    .
;            $8000 = Data 1                       .
;            $A000 = Data 2                       .
;            $C000 = Main                         .
;            $E000 = Fixed Libray                 .
;                                                 .
;..................................................


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;//  Vars


    ;// Varibles defines
    .include "../base_func/vars.inc"
    .include "../base_func/video/vdc/vars.inc"
    .include "../base_func/video/vdc/sprites/vars.inc"
    .include "../base_func/IO/irq_controller/vars.inc"
    .include "../base_func/audio/wsg/vars.inc"
    .include "../base_func/IO/gamepad/vars.inc"


    .include "../lib/controls/vars.inc"
    .include "../lib/random/16bit/vars.inc"
    .include "../lib/Hsync/vars.inc"

    .include "../demo/vars.inc"

;....................................
    .code

    .bank $00, "Fixed Lib/Start up"
    .org $e000
;....................................

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Support files: equates and macros

    ;// Support files for MAIN
    .include "../base_func/base.inc"
    .include "../base_func/video/video.inc"
    .include "../base_func/video/vdc/vdc.inc"
    .include "../base_func/video/vdc/sprites/sprites.inc"
    .include "../base_func/video/vce/vce.inc"
    .include "../base_func/timer/timer.inc"
    .include "../base_func/IO/irq_controller/irq.inc"
    .include "../base_func/IO/mapper/mapper.inc"
    .include "../base_func/audio/wsg/wsg.inc"
    .include "../base_func/IO/gamepad/gamepad.inc"

    .include "../lib/controls/controls.inc"
    .include "../lib/random/16bit/random_16bit.inc"
    .include "../lib/Hsync/Hsync.inc"

    .include "../demo/demo.inc"


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Startup and fix lib @$E000

startup:
        ;................................
        ;Main initialization routine.
        InitialStartup
        
        stz $2000
        tii $2000,$2001,$2000
        
        CallFarWide init_audio
        CallFarWide init_video

        ;................................
        ;Set video parameters
        VCE.reg LO_RES|H_FILTER_ON
        sVDC.reg HSR  , #$0202
ifdef DEBUG_BENCHMARK
        sVDC.reg HDR  , #$051e
        sVDC.reg VSR  , #$1602
else
        sVDC.reg HDR  , #$041f
        sVDC.reg VSR  , #$1602
endif
        sVDC.reg VDR  , #$00e4
        sVDC.reg VDE  , #$00ff
        sVDC.reg DCR  , #AUTO_SATB_ON
        sVDC.reg CR   , #$0000
        sVDC.reg SATB , #$0800
        sVDC.reg MWR  , #SCR32_64

        IRQ.control IRQ2_ON|VIRQ_ON|TIRQ_OFF

        TIMER.port  _7.00khz
        TIMER.cmd   TMR_OFF

        MAP_BANK #MAIN, MPR6
        jmp MAIN

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Data / fixed bank


;Stuff for printing on screen
    .include "../base_func/video/print/lib.asm"

;other basic functions
    .include "../base_func/video/vdc/lib.asm"
    .include "../base_func/video/vdc/sprites/lib.asm"

; Lib stuffs
    .include "../lib/controls/lib.asm"
    .include "../base_func/IO/gamepad/lib.asm"
    .include "../lib/slow16by16Mul/lib.asm"
    .include "../lib/random/16bit/lib.asm"

    .include "../lib/palFade/palFade_lib.asm"
    .include "../lib/palFade/palFade.inc"
    .include "../lib/Hsync/Hsync_lib.asm"


    .include "../demo/dda_lib.asm"
    .include "../demo/sin.inc"


;end DATA
;//...................................................................


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Interrupt routines

    .include "../base_func/video/vdc/vectors.inc"

;end INT

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// INT VECTORS

  .org $fff6

    .dw BRK
    .dw VDC
    .dw TIRQ
    .dw NMI
    .dw startup

;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;Bank 0 end





;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Main code bank @ $C000

;....................................
    .bank $01, "MAIN"
    .org $c000
;....................................


MAIN
        ;................................
        Random.seed #$18ca    ; initailize random seed
        DMA.set.init          ; initialize Txx instruction in ram 

        ;...............................
        ; Initalize Hsync ISR tables before trying to use them.
        Hsync.Init 

        ;...............................
        ; Setup our DDA TIRQ code
        MOVE.w #Hsync.ISR, vdc_vect

        ;................................
        ;Load Ghosthouse assets
        loadCellToCram.BG     image1,     0       ; Load palette block starting at BG color #0
        loadDataToVram        image1.map, $0000   ; map is at vram address $0000

        ;................................
        ; There's no macro to load a very large image into vram. Needs to be done manually.
        sVDC.reg MAWR, #$800
        sVDC.reg VRWR

        MAP_BANK.4 #image1.cell , MPR2
        DMA.word.port image1.cell, Page.2, vdata_port, $4000
        MAP_BANK_MANUAL.4 bank(image1.cell) + 2 , MPR2
        DMA.word.port image1.cell + $4000, Page.2, vdata_port, $4000
        MAP_BANK_MANUAL.4 bank(image1.cell) + 4 , MPR2
        DMA.word.port image1.cell + $8000, Page.2, vdata_port, $4000
        MAP_BANK_MANUAL.4 bank(image1.cell) + 6 , MPR2
        DMA.word.port image1.cell + $C000, Page.2, vdata_port, $4000

        QueueImage  image1
        QueueImage  image2
        QueueImage  image3
        QueueImage  image4
        QueueImage  image5
        QueueImage  image6
        QueueImage  image7
        QueueImage  image8
        QueueImage  image9
        QueueImage  image10
        QueueImage  image11
        QueueImage  image12
        QueueImage  image13
        QueueImage  image14

        MOVE.b #10, Image.Queue.idx
        jsr LoadImageQueue

        ; Start with wavy mode
        MOVE.b #$00, effectMode
        MOVE.b #$00, waveMode

        ;................................
        ;Turn display on
        sVDC.reg CR , #(BG_ON|SPR_OFF|VINT_ON|HINT_ON)
        MOVE.b        #(BG_ON|SPR_OFF|VINT_ON|HINT_ON), vdc_control

        ; Set sprite color #0 to black. This is the border color in overscan.
        stz $402
        lda #$01
        sta $403
        stz $404
        stz $405

        ;...............................
        ; Setup our DDA TIRQ code
        MOVE.w #DDA.timerISR, timer_vect

        ;...............................
        ; Need to initalize before using!
        DDA.initialize

        ;...............................
        ; TIRQ ON
        TIMER.port  _7.00khz
        TIMER.cmd   TMR_ON
        IRQ.control IRQ2_ON|VIRQ_ON|TIRQ_ON

        ;...............................
        ; Set scroll positions
        MOVE.w #$00, _BXR
        MOVE.w #$00, _BYR
        MOVE.w #$40, _RCR

        ;................................
        ;start the party
        Interrupts.enable

        WAITVBLANK

        WSG.reg.safe  #$ff, WSG.globalPanVol, 0

        WSG.reg.safe  #$df, WSG.Control, 0
        WSG.reg.safe  #$ff, WSG.ChannelPanVol, 0
        WSG.reg.safe  #$df, WSG.Control, 1
        WSG.reg.safe  #$ff, WSG.ChannelPanVol, 1
        WSG.reg.safe  #$df, WSG.Control, 2
        WSG.reg.safe  #$ff, WSG.ChannelPanVol, 2
        WSG.reg.safe  #$df, WSG.Control, 3
        WSG.reg.safe  #$ff, WSG.ChannelPanVol, 3
        WSG.reg.safe  #$df, WSG.Control, 4
        WSG.reg.safe  #$ff, WSG.ChannelPanVol, 4
        WSG.reg.safe  #$df, WSG.Control, 5
        WSG.reg.safe  #$ff, WSG.ChannelPanVol, 5


        DDA.AddToQueue #hypercocoon
        DDA.AddToQueue #emergency
        DDA.AddToQueue #explosion2
        DDA.AddToQueue #lightning
        DDA.AddToQueue #stageclear

        MOVE.b #$01, DDA.QueueSlot

main_loop:

      WAITVBLANK
        TIMER.cmd   TMR_OFF
        TIMER.cmd   TMR_ON

        jsr flipHsyncTables

        ; Do I/O gamepad stuffs
        call Gamepad.READ_IO.single_controller
        call Controls.ProcessInput
        call DoDemoControls

  debugBENCH 7,7,0
      jsr doHsyncEffects
  debugBENCH 0,0,0
        
      jmp main_loop

;//...................................................................



;Func
;//...................................................................

;...........................
flipHsyncTables:
        lda effectMode
        cmp #$01
      bne .cont
  rts

.cont
        lda Hsync.curTable
        eor #$01
        sta Hsync.curTable

        cmp #$01
      beq .1
.0
      MOVE.w #Hsync.tbl0.BXR, Hsync.tbl.ptr0
      MOVE.w #Hsync.tbl0.BYR, Hsync.tbl.ptr1
      MOVE.w #Hsync.tbl0.BYR.hi, Hsync.tbl.ptr2
      MOVE.w #Hsync.tbl1.BXR, Hsync.work.ptr0
      MOVE.w #Hsync.tbl1.BYR, Hsync.work.ptr1
      MOVE.w #Hsync.tbl1.BYR.hi, Hsync.work.ptr2
    jmp .out
.1
      MOVE.w #Hsync.tbl1.BXR, Hsync.tbl.ptr0
      MOVE.w #Hsync.tbl1.BYR, Hsync.tbl.ptr1
      MOVE.w #Hsync.tbl1.BYR.hi, Hsync.tbl.ptr2
      MOVE.w #Hsync.tbl0.BXR, Hsync.work.ptr0
      MOVE.w #Hsync.tbl0.BYR, Hsync.work.ptr1
      MOVE.w #Hsync.tbl0.BYR.hi, Hsync.work.ptr2
.out
 rts

;...........................
doHsyncEffects:
      lda effectMode
      cmp #$00
    beq .wavy
      cmp #$01
    beq .pause
      cmp #$02
    bcs .static

.wavy
    jmp doHsyncWavyEffects
.static
    jmp doHsyncStaticScreen
.pause
  rts

doHsyncWavyEffects:
        lda waveMode
        asl a
        tax
        jmp [.tbl,x]

.tbl
  .dw doHsyncWavyEffects0, doHsyncWavyEffects1, doHsyncWavyEffects2
doHsyncWavyEffects0:
      ldx Hsync.work.idx.0
      MOVE.w #00, <D0
      ldx Hsync.work.idx.0
      lda sine.table,x
      sta <R0.l
      MOVE.b #$1, <R0.h
      MOVE.w #$000, <R1
      cly
.loop
      lda sine.table,x
      lsr a
      lsr a
      clc
      adc #-$20
      sta [<Hsync.work.ptr0],y
        phx
      lsr a
      tax
      lda sine.table,x
      lsr a
      lsr a
      lsr a
      clc
      adc <D0.l
      sta [<Hsync.work.ptr1],y
      cla
      adc <D0.h
      sta [<Hsync.work.ptr2],y
        plx

      lda <R1.l
      clc
      adc <R0.l
      sta <R1.l
      lda <D0.l
      adc <R0.h
      sta <D0.l
      lda <D0.h
      adc #$00
      sta <D0.h


      inx
      iny
      cpy #240
    bcc .loop

      inc Hsync.work.idx.0
      inc Hsync.work.idx.0
  rts

doHsyncWavyEffects2:
      ldx Hsync.work.idx.0
      MOVE.w #00, <D0
      ldx Hsync.work.idx.0
      lda sine.table,x
      sta <R0.l
      MOVE.b #$1, <R0.h
      MOVE.w #$000, <R1
      cly
.loop
      lda sine.table,x
        phx
      tax
      lda sine.table,x
      tax
      lda sine.table,x
        plx
      lsr a
      lsr a
      clc
      adc #-$20
      sta [<Hsync.work.ptr0],y
        phx
      lsr a
      tax
      lda sine.table,x
      lsr a
      lsr a
      lsr a
      clc
      adc <D0.l
      sta [<Hsync.work.ptr1],y
      cla
      adc <D0.h
      sta [<Hsync.work.ptr2],y
        plx

      lda <R1.l
      clc
      adc <R0.l
      sta <R1.l
      lda <D0.l
      adc <R0.h
      sta <D0.l
      lda <D0.h
      adc #$00
      sta <D0.h


      inx
      iny
      cpy #240
    bcc .loop

      inc Hsync.work.idx.0
      inc Hsync.work.idx.0
  rts

doHsyncWavyEffects1:
      ldx Hsync.work.idx.0
      MOVE.w #00, <D0
      ldx Hsync.work.idx.0
      lda sine.table,x
      sta <R0.l
      MOVE.b #$1, <R0.h
      MOVE.w #$000, <R1
      cly
.loop
      lda sine.table,x
        phx
      tax
      lda sine.table,x
        plx
      lsr a
      lsr a
      clc
      adc #-$20
      sta [<Hsync.work.ptr0],y
        phx
      lsr a
      tax
      lda sine.table,x
      lsr a
      lsr a
      lsr a
      clc
      adc <D0.l
      sta [<Hsync.work.ptr1],y
      cla
      adc <D0.h
      sta [<Hsync.work.ptr2],y
        plx

      lda <R1.l
      clc
      adc <R0.l
      sta <R1.l
      lda <D0.l
      adc <R0.h
      sta <D0.l
      lda <D0.h
      adc #$00
      sta <D0.h


      inx
      iny
      cpy #240
    bcc .loop

      inc Hsync.work.idx.0
      inc Hsync.work.idx.0
  rts

doHsyncStaticScreen:

      ldx Hsync.work.idx.0
      MOVE.w Hsync.work.idx.1, <D0
      cly
.loop


      lda sine.table,x
      sta [<Hsync.work.ptr0],y
      lda #$40 
      sta [<Hsync.work.ptr1],y
      cla
      sta [<Hsync.work.ptr2],y

      inx
      iny
      cpy #240
    bcc .loop

  rts


;...........................
DoDemoControls:
;..................
; Directions

;........
.check.up
        lda input_state.directions
        and #control.up.mask
        cmp #control.up.pressed
      bne .check.dn
.do_up
        lda effectMode
        cmp #$03
      bcs .check.rh
        inc effectMode
        jmp .check.rh

;........
.check.dn
        lda input_state.directions
        and #control.dn.mask
        cmp #control.dn.pressed
      bne .check.rh
.do_dn
        lda effectMode
      BEQ.l .check.rh
        dec effectMode
        jmp .check.rh

;........
.check.rh
        lda input_state.directions
        and #control.rh.mask
        cmp #control.rh.pressed
      bne .check_left
.do_right
        lda Image.Queue.idx
      beq .check_left
        dec Image.Queue.idx
        jsr LoadImageQueue
        jmp .check.b2

;........
.check_left
        lda input_state.directions
        and #control.lf.mask
        cmp #control.lf.pressed
      bne .check.b2
.do_left
        lda Image.Queue.idx
      beq .do.left
        inc a
        cmp Image.Queue.len
      bcs .check.b2
.do.left
        inc Image.Queue.idx
        jsr LoadImageQueue
        jmp .check.b2

;..................
; Buttons

;........
.check.b2
        lda input_state.buttons
        and #control.b2.mask
        cmp #control.b2.pressed
      bne .check.b1
.do_b2
      lda DDA.QueueSlot
      inc a
      cmp DDA.QueueLen
    bcc .cont
      bra .check.b1
.cont
      inc DDA.QueueSlot
      DDA.PlayQueue DDA.QueueSlot
      jmp .out




;........
.check.b1
        lda input_state.buttons
        and #control.b1.mask
        cmp #control.b1.pressed
      bne .check.st
.do_b1
      lda DDA.QueueSlot
    beq .check.st
      dec DDA.QueueSlot
      DDA.PlayQueue DDA.QueueSlot
      jmp .out

;........
.check.st
        lda input_state.buttons
        and #control.st.mask
        cmp #control.st.pressed
      bne .check.sl
.do_st
      DDA.PlayQueue DDA.QueueSlot
      jmp .out

;........
.check.sl
        lda input_state.buttons
        and #control.sl.mask
        cmp #control.sl.pressed
      bne .out
.do_sl
      lda waveMode
      inc a
      cmp #$03
    bcc .sl.update
      cla
.sl.update
      sta waveMode

.out

  rts

;Main end
;//...................................................................

    .include "../demo/image_lib.asm"


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;

;....................................
    .code
    .bank $02, "Subcode 1"
    .org $8000
;....................................


  IncludeBinary Font.cell, "../base_func/video/print/font.dat"

Font.pal: .db $00,$00,$33,$01,$ff,$01,$ff,$01,$ff,$01,$ff,$01,$ff,$01,$f6,$01
Font.pal.size = sizeof(Font.pal)


    ;// Support files for MAIN
    .include "../base_func/init/InitHW.asm"


;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;Bank 2 end

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Data/Code


;/////////////////////////////////////////////////////////////////////////////////
;

;....................................
  .bank $03, "DDA samples"
    .org $4000
;....................................
    .page 3
    IncludeData emergency, "../assets/audio_dda/emergency.data.inc"

    .page 3
    IncludeData explosion2,  "../assets/audio_dda/explosion2.data.inc"

    .page 3
    IncludeData hypercocoon,  "../assets/audio_dda/hypercocoon.data.inc"

    .page 3
    IncludeData lightning,  "../assets/audio_dda/lightning.data.inc"

    .page 3
    IncludeData stageclear,  "../assets/audio_dda/stageclear.data.inc"


;/////////////////////////////////////////////////////////////////////////////////
;

;....................................
  .bank $10, "Images"
    .org $4000
;....................................

;....................................
    .page 2
    IncludeBinary image1.cell, "../assets/BG/1/test.bin", 32
    .page 2
    IncludeBinary image1.pal, "../assets/BG/1/test.pal"
    .page 2
    IncludeBinary image1.map, "../assets/BG/1/test.map"

;....................................
    .page 2
    IncludeBinary image2.cell, "../assets/BG/2/test.bin", 32
    .page 2
    IncludeBinary image2.pal, "../assets/BG/2/test.pal"
    .page 2
    IncludeBinary image2.map, "../assets/BG/2/test.map"

;....................................
    .page 2
    IncludeBinary image3.cell, "../assets/BG/3/test.bin", 32
    .page 2
    IncludeBinary image3.pal, "../assets/BG/3/test.pal"
    .page 2
    IncludeBinary image3.map, "../assets/BG/3/test.map"

;....................................
    .page 2
    IncludeBinary image4.cell, "../assets/BG/4/test.bin", 32
    .page 2
    IncludeBinary image4.pal, "../assets/BG/4/test.pal"
    .page 2
    IncludeBinary image4.map, "../assets/BG/4/test.map"

;....................................
    .page 2
    IncludeBinary image5.cell, "../assets/BG/5/test.bin", 32
    .page 2
    IncludeBinary image5.pal, "../assets/BG/5/test.pal"
    .page 2
    IncludeBinary image5.map, "../assets/BG/5/test.map"

;....................................
    .page 2
    IncludeBinary image6.cell, "../assets/BG/6/test.bin", 32
    .page 2
    IncludeBinary image6.pal, "../assets/BG/6/test.pal"
    .page 2
    IncludeBinary image6.map, "../assets/BG/6/test.map"

;....................................
    .page 2
    IncludeBinary image7.cell, "../assets/BG/7/test.bin", 32
    .page 2
    IncludeBinary image7.pal, "../assets/BG/7/test.pal"
    .page 2
    IncludeBinary image7.map, "../assets/BG/7/test.map"

;....................................
    .page 2
    IncludeBinary image8.cell, "../assets/BG/8/test.bin", 32
    .page 2
    IncludeBinary image8.pal, "../assets/BG/8/test.pal"
    .page 2
    IncludeBinary image8.map, "../assets/BG/8/test.map"

;....................................
    .page 2
    IncludeBinary image9.cell, "../assets/BG/9/test.bin", 32
    .page 2
    IncludeBinary image9.pal, "../assets/BG/9/test.pal"
    .page 2
    IncludeBinary image9.map, "../assets/BG/9/test.map"

;....................................
    .page 2
    IncludeBinary image10.cell, "../assets/BG/10/test.bin", 32
    .page 2
    IncludeBinary image10.pal, "../assets/BG/10/test.pal"
    .page 2
    IncludeBinary image10.map, "../assets/BG/10/test.map"

;....................................
    .page 2
    IncludeBinary image11.cell, "../assets/BG/11/test.bin", 32
    .page 2
    IncludeBinary image11.pal, "../assets/BG/11/test.pal"
    .page 2
    IncludeBinary image11.map, "../assets/BG/11/test.map"

;....................................
    .page 2
    IncludeBinary image12.cell, "../assets/BG/12/test.bin", 32
    .page 2
    IncludeBinary image12.pal, "../assets/BG/12/test.pal"
    .page 2
    IncludeBinary image12.map, "../assets/BG/12/test.map"

;....................................
    .page 2
    IncludeBinary image13.cell, "../assets/BG/13/test.bin", 32
    .page 2
    IncludeBinary image13.pal, "../assets/BG/13/test.pal"
    .page 2
    IncludeBinary image13.map, "../assets/BG/13/test.map"

;....................................
    .page 2
    IncludeBinary image14.cell, "../assets/BG/14/test.bin", 32
    .page 2
    IncludeBinary image14.pal, "../assets/BG/14/test.pal"
    .page 2
    IncludeBinary image14.map, "../assets/BG/14/test.map"

;....................................
    ;Pad the Rom
    .bank $7f, "PAD"
;....................................


;END OF FILE