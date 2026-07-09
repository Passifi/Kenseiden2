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
  ld a,0
  ld b,0 
  call changeAttunation
  ld c,0 
  ld hl,Pitches
  ld a,(Index)
  cp 0 
  jr z,.getPitch 
  ld c,a 
  ld b,0
  sla c 
  rl b
  sla c 
  rl b 
.getPitch
  add hl,bc 
  ld e,(hl)
  inc hl 
  ld d,(hl)
  call changePitchNew 
  inc hl 
  ld c,(hl)
  inc hl 
  ld b,(hl)
  ld (Counter),bc 
  ld a,(Index)
  inc a 
  cp 11 
  jp nz,.setIndex
  ld a,0
.setIndex
  ld (Index),a
  jp main

changeAttunation: ; a = channel, b = attenuation 
  rrca 
  rrca 
  or b  
  or &90 
  ld (PSG),a
  ret

changePitchNew: ; load pitchdata into de 
  ld a,d
  ld (PSG),a
  ld a,e
  ld (PSG),a
  ret 

changePitch: ; c = channel, de = frequnecy, a,b = scratch 
  ld a,e 
  and &0f 
  ld b,a 

  ld a,c 
  rrca
  rrca 
  rrca 
  or b 
  or &80 

  ld (PSG),a 

  ld a,e 
  and &F0
  rrca 
  rrca 
  rrca 
  rrca 
  ld b,a 
  ld a,d 
  rlca
  rlca
  rlca 
  rlca 
  or a,b 
  ld (PSG),a 
  ret 
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
ChangeVolumePGS:
ChangeVolumeFM:
SetFMRegister:
SetPSGNoiseRegister:
NoteOn:
NoteOff:
Loop:

.endOfCall00
  ret 
  
Pitches: dw &8104, &0000,&8203, &01df,&8104, &0000,&8203, &0001,&8304, &0000,&8403, &01df,&8304, &0000,&8403, &0001,&8504, &0000,&8503, &01df,&8504, &0000,&8503, &0001,&8704, &0000,&8703, &01df,&8704, &0000,&8703, &0001,&8804, &0000,&8903, &01df,&8903, &0001,&8703, &00ef,&8804, &0001,&8304, &00ef,&8304, &0000,&8703, &0001,&8504, &0000,&8503, &00ef,&8504, &0001,&8704, &00ef,&8704, &0000,&8503, &0001,&8804, &0000,&8403, &00ef,&8804, &0001,&8a04, &00ef,&8a04, &0000,&8403, &0001,&8c04, &0000,&8503, &077f,&8c04, &0000,&8503, &0000
SoundRoutineJMPTable:
  dw Wait
  dw ChangePitchYM
  dw ChangePitchPSG
Index: db 0 
Counter: dw 0
