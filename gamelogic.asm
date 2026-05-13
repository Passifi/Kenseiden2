BulletArraySize equ $20
BulletIndex equ $ff3ffA
BulletArrayPositions equ $ff4000
BulletArrayVelocities equ $ff4000+BulletArraySize*4
BulletStackLimit      equ BulletArrayVelocities+BulletArraySize*4
BulletsToRemoveStack  equ BulletArrayVelocities+BulletArraySize*4+20
BulletStackPointer    equ BulletsToRemoveStack+8
BulletArrayLength equ $10

BulletDataSize equ 10

MouseIndex equ $ff4ffa
MouseArray equ $ff5000

MouseX equ 0 
MouseY equ 2 
MouseVelocityX equ 4
MouseVelocityY equ 6

MouseSize equ MouseX + MouseY + MouseVelocityX + MouseVelocityY 
MouseToRemoveStack equ $ff5300 
MouseToRemoveStackpointer equ MouseToRemoveStack  + 4 

pushStack: Macro 
  move.l \1,a5 
  move.b d6,-(a5)
  move.l a5,\1
ENDM

pushBullet: Macro 
  pushStack BulletStackPointer 
ENDM

popBullet: Macro 
  move.l BulletStackPointer,a0
  move.b (a0)+,d6 ; currently not bveing used just to remind myself of the clean implementation where a value gets retrieved
  move.l a0,(BulletStackPointer)
ENDM

pushMouse: Macro 
  pushStack MouseToRemoveStackpointer
ENDM

initMouseArray:
  move.w #0,(MouseIndex)
  move.l #MouseToRemoveStack,MouseToRemoveStackpointer
  rts

initBulletArray:
  move.w #0,(BulletIndex)
  move.l #BulletsToRemoveStack,(BulletStackPointer)
  rts

addMouse: ;d0,d1 -> x,y
  lea MouseArray,a0 
  clr.l d3
  move.w (MouseIndex),d3
  lsl.w #3,d3
  move.w d0,(MouseX,a0,d3)
  move.w d1,(MouseY,a0,d3)
  move.w #15,(MouseVelocityX,a0,d3)
  move.w #15,(MouseVelocityY,a0,d3)
  addq.w #1,(MouseIndex)
  rts
moveMouses: 
  lea MouseArray,a0
  lea MouseIndex,a1
  clr.l d3
  move.w #0,d5
.loop
  move.w d5,d3
  lsl.w #3,d3
  move.w (MouseX,a0,d3),d0
  move.w (MouseY,a0,d3),d1
  add.w (MouseVelocityX,a0,d3),d0
  add.w (MouseVelocityY,a0,d3),d1
  move.w d0,(MouseX,a0,d3)
  move.w d1,(MouseY,a0,d3)
  addq.w #1,d5
  cmp.w (a1),d5
  bne .loop
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
  cmp.w #$1320,d0
  bhi .removeonX
  cmp.w #$00,d0 
  bge .next
.removeonX
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
  cmp.w #$1320,d0
  bhi .removeOnY
  cmp.w #$0000,d0 
  bge .next2
.removeOnY
  pushBullet
.next2
  move.w d0,(a0)+
.continue
  addq.l #1,d6
  dbf d3,.loop
.end
  rts

compactMouseArray: 
  move.l MouseToRemoveStackpointer,a0 
  lea MouseArray,a1 
  move.w MouseIndex,d0
  clr d3 
.loop
  move.b (a0)+,d3
  cmpa.l #MouseToRemoveStack,a0
  bge .end
  move.w d0,d2 
  lsl.w #3,d2
  lsl.w #3,d3
  move.w (MouseX,a1,d2),d4
  move.w d4,(MouseX,a1,d3)
  move.w (MouseY,a1,d2),d4
  move.w d4,(MouseY,a1,d3)
  move.w (MouseVelocityX,a1,d2),d4
  move.w d4,(MouseVelocityX,a1,d3)
  move.w (MouseVelocityY,a1,d2),d4
  move.w d4,(MouseVelocityY,a1,d3)
  subq.w #1,d0
  jmp .loop
.end 
  move.w d0,(MouseIndex)
  move.l a0,(MouseToRemoveStackpointer)
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




