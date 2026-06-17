rng: ; returns a random value in d0 
  ; touches d0-d2 
  move.l (randomSeed),d0
  move.l d0,d2 
  lsl.l #7,d2
  lsl.l #6,d2
  eor.l d2,d0
  move.l d0,d2
  lsr.l #7,d2
  lsr.l #7,d2
  lsr.l #3,d2
  eor.l d2,d0
  move.l d0,d2
  lsl.l #5,d2
  eor.l d2,d0
  move.l d0,(randomSeed)
  rts

