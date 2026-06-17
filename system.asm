readCTRL:
  FastPauseZ80
  lea Data_Port_1,a0
  move.b #$40,(a0)
  nop
  nop
  nop
  nop
  move.b (a0),d0
  and.b #$3f,d0
  move.b #$00,(a0)
  nop
  nop
  nop
  nop
  move.b (a0),d1
  and.b #$30,d1 
  lsl.b #2,d1
  or.b  d1,d0
  move.b d0,(RAM_START)
  ResumeZ80
  rts

updateScoreWindow: ; touches a0,a1,d0,d1 
  lea (VDP_data),a0
  lea (currentScore),a1
  writeToVRAMAddr (Window_Base_Address+68+12) ; intilaize to VRAM address of Window
.loop
  move.b (a1)+,d0 
  clr.l d1
  move.b d0,d1
  lsr.w #4,d0 
  and.w #$000f,d0
  add.w #Position_Zero_Digit,d0 ; $0bf being the position of 
  and.w #$000f,d1
  add.w #Position_Zero_Digit,d1
  or.w #TilePalette1,d0 
  or.w #TilePalette1,d1 
  move.w d0,(a0)
  move.w d1,(a0)
  cmpa.l #currentScoreEnd,a1
  bne .loop 
  rts 

changeScore: ; touches d0-d1, a0
  move #0,ccr
  move.l #$1234,d0 ; for values larger than a long (so effectivly decimal values with more than 8 digits) you'd need a memory based solution, but this should be fine unlikely that I need them 
  lea currentScoreEnd,a0 
  move.l #5,d2
.loop
  move.b -(a0),d1
  abcd d0,d1 
  ror.l #8,d0
  and.l #$00ffffff,d0
  move.b d1,(a0)
  dbra d2,.loop ; technically could end when Xtend isn't set but we also have to check whether the added value is consumed so this is simpler 
  rts

