BulletArrayMaxSize equ $20
BulletArrayLength equ $10
BulletState equ 0 
BulletX equ BulletState+2
BulletY equ BulletX+2 
BulletVelocityX equ BulletY+2
BulletVelocityY equ BulletVelocityX+2 
BulletDataSize equ 16
EnemyTail equ $ff4ffa
Enemies equ $ff5000
EnemyState equ 0
EnemyX equ EnemyState+2
EnemyY equ EnemyX+2
EnemyVelocityX equ EnemyY+2
EnemyVelocityY equ EnemyVelocityX+2
MaxEnemies equ 16
SpriteFrame equ EnemyVelocityY+2 
EnemyDataSize equ 16
SpawnTimer equ $3000

MouseW equ 8<<4 
MouseH equ 8<<4
BulletW equ 8<<4
BulletH equ 8<<4

Dead equ $ff 
Alive equ $00

pushStack: Macro 
  move.l \1,a5 
  move.b d6,-(a5)
  move.l a5,\1
ENDM

pushBullet: Macro 
  move.l \1,a5 
  move.w (0,a0),-(a5) 
  move.l a5,\1
ENDM

popBullet: Macro 
  move.l \1,a0
  move.b (a0)+,d6 ; currently not bveing used just to remind myself of the clean implementation where a value gets retrieved
  move.l a0,(\1)
ENDM

pushMouse: Macro 
  pushStack MouseToRemoveStackpointer
ENDM

initEnemies:
  move.w #0,(EnemyTail)
  move.l #MouseToRemoveStack,MouseToRemoveStackpointer
  rts

hitDetection: 
  ;  go through all bullets, all mice  
   
  move.w (BulletIndex),d0
  move.w (EnemyTail),d1
  cmp #0,d0 
  beq .end
  cmp #0,d1
  beq .end
  move.w #0,d0
  move.w #0,d1 
  lea Enemies,a0
  lea BulletArray,a1 
.outerLoop 
  move.w d0,-(a7)
  lsl.w #4,d0
.innerLoop  
    move.w d1,-(a7)
    lsl.w #3,d1
      move.w (BulletX,a1,d1),d2 
      move.w (EnemyX,a0,d0),d3
      move.w (EnemyX,a0,d0),d4 
      add.w #MouseW,d3 
      cmp.w d3,d2
      bge .nextInner
      add.w #BulletW,d2 
      cmp.w d2,d4 
      bge .nextInner
      move.w (BulletY,a1,d1),d2 
      move.w (EnemyY,a0,d0),d3 
      move.w (EnemyY,a0,d0),d4
      add.w #MouseH,d3
      cmp.w d3,d2 
      bge .nextInner
      add.w #BulletH,d2
      cmp.w d2,d4
      bge .nextInner
      move.w d0,d6
      move.w #Dead,(BulletState,a1,d1)
      move.w (a7)+,d1 
      move.w (a7)+,d1 

      jmp .end
      ; for testing
.nextInner
    move.w (a7)+,d1 
    addq.w #1,d1 
    cmp.w (BulletIndex),d1
    blt .innerLoop
  move.w (a7)+,d0
  addq.w #1,d0
  cmp.w (EnemyTail),d1
  blt .outerLoop
.end
  rts

spawnEnemies:
  move.w (EnemyTail),d0
  cmp #MaxEnemies,d0
  ble .end 
  subq.w #1,(SpawnTimer) 
  bgt .end
  move.w #300,(SpawnTimer)
  jsr rng 
  move.l d0,d1 
  lsr.w #8,d1  
  and.b #127,d1
  and.b #127,d1  
  jsr addEnemy 
.end 
  rts 

addEnemy: ;d0,d1 -> x,y
  lea Enemies,a0 
  clr.l d3
  move.w (EnemyTail),d3
  lsl.w #4,d3
  move.w d0,(EnemyX,a0,d3)
  move.w d1,(EnemyY,a0,d3)
  move.w #15,(EnemyVelocityX,a0,d3)
  move.w #15,(EnemyVelocityY,a0,d3)
  move.w #0,(SpriteFrame,a0,d3)
  addq.w #1,(EnemyTail)
  rts

steerEnemies: 
  lea Enemies,a0
  lea EnemyTail,a1 
  moveq #0,d5 
  move.w #0,d6
.loop 
  move.w d5,d6 
  lsl.w #4,d6 
  move.w (EnemyX,a0,d6),d0  
  move.w (EnemyY,a0,d6),d1  
  move.w (EnemyVelocityX,a0,d6),d2  
  move.w (EnemyVelocityY,a0,d6),d3
  cmp #$1000,d0 
  blt .check0Boundary
  jmp .inverseVelocityX
.check0Boundary
  cmp #$0,d0 
  bgt .checkYBoundary
.inverseVelocityX 
  not.w d2
  addq.w #1,d2 
  move.w d2,(EnemyVelocityX,a0,d6)
.checkYBoundary
  cmp #$c80,d1 
  blt .checkY0Boundary 
  jmp .inverseVelocityY
.checkY0Boundary 
  cmp #0,d1 
  bgt .wrapUp
.inverseVelocityY
  not.w d3
  addq.w #1,d3
  move.w d3,(EnemyVelocityY,a0,d6)
.wrapUp
  addq.w #1,d5 
  cmp (a1),d5 
  bne .loop
  rts 
moveMouses: 
  lea Enemies,a0
  lea EnemyTail,a1
  clr.l d3
  move.w #0,d5
.loop
  move.w d5,d3
  lsl.w #4,d3
  move.w (EnemyX,a0,d3),d0
  move.w (EnemyY,a0,d3),d1
  add.w (EnemyVelocityX,a0,d3),d0
  add.w (EnemyVelocityY,a0,d3),d1
  move.w d0,(EnemyX,a0,d3)
  move.w d1,(EnemyY,a0,d3)
  addq.w #1,d5
  cmp.w (a1),d5
  bne .loop
  rts
compactEnemies: 
  move.l MouseToRemoveStackpointer,a0 
  lea Enemies,a1 
  move.w EnemyTail,d0
  clr d3 
.loop
  move.b (a0)+,d3
  cmpa.l #MouseToRemoveStack,a0
  bge .end
  move.w d0,d2 
  lsl.w #4,d2
  lsl.w #4,d3
  move.w (EnemyX,a1,d2),d4
  move.w d4,(EnemyX,a1,d3)
  move.w (EnemyY,a1,d2),d4
  move.w d4,(EnemyY,a1,d3)
  move.w (EnemyVelocityX,a1,d2),d4
  move.w d4,(EnemyVelocityX,a1,d3)
  move.w (EnemyVelocityY,a1,d2),d4
  move.w d4,(EnemyVelocityY,a1,d3)
  move.w (SpriteFrame,a1,d4),(SpriteFrame,a1,d3)
  subq.w #1,d0
  jmp .loop
.end 
  move.w d0,(EnemyTail)
  move.l a0,(MouseToRemoveStackpointer)
  rts 

initBulletArray:
  move.w #0,(BulletIndex)
  move.l #BulletsToRemoveStack,(BulletStackPointer)
  rts

addBullet: ;d0,d1,d2,d3,d4 -> x,y,xVel,yVel,type
  move.w (BulletIndex),d5 
  cmp.w #BulletArrayMaxSize,d5 
  bge .end ; if index >= array size return 
  lsl.w #4,d5 ;set d5 to proper position in array
  lea BulletArray,a0 
  adda.w d5,a0
  move.w #Alive,(BulletState,a0)
  move.w d0,(BulletX,a0)
  move.w d1,(BulletY,a0)
  move.w d2,(BulletVelocityX,a0)
  move.w d3,(BulletVelocityY,a0)
  addq.w #1,(BulletIndex)
.end
  rts
removeBullet: Macro
  cmp (BulletIndex),d0
  beq .endOfArray 
  cmp #0,(BulletIndex)
  beq .zeroIndex
  move.w (BulletIndex),d3 
  subq.w #1,d3
  lsl.w #4,d3 
  cmp #Dead,(BulletState,a1,d3)
  beq .endOfArray
  move.w (BulletState,a1,d3),(BulletState,a1,d1)
  move.w (BulletX,a1,d3),(BulletX,a1,d1)
  move.w (BulletY,a1,d3),(BulletY,a1,d1)
  move.w (BulletVelocityX,a1,d3),(BulletVelocityX,a1,d1)
  move.w (BulletVelocityY,a1,d3),(BulletVelocityY,a1,d1)
  move.w #0,(BulletState,a1,d3)
  move.w #0,(BulletX,a1,d3)
  move.w #0,(BulletY,a1,d3)
  move.w #0,(BulletVelocityX,a1,d3)
  move.w #0,(BulletVelocityY,a1,d3)
.endOfArray 
  subq.w #1,(BulletIndex)
.zeroIndex
ENDM

compactBulletArray:
  move.w (BulletIndex),d0 
  lea BulletArray,a0
  move.l a0,a1
  subq.w #1,d0 
.loop 
  move.w d0,d1 
  lsl.w #4,d1 
  move.w (BulletState,a0,d1),d2 
  cmp #Dead,d2 
  bne .continue
  removeBullet
.continue 
  subq.w #1,d0 
  bge .loop
  ; dumb safety check 
  cmp #0,(BulletIndex)
  bge .end 
  move.w #0,(BulletIndex)
.end
  rts

processBullets: ;d6 contains the current index. It's used in pushBullet so don't touch it!
  move.w (BulletIndex),d5
  cmp.w #0,d5
  ble .end ; no Bullets return
  subq.w #1,d5
  lea (BulletArray),a0
.loop
  move.w (BulletX,a0),d0 
  add.w (BulletVelocityX,a0),d0 
  cmp.w #$1400,d0
  bge .removeonX
  cmp.w #$Fa00,d0 
  bge .next
.removeonX
  move.w #Dead,(BulletState,a0) 
  jmp .continue
.next
  move.w d0,(BulletX,a0)
  move.w (BulletY,a0),d0 
  add.w (BulletVelocityY,a0),d0
  cmp.w #$2020,d0
  bge .removeOnY
  cmp.w #$F07C,d0 
  bge .next2
.removeOnY
  move.w #Dead,(BulletState,a0) 
.next2
  move.w d0,(BulletY,a0)
.continue
  add.l #BulletDataSize,a0
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
