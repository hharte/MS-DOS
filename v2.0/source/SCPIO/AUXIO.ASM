; Auxiliary I/O for MS-DOS 2.0

        INCLUDE IODEF.ASM

IO      GROUP   CODE,INITSEG,LASTSEG

INITSEG SEGMENT BYTE PUBLIC 'IOSYS'
        ASSUME  CS:IO, DS:IO

        IF      SERIAL
        MOV     CX,4
        MOV     SI,OFFSET IO:SERTAB
SERINIT:
        LODSB
        OUT     SIOBASE+1,AL
        OUT     SIOBASE+3,AL
        LOOP    SERINIT
        LODSB                   ;Baud rate for channel 0
        OUT     SIOBASE+8,AL
        LODSB                   ;Baud rate for channel 1
        OUT     SIOBASE+9,AL
        ENDIF

INITSEG ENDS


LASTSEG SEGMENT BYTE PUBLIC 'IOSYS'

        IF      SERIAL
SERTAB  DB      0B7H, 77H, 4EH, 37H, PRNBAUD, AUXBAUD
        ENDIF

LASTSEG ENDS


CODE    SEGMENT BYTE PUBLIC 'IOSYS'
        ASSUME  CS:IO, DS:IO

        PUBLIC  AUXTBL

        EXTRN   EXIT:NEAR, CMDERR:NEAR, BUS$EXIT:NEAR, RDNDEXIT:NEAR

AUXTBL:
        DW      EXIT
        DW      EXIT
        DW      EXIT
        DW      CMDERR
        DW      AUX$READ
        DW      AUX$RDND
        DW      EXIT
        DW      AUX$FLSH
        DW      AUX$WRIT
        DW      AUX$WRIT
        DW      AUX$WRST

AUX$RDND:
        CALL    AUXISTAT
        JZ      BUS$EXITJ
        JMP     RDNDEXIT

AUXISTAT:
        MOV     AL,[AUXCHAR]
        TEST    [AUXBST],1
        JNZ     RET2
        IN      AL,AUXSTAT
        AND     AL,DAV
        JZ      RET2
        IN      AL,AUXDATA
        MOV     [AUXCHAR],AL
        MOV     [AUXBST],1
RET2:   RET

BUS$EXITJ:JMP   BUS$EXIT

AUX$READ:
        CALL    AUXIN
        STOSB
        LOOP    AUX$READ
        JMP     EXIT

AUXIN:
        CALL    AUXISTAT
        JZ      AUXIN
AUXFLUSH:
        MOV     [AUXBST],0
        RET

AUX$FLSH:
        CALL    AUXFLUSH
        JMP     EXIT

AUX$WRST:
        IN      AL,AUXSTAT
        AND     AL,TBMT
        JZ      BUS$EXITJ
        JMP     EXIT

AUX$WRIT:
        MOV     SI,DI
AUXOUTLP:
        LODS    BYTE PTR ES:[SI]
        CALL    AUXOUT
        LOOP    AUXOUTLP
        JMP     EXIT

AUXOUT:
        PUSH    AX
AUXLP:
        IN      AL,AUXSTAT
        AND     AL,TBMT
        JZ      AUXLP
        POP     AX
        OUT     AUXDATA,AL
        RET

AUXCHAR DB      0
AUXBST  DB      0

CODE    ENDS
        END
