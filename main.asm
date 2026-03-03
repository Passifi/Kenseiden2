  include "system/cpuVectors.asm"
  include "system/cartridgeHeader.asm"
  include "graphics.asm"

copyLettersToVRAM:

  writeToVRAMAddr $0c20
  lea letters,a0
  lea vdp_data,a1 
  move #((_end-letters)/2),d1 
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
  move.l #0,d2
  jsr print
  move.w #$2300,SR
LoopPoint:
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

