; tests the basic memory read write

Beginning:
    ; sets 0xFFFF to 15
    LOADI 1
    OUT MemAddr
    LOADI 15
    OUT MemData

    ; config incrementing 1 on write only
    LOADI &H41
    OUT MemConfig

    LOADI &HF
    OUT Hex0
    CALL Delay
    
    LOADI 0
    OUT MemAddr

    LOADI 1
    OUT MemData
    IN MemData

    OUT Hex0
    CALL Delay

    

    JUMP Beginning


; To make things happen on a human timescale, the timer is
; used to delay for 1 second.
Delay:
	OUT    Timer
WaitingLoop:
	IN     Timer
	ADDI   -10
	JNEG   WaitingLoop
	RETURN

AddrMax: DW &HFFFF
DataMax: DW &HFFFF

Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
MemAddr:   EQU &H70
MemData:   EQU &H71
MemConfig: EQU &H72
MemErr:    EQU &H73