PSGPort equ $C00011 
C3      equ	851
CSharp3	equ 803
D3      equ	758
DSharp3 equ	715
E3      equ	675
F3	    equ 637
FSharp3	equ 601
G3	    equ 568
GSharp3 equ	536
A3	    equ 506
ASharp3 equ	477
B3      equ	450

VolumeBit equ 0 
PitchBit  equ 1 
NoiseBit  equ 2 
setVolume:  ; d1 attunation, d0 channel
  or.b #$90,d0 
  and.b #$0f,d1
  or.b d1,d0 
  move.b d0,(PSGPort)
  rts 

setPitch:  ; d1 pitch,d0  channel
  move d1,d2 
  and.w #$0f,d2 
  lsr.w #4,d1 
  or.b #$80,d0 
  or.b d2,d0 
  move.b d0,(PSGPort)
  move.b d1,(PSGPort)
  rts 
noteOn: 
  rts

noteOff:
  rts 

soundRoutine:
  move.b (soundTimer),d0 
  cmp.b #0,d0 
  ble .processing
  subq.b #1,d0
  move.b d0,(soundTimer)
  bgt .end
.processing
  ; interval counter
  lea (sounddata),a0 
  move.l (soundIndex),d0
  lsl.l #2,d0  ; width of one instruction is 4 bytes
  adda.l d0,a0
  eor.l d0,d0
  ; load in data d0 CMD d1 values  d6 delta ,  since it's on long it's probably betters 
  ; to load it as one and do the processing into registers later :)
.loop
  addq.l #1,(soundIndex)
  move.b (a0)+,d0 
  move.b (a0)+,d1 
  lsl.l #8,d1
  or.b (a0)+,d1  
  move.b (a0)+,d6
  btst #VolumeBit,d0
  bne .checkPitch 
  and.w #$60,d0 ; filter out the command bits 
  jsr setVolume
  jmp .checkDelta
.checkPitch:
  btst #PitchBit,d0 
  bne .checkNoise
  and.w #$60,d0 
  jsr setPitch
  jmp .checkDelta
.checkNoise:
  btst #NoiseBit,d0
  bne .checkDelta
  move.l #0,(soundIndex)
  move #122,(soundTimer)
  jmp .end
.checkDelta 
  cmp.b #0,d6 
  beq .loop 
  move.b d6,(soundTimer)
.end  
  rts 



