; Blank.asm
; There's nothing here yet...
START:
LOADI 0
OUT Address
LOAD LByteConfig
OUT Config
LOAD SOMEVALUE
OUT Data
LOAD HByteConfig
OUT Config
LOAD SOMEVALUE
OUT Data

LOAD LByteConfig
OUT Config
IN DATA
OUT HEX0
CALL Delay

LOAD HByteConfig
OUT Config
IN DATA
OUT HEX0
CALL DELAY

JUMP START






Delay:
	OUT    Timer
WaitingLoop:
	IN     Timer
	ADDI   -10
	JNEG   WaitingLoop
	RETURN






















SOMEVALUE: DW &H1234 
LByteConfig: DW &H0080
HByteConfig: DW &H0100
Address: EQU &H0070
Data: EQU &H0071
Config: EQU &H0072
Hex0: EQU 004
Hex1: EQU 005
Timer:     EQU 002
