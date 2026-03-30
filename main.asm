  include "system/cpuVectors.asm"
  include "system/cartridgeHeader.asm"
  include "graphics.asm"
; Ports 
Ctrl_Port_1 equ $A10009
Data_Port_1 equ $A10003

RAM_START           equ $ff0000
PressedButtons      equ RAM_START+10
GraphicStack        equ RAM_START+100
GraphicStackPointer equ RAM_START+104
MainTimer           equ RAM_START+200
TimerArray          equ RAM_START+204 ;; consider always marking how large a memory block is and not just where it starts
WaitTimer           equ TimerArray
PressWait           equ $30
CursorPosition      equ RAM_START+400
CursorX             equ CursorPosition 
CursorY             equ CursorPosition+2
CurrentTileNo       equ CursorPosition+4
VblankStatus       equ RAM_START+500
; Macros
; constants 
WAITING_FOR_VBLANK  equ 0 
VBLANK_OCCURED      equ 1
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

EntryPoint:
  TurnOffIRQ
  jsr initializeVDP 
  ; Ram intializations 
  ; ===============================
  jsr ClearVRAM
  jsr clearCRAM
  jsr copyLettersToVRAM 
  jsr copyTiles
  jsr clearRAM
  jsr fillRAM
  move.w #10,d1
  lea TimerArray,a0 
.loop1
  move.w #$ffff,(a0)+ 
  dbf d1,.loop1
  SetCursor 0,$80
  move.w #12,(CurrentTileNo)
  move.b #WAITING_FOR_VBLANK,(VblankStatus)
; ==================================
  ; copy initial tiles to VRAM by DMA 
  move.l #GraphicStack,(GraphicStackPointer) 
  move.l #((tileDataEnd-tileData)/2),d1 ;
  move.l #tileData,d2 
  move.l #$0000,d3
  move.l #VRAMWrite,d4
  jsr DMACopy
  move.l #((colorsEnd-colors)),d1 
  move.l #colors,d2
  move.l #$0000,d3 
  move.l #CRAMWrite,d4
  jsr DMACopy
  move.l #cursorData,d2 
  move.l #((cursorDataEnd-cursorData)/2),d1
  move.l #$0020,d3 
  move.l #VRAMWrite,d4
  jsr DMACopy
  move.l #0,d0 
  lea vdp_control,a0 
  lea vdp_data,a1
  move.l #$c000,d0 
  move.l d0,d1 
  lsr.l #2,d1 
  or.w VRAMWrite,d1 
  move.w d1,(a0)
  and.w #$c000,d0 
  lsr.l #7,d0
  lsr.l #7,d0
  move.w d0,(a0)
  move.l #(30*40),d1 
.loop 
  move.l d1,(a1)
  dbra d1,.loop
  TurnOnIRQ

mainLoop:
  move.b VblankStatus,d0 
  cmp.b #VBLANK_OCCURED,d0 
  bne mainLoop
  jsr clearSprites

  move.w (CurrentTileNo),d2 
  move.w (CursorX),d0
  move.w (CursorY),d1
  move.w #0,d3
  jsr addSprite ; should actually be called outside because its sprite logic same for clear Sprites
  move.b #WAITING_FOR_VBLANK,VblankStatus
  jmp mainLoop

readCTRL:
  move.b #$40,(Data_Port_1)
  move.b #$40,(Ctrl_Port_1)
  move.b (Data_Port_1),(RAM_START)
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


inputHandler:
  move.b RAM_START,d0
  move.b #$7f,RAM_START 
  move.b PressedButtons,d1
  ; check whether button is pressed  
  ; second check checks whether it was pressed before
  btst #0,d0
  bne processDown  
  btst #0,d1 
  beq processDown 
processUp:
  move.b #1,d3 
  jmp processStart
processDown:
  btst #1,d0
  bne processLeft  
  btst #1,d1 
  beq processLeft 
processLeft:
processRight:
processA:
processB:
processC:
processStart:
.end
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

HBlankInterrupt:
  ;DMACopyVRAM 1000,$0000,$0000 
  rte 

VBlankInterrupt: 
  movem.l d0-d7,-(sp)
    move.b #VBLANK_OCCURED,VblankStatus
    ; handle sprite logic 
    jsr copySpriteTable
    jsr handleTimers
    jsr readCTRL
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
letters:
  incbin "letters.bin"
lettersEnd:
tile1:
  incbin "tile1.bin"
colors:
  incbin "color.bin"
colorsEnd:
tileData:
  incbin "shinobirip.bin"
tileDataEnd:
cursorData:
  move.w #0,d3
  incbin "cursor.bin"
cursorDataEnd:
errorStr:
  dc.b "something went wrong\0"
jumpTable:
  dc.l vramCopy
  dc.l cramCopy
  dc.l vsramCopy

_end: 

