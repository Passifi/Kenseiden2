BulletArraySize equ $20
BulletArrayPositions equ $ff4000
BulletArrayVelocities equ $ff4000+BulletArraySize*2

BulletIndex equ $ff3ffA
BulletArrayLength equ $10

BulletDataSize equ 10

initBulletArray:
  move.w #0,(BulletIndex)
  rts 

addBullet: ;d0,d1,d2,d3,d4 -> x,y,xVel,yVel,type
  move.w (BulletIndex),d5 
  cmp.w #BulletArraySize-1,d5
  bge .end 
  lsl.w #1,d5
  lea BulletArrayVelocities,a0 
  lea BulletArrayPositions,a1
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
  move.w (BulletIndex),d3
  lea (BulletArrayPositions),a0
  lea (BulletArrayVelocities),a1
.loop
  move.w (a0),d0 
  move.w (a1)+,d1
  add.w d1,d0
  move.w d0,(a0)+
  move.w (a0),d0 
  move.w (a1)+,d1
  add.w d1,d0
  move.w d0,(a0)+
  dbf d3,.loop
  rts 

removeBullet:
  rts 




