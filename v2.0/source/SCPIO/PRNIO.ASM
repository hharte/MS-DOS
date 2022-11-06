; Printer I/O for MS-DOS 2.0

        INCLUDE IODEF.ASM

IO      GROUP   CODE

CODE    SEGMENT BYTE PUBLIC 'IOSYS'
        ASSUME  CS:IO, DS:IO

        PUBLIC  PRNTBL

        EXTRN   EXIT:NEAR, CMDERR:NEAR, BUS$EXIT:NEAR

PRNTBL:
        DW      EXIT            ;INIT
        DW      EXIT
        DW      EXIT
        DW      CMDERR
        DW      EXIT
        DW      BUS$EXIT
        DW      EXIT
        DW      EXIT
        DW      PRN$WRIT
        DW      PRN$WRIT
        DW      PRN$STAT
        DW      EXIT

PRN$STAT:
        IN      AL,PRNSTAT
        AND     AL,TBMT
        JZ      BUS$EXITJ
        JMP     EXIT

BUS$EXITJ: JMP  BUS$EXIT

PRN$WRIT:
        MOV     SI,DI
PRNOUTLP:
        LODS    BYTE PTR ES:[SI]
        CALL    PRINT
        LOOP    PRNOUTLP
        JMP     EXIT

PRINT:
        PUSH    AX
PRINLP:
        IN      AL,PRNSTAT
        AND     AL,TBMT
        JZ      PRINLP
        POP     AX
        OUT     PRNDATA,AL
        RET

CODE    ENDS
        END
