FMSound equ $00
PSG equ $7F11
C_3 equ	851
CSharp3 equ	803
D_3 equ	758
DSharp3 equ	715
E_3 equ	675
F_3 equ	637
FSharp3 equ	601
G_3	equ 568
GSharp3 equ	536
A_3 equ	506
ASharp3 equ	477
B_3	equ 450

Entry:
  ld hl,$1fff 
  ld sp,hl 
main:  
  ld a,0
  ld b,0 
  call changeAttunation
  ld c,0 
  ld a,(Index)
  ld ix,Pitches
  cp #0 
  jr z,.getPitch 
.loop 
  inc ix
  inc ix 
  dec a 
  cp #0 
  jr nz,.loop
.getPitch
  ld d,(ix)
  inc ix 
  ld e,(ix)
  call changePitch 
  ld a,(Index)
  inc a 
  cp #11 
  jp nz,.setIndex
  ld a,0
.setIndex
  ld (Index),a
  ld a,255 
.loop2 
  dec a 
  cp 0 
  nop 
  nop 
  nop 
  nop
  nop 
  nop 
  nop 
  nop
  nop 
  nop 
  nop 
  nop
  nop 
  nop 
  nop 
  nop
  jp nz,.loop2
  jp main


changeAttunation: ; a = channel, b = attenuation 
  rrca 
  rrca 
  or b  
  or $90 
  ld (PSG),a
  ret

changePitch: ; c = channel, de = frequnecy, a,b = scratch 
  ld a,e 
  and $0f 
  ld b,a 

  ld a,c 
  rrca
  rrca 
  rrca 
  or b 
  or $80 

  ld (PSG),a 

  ld a,e 
  and $F0
  rrca 
  rrca 
  rrca 
  rrca 
  ld b,a 
  ld a,d 
  rlca
  rlca 
  rlca
  or a,b 
  ld (PSG),a 
  ret 

Pitches: dw C_3,CSharp3,D_3,DSharp3,E_3,F_3,FSharp3,G_3,GSharp3,A_3,ASharp3,B_3 
Index: db 0 
