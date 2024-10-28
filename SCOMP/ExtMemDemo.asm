; ExtMemDemo.asm
; tests writing to external memory peripheral

ORG 0

    LOADI Number
    OUT ExtMem
    
    ; JUMP loop

    loop:
        JUMP loop

Number: EQU &B1010101010
ExtMem: EQU &H070