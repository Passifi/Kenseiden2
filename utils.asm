TimerDone     equ $1000
TimerRepeat   equ $0001

; struct Timer Data
TimerInterval equ 0 ; Word
TimerStartInterval equ 2 ; Word
TimerCallback equ 4 ; Long
TimerStride equ 8

;testStruct 
MultiplyIndexRegisterBytimerStride: Macro  ; \1 is the index register \2 is which ecer register is free for the bitshift multoperations
  move.w \1,\2 
  lsl.w #3,\1 
  ENDM
; struct End 


rng: ; returns a random value in d0 
  ; touches d0-d2 
  move.l (randomSeed),d0
  move.l d0,d2 
  lsl.l #7,d2
  lsl.l #6,d2
  eor.l d2,d0
  move.l d0,d2
  lsr.l #7,d2
  lsr.l #7,d2
  lsr.l #3,d2
  eor.l d2,d0
  move.l d0,d2
  lsl.l #5,d2
  eor.l d2,d0
  move.l d0,(randomSeed)
  rts
FastPauseZ80: macro
  move.w #RequestBus,(Z80BusReq) 
  endm
  
PauseZ80: Macro
  move.w #RequestBus,(Z80BusReq)
.wait 
  btst.b #BusReadyBit,(Z80BusReq)
  bne.s .wait
  ENDM

ResumeZ80: Macro
  move.w #ReleaseBus,(Z80BusReq)
  ENDM


TurnOffIRQ: Macro 
  move.w #$2700,SR 
  ENDM
TurnOnIRQ: Macro 
  move.w #$2300,SR 
  ENDM

IncTimer: Macro 
  addq.l #1,MainTimer
ENDM
CleanUpTimers: Macro 
  ; lea stackAddress,a0
  ; movea.l stackPtr,a1
.loop
  cmpa.w a0,a1
  beq .end
  move.w (a0)
.end
ENDM

SetupControllers: Macro 
  FastPauseZ80
    move.b  #$40,(Ctrl_Port_1)   ; 1P control port
    move.b  #$40,(Data_Port_1)   ; 1P data port
  ResumeZ80
  ENDM

addTimer:; d0 contains Interval d1 contains 
;timer,d2 contains flags 
  lea TimerArray,a0
  clr.l d5  
  move.w TimerIndex,d5
  ; TimerStride * TimerIndex to get the index at the right position currently TimerStride is 10
  MultiplyIndexRegisterBytimerStride d5,d6 
  move.w d0,(TimerInterval,a0,d5)
  move.w d0,(TimerStartInterval,a0,d5)
  move.l d1,(TimerCallback,a0,d5)
  addq.w #1,(TimerIndex)
  rts

doFunStuff:
  rts

resetTimer: ; uses d3 as index  and modifies d2
  lea TimerArray,a3
  MultiplyIndexRegisterBytimerStride d3,d4 
  move.w (TimerStartInterval,a3,d3),(TimerInterval,a3,d3)
  rts


handleTimers:
  addq.l #1,(MainClock)
  lea TimerArray,a0 
  move.w TimerIndex,d5
  move.w #0,d0 
  subq.w #1,d5  
.loop
  subq.w #1,(TimerInterval,a0,d0)
  bgt .next 
  move.w (TimerStartInterval,a0,d0),(TimerInterval,a0,d0)
.handleCallback
  move.l (TimerCallback,a0,d0),a1
  cmpa.l #0,a1
  beq .next
  movem.l d0-d7/a0-a1,-(sp)
  jsr (a1)
  movem.l (sp)+,d0-d7/a0-a1
.next 
  add.w #TimerStride,d0  
  dbra d5,.loop
  rts
