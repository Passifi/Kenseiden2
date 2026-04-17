BulletArray equ $FF004000
BulletIndex equ $FF003ffA
BulletArrayLength equ $10

BulletDataSize equ 10

initBulletArray:
  move.w #0,(BulletIndex)
  rts 

addBullet: ;d0,d1,d2,d3,d4 -> x,y,xVel,yVel,type
  lea BulletArray,a0  
  move.w (BulletIndex),d5 
  move.w d5,d6 
  lsl.w #3,d5 
  lsl.w #2,d6
  add.w d5,d6
  adda.w d6,a0
  move.w d0,(a0)+
  move.w d1,(a0)+
  move.w d2,(a0)+
  move.w d3,(a0)+
  move.w d4,(a0)+
  addq.w #1,(BulletIndex) 
  rts 

processBullets:
  lea BulletArray,a0
  lea BulletIndex,a2
  move.w #0,d5
.loop 
  movea.l a0,a1
  move.w (a0)+,d0
  move.w (a0)+,d1
  move.w (a0)+,d2
  move.w (a0)+,d3
  adda.l #2,a0
  add.w d2,d0 
  add.w d3,d1
  move.w d0,(a1)+
  move.w d1,(a1)
  addq.w #1,d5
  cmp.w (a2),d5
  blt .loop
  rts 

removeBullet:
  rts 




