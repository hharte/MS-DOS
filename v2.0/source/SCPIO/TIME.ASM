; Time & date for MS-DOS 2.0

PAGE    60,132

        INCLUDE IODEF.ASM

IO      GROUP   CODE,INITSEG,LASTSEG

INITSEG SEGMENT BYTE PUBLIC 'IOSYS'
        ASSUME  CS:IO, DS:IO

; Initialize time-of-day clock.

        MOV     SI,OFFSET IO:STCTAB
        MOV     CX,4            ;Initialize 4 registers
        CLD
INITSTC:
        LODSB
        OUT     STCCOM,AL       ;Select register to initialize
        LODSB
        OUT     STCDATA,AL
        LODSB
        OUT     STCDATA,AL
        LOOP    INITSTC

INITSEG ENDS


LASTSEG SEGMENT BYTE PUBLIC 'IOSYS'

STCTAB  DB      17H             ;Select master mode register
        DW      84F3H           ;Enable time-of-day
        DB      1               ;Counter 1 mode register
        DW      0138H
        DB      2
        DW      0038H
        DB      3
        DW      0008H           ;Set counter 3 to count days

LASTSEG ENDS


CODE    SEGMENT BYTE PUBLIC 'IOSYS'
        ASSUME  CS:IO, DS:IO

        PUBLIC  TIMTBL

        EXTRN   EXIT:NEAR, CMDERR:NEAR, BUS$EXIT:NEAR

TIMTBL:
        DW      EXIT
        DW      EXIT
        DW      EXIT
        DW      CMDERR
        DW      TIM$READ
        DW      BUS$EXIT
        DW      EXIT
        DW      EXIT
        DW      TIM$WRIT
        DW      TIM$WRIT

TIM$READ:
        MOV     AL,0A7H         ;Save counters 1,2,3
        OUT     STCCOM,AL
        MOV     AL,0E0H         ;Enable data pointer sequencing
        OUT     STCCOM,AL
        MOV     AL,19H          ;Select hold 1 / hold cycle
        OUT     STCCOM,AL
        CALL    STCTIME         ;Get seconds & 1/100's
        XCHG    AX,DX
        CALL    STCTIME         ;Get hours & minutes
        XCHG    AX,CX
        IN      AL,STCDATA
        MOV     AH,AL
        IN      AL,STCDATA
        XCHG    AL,AH           ;Count of days
        CALL    POINTSTAT
        STOSW
        MOV     AX,CX
        STOSW
        MOV     AX,DX
        STOSW
        JMP     EXIT

STCTIME:
        CALL    STCBYTE
        MOV     CL,AH
STCBYTE:
        IN      AL,STCDATA
        MOV     AH,AL
        SHR     AH,1
        SHR     AH,1
        SHR     AH,1
        SHR     AH,1
        AND     AL,0FH          ;Unpack BCD digits
        AAD                     ;Convert to binary
        MOV     AH,AL
        MOV     AL,CL
        RET

TIM$WRIT:
        MOV     DX,ES:[DI]      ;Put date in DX
        MOV     AL,0BH          ;Select Counter 3 load register
        OUT     STCCOM,AL
        XCHG    AX,DX
        OUT     STCDATA,AL
        MOV     AL,AH
        OUT     STCDATA,AL
        MOV     AL,44H          ;Load counter 3
        OUT     STCCOM,AL
        CALL    LOAD0           ;Put 0 into load registers to condition timer
        MOV     AL,43H          ;Load counters 1 & 2
        OUT     STCCOM,AL
        MOV     CX,ES:[DI+2]
        MOV     DX,ES:[DI+4]
        CALL    LOAD
        MOV     AL,43H
        OUT     STCCOM,AL       ;Load counters 1&2
        CALL    LOAD0
        MOV     AL,27H          ;Arm counters 1,2,3
        OUT     STCCOM,AL
        CALL    POINTSTAT
        JMP     EXIT

LOAD0:
        XOR     CX,CX
        MOV     DX,CX
LOAD:
        MOV     AL,09           ;Counter 1 load register
        CALL    OUTDX
        MOV     AL,0AH          ;Counter 2 load register
        MOV     DX,CX
OUTDX:
        OUT     STCCOM,AL       ;Select a load register
        MOV     AL,DL
        CALL    OUTBCD
        MOV     AL,DH
OUTBCD:
        AAM                     ;Convert binary to unpacked BCD
        SHL     AH,1
        SHL     AH,1
        SHL     AH,1
        SHL     AH,1
        OR      AL,AH           ;Packed BCD
        OUT     STCDATA,AL
        RET


POINTSTAT:
        PUSH    AX
        MOV     AL,1FH          ;Point to status register
        OUT     STCCOM,AL       ;       so power-off glitches won't hurt
        POP     AX
        RET

CODE    ENDS
        END
