Beginning:	
	LOADI 0
    OUT MemAddr
    LOADI &H15
    OUT MemData
	
	LOADI 1
    OUT MemAddr
    LOADI &H33
    OUT MemData
	
	LOADI 1
    OUT MemAddr
	
	IN MemData
	OUT Hex0
	CALL Delay
	IN MemData
	OUT Hex0
	CALL Delay
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
Timer:     EQU 002
Hex0:      EQU 004
MemAddr:   EQU &H70
MemData:   EQU &H71
