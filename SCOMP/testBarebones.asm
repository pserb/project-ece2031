; tests the basic memory read write

Beginning:
    ; write sequences

    LOADI 0
    OUT MemAddr
    LOADI 0
    OUT MemData

    LOADI 1
    OUT MemAddr
    LOADI &H65
    OUT MemData

    LOADI &HF
    OUT MemAddr
    LOADI &H8F
    OUT MemData

    LOADI &H6F
    OUT MemAddr
    LOADI &HF9
    OUT MemData

    LOADI &H18C
    OUT MemAddr
    LOADI &H1AD
    OUT MemData

    LOADI 5
    OUT MemAddr
    LOADI &H30
    OUT MemData

    LOAD AddrMax
    OUT MemAddr
    LOAD DataMax
    OUT MemData

    ; reads with delay

    ; should be 0
    LOADI 0
    CALL DisplayData
    ; CALL Delay

    ; should be 0x65
    LOADI 1
    CALL DisplayData
    ; CALL Delay

    ; should be 0
    LOADI 2
    CALL DisplayData
    ; CALL Delay

    ; should be 0x30
    LOADI 5
    CALL DisplayData
    ; CALL Delay

    ; should be 0x8F
    LOADI &HF
    CALL DisplayData
    ; CALL Delay

    ; should be 0xF9
    LOADI &H6F
    CALL DisplayData
    ; CALL Delay

    ; should be 0x1AD
    LOADI &H18C
    CALL DisplayData
    ; CALL Delay

    ; should be 0xFFFF
    LOAD AddrMax
    CALL DisplayData
    ; CALL Delay
    
    JUMP Beginning

DisplayData:
    OUT MemAddr
    IN MemData
    OUT Hex0
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

AddrMax: DW &H7FF
DataMax: DW &HFFFF

Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
MemAddr:   EQU &H70
MemData:   EQU &H71