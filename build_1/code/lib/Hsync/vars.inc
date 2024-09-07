
    .zp

        Hsync.tbl.ptr0:          .ds 2
        Hsync.tbl.ptr1:          .ds 2
        Hsync.tbl.ptr2:          .ds 2

        Hsync.work.ptr0:         .ds 2
        Hsync.work.ptr1:         .ds 2
        Hsync.work.ptr2:         .ds 2

        Hsync.work.idx.0:          .ds 1
        Hsync.work.idx.1:          .ds 2

        Hsync.RCR:               .ds 2

    .bss

        Hsync.tbl0.BXR:          .ds 240
        Hsync.tbl0.BYR:          .ds 240
        Hsync.tbl0.BYR.hi:       .ds 240

        Hsync.tbl1.BXR:          .ds 240
        Hsync.tbl1.BYR:          .ds 240
        Hsync.tbl1.BYR.hi:       .ds 240

        Hsync.curTable:          .ds 1

        Hsync.temp:              .ds 2

        vdc_control:             .ds 2

        effectMode:              .ds 1

        waveMode:                .ds 1