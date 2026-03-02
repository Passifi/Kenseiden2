  include "system/cpuVectors.asm"
  include "system/cartridgeHeader.asm"
  include "graphics.asm"

copyLettersToVRAM:

  writeToVRAMAddr 2080
  lea letters,a0
  lea vdp_data,a1 
  move #416,d1 
.loop
  move.w (a0)+,(a1)
  dbf d1,.loop
  rts 


EntryPoint:
	move.w #$2700,SR 
  jsr initializeVDP 
  jsr ClearVRAM
  jsr clearCRAM
  jsr copyLettersToVRAM 
  move.w #$2300,SR
  move.l #0,d2
LoopPoint:
  lea (vdp_control),a0
  tst.w (vdp_control)   
  lea (vdp_data),a1
  clr.l d3
  move.b d2,d3
  or.w #$8700,d3
  move.w d3,(a0)  
  addq.b #1,d2
  jmp LoopPoint

HBlankInterrupt:
  
  rte 

VBlankInterrupt:

  rte

Exception:
  rte
letters:
  incbin "letters.bin"
_end: 

