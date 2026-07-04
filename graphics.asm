; variable positions
RAMStart    equ $ff0000
variableStart equ $ffff00
SpriteTableVDP_Base equ $F000
; command macros
VRAMWrite   equ $4000
CRAMWrite   equ $C000
VSRAM_ADDR_CMD equ $40000010
VDP_control equ $c00004
VDP_data    equ $c00000

;constants
; relative position of these window elements in PatternTable 
; must be adjusted when changing graphics loading routines 
; or it must be made sure that they remain the same inside the routine
CornerBlock equ $11
SingleLineBlock equ $12 
TopLineBlock  equ $15
MiddleBlock   equ $17

SCREEN_H equ 320 
SCREEN_W equ 256 
MAX_SPRITES equ 53
VDP_mode_1          equ $00
VDP_mode_2          equ $01
PatternA_addr       equ $02
PatternWindow_addr  equ $03
PatternB_addr       equ $04
Sprite_Attrib_Table_Addr equ $05
Background_color_reg equ $07
hirq_reg equ $0a
VDP_mode_3          equ $0b
VDP_mode_4          equ $0c
hScroll_data_addr   equ $0d
auto_incr_reg   equ     $0f
scroll_size     equ     $10 
window_x_position equ   $11 
window_y_position equ   $12 
DMA_length_low    equ $13 
DMA_length_high   equ $14
DMA_src_low       equ $15 
DMA_src_mid       equ $16
DMA_src_high      equ $17
HScroll           equ $f400

SET_REGISTER  equ $8000

Mode1_Base equ $4
HIRQBit     equ %00010000
HV_CounterBit     equ %00000100

Mode2_Base    equ $4
DisplayBit    equ %01000000 
VIrqBIT       equ %00100000 
DMAEnableBit  equ %00010000 
Cell30ModeBit equ %00001000 


;struct Sprite
spriteX equ 1
spriteY equ 2
SpriteTile equ 2 
SpriteSize equ 16
;struct Sprite_End
; TileAttributes  
FlipTile_Horizontally equ $0800
FlipTile_Vertically equ $1000
TilePalette0        equ $0000 
TilePalette1        equ $2000 
TilePalette2        equ $4000 
TilePalette3        equ $6000 
TilePriority        equ $8000 


string:
  dc.b "hello world!\0"
strEnd:

; MACROS
writeToRegister MACRO
  move.w #((($80|(\2&$1f))<<8)|\1),(VDP_control)
ENDM

writeToVRAMAddr: MACRO
  move.w #VRAMWrite|($3fff&\1),(VDP_control)
  move.w #(\1>>14),(VDP_control) 
ENDM

DMACopyVRAM: MACRO
  writeToRegister %01110000|Mode2_Base,VDP_mode_2
  writeToRegister (\1>>1&$ff),DMA_length_low
  writeToRegister ((\1>>1&$ff00)>>8),DMA_length_high
  writeToRegister ((\2>>1)&$ff),DMA_src_low
  writeToRegister ((\2>>1)&$ff00)>>8,DMA_src_mid
  writeToRegister ((\2>>1)&$3f0000)>>16,DMA_src_high
  move.w #($4000|(($efff&\3))),(VDP_control)
  move.w #($80)|(($c000&\3)>>14),(VDP_control)
  writeToRegister %01100000|Mode2_Base,VDP_mode_2
ENDM

SetRegister: MACRO 
  move.w #SET_REGISTER,d0 
  or.w #(\1<<8),d0 
ENDM 

SetWindowSize: MACRO 
  SetRegister window_x_position
  or.b #\1,d0 
  move d0,(VDP_control) 
  SetRegister window_y_position
  or.b #\2,d0  
  move d0,(VDP_control) 
  ENDM
initializeVDP:
  writeToRegister (Mode1_Base|HV_CounterBit),(VDP_mode_1) 
  writeToRegister ((Mode2_Base)|%01100000),VDP_mode_2
  writeToRegister %00000000,VDP_mode_3 
  writeToRegister $30,PatternA_addr 
  writeToRegister $34,PatternWindow_addr 
  writeToRegister $07,PatternB_addr 
  writeToRegister $3D,hScroll_data_addr 
  writeToRegister $78,Sprite_Attrib_Table_Addr 
  writeToRegister %00000000,6 
  writeToRegister %00000000,Background_color_reg 
  writeToRegister %00000000,8 
  writeToRegister %00000000,9 
  writeToRegister $ff,hirq_reg 
  writeToRegister %00000000,window_x_position 
  writeToRegister %00000000,window_y_position 
  writeToRegister %00000010,auto_incr_reg 
  writeToRegister $1,scroll_size 
  rts

ClearVRAM:
  tst.w (VDP_control)
  lea (VDP_control),a0
  lea (VDP_data),a1 
  move.l #$40000000,(a0)
  move.w #0,d0
  move.w #($ffff/2),d1
.loop
  move.w d0,(a1)
  dbf d1,.loop
  rts

clearCRAM:
  tst.w (VDP_control)
  lea (VDP_control),a0 
  lea (VDP_data),a1 
  move.l #$C0000000,(a0)
  move.w #12,d0 
  move.w #($80/2),d1
.loop 
  move.w d0,(a1)
  add.w #15,d0 
  dbf d1,.loop
  rts

clearVSRAM: 
  tst.w (VDP_control) 
  lea (VDP_control),a0
  lea (VDP_data),a1 
  move.l #VSRAM_ADDR_CMD,(a0)
  move.l #120,d1
.loop 
  move.w d0,(a1)
  dbf d1,.loop 
  rts 

clearSprites: ;; clears sprite table pointers
  clr.b (numOfSprites)
  clr.l (SpriteTable+0)
  clr.l (SpriteTable+4)
  rts

Even
DMACopy:
  ; d1 contains length, d2 contains src d3 contains target and d4 contains ram type  
  lea VDP_control,a0
  ; shift src and length registers to get proper length 
  lsr.l #1,d1
  lsr.l #1,d2

  SetRegister VDP_mode_2
  or.w #%01110000|Mode2_Base,d0 
  move.w d0,(a0);register is set DMA is activated 
  ; set length low 
  SetRegister DMA_length_low 
  or.b d1,d0 
  move.w d0,(a0)
  lsr.l #8,d1
  ; set length high
  SetRegister DMA_length_high 
  or.b d1,d0
  move.w d0,(a0)
  ; set low srcbyte
  SetRegister DMA_src_low 
  or.b d2,d0 
  move.w d0,(a0)
  ;set mid source byte
  SetRegister DMA_src_mid 
  lsr.l #8,d2 
  or.b d2,d0 
  move.w d0,(a0)
  ; set high src byte
  SetRegister DMA_src_high 
  lsr.l #8,d2
  and.b #$7f,d2
  or.b d2,d0 
  move.w d0,(a0)
  ; calcualte address data
  move.l d3,d0
  and.w #$3fff,d0 
  or.w d4,d0 ; set ramType (VRAM,CRAM,VSRAM)
  move.w d0,(a0)
  and.w #$c000,d3 
  lsr.w #6,d3 
  lsr.w #8,d3
  move.w d3,d0 
  or.b #$80,d0 
  move.w d0,(a0)
  move.w $ff000000,(a0) ; 
  SetRegister VDP_mode_2
  or.w #%01100000|Mode2_Base,d0 
  move.w d0,(a0);register is set DMA is activated 
  rts

transferTiledata: ; needed? else erease
  rts 

copySpriteTable:
  eor d1,d1 
  move.b (numOfSprites),d1
  cmp #0,d1 
  beq .noSprites
  lsl.l #3,d1
  move.l #SpriteTable,d2 
  move.l #SpriteTableVDP_Base,d3 
  move.l #VRAMWrite,d4
  jsr DMACopy
.noSprites
  rts

createWindowframe: ; needs to be called when the window was changed, or window data was overwritten
  lea VDP_data,a0
  move.w #29,d1 
  writeToVRAMAddr $d000 
  move.w #(CornerBlock|TilePalette1),(a0)
.loopTop 
  move.w #(TopLineBlock|TilePalette1),(a0)
  dbf d1,.loopTop
  move.w #(CornerBlock|FlipTile_Horizontally|TilePalette1),(a0)
  move.l #1,d4
.middleBlockLoop
  move.w #(SingleLineBlock|TilePalette1),(a0)
  move.w #29,d1
.middleLoop 
  move.w #(MiddleBlock|TilePalette1),(a0)
  dbf d1,.middleLoop
  move.w #(SingleLineBlock|FlipTile_Horizontally|TilePalette1),(a0)
  dbf d4,.middleBlockLoop
  move.w #29,d1
  move.w #(CornerBlock|FlipTile_Vertically|TilePalette1),(a0)
.loopBottom 
  move.w #(TopLineBlock|FlipTile_Vertically|TilePalette1),(a0)
  dbf d1,.loopBottom
  move.w #(CornerBlock|FlipTile_Vertically|FlipTile_Horizontally|TilePalette1),(a0)
  rts
writeString: ; srcAddr: a0, targetAddr: d0, length: d2, note that we presume VDP writes  
  jsr setVRAMAddr
  lea (VDP_data),a1
  and.w #$00ff,d1 
.loop 
  move.b (a0)+,d1 
  cmp.b #0,d1
  beq .end
  addq.b #1,d1
  or.w #TilePalette1,d1
  move.w d1,(a1)
  jmp .loop
.end
  rts 

setVRAMAddr: ; address in d0 
  clr.l d1
  move.w d0,d1 
  and.w #$3fff,d0
  or.w #VRAMWrite,d0 
  move.w d0,(VDP_control)
  lsr.w #7,d1
  lsr.w #7,d1
  move.w d1,(VDP_control)
  rts
addSprite: ; modifies d2-d5, a0
  ; usage: x: d0, y: d1, TileNo: d2, SpriteSize: d3 
  ; check xPosition against screen Boundaries
  cmp.w #SCREEN_W,d0
  bge.s .skip
  cmp.w #-32,d0
  ble.s .skip
  ; check yPosition against screen Boundaries 
  cmp.w #(SCREEN_H+32),d1
  bge.s .skip
  lea (SpriteTable),a0 
  move.b (numOfSprites),d4 
  beq.s .first 
  cmp.b #MAX_SPRITES,d4 
  bhs.s .skip
  moveq #0,d5 ; clear d5 
  move.b d4,d5
  lsl.w #3,d5 
  lea (a0,d5.w),a0
  move.b d4,-5(a0)
.first
  addq.b #1,d4 
  add.w #128,d0
  add.w #128,d1
  move.w d1,(a0)+
  move.b d3,(a0)+
  move.b d4,(a0)+
  move.w d2,(a0)+
  move.w d0,(a0)+
  move.b d4,(numOfSprites)
.skip
  rts

buildSpriteTable: ; was this a test? delete if so 
  move.w (spriteX),d0
  move.w (spriteY),d1
  move.w (SpriteTile),d2
  move.w (SpriteSize),d3
  jsr addSprite
  rts
spriteComplete: 
  lea (SpriteTable),a0 
  clr d0 
  move.b (numOfSprites),d0
  cmp.b #0,d0
  beq .initial
  subq.b #1,d0
.initial 
  ; multiply index by 8 + 3 
  lsl.w #3,d0 
  addq.w #3,d0
  lea (a0,d0.w),a0
  move.b #0,(a0)
  rts 

copyTilemapDynamic: Macro ;1 is length \2 is src /3 is destination
  move.l #\1,d1
  move.l #\2,d2 
  move.l #\3,d3 
  move.l #VRAMWrite,d4  
  jsr DMACopy 
  ENDM
copyTilemap: ;
  ;couple of issues here. 1. How to find the exact area to fill in based on the scrollcutout 
  ; this is an issue for another function, and I guess this one should work fine 
  ; but i probably need to move away from a macro to setting d1,d2 before calling the copy tilemap
  copyTilemapDynamic (TilemapEnd-Tilemap),Tilemap,$C000
  ;move.l #(TilemapEnd-Tilemap),d1 
  ;move.l #Tilemap,d2 
  ;move.l #$C000,d3 
  ;move.l #VRAMWrite,d4
  ;jsr DMACopy
  rts

addBulletSprites: 
  lea BulletArray,a1 
  move.w (BulletIndex),d6
  move.w #0,d5
  cmp #0,d6 
  ble .end
  subq.w #1,d6 
.loop
  cmp #Dead,(BulletState,a1,d5)
  beq .deadBullet
  move.w #BulletSpriteNo,d2
  move.w #%0101,d3
  move.w (BulletX,a1,d5),d0
  move.w (BulletY,a1,d5),d1
  lsr.w #4,d0
  lsr.w #4,d1
  move.w d5,-(sp)
  jsr addSprite
  move.w (sp)+,d5
.deadBullet
  add.w #16,d5
  dbf d6,.loop
.end
  rts 

addEnemySprite:
  lea  Enemies,a1
  move.w (EnemyTail),d6
  subq.w #1,d6
  add.w #2,a1
.loop
  move.w (a1)+,d0 
  move.w (a1)+,d1
  lsr.w #4,d0 
  lsr.w #4,d1 
  move.w #%0101,d3 
  move.w #$25,d2
  jsr addSprite
  adda.w #4,a1
  dbf d6,.loop
  rts 

scrollScreen:
  move.w (ScrollPosition),d0 
  writeToVRAMAddr $f400
  move.w d0,(VDP_data)
  addq.w #1,d0 
  move.w d0,(ScrollPosition)
  rts


