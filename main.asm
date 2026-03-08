  include "system/cpuVectors.asm"
  include "system/cartridgeHeader.asm"
  include "graphics.asm"

TurnOffIRQ: Macro 
  move.w #$2700,SR 
  ENDM
TurnOnIRQ: Macro 
  move.w #$2300,SR 
  ENDM

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
  TurnOnIRQ
  jsr initializeVDP 
  jsr ClearVRAM
  jsr clearCRAM
  jsr copyLettersToVRAM 
  move.l #0,d2
  move.l #5,d3
  lea errorStr,a0
  jsr print
  TurnOffIRQ

mainLoop:
  jmp mainLoop

HBlankInterrupt:
  rte 

VBlankInterrupt:
  DMACopyVRAM 1000,$2000,$a000 
  rte

Exception:
  rte
letters:
  incbin "letters.bin"
errorStr:
  dc.b "something went wrong\0"

_end: 

