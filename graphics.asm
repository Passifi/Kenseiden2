vdp_control equ $C00004
vdp_data    equ $C00000

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


Mode1_Base equ $4
HIRQBit     equ %00010000
HV_CounterBit     equ %00000100

Mode2_Base    equ $4
DisplayBit    equ %01000000 
VIrqBIT       equ %00100000 
DMAEnableBit  equ %00010000 
Cell30ModeBit equ %00001000 
VRAMWrite     equ $4000

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
  writeToRegister ((Mode2_Base)|%01000000),vdp_mode_2
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
