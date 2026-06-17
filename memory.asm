clearRAM:
  lea RAM_START,a0 
  move.l #0,d0 
  move.l #($ffffff-RAM_START)>>4,d1 
.loop 
  move.l d0,(a0)+ 
  dbra d1,.loop
  rts

fillRAM:
  lea SpriteTable,a0 
  move.l #$300,d1
  move.l #$ffff,d0
.loop
  move.w d0,(a0)+ 
  dbra d1,.loop
  rts

copyLettersToVRAM:
  writeToVRAMAddr $0c20
  lea letters,a0
  lea vdp_data,a1 
  move #((lettersEnd-letters)/2),d1 
.loop
  move.w (a0)+,(a1)
  dbf d1,.loop
  rts
copyTiles:
  rts


