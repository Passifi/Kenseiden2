; FLags, constants
TimerDone     equ $1000
TimerRepeat   equ $0001

; struct Timer Data
TimerInterval equ 0 
TimerStartInterval equ 2
TimerCallback equ 4
TimerFlags    equ 8
TimerStride equ TimerInterval+TimerStartInterval+TimerCallback+TimerFlags 
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

addTimer:; d0 contains Interval d1 contains timer,d2 contains flags 
  
  lea TimerArray,a0
  clr.l d5  
  move.w TimerIndex,d5
  ; TimerStride * TimerIndex to get the index at the right position currently TimerStride is 10
  lsl.w #3,d5 
  lsl.w #1,d6 
  add.w d6,d5 
  move.w d0,(TimerInterval,a0,d5)
  move.w d0,(TimerStartInterval,a0,d5)
  move.l d1,(TimerCallback,a0,d5)
  move.w d2,(TimerFlags,a0,d5)
  addq.w #1,(TimerIndex)
  rts
; timer should either be in game logic or it's own file
resetTimer: ; uses d3 as index 
  lea TimerArray,a3
  lsl.l #4,d3 
  move.w #$0001,(TimerFlags,a3,d3)
  move.w (TimerStartInterval,a3,d3),(TimerInterval,a3,d3)
  rts

handleTimers:
  lea TimerArray,a0 
  move.w TimerIndex,d5
  move.w #0,d0 
  subq.w #1,d5  
.loop
  subq.w #1,(TimerInterval,a0,d0)
  bgt .next 
  move.w #TimerDone,(TimerFlags,a0,d0) 
  move.w (TimerStartInterval,a0,d0),(TimerInterval,a0,d0)
  move.l (TimerCallback,a0,d0),a1
  jmp .next
  cmpa.l #0,a1
  beq .next
  movem.l d0-d4/a0-a4,-(sp)
  jsr (a1)
  movem.l (sp)+,d0-d4/a0-a4
.next 
  add.w #TimerStride,d0  
  dbra d5,.loop
  rts
