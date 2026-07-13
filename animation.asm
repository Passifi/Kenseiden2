
AnimationTimers equ $ff6000
AnimationTimersEnd equ $ff6200
PlayerAnimationTimer equ AnimationTimers 
PlayerState equ PlayerX+8
PlayerAnimation equ PlayerX+10

PlayerAnimationCurrentFrame equ 0 
PlayerAnimationtimeRemaining equ 2
PlayerAnimationdataindex = equ 4
SpriteArray equ $ff0000
; non-player animations with preloaded spritedata 
; when constructing the sprite table we use SpriteOffset to be added to the spritebase 
; e.g. TileNo 123 is the base then we add the offset to that base 
; when the Timer has run out 
TimerDone equ 7
AnimationDataFrameLength equ 2 
AnimationDataMaxFrames equ 0
PlayerAnimationData:; first byte maxFrames, secondByte frameLength
  dc.w 4,20,4,20,4,20,4,20,4,20,4,20,4,20,4,20
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
  lea Player,a2
  lea PlayerAnimation,a0
  lea PlayerAnimationData,a1 
  move.w (PlayerState,a2),d0 
  btst #7,d0
  bne animatePlayer
setAnimationState:
  and.w #$ef,d0 
  lsl.w #3,d0 
  move.w #0,(PlayerAnimationCurrentFrame,a0) 
  move.w (AnimationDataFrameLength,a1,d0),d1 
  move.w d1,(PlayerAnimationtimeRemaining,a0)
  rts 
animatePlayer:
  move.w (PlayerAnimationtimeRemaining,a0),d2
  subq.w #1,d2
  bgt.w .next
  move.w (AnimationDataFrameLength,a1),d2
  move.w (PlayerAnimationCurrentFrame),d1
  addq.w #1,d1 
  cmp (AnimationDataMaxFrames,a1,d0),d1
  blt.w .next
  move.w #0,d1
.next
  move.w d1,(PlayerAnimationCurrentFrame,a0)
  move.w d2,(PlayerAnimationtimeRemaining,a0)
  rts 
; idle idle-Statusswitch 

; walking equ 4
; hurt equ 8
;
statusSwitch:
idle equ handleIdle
walking equ handleWalking
hurt equ handleHurt

loadFrame: 
  move.w (playerStatus),d0 
  lea playerAnimations,a0 
  lea statusSwitch,a1 

  rts
  

