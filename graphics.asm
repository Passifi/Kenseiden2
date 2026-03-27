RAMStart    equ $ff0000

SpriteTable equ RAMStart+1000
variableStart equ $ffff00
SpriteTableVDP_Base equ $F000
VRAMWrite   equ $4000
CRAMWrite   equ $C000

SCREEN_H equ 320 
SCREEN_W equ 200 
numOfSprites equ 64
vdp_control equ $C00004
vdp_data    equ $C00000
SpriteSize equ 16
spriteX equ 1
spriteY equ 2
SpriteTile equ 2 
MAX_SPRITES equ 53
vdp_mode_1          equ $00
vdp_mode_2          equ $01
patternA_addr       equ $02
patternWindow_addr  equ $03
patternB_addr       equ $04
sprite_attrib_table_addr equ $05
background_color_reg equ $07
hirq_reg equ $0a
vdp_mode_3          equ $0b
vdp_mode_4          equ $0c
hScroll_data_addr   equ $0d
auto_incr_reg   equ     $0f
scroll_size     equ     $10 
window_x_position equ   $11 
window_y_position equ   $12 
dma_length_low    equ $13 
dma_length_high   equ $14
dma_src_low       equ $15 
dma_src_mid       equ $16
dma_src_high      equ $17

SET_REGISTER  equ $8000

Mode1_Base equ $4
HIRQBit     equ %00010000
HV_CounterBit     equ %00000100

Mode2_Base    equ $4
DisplayBit    equ %01000000 
VIrqBIT       equ %00100000 
DMAEnableBit  equ %00010000 
Cell30ModeBit equ %00001000 

string:
  dc.b "hello world!\0"
strEnd:
writeToRegister MACRO
  move.w #((($80|(\2&$1f))<<8)|\1),(vdp_control)
ENDM

writeToVRAMAddr: MACRO
  move.w #VRAMWrite|($3fff&\1),(vdp_control)
  move.w #(\1>>14),(vdp_control) 
ENDM



DMACopyVRAM: MACRO
  writeToRegister %01110000|Mode2_Base,vdp_mode_2
  writeToRegister (\1>>1&$ff),dma_length_low
  writeToRegister ((\1>>1&$ff00)>>8),dma_length_high
  writeToRegister ((\2>>1)&$ff),dma_src_low
  writeToRegister ((\2>>1)&$ff00)>>8,dma_src_mid
  writeToRegister ((\2>>1)&$3f0000)>>16,dma_src_high
  move.w #($4000|(($efff&\3))),(vdp_control)
  move.w #($80)|(($c000&\3)>>14),(vdp_control)
  writeToRegister %01100000|Mode2_Base,vdp_mode_2
ENDM

SetRegister: MACRO 
  move.w #SET_REGISTER,d0 
  or.w #(\1<<8),d0 
ENDM 

Even
DMACopy:
  ; d1 contains length, d2 contains src d3 contains target and d4 contains ram type  
  lea vdp_control,a0
  ; shift src and length registers to get proper length 
  lsr.l #1,d1
  lsr.l #1,d2

  SetRegister vdp_mode_2
  or.w #%01110000|Mode2_Base,d0 
  move.w d0,(a0);register is set dma is activated 
  ; set length low 
  SetRegister dma_length_low 
  or.b d1,d0 
  move.w d0,(a0)
  lsr.l #8,d1
  ; set length high
  SetRegister dma_length_high 
  or.b d1,d0
  move.w d0,(a0)
  ; set low srcbyte
  SetRegister dma_src_low 
  or.b d2,d0 
  move.w d0,(a0)
  ;set mid source byte
  SetRegister dma_src_mid 
  lsr.l #8,d2 
  or.b d2,d0 
  move.w d0,(a0)
  ; set high src byte
  SetRegister dma_src_high 
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
  rts

transferTiledata:

  rts 

copySpriteTable:
  ; for now copy the entire possible size of the sprite table 
  move.l #$300,d1 
  move.l #SpriteTable,d2 
  move.l #SpriteTableVDP_Base,d3 
  move.l #VRAMWrite,d4
  jsr DMACopy
  rts

setVRAMAddr:
  clr.l d1
  move.w d0,d1 
  and.w #$3fff,d0
  or.w #VRAMWrite,d0 
  move.w d0,(vdp_control)
  lsr.w #7,d1
  lsr.w #7,d1
  move.w d1,d4
  move.w d1,(vdp_control)
  rts 
print:
  move.w #$c000,d0
  lsl.w #1,d2
  lsl.w #7,d3 
  add.w d2,d0
  add.w d3,d0
  jsr setVRAMAddr
  lea vdp_data,a1
  clr.l d0 
  or.w #$8000,d0
.loop 
  move.b (a0)+,d0 
  cmp.b '\0',d0
  beq .end
  addq.b #1,d0
  move.w d0,(a1)
  jmp .loop
.end
  rts
initializeVDP:
  writeToRegister (Mode1_Base|HV_CounterBit),(vdp_mode_1) 
  writeToRegister ((Mode2_Base)|%01100000),vdp_mode_2
  writeToRegister %00000000,vdp_mode_3 
  writeToRegister $30,patternA_addr 
  writeToRegister $34,patternWindow_addr 
  writeToRegister $07,patternB_addr 
  writeToRegister $78,sprite_attrib_table_addr 
  writeToRegister %00000000,6 
  writeToRegister %00000000,background_color_reg 
  writeToRegister %00000000,8 
  writeToRegister %00000000,9 
  writeToRegister $ff,hirq_reg 
  writeToRegister %00000000,window_x_position 
  writeToRegister %00000000,window_y_position 
  writeToRegister %00000010,auto_incr_reg 
  writeToRegister $1,scroll_size 
  rts

ClearVRAM:
  tst.w (vdp_control)
  lea (vdp_control),a0
  lea (vdp_data),a1 
  move.l #$40000000,(a0)
  move.w #0,d0
  move.w #($ffff/2),d1
.loop
  move.w d0,(a1)
  dbf d1,.loop
  rts

clearCRAM:
  tst.w (vdp_control)
  lea (vdp_control),a0 
  lea (vdp_data),a1 
  move.l #$C0000000,(a0)
  move.w #12,d0 
  move.w #($80/2),d1
.loop 
  move.w d0,(a1)
  add.w #15,d0 
  dbf d1,.loop
  rts

clearSprites:
  clr.b (numOfSprites)
  clr.l (SpriteTable+0)
  clr.l (SpriteTable+4)
  rts

; addsprite usage 
; set 
; move.w (SpriteX),d0 
; move.w (SpriteY),d1 
; move.w (SpriteTile),d2 
; move.w (SpriteSize),d3

addSprite:
  cmp.w #SCREEN_W,d0 
  bge.s .skip
  cmp.w #-32,d0 
  ble.s .skip
  cmp.w #SCREEN_H,d1 
  bge.s .skip
  
  lea (SpriteTable),a0 
  move.b (numOfSprites),d4 
  beq.s .first 
  cmp.b #MAX_SPRITES,d4 
  bhs.s .skip 
  
  moveq #0,d5 
  move.b d4,d5 
  lsl.w #3,d5 
  lea (a0,d5.w),a0
  move.b d4,-5(a0)
.first 
  add.w #128,d0 
  add.w #128,d0
  move.w d1,(a0)+
  move.b d3,(a0)+
  move.b #0,(a0)+
  move.w d2,(a0)+
  move.w d0,(a0)+
  addq.b #1,d4 
  move.b d4,(numOfSprites)
.skip
  rts

buildSpriteTable:
  move.w (spriteX),d0
  move.w (spriteY),d1
  move.w (SpriteTile),d2
  move.w (SpriteSize),d3
  jsr addSprite
  rts


