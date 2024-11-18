; bufferDemo.asm
; 1-channel data capture from a peripheral to a buffer in external memory.

JUMP Start

Feed:        DW &HFEED
Dead:        DW &HDEAD
CountInVal:  DW 10
DurationCount: DW 20
ReplayCount:   DW 20
Temp:        DW 0

; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005

Address:   EQU &H070
Data:      EQU &H071
Config:    EQU &H072
Error:     EQU &H073
ID:        EQU &H074
Bounds:    EQU &H075

; Signal One
ID_SignalOne:  DW 0
LowBoundOne:   DW 0
HighBoundOne:  DW 19

; External memory flags
WriteIncEn:  DW &B1000000
ReadIncEn:   DW &B100000
WriteIncDir: DW &B00000 ; positive increment
ReadIncDir:  DW &B0000  ; positive increment

; Instructions begin here
Start:
	; setup config
	LOADI 1 ; increment amount
    OR WriteIncEn
    OR ReadIncEn
    OR WriteIncDir
    OR ReadIncDir
    
    OUT Config
    
    ; setup ID and its bounds
    LOAD ID_SignalOne
    OUT ID
   
    LOAD HighBoundOne
    OUT Bounds
    
    LOAD LowBoundOne
    OUT Address
CountDown:
    CALL Delay

	LOAD CountInVal
    OUT Hex1
    ADDI -1
    STORE CountInVal
    
    JPOS CountDown

    LOAD Feed
    OUT Hex0
    LOAD DurationCount
Collection:
    OUT Hex1
    ADDI -1
    STORE DurationCount

    CALL Delay
    
    IN Switches
    OUT Data

	LOAD DurationCount
    
    JPOS Collection
    
    LOAD LowBoundOne
    OUT Address
Replay:
	CALL Delay

    IN Data
	; Load curr signal one val
    OUT Hex0
    
	LOAD ReplayCount
    OUT Hex1
    ADDI -1
    STORE ReplayCount
    
    JPOS Replay
BoundsError:
    LOAD Dead
	OUT Address
    IN Error
    OUT Hex0
    
    LOADI &HE
    OUT Hex1
Forever:
	JUMP Forever
    
; Delays a second.
Delay:
	OUT    Timer
WaitingLoop:
	IN     Timer
	ADDI   -10
	JNEG   WaitingLoop
	RETURN