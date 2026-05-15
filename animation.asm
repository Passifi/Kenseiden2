AnimationTimers equ $ff6000
AnimationTimersEnd equ $ff6200
SpriteArray equ $ff0000
handleAnimation:
  lea AnimationTimers,a0
  lea SpriteArray,a1 
  move.l #0,d5
  move.l (AnimationIndex),d4
  subq.l #1,d4
.loop 
  move.b (TimerFlags,a0,d5),d0
  btst #7,d0
  bne .next 
  move.b (SpriteOffset,a1,d5),d0 
  move.b (SpriteOffsetMax,a1,d5),d1 
  cmp.b d0,d1
  bge.b .incrementOffset
  move.b #-1,d0
.incrementOffset   
  addq.b #1,d0
  move.b d0,(SpriteOffset,a1,d5) 
  add.w #8,d5
.next
  dbf d4,.loop
  rts 
