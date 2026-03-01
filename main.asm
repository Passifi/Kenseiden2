  include "system/cpuVectors.asm"
  include "system/cartridgeHeader.asm"
  include "graphics.asm"

EntryPoint:
	move.w #$2700,SR 
  jsr initializeVDP 
  jsr ClearVRAM
  jsr clearCRAM
  move.w #$2300,SR
  move.l #0,d2
LoopPoint:
  lea (vdp_control),a0
  tst.w (vdp_control)   
  lea (vdp_data),a1
  move.l #$C0000000,(a0)
  move.w d2,(a1) 
  addq.w #1,d2
  jmp LoopPoint

HBlankInterrupt:
  
  rte 

VBlankInterrupt:

  rte

Exception:
  rte

_end: 

