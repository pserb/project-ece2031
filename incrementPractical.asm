; incrementPractical.asm
prog:
    ; configure memory
    LOAD UserMemConfig
    OUT MemConfig

    ; initialize array
    CALL initArray

    ; read the array
    ; start at memory address 0
    LOADI 0
    OUT MemAddr

    ; should be 0x0001
    CALL readArray

    ; should be 0x0002
    CALL readArray

    ; should be 0x0003
    CALL readArray

    ; should be 0x0004
    CALL readArray

    ; should be 0x0005
    CALL readArray

    ; should be 0x0000
    CALL readArray

    ; reset and restart
    CALL reset
    JUMP prog

initArray:
    ; loops 5 times
    CALL saveToArray
    LOAD loopCounter
    ADDI -1
    STORE loopCounter
    LOAD loopCounter
    JPOS initArray
    RETURN

readArray:
    ; read the data
    IN MemData
    OUT Hex0
    CALL Delay
    RETURN

reset:
    LOADI 5
    STORE loopCounter
    LOADI 1
    STORE arrayCounter
    RETURN

saveToArray:
    LOAD arrayCounter
    OUT MemData
    LOAD arrayCounter
    ADDI 1
    STORE arrayCounter
    RETURN

; To make things happen on a human timescale, the timer is
; used to delay for 1 second.
Delay:
	OUT    Timer
WaitingLoop:
	IN     Timer
	ADDI   -10
	JNEG   WaitingLoop
	RETURN

loopCounter: DW 5
arrayCounter: DW 1
; incrememnt reading and writing
UserMemConfig: DW &B0000000001100001

Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
MemAddr:   EQU &H70
MemData:   EQU &H71
MemConfig: EQU &H72
MemErr:    EQU &H73