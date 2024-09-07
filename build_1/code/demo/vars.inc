    .zp

        ; Audio related
        DDA.ptr:            .ds 2
        DDA.addr.lo:        .ds 6
        DDA.addr.hi:        .ds 6
        DDA.bank:           .ds 6

        DDA.process:        .ds 1


    .bss

        ; Audio related
        DDA.queue.lo:       .ds 50
        DDA.queue.hi:       .ds 50
        DDA.queue.bank:     .ds 50

        DDA.QueueLen:       .ds 1
        DDA.QueueSlot:      .ds 1

        Image.Queue.tile.addr:   .ds 30 * 2
        Image.Queue.tile.bank:   .ds 30 * 2
        Image.Queue.tile.size:   .ds 30 * 2
        Image.Queue.map.addr:    .ds 30 * 2
        Image.Queue.map.bank:    .ds 30 * 2
        Image.Queue.map.size:    .ds 30 * 2
        Image.Queue.pal.addr:    .ds 30 * 2
        Image.Queue.pal.bank:    .ds 30 * 2
        Image.Queue.pal.size:    .ds 30 * 2

        Image.Queue.len:         .ds 1
        Image.Queue.idx:         .ds 1


