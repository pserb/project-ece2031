; tests the basic memory read write with input through switches

Loop:
    ; 0 indicates ready for address input
    LOADI 0
    OUT Hex1
    CALL WaitForMSBChange
    IN Switches
    OUT MemAddr

    ; 1 indicates ready for command (0 LSB is read, 1 LSB is write)
    LOADI 1
    OUT Hex1
    CALL WaitForMSBChange
    IN Switches
    AND CommandMask
    JZERO Read

    ; 2 indicates ready for data
    LOADI 2
    OUT Hex1
    CALL WaitForMSBChange
    IN Switches
    AND DataMask
    OUT MemData

    Read:
        IN MemData
        OUT Hex0
        JUMP Loop

CommandMask: DW 1
DataMask: DW &H1FF

WaitForMSBChange:
    IN Switches
    SHIFT -9
    STORE MSBChangeState
    MSBChangeLoop:
        IN Switches
        OUT LEDs
        SHIFT -9
        SUB MSBChangeState
        JPOS MSBChangeAnotherCheck
        JNEG MSBChangeAnotherCheck
        JUMP MSBChangeLoop
    ; checks to make sure was intentional change
    MSBChangeAnotherCheck:
        CALL Delay
        IN Switches
        SHIFT -9
        SUB MSBChangeState
        JPOS MSBChangeOut
        JNEG MSBChangeOut
        JUMP MSBChangeLoop
    MSBChangeOut:
        RETURN
MSBChangeState: DW 0

; To make things happen on a human timescale, the timer is
; used to delay for 1 second.
Delay:
	OUT    Timer
WaitingLoop:
	IN     Timer
	ADDI   -5
	JNEG   WaitingLoop
	RETURN

Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
MemAddr:   EQU &H70
MemData:   EQU &H71