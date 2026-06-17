  
  include "variables.asm" 
  include "system/cpuVectors.asm"
  include "system/cartridgeHeader.asm"
  include "graphics.asm"
  include "sound.asm"
  include "gamelogic.asm"; 
  include "memory.asm"
  include "utils.asm"
  include "system.asm" 

;Ports 
Ctrl_Port_1 equ $A10009
Data_Port_1 equ $A10003
Z80Ram      equ $A00000  ; Where Z80 RAM starts
Z80BusReq   equ $A11100  ; Z80 bus request line
Z80Reset    equ $A11200  ; Z80 reset line

; constants 
WAITING_FOR_VBLANK  equ 0 
VBLANK_OCCURED      equ 1
UP_BTN              equ 0
RequestBus          equ $100
ReleaseBus          equ 0
BusReadyBit         equ 0
Edit_Mode_CursorBit    equ 0
BulletSpriteNo         equ $21
MouseSpriteTileNo     equ $25
Position_Zero_Digit equ $0b1
Window_Base_Address equ $d000
PlayerSpeed equ 120000
; Timer flags

;CurrentMouseFrame 

ShotWaitPeriod equ 20

EntryPoint:
  TurnOffIRQ
  jsr initializeVDP 
  SetWindowSize 0,$4
  ; Ram intializations 
  ; ===============================
  SetupControllers
  jsr clearRAM
  jsr ClearVRAM
  jsr clearCRAM 
  jsr clearVSRAM
  jsr copyLettersToVRAM
  ;---------------------------------a-------------------------------- 
  ; load data
  jsr copyTiles
  jsr createWindowframe 
  ; setup scoreTimer, shotWaitTimer 
  move.w #10,d0 
  move.l #changeScore,d1 
  move.w #01,d2
  jsr addTimer
  move.w #ShotWaitPeriod,d0 
  move.l #0,d1 
  move.w #01,d2
  jsr addTimer
  ;intializePlayer
  move.w #200,(PlayerX) 
  move.w #200,(PlayerY) 
  move.w #10,d1
  move.b #WAITING_FOR_VBLANK,(VblankStatus)
; ==================================
  ; copy initial tiles to VRAM by DMA 
  move.l #GraphicStack,(GraphicStackPointer) 
  move.l #((tileDataEnd-tileData)),d1 ;
  move.l #tileData,d2 
  move.l #$0000,d3
  move.l #VRAMWrite,d4
  jsr DMACopy
  move.l #((colorsEnd-colors)),d1 
  move.l #colors,d2
  move.l #$0000,d3 
  move.l #CRAMWrite,d4
  jsr DMACopy
  move.l #0,d0 
  move.w #$00,(currentScore) 
  jsr changeScore
  move.w #120,shotDirectionX 
  move.w #120,shotDirectionY 
  lea scoreStr,a0 
  move.w #(Window_Base_Address+68),d0
  move.w #5,d2
  jsr writeString
  FastPauseZ80
  move.w #$100,(Z80Reset)
  ResumeZ80
  PauseZ80
  jsr playFMNote
  jsr initBulletArray 
  jsr initMouseArray 
  move.l #33,(randomSeed)
  ResumeZ80
  TurnOnIRQ
mainLoop:
  move.b VblankStatus,d0 
  cmp.b #VBLANK_OCCURED,d0 
  bne mainLoop
  jsr processBullets
  jsr compactBulletArray
  jsr moveMouses
  jsr inputHandler 
  ; soundroutine here
  jsr clearSprites
  move.w #1,d2 
  move.w (PlayerX),d0
  move.w (PlayerY),d1
  move.w #%1111,d3
  jsr addSprite
  jsr addBulletSprites
  jsr addMouseSprites
  move.b #WAITING_FOR_VBLANK,VblankStatus
  jmp mainLoop

inputHandler:
  clr.l d4 
  clr.l d5
  move.b RAM_START,d0
  move.b d0,d6
  not.b d6
  and.b #$0f,d6
  cmp.b #0,d6
  beq .noMovement 
  jsr resetShots
.noMovement 
  btst #0,d0
  bne processDown
processUp:
moveUp:
  move.w #-120,(shotDirectionY) 
  move.l #(-1*PlayerSpeed),d5 
  jmp processLeft
processDown:
  btst #1,d0
  bne processLeft
moveDown:
  move.l #PlayerSpeed,d5
  move.w #120,(shotDirectionY)
  jmp processLeft
processLeft:
  btst #2,d0 
  bne processRight
  move.w #-120,(shotDirectionX)
  move.l #-PlayerSpeed,d4
processRight:
  btst #3,d0 
  bne processA
  move.w #120,(shotDirectionX)
  move.l #PlayerSpeed,d4
processA:
  btst #4,d0 
  bne processB
  ; check cooldown
  move.b (TimerArray+16+TimerFlags),d6
  btst #4,d6
  beq processB 
  ; refactor this into a routine 
  movem.l d0-d7,-(sp)
    move.l #1,d3
    jsr resetTimer
    clr.l d5
    move.w (PlayerX),d0 
    move.w (PlayerY),d1 
    lsl.w #4,d0
    lsl.w #4,d1
    move.w (shotDirectionX),d2
    move.w (shotDirectionY),d3
    jsr addBullet
  movem.l (sp)+,d0-d7
processB:
  btst #5,d0 
  bne processC 
processC:
  btst #6,d0
  bne processStart 
processStart:
  btst #7,d0
  bne .end
.end
  jsr movePlayer
  move.b d0,PressedButtons
  rts 

HBlankInterrupt:
  ;DMACopyVRAM 1000,$0000,$0000 
  rte

VBlankInterrupt: 
  movem.l d0-d7,-(sp)
    jsr readCTRL
    move.b #VBLANK_OCCURED,VblankStatus
    ; handle sprite logic 
    jsr spriteComplete ;finish the sprite table
    jsr copySpriteTable
    jsr copyTilemap
    ; other logic
    jsr handleTimers
    jsr updateScoreWindow
  movem.l (sp)+,d0-d7
  rte
AddressError:
  move.l #$1111,d0 
  move.l #$2222,d1 
  move.l #$3333,d2 
  move.l #$4444,d3 
  move.l #$5555,d4 
  move.l #$6666,d5 
  move.l #$7777,d6 
  move.l #$8888,d7
  jmp AddressError
  rte 

IllegalInstruction:

  rte
Exception:
  rte
  even
letters:
  incbin "assets/letters.bin"
lettersEnd:
colors:
  incbin "assets/palette.bin"
  incbin "assets/frameTiles_palette.bin"
  incbin "assets/enemy_palette.bin"
  incbin "assets/mouse_palette.bin"
colorsEnd:
tileData:
  dc.l 0,0,0,0,0,0,0,0
  incbin "assets/sprite.bin"
  incbin "assets/frameTiles.bin"
  incbin "assets/enemy.bin"
  incbin "assets/mouse.bin"
tileDataEnd:
cursorData:
  move.w #0,d3
  incbin "assets/cursor.bin"
cursorDataEnd:
sounddata:
  dc.b VolumeBit,0,0,0 
  dc.b PitchBit
  dc.w C3
  dc.b 1
  dc.b PitchBit
  dc.w GSharp3
  dc.b 1
  dc.b PitchBit
  dc.w C3>>1
  dc.w D3
  dc.b 1
  dc.b PitchBit
  dc.w GSharp3>>1
  dc.b 1
  dc.b PitchBit
  dc.w F3>>1
  dc.b 1
  dc.b 2,0,0,0
errorStr:
  dc.b "something went wrong",0
scoreStr: 
  dc.b "score",0
_end:

