; tests the basic memory read write

Beginning:
    ; sets 0xFFFF to 15
    LOAD AddrMax
    OUT MemAddr
    LOAD Val
    OUT MemData

    ; config incrementing 1 on write only with lower byte
    LOADI &B11000001
    OUT MemConfig
    ; write sequences

    LOADI 0
    OUT MemAddr
    ; byte addresses 0-5 will hold 0-5
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

    LOADI 5
    OUT MemData

    ; config incrementing 1 on write only with upper byte
    LOADI &B101000001
    OUT MemConfig
    LOADI 2
    OUT MemAddr
    ; should be 5
    IN MemData
    OUT Hex0
    CALL Delay
    IN MemData
    OUT Hex0
    CALL Delay

    ; reads with delay
    ; config decrementing 1 on read only with upper byte
    LOADI &B100101001
    OUT MemConfig

    ; should be 5
    IN MemData
    OUT Hex0
    CALL Delay

    ; should be 4
    IN MemData
    OUT Hex0
    CALL Delay

    ; should be 3
    IN MemData
    OUT Hex0
    CALL Delay

    ; should be 2
    IN MemData
    OUT Hex0
    CALL Delay

    ; should be 0
    IN MemErr
    OUT Hex0
    CALL Delay
    
    ; should be 1
    IN MemData
    OUT Hex0
    CALL Delay

    ; should be 0xFFFF
    IN MemErr
    OUT Hex0
    CALL Delay

    OUT MemErr

    ; should be 0x34
    IN MemData
    OUT Hex0
    CALL Delay
    
    ; config update to increment 3 on write as well
    LOADI &B11100011
    OUT MemConfig

    ; should be 0x1
    OUT MemData
    IN MemErr
    OUT Hex0
    CALL Delay

    ; should be 1
    IN MemData
    OUT Hex0
    CALL Delay

    ; should be 4
    IN MemData
    OUT Hex0
    CALL Delay

    LOADI 0
    OUT MemAddr

    ; config increment 1 both read and write full word
    LOADI &B1100001
    OUT MemConfig

    ; should be 0x100
    IN MemData
    OUT Hex0
    CALL Delay

    ; should be 0x302
    IN MemData
    OUT Hex0
    CALL Delay

    ; should be 504
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
Val: DW &H1234

Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
MemAddr:   EQU &H70
MemData:   EQU &H71
MemConfig: EQU &H72
MemErr:    EQU &H73