Beginning:	
	LOADI 0
    OUT MemID ;set current id to 0

    LOADI 1000
    OUT MemBounds ;set bounds for id 0, from 0 to 1000

    LOADI 500
    OUT MemAddr 
    LOADI &H55
    OUT MemData ;;put 0x55 in mem addr 500
	
	IN MemData
	OUT Hex0
	; CALL Delay ;;visually verify that mem addr 500 has 0x55
	
	In MemErr
	OUT Hex0
	; CALL Delay ;;visually verify that the error code is 0

    LOADI 1
    OUT MemID ;;set id to 1
	
    LOAD FIVEK
    OUT MemBounds ;;set bounds for id 1 to be from 1000 to 0x5000
	
	In MemErr
	OUT Hex0
	; CALL Delay ;;visually verify that the error code is 0
	
	LOAD FIVEK
    OUT MemData
	;this should cause an error
	;as it tries to write 0x5000 to mem adrr 500
	;which is out of bounds for the current id
	
	IN MemErr
    OUT Hex0
    ; CALL Delay ;verify that the error code is 3
	
	LOADI 0
    OUT MemID ;set current id to 0
	
	IN MemData
    OUT Hex0
    ; CALL Delay ;verify that the data is still 0x55
	
	LOADI &H101
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
FIVEK:     DW &H5000
Timer:     EQU 002
Hex0:      EQU 004
MemAddr:   EQU &H70
MemData:   EQU &H71
MemConfig: EQU &H72
MemErr:    EQU &H73
MemID:     EQU &H74
MemBounds: EQU &H75
