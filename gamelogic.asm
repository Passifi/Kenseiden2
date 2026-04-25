BulletArraySize equ $20
BulletArrayPositions equ $ff4000
BulletArrayVelocities equ $ff4000+BulletArraySize*4
BulletStackLimit      equ BulletArrayVelocities+BulletArraySize*4
BulletsToRemoveStack  equ BulletArrayVelocities+BulletArraySize*4+20
BulletStackPointer    equ BulletsToRemoveStack+8
BulletIndex equ $ff3ffA
BulletArrayLength equ $10

BulletDataSize equ 10

pushBullet: Macro 
  move.l BulletStackPointer,a5
  move.b d6,-(a5) ; presumes it's being used inside the bullet processing routine where d3 => current index
  move.l a5,(BulletStackPointer)
ENDM

popBullet: Macro 
  move.l BulletStackPointer,a0
  move.b (a0)+,d6 ; currently not bveing used just to remind myself of the clean implementation where a value gets retrieved
  move.l a0,(BulletStackPointer)
ENDM

initBulletArray:
  move.w #0,(BulletIndex)
  move.l #BulletsToRemoveStack,(BulletStackPointer)
  rts

addBullet: ;d0,d1,d2,d3,d4 -> x,y,xVel,yVel,type
  move.w (BulletIndex),d5 
  cmp.w #BulletArraySize,d5
  bge .end
  lsl.w #2,d5
  lea BulletArrayPositions,a0 
  lea BulletArrayVelocities,a1
  adda.l d5,a0
  adda.l d5,a1
  move.w d0,(a0)+ 
  move.w d1,(a0) 
  move.w d2,(a1)+ 
  move.w d3,(a1) 
  addq.w #1,(BulletIndex)
.end 
  rts 

processBullets:
  move.w #0,d6
  move.w (BulletIndex),d3
  cmp.w #0,d3 
  ble .end
  lea (BulletArrayPositions),a0
  lea (BulletArrayVelocities),a1
.loop
  move.w (a0),d0 
  move.w (a1)+,d1
  add.w d1,d0
  cmp #$1400,d0
  blt .next
  pushBullet
  move.w #0,(a0)+
  move.w #0,(a0)+
  suba.l #2,a1
  move.w #0,(a1)+
  move.w #0,(a1)+
  jmp .continue
.next
  move.w d0,(a0)+
  move.w (a0),d0 
  move.w (a1)+,d1
  add.w d1,d0
  cmp #$1400,d0
  blt .next2
  ;pushBullet
.next2
  move.w d0,(a0)+
.continue
  addq.l #1,d6
  dbf d3,.loop
.end
  rts

compactBulletArray:
  move.l BulletStackPointer,a0 
  clr d3
.loop 
  cmpa.l #BulletsToRemoveStack,a0
  bge .end 
  move.b (a0)+,d3 
  jsr removeBullet
  jmp .loop
.end
  move.l a0,(BulletStackPointer)
  rts 

removeBullet: ; index in d3 a2, 
  clr.l d4 
  move.w (BulletIndex),d4
  cmp.w #0,d4
  ble.w .end
  subq.w #1,d4
  move.w d4,(BulletIndex)
  lea (BulletArrayPositions),a2 
  lea (BulletArrayVelocities),a3
  move.l a2,a5 
  move.l a3,a6
  lsl.w #2,d4 
  adda.l d4,a2 
  adda.l d4,a3
  move.l (a2),d5
  move.l (a3),d6
  clr.l d4
  move.w d3,d4
  lsl.w #2,d4 
  adda.l d4,a5 
  adda.l d4,a6
  move.l d5,(a5)
  move.l d6,(a6)
.end 
  rts




