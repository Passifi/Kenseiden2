AnimationTimers equ $ff6000
AnimationTimersEnd equ $ff6200
SpriteArray equ $ff0000
; non-player animations with preloaded spritedata 
; when constructing the sprite table we use SpriteOffset to be added to the spritebase 
; e.g. TileNo 123 is the base then we add the offset to that base 
; when the Timer has run out 
TimerDone equ 7
handleAnimation:
  lea AnimationTimers,a0
  lea SpriteArray,a1 
  move.l #0,d5
  move.l (AnimationIndex),d4
  subq.l #1,d4
.loop 
  move.b (TimerFlags,a0,d5),d0
  btst #TimerDone,d0
  bne .next 
  ; reset Time
  move.b #0,(TimerFlags,a0,d5)
  move.w (TimerIntervalStart,a0,d5),(TimerInterval,a0,d5)
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
; check the state
playerAnimation:
  lea (Timer+PlayerTimerOffset),a0  
  lea PlayerAnimationAddress,a1 
  move.b (TimerFlags,a0,d5),d0
  btst #TimerDone,d0
  move.b #0,(TimerFlags,a0,d5)
  move.w (TimerIntervalStart,a0,d5),(TimerInterval,a0,d5)
  
  bne .next

.next 
  rts 

