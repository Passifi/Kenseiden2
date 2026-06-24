BulletArraySize equ $20
BulletArrayLength equ $10
BulletX equ 0
BulletY equ 2 
BulletVelocityX equ 4 
BulletVelocityY equ 6 
BulletDataSize equ 8
MouseIndex equ $ff4ffa
MouseArray equ $ff5000
MouseX equ 0 
MouseY equ 2 
MouseVelocityX equ 4
MouseVelocityY equ 6
SpriteFrame equ 8 
MouseSize equ 16
pushStack: Macro 
  move.l \1,a5 
  move.b d6,-(a5)
  move.l a5,\1
ENDM

pushBullet: Macro 
  pushStack \1 
ENDM

popBullet: Macro 
  move.l \1,a0
  move.b (a0)+,d6 ; currently not bveing used just to remind myself of the clean implementation where a value gets retrieved
  move.l a0,(\1)
ENDM

pushMouse: Macro 
  pushStack MouseToRemoveStackpointer
ENDM

initMouseArray:
  move.w #0,(MouseIndex)
  move.l #MouseToRemoveStack,MouseToRemoveStackpointer
  rts

addMouse: ;d0,d1 -> x,y
  lea MouseArray,a0 
  clr.l d3
  move.w (MouseIndex),d3
  lsl.w #4,d3
  move.w d0,(MouseX,a0,d3)
  move.w d1,(MouseY,a0,d3)
  move.w #15,(MouseVelocityX,a0,d3)
  move.w #15,(MouseVelocityY,a0,d3)
  move.w #0,(SpriteFrame,a0,d3)
  addq.w #1,(MouseIndex)
  rts
moveMouses: 
  lea MouseArray,a0
  lea MouseIndex,a1
  clr.l d3
  move.w #0,d5
.loop
  move.w d5,d3
  lsl.w #4,d3
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
  move.w (SpriteFrame,a1,d4),(SpriteFrame,a1,d3)
  subq.w #1,d0
  jmp .loop
.end 
  move.w d0,(MouseIndex)
  move.l a0,(MouseToRemoveStackpointer)
  rts 

initBulletArray:
  move.w #0,(BulletIndex)
  move.l #BulletsToRemoveStack,(BulletStackPointer)
  rts

addBullet: ;d0,d1,d2,d3,d4 -> x,y,xVel,yVel,type
  move.w (BulletIndex),d5 
  cmp.w #BulletArraySize,d5 
  bge .end ; if index >= array size return 
  lsl.w #3,d5 ;set d5 to proper position in array
  lea BulletArray,a0 
  move.w d0,(BulletX,a0,d5)
  move.w d1,(BulletY,a0,d5)
  move.w d2,(BulletVelocityX,a0,d5)
  move.w d3,(BulletVelocityY,a0,d5)
  addq.w #1,(BulletIndex)
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
  subq.w #1,d4
  cmp.w #1,d4
  ble.w .end
  lsl.w #3,d4 
  lsl.w #3,d3  
  lea (BulletArray),a2 
  move.w (BulletX,a2,d4),(BulletX,a2,d3)
  move.w (BulletY,a2,d4),(BulletY,a2,d3)
  move.w (BulletVelocityX,a2,d4),(BulletVelocityX,a2,d3)
  move.w (BulletVelocityX,a2,d4),(BulletVelocityY,a2,d3)
.end 
  subq.w #1,(BulletIndex)
  rts



processBullets: ;d6 contains the current index. It's used in pushBullet so don't touch it!
  move.w (BulletIndex),d5
  moveq #0,d6 
  cmp.w #0,d5
  ble .end ; no Bullets return
  moveq #0,d3
  subq.w #1,d5
  lea (BulletArray),a0
.loop
  move.w (BulletX,a0,d3),d0 
  add.w (BulletVelocityX,a0,d3),d0 
  cmp.w #$1320,d0
  bhi .removeonX
  cmp.w #$00,d0 
  bge .next
.removeonX
  pushBullet BulletStackPointer
  add.w #8,d3
  jmp .continue
.next
  move.w d0,(BulletX,a0,d3)
  move.w (BulletY,a0,d3),d0 
  add.w (BulletVelocityY,a0,d3),d0
  cmp.w #$1320,d0
  bhi .removeOnY
  cmp.w #$0000,d0 
  bge .next2
.removeOnY
  pushBullet BulletStackPointer
.next2
  move.w d0,(BulletY,a0,d3)
.continue
  addq.l #8,d3
  addq.w #1,d6 
  dbf.w d5,.loop
.end
  rts
movePlayer: ; dynamic version with d4,d5 as x,y change ; touches d4,5 
  add.l d4,(PlayerXAccu) 
  add.l d5,(PlayerYAccu) 
  rts 
resetShots: 
  move.w #0,(shotDirectionY) 
  move.w #0,(shotDirectionX)
  rts 
