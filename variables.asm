RAM_START           equ $ff0000
PressedButtons      equ RAM_START+1
EditingFlags        equ RAM_START+2
ScrollPosition      equ RAM_START+6
randomSeed          equ RAM_START+10
currentScore        equ RAM_START+20
currentScoreEnd     equ currentScore+5
shotDirection       equ currentScoreEnd+11
shotDirectionX      equ shotDirection
shotDirectionY      equ shotDirection+2
GraphicStack        equ RAM_START+100
GraphicStackPointer equ RAM_START+104
MainTimer           equ RAM_START+200
TimerArray          equ RAM_START+204 ;; consider always marking how large a memory block is and not just where it starts
WaitTimer           equ TimerArray
TimerIndex          equ TimerArray-2
MainClock           equ TimerArray-6

MaxTimers           equ 20 
TimerArrayEnd       equ TimerArray+MaxTimers*8
LastShot            equ TimerArrayEnd+10
PressWait           equ $30
;PlayerData
PlayerPosition      equ RAM_START+300 
PlayerXAccu         equ RAM_START+300
PlayerYAccu         equ RAM_START+304
PlayerX             equ PlayerXAccu
PlayerY             equ PlayerYAccu 
PlayerStatus        equ PlayerYAccu+4 
PlayerSpriteBase    equ PlayerYAccu+8  
CurrentPlayerAnimationFrame equ PlayerSpriteBase+4
LastAnimationTime   equ CurrentPlayerAnimationFrame+4
VblankStatus        equ RAM_START+500
soundIndex          equ RAM_START+506
soundTimer          equ RAM_START+510

Tilemap             equ RAM_START+$1000
TilemapEnd          equ Tilemap+64*28*2
numOfSprites        equ RAMStart+100
SpriteTable         equ numOfSprites+4

CurrentBulletID       equ $ff3ff6
BulletIndex           equ $ff3ffA
BulletArray           equ $Ff4000
BulletsToRemoveStack  equ BulletArray+BulletArrayMaxSize*8+20
BulletStackPointer    equ BulletsToRemoveStack+8
MouseToRemoveStack equ $ff5300 
MouseToRemoveStackpointer equ MouseToRemoveStack  + 4 

