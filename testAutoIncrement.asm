; tests the basic memory read write

Beginning:
    ; sets 0xFFFF to 15
    LOAD AddrMax
    OUT MemAddr
    LOADI 15
    OUT MemData

    ; config incrementing 1 on write only
    LOADI &H41
    OUT MemConfig
    ; write sequences

    LOADI 0
    OUT MemAddr
    ; addresses 0-4 will hold 0-4
    LOADI 0
    OUT MemData

    LOADI 1
    OUT MemData

    LOADI 2
    OUT MemData

    LOADI 3
    OUT MemData

    LOADI 4
    OUT MemData

    OUT MemAddr
    IN MemData
    OUT Hex0
    CALL Delay
    IN MemData
    OUT Hex0
    CALL Delay

    ; reads with delay
    ; config decrementing 2 on read only
    LOADI &H2A
    OUT MemConfig
    LOADI 4
    OUT MemAddr

    ; should be 4
    IN MemData
    OUT Hex0
    CALL Delay

    ; should be 2
    IN MemData
    OUT Hex0
    CALL Delay

    LOADI 3
    OUT MemAddr

    ; should be 3
    IN MemData
    OUT Hex0
    CALL Delay

    LOADI 5
    OUT MemData

    ; should be 0
    IN MemErr
    OUT Hex0
    CALL Delay
    
    ; should be 5
    IN MemData
    OUT Hex0
    CALL Delay

    ; should be 0xFFFF
    IN MemErr
    OUT Hex0
    CALL Delay

    ; should be 0
    OUT MemErr
    IN MemErr
    OUT Hex0
    ; CALL Delay

    ; should be 0xF
    IN MemData
    OUT Hex0
    ; CALL Delay
    
    ; config update to increment 7 on write as well
    LOADI &H6F
    OUT MemConfig

    ; should be 0x1
    OUT MemData
    IN MemErr
    OUT Hex0
    ; CALL Delay

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