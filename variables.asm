RAM_START           equ $ff0000

SystemBlock         equ RAM_START 
PressedButtons      equ RAM_START+1 ;byte
EditingFlags        equ RAM_START+2 ;byte
ScrollPosition      equ RAM_START+6 ;long
randomSeed          equ RAM_START+10 ;long
currentScore        equ RAM_START+20 ;long
currentScoreEnd     equ currentScore+5 ;marker
shotDirection       equ currentScoreEnd+11 ; marker 
shotDirectionX      equ shotDirection ;word
shotDirectionY      equ shotDirection+2 ;word
VblankStatus        equ RAM_START+shotDirectionY ;byte
;Timer Data
MainTimer           equ RAM_START+300 ; Long
SpawnTimer          equ MainTimer+4 ;long
TimerArray          equ SpawnTimer+4 ;; consider always marking how large a memory block is and not just where it starts
WaitTimer           equ TimerArray ;word
TimerIndex          equ TimerArray-2 ;word
MainClock           equ TimerArray-6 ;long
TimerArrayEnd       equ TimerArray+MaxTimers*8
LastShot            equ TimerArrayEnd+10

GraphicsBlock       equ RAM_START+$1000  ;base     
GraphicStack        equ GraphicsBlock ; long
GraphicStackPointer equ GraphicsBlock+4 ;long addressPointer
; PlayerData
PlayerBlock         equ RAM_START+$2000
PlayerPosition      equ PlayerBlock+300 
PlayerXAccu         equ PlayerBlock+300
PlayerYAccu         equ PlayerBlock+304
PlayerX             equ PlayerXAccu
PlayerY             equ PlayerYAccu 
PlayerStatus        equ PlayerYAccu+4 
PlayerSpriteBase    equ PlayerYAccu+8  
CurrentPlayerAnimationFrame equ PlayerSpriteBase+4
LastAnimationTime   equ CurrentPlayerAnimationFrame+4; long
; PlayerBulletData
CurrentBulletID       equ LastAnimationTime+4 ; long
BulletIndex           equ CurrentBulletID+4
BulletArray           equ BulletIndex+2
BulletsToRemoveStack  equ BulletArray+BulletArrayMaxSize*8+20
BulletStackPointer    equ BulletsToRemoveStack+8
;Enemy Data
EnemyBlock        equ RAM_START+$3000
MouseToRemoveStack equ EnemyBlock 
MouseToRemoveStackpointer equ  MouseToRemoveStack+4 
;Tilemap Data
TilemapBlock:
Tilemap             equ RAM_START+$4000
TilemapEnd          equ Tilemap+64*28*2
numOfSprites        equ TilemapEnd+100
SpriteTable         equ numOfSprites+4


