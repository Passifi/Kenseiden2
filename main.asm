  include "system/cpuVectors.asm"
  include "system/cartridgeHeader.asm"
  include "graphics.asm"
  include "sound.asm"
  include "variables.asm" 
  include "gamelogic.asm"; 
Ports 
Ctrl_Port_1 equ $A10009
Data_Port_1 equ $A10003
Z80Ram      equ $A00000  ; Where Z80 RAM starts
Z80BusReq   equ $A11100  ; Z80 bus request line
Z80Reset    equ $A11200  ; Z80 reset line

; Macros
; constants 
WAITING_FOR_VBLANK  equ 0 
VBLANK_OCCURED      equ 1
UP_BTN              equ 0
RequestBus          equ $100
ReleaseBus          equ 0
BusReadyBit         equ 0
Edit_Mode_CursorBit    equ 0
BulletSpriteNo         equ $21
FastPauseZ80: macro
  move.w #RequestBus,(Z80BusReq) 
  endm
  
PauseZ80: Macro
  move.w #RequestBus,(Z80BusReq)
.wait 
  btst.b #BusReadyBit,(Z80BusReq)
  bne.s .wait
  ENDM

ResumeZ80: Macro
  move.w #ReleaseBus,(Z80BusReq)
  ENDM

SetCursor: Macro 
  move.w #\1,CursorX
  move.w #\2,CursorY
ENDM
TurnOffIRQ: Macro 
  move.w #$2700,SR 
  ENDM
TurnOnIRQ: Macro 
  move.w #$2300,SR 
  ENDM

IncTimer: Macro 
  addq.l #1,MainTimer
ENDM

PushTimer: Macro 
  ; movea.l stackPtr,a0
  move.w #\1,-(a0)
  move.w #\2,-(a0)
  ; move.l a0,stackPtr
ENDM

CleanUpTimers: Macro 
  ; lea stackAddress,a0
  ; movea.l stackPtr,a1
.loop
  cmpa.w a0,a1
  beq .end
  move.w (a0)
.end
ENDM

SetupControllers: Macro 
  FastPauseZ80
    move.b  #$40,(Ctrl_Port_1)   ; 1P control port
    move.b  #$40,(Data_Port_1)   ; 1P data port
  ResumeZ80
  ENDM

EntryPoint:
  TurnOffIRQ
  jsr initializeVDP 
  SetWindowSize 0,$4
  ; Ram intializations 
  ; ===============================
  SetupControllers
  jsr ClearVRAM
  jsr clearCRAM
  jsr copyLettersToVRAM 
  jsr copyTiles
  jsr createWindowframe 
  jsr clearRAM
  ;jsr fillRAM
  move.w #200,(PlayerX) 
  move.w #200,(PlayerY) 
  move.w #10,d1
  lea TimerArray,a0 
.loop1
  move.w #$ffff,(a0)+ 
  dbf d1,.loop1
  SetCursor 0,$80
  move.w #1,(CurrentTileNo)
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
  lea scoreStr,a0 
  move.w #(Window_Base_Address+68),d0
  move.w #5,d2
  jsr writeString
  FastPauseZ80
  move.w #$100,(Z80Reset)
  ResumeZ80
  PauseZ80
  move.b #$f3,d0 
  move.l #$2000,d1
  move.l #$A00000,a0
.z80fillLoop  
  move.b d0,(a0)+
  dbra d1,.z80fillLoop
  jsr playFMNote
  jsr initBulletArray 
  move.l #33,(randomSeed)
  ResumeZ80
  TurnOnIRQ
mainLoop:
  move.b VblankStatus,d0 
  cmp.b #VBLANK_OCCURED,d0 
  bne mainLoop
  jsr processBullets
  jsr inputHandler 
  ; soundroutine here
  jsr clearSprites
  move.w (CurrentTileNo),d2 
  move.w (PlayerX),d0
  move.w (PlayerY),d1
  move.w #%1111,d3
  jsr addSprite
  jsr addBulletSprites
  move.b #WAITING_FOR_VBLANK,VblankStatus
  jsr changeScore
  jmp mainLoop

addBulletSprites: 
  lea BulletArrayPositions,a1 
  move.w (BulletIndex),d6
  cmp #0,d6 
  ble .end
  subq.w #1,d6 
.loop
  move.w #BulletSpriteNo,d2
  move.w #%0101,d3
  move.w (a1)+,d0
  move.w (a1)+,d1
  lsr.w #4,d0
  lsr.w #4,d1
  jsr addSprite
  dbf d6,.loop
.end
  rts 

setTile:
  movem.l d0-d7,-(a7) 
  lea Tilemap,a0 
  move.w (CursorX),d0 
  move.w (CursorY),d1
  move.w (CurrentTileNo),d2
  lsr.w #3,d0
  sub.w #$80,d1
  lsl.w #3,d1
  add.w d0,d1
  lsl.w #1,d1
  adda.l d1,a0
  move.w d2,(a0)
  movem.l (a7)+,d0-d7 
  rts

readCTRL:
  FastPauseZ80
  lea Data_Port_1,a0
  move.b #$40,(a0)
  nop
  nop
  nop
  nop
  move.b (a0),d0
  and.b #$3f,d0
  move.b #$00,(a0)
  nop
  nop
  nop
  nop
  move.b (a0),d1
  and.b #$30,d1 
  lsl.b #2,d1
  or.b  d1,d0
  move.b d0,(RAM_START)
  ResumeZ80
  rts

clearRAM:
  lea RAM_START,a0 
  move.l #0,d0 
  move.l #($ffffff-RAM_START)>>4,d1 
.loop 
  move.l d0,(a0)+ 
  dbra d1,.loop 
  rts

fillRAM:
  lea SpriteTable,a0 
  move.l #$300,d1
  move.l #$ffff,d0
.loop
  move.w d0,(a0)+ 
  dbra d1,.loop
  rts

copyLettersToVRAM:
  writeToVRAMAddr $0c20
  lea letters,a0
  lea vdp_data,a1 
  move #((lettersEnd-letters)/2),d1 
.loop
  move.w (a0)+,(a1)
  dbf d1,.loop
  rts
copyTiles:
  rts

scrollScreen:
  move.w (ScrollPosition),d0 
  writeToVRAMAddr $f400
  move.w d0,(vdp_data)
  addq.w #1,d0 
  move.w d0,(ScrollPosition)
  rts

Position_Zero_Digit equ $0b1
Window_Base_Address equ $d000
updateScoreWindow: ; touches a0,a1,d0,d1 
  lea (vdp_data),a0
  lea (currentScore),a1
  writeToVRAMAddr (Window_Base_Address+68+12) ; intilaize to VRAM address of Window
.loop
  move.b (a1)+,d0 
  clr.l d1
  move.b d0,d1
  lsr.w #4,d0 
  and.w #$000f,d0
  add.w #Position_Zero_Digit,d0 ; $0bf being the position of 
  and.w #$000f,d1
  add.w #Position_Zero_Digit,d1
  or.w #TilePalette1,d0 
  or.w #TilePalette1,d1 
  move.w d0,(a0)
  move.w d1,(a0)
  cmpa.l #currentScoreEnd,a1
  bne .loop 
  rts 
handleTimers:
  lea TimerArray,a0 
  move.l #10,d1
.loop 
  move.w (a0),d0
  subq.w #1,d0
  cmp #0,d0 
  blt .pos
  eor.w d0,d0
.pos
  move.w d0,(a0)+
  dbra d1,.loop
  rts

movePlayer: ; dynamic version with d4,d5 as x,y change ; touches d4,5 
  add.l d4,(PlayerXAccu) 
  add.l d5,(PlayerYAccu) 
  rts 

changeScore: ; touches d0-d1, a0
  move #0,ccr
  move.l #$1234,d0 ; for values larger than a long (so effectivly decimal values with more than 8 digits) you'd need a memory based solution, but this should be fine unlikely that I need them 
  lea currentScoreEnd,a0 
  move.l #5,d2
.loop
  move.b -(a0),d1
  abcd d0,d1 
  ror.l #8,d0
  and.l #$00ffffff,d0
  move.b d1,(a0)
  dbra d2,.loop ; technically could end when Xtend isn't set but we also have to check whether the added value is consumed so this is simpler 
  rts

PlayerSpeed equ 120000
inputHandler:
  clr.l d4 
  clr.l d5
  move.b RAM_START,d0
  move.b (EditingFlags),d1
  btst #0,d0
  bne processDown
processUp:
  btst #Edit_Mode_CursorBit,d1
  bne changeTileUp
moveUp:
  move.l #(-1*PlayerSpeed),d5
  jmp processLeft
changeTileUp:
  addq.w #1,(CurrentTileNo)
  jmp processStart
processDown:
  btst #1,d0
  bne processLeft
  btst #Edit_Mode_CursorBit,d1
  bne changeTileDown
moveDown:
  move.l #PlayerSpeed,d5
  jmp processLeft
changeTileDown:
  subq.w #1,(CurrentTileNo)
processLeft:
  btst #2,d0 
  bne processRight
  move.l #-PlayerSpeed,d4
processRight:
  btst #3,d0 
  bne processA
  move.l #PlayerSpeed,d4
processA:
  btst #4,d0 
  bne processB
  movem.l d0-d7,-(sp)
  move.w (PlayerX),d0 
  move.w (PlayerY),d1 
  ;add.w #200,d0
  ;add.w #200,d1 
  lsl.w #4,d0
  lsl.w #4,d1
  move.w #12,d2
  move.w #0,d3
  jsr addBullet

  movem.l (sp)+,d0-d7
processB:
  btst #5,d0 
  bne processC 
  move.w CurrentTileNo,d3 
  move.w d3,d2 
  and.w #$6000,d2 
  cmp.w #$6000,d2
  bne incrementPalette
  and.w #$9fff,d3 
  move.w d3,CurrentTileNo
  jmp processC
incrementPalette:
  add.w #$2000,d3 
  move.w d3,CurrentTileNo
processC:
  btst #6,d0
  bne processStart 
processStart:
  btst #7,d0
  bne .end
  move.b (EditingFlags),d2 
  eor #1,d2
  move.b d2,(EditingFlags)
.end
  jsr movePlayer
  move.b d0,PressedButtons
  rts 

colorChange:
  clr.w d0 
  move.b (RAM_START+1),d0
  addq.b #1,d0
  move.b d0,(RAM_START+1)
  or.w #$8700,d0 
  move.w d0,(vdp_control)
  rts
changeBackgroundColor:
  move.l (GraphicStackPointer),a0
  move.w #colorChange,d0
  move.w d0,-(a0)
  move.l a0,(GraphicStackPointer)
  rts

changeSprites:
  move.l (GraphicStackPointer),a0 
  move.w #copySpriteTable,d0
  move.w d0,-(a0)
  move.l a0,(GraphicStackPointer)
  rts

handleGraphicStack:
  move.l (GraphicStackPointer),a0
  cmpa.l #GraphicStack,a0
  bge .end
.loop
  movea.w (a0),a1
  jsr (a1)
  adda.l #4,a0
  cmpa.l #GraphicStack,a0
  blt .loop
  move.l a0,(GraphicStackPointer)
.end
  rts

dmaBranchTest:
  ; branch condition is saved in d4 

jumpStart:
  cmp #3,d4 
  bge .end
  lea jumpTable,a0    
  lsl.l #2,d4 
  adda.l d4,a0
  move.l (a0),a1
  jmp (a1) 
.end
  rts 


vramCopy:
  move.l #$1000,d6
  rts
cramCopy:
  move.l #$1100,d6
  rts
vsramCopy:
  move.l #$1200,d6
  rts
four:
  move.l #$1300,d6
  rts

moveCursor:
  move.w (CursorX),d0
  move.w (CursorY),d1
  addq.w #1,d0
  addq.w #1,d1
  and.w #$1ff,d0
  and.w #$1ff,d1
  move.w d0,(CursorX)
  move.w d1,(CursorY)
  rts
rng: ; returns a random value in d0 
  move.l (randomSeed),d0
  move.l d0,d2 
  lsl.l #7,d2
  lsl.l #6,d2
  eor.l d2,d0
  move.l d0,d2
  lsr.l #7,d2
  lsr.l #7,d2
  lsr.l #3,d2
  eor.l d2,d0
  move.l d0,d2
  lsl.l #5,d2
  eor.l d2,d0
  move.l d0,(randomSeed)
  rts
HBlankInterrupt:
  ;DMACopyVRAM 1000,$0000,$0000 
  rte 

copyTilemap:
  move.l #(TilemapEnd-Tilemap),d1 
  move.l #Tilemap,d2 
  move.l #$C000,d3 
  move.l #VRAMWrite,d4
  jsr DMACopy
  rts
VBlankInterrupt: 
  movem.l d0-d7,-(sp)
    jsr readCTRL
    move.b #VBLANK_OCCURED,VblankStatus
    ; handle sprite logic 
    jsr copySpriteTable
    jsr copyTilemap
    jsr handleTimers
    jsr updateScoreWindow
  ;jsr handleGraphicStack
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
  incbin "letters.bin"
lettersEnd:
tile1:
  incbin "tile1.bin"
colors:
  incbin "palette.bin"
  incbin "frameTiles_palette.bin"
  incbin "enemy_palette.bin"
colorsEnd:
tileData:
  dc.l 0,0,0,0,0,0,0,0
  incbin "sprite.bin"
  incbin "frameTiles.bin"
  incbin "enemy.bin"
tileDataEnd:
cursorData:
  move.w #0,d3
  incbin "cursor.bin"
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
jumpTable:
  dc.l vramCopy
  dc.l cramCopy
  dc.l vsramCopy

_end:

