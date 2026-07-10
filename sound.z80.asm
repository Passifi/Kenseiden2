FMSound equ $00
PSG equ $7F11
C_3 equ	851>>1
CSharp3 equ	803>>1
D_3 equ	758>>1
DSharp3 equ	715>>1
E_3 equ	675>>1
F_3 equ	637>>1
FSharp3 equ	601>>1
G_3	equ 568>>1
GSharp3 equ	536>>1
A_3 equ	506>>1
ASharp3 equ	477>>1
B_3	equ 450>>1

PSGChannel1 equ 0 
PSGChannel2 equ &64 
PSGChannel3 equ &128

Entry:
  ld hl,$1fff 
  ld sp,hl 
  EI
  IM 1
  ld hl,Pitches
  jp main
  org &38 
VBLANK:
  EI ; why does the interrupt turn interrupt handling off? 
  reti
  org &100
main: 
  halt
  ld ix,Counter
  ld b,(ix+1)
  jp z,.next
  ld c,(ix)
  ld a,0 
  cp c 
  jp nz,.loadBack 
  cp b 
  jp z,.next
.loadBack
  dec bc
  ld (Counter),bc
  jp main

.next
byteProcessing:
  ld b,0
  ld c,(hl) ; now contains controlbyte
  push hl 
    ld hl,SoundRoutineJMPTable
    add hl,bc
    jp (hl)
processNextByte:
  ld a,0 
  cp b 
  jp nz,main 
  cp c 
  jp nz,main 

 jp byteProcessing

SoundRoutines:
  ld a,(hl)
  ld b,0 
  ld c,a
  ld hl,Wait 
  add hl,bc 
  add hl,bc 
  jp (hl)
Wait:
ChangePitchPSG:
ChangePitchYM:
ChangeVolumePSG:
ChangeVolumeFM:
SetFMRegister:
SetPSGNoiseRegister:
EndOfTrack:
NoteOn:
  pop hl 
  inc hl 
  ld a,(hl) ; set Pitch
  ld (PSG),a 
  inc hl 
  ld a,(hl)
  ld (PSG),a
  inc hl  ; set volume 
  ld a,(hl)
  ld (PSG),a 
  inc hl ; set waitTime 
  ld b,(hl) 
  inc hl 
  ld c,(hl)
  push hl 
    ld hl,Counter 
    ld (hl),b
    inc hl 
    ld (hl),c
  pop hl
  jp processNextByte 
NoteOff:
Loop:

.endOfCall00
  ret 
  
Pitches:
  incbin "./test.bin"
SoundRoutineJMPTable:
  dw NoteOn
  dw NoteOff
  dw ChangePitchPSG
  dw ChangeVolumePSG
  dw EndOfTrack
Index: db 0 
Counter: dw 0
