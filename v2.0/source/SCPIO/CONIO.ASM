
;Console I/O for MS-DOS 2.0

        INCLUDE IODEF.ASM

IO      GROUP   CODE,INITSEG


INITSEG SEGMENT BYTE PUBLIC 'IOSYS'
        ASSUME  CS:IO, DS:IO

        IF      INTINP
                                ; SS and BP are zero
        CLI                     ; Set up keyboard interrupt vector.
        MOV     WORD PTR [BP+64H],OFFSET IO:KBINT
        MOV     [BP+66H],CS
        STI
        ELSE
        MOV     AL,0FFH
        OUT     BASE+3,AL       ; Mask all interrupts
        ENDIF

;Set up vector 29H for fast console output
        MOV     WORD PTR [BP+0A4H],OFFSET IO:CON$INT
        MOV     [BP+0A6H],CS

INITSEG ENDS


CODE    SEGMENT BYTE PUBLIC 'IOSYS'
        ASSUME  CS:IO, DS:IO

        PUBLIC  CONTBL,RDNDEXIT

        EXTRN   EXIT:NEAR, CMDERR:NEAR, BUS$EXIT:NEAR, PTRSAV:DWORD

; Command table

CONTBL:
        DW      EXIT            ; Init
        DW      EXIT
        DW      EXIT
        DW      CMDERR
        DW      CON$READ
        DW      CON$RDND
        DW      EXIT
        DW      CON$FLSH
        DW      CON$WRIT
        DW      CON$WRIT
        DW      CON$WRST

; Console keyboard interrupt handler.

KBINT   PROC    FAR
        PUSH    AX
        PUSH    SI
        MOV     AL,20H          ;End of Interrupt command
        OUT     BASE+2,AL       ;Send to slave
        IN      AL,DATA         ;Get the character
        AND     AL,7FH
        CMP     AL,"C"-"@"
        JZ      FLSH
        CMP     AL,"S"-"@"
        JZ      FLSH
        CMP     AL,"F"-"@"
        JNZ     SAVKY
FLSH:
        CALL    FLUSH           ; Call I/O system keyboard buffer flush.
SAVKY:
        MOV     SI,CS:[REAR]    ;Pointer to rear of queue
        CALL    INCQ
        CMP     SI,CS:[FRONT]   ;Any room in queue?
        JZ      QFULL
        MOV     CS:[SI],AL      ;Put character in queue
        MOV     CS:[REAR],SI    ;Save pointer
LEAVINT:
        POP     SI
        POP     AX
        IRET
KBINT   ENDP

QFULL:
        MOV     AL,7            ; BELL character.
        CALL    OUTCHR          ; Call I/O system console output function.
        JMP     SHORT LEAVINT

BUSEXIT:JMP     BUS$EXIT

CON$RDND:
        CALL    CSTATUS
        JZ      BUSEXIT
RDNDEXIT:
        LES     DI,[PTRSAV]
        MOV     ES:[DI.MEDIA],AL
        JMP     EXIT

CSTATUS:
        IF      INTINP-1
        IN      AL,STAT
        AND     AL,DAV
        JZ      REPEAT
        PUSHF                   ;Look like an INT
        CALL    KBINT
REPEAT:
        ENDIF

        PUSH    SI
        CLI                     ; Disable interrupts while checking queue.
        MOV     SI,[FRONT]
        CMP     SI,[REAR]       ; Anything in queue?
        JZ      NOCHR           ; Jump if nothing in queue.
        CALL    INCQ
        LODSB                   ;Get character (if there is one)
        OR      SI,SI
NOCHR:
        STI
        POP     SI
        RET

CON$READ:
        CALL    INP
        STOSB
        LOOP    CON$READ
        JMP     EXIT

INP:
        CALL    CSTATUS         ; Get I/O system console input status.
        JZ      INP
        PUSH    SI
        CLI                     ; Disable interrupts while changing queue pointers.
        MOV     SI,[FRONT]
        CALL    INCQ            ; Permanently remove char from queue
        MOV     [FRONT],SI
        STI
        POP     SI
        RET

CON$FLSH:
        CALL    FLUSH
        JMP     EXIT

FLUSH:
        CLI
        MOV     CS:[REAR],OFFSET IO:QUEUE
        MOV     CS:[FRONT],OFFSET IO:QUEUE
        STI
        RET

INCQ:
        INC     SI
        CMP     SI,OFFSET IO:ENDQ        ;Exceeded length of queue?
        JB      RET1
        MOV     SI,OFFSET IO:QUEUE
RET1:   RET

FRONT   DW      OFFSET IO:QUEUE
REAR    DW      OFFSET IO:QUEUE
QUEUE   DB      QSIZE DUP(?)
ENDQ    LABEL   BYTE


; ************ Console Output ************

CON$WRST:
        IN      AL,STAT
        AND     AL,TBMT
        JZ      BUS$EXITV
        JMP     EXIT
BUS$EXITV:
        JMP     BUS$EXIT

CON$INT:
        STI             ;INTS back on
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        PUSH    DS
        PUSH    CS
        POP     DS
        CALL    CONOUT
        POP     DS
        POP     DI
        POP     DX
        POP     CX
        POP     AX
        IRET

CON$WRIT:
        MOV     SI,DI
CONOUTLP:
        LODS    BYTE PTR ES:[SI]
        PUSH    CX
        CALL    CONOUT
        POP     CX
        LOOP    CONOUTLP
        JMP     EXIT

ESCAPE  EQU     1BH
STATE   DW      ST1
PRMPNT  DW      PARMS
PARMS   DB      0,0,0,0,0,0,0
LASTPRM DB      0
BUFF    DB      0,0,0,0,0,0,0,0,0,0

; Cursor control table

CMDTABL DB      'A'             ;Cursor up
        DW      CUU
        DB      'B'             ;Cursor down
        DW      CUD
        DB      'C'             ;Cursor forward
        DW      CUF
        DB      'D'             ;Cursor backward
        DW      CUB
        DB      'H'             ;Cursor position
        DW      CUP
        DB      'J'             ;Erase display
        DW      ED
        DB      'K'             ;Erase line
        DW      EL
        DB      'f'             ;Cursor position
        DW      CUP
        DB      'm'             ;Exit/Enter reverse video mode
        DW      SGR
        DB      's'             ;Save cursor position
        DW      PSCP
        DB      'u'             ;Set cursor to saved position
        DW      PRCP
        DB      00

CONOUT:
        MOV     DI,OFFSET IO:STATE
        JMP     WORD PTR [DI]           ;JUMP TO THE CURRENT ANSI STATE

ST1:
        CMP     AL,ESCAPE
        JNZ     OUTCHR
        MOV     WORD PTR [DI],OFFSET IO:ST2
        RET

OUTCHR: PUSH    AX
OUTLP:  IN      AL,STAT
        AND     AL,TBMT
        JZ      OUTLP
        POP     AX
        OUT     DATA,AL
        MOV     [STATE],OFFSET IO:ST1
        RET

SENDESC:
        PUSH    AX
        MOV     AL,ESCAPE
        CALL    OUTCHR
        JMP     OUTLP

ST2:    CMP     AL,'['
        JNZ     SENDESC
        MOV     BX,OFFSET IO:PARMS
        MOV     [BX],BYTE PTR 31H
        MOV     WORD PTR [PRMPNT],BX
        MOV     IO:[STATE],OFFSET IO:ST3
        RET

ST3:    CMP     AL,';'
        JNZ     ST3A
        INC     WORD PTR [PRMPNT]
        RET

ST3A:   CMP     AL,'0'
        JB      ST3B
        CMP     AL,'9'
        JA      ST3B
        PUSH    DI
        MOV     DI,[PRMPNT]
        MOV     [DI],AL
        POP     DI
        RET

ST4:    PUSH    AX
        MOV     AL,ESCAPE
        CALL    OUTCHR
        MOV     AL,'['
        CALL    OUTCHR
        JMP     OUTLP

ST3B:   MOV     DI,OFFSET IO:CMDTABL-3
ST3C:   ADD     DI,3
        CMP     BYTE PTR [DI],0
        JZ      ST4             ;Output characters in buffer
        CMP     AL,[DI]
        JNZ     ST3C
        INC     DI              ;Point to translate characters
        MOV     BX,WORD PTR [DI]
        MOV     SI,OFFSET IO:BUFF               ;Set up temp buffer
        MOV     CX,1            ;Set counter to at least 1 time
        MOV     DL,0            ;Set # of characters
TLOOP:
        MOV     AL,[BX]         ;Fetch xlate char
        CMP     AL,0
        JZ      TEXIT           ;End of characters
        TEST    AL,80H          ;Test for special character
        JZ      NEXTCHR
        CMP     AL,0F1H         ;Is it 1st parm
        JNZ     SCHR
        MOV     AL,IO:[PARMS]   ;Fetch it
        JMP     NEXTCHR
SCHR:
        CMP     AL,0F2H         ;Is it 2nd parm
        JNZ     TCHR
        MOV     AL,IO:[PARMS+1]
        JMP     NEXTCHR
TCHR:
        CMP     AL,0FEH         ;Use special driver ?
        JZ      TDRIV
        CMP     AL,0FFH         ;Is it count char
        JNZ     NEXTCHR
        MOV     CL,IO:[PARMS]
        CMP     CL,31H
        JAE     TCHR1
        MOV     CL,31H
TCHR1:  SUB     CL,30H
        INC     BX
        JMP     TLOOP
NEXTCHR:
        MOV     [SI],AL         ;Put to buffer
        INC     SI              ;Temp buffer
        INC     BX              ;Xlate table
        INC     DL              ;# of char in BUFF
        JMP     TLOOP           ;Get next character
TEXIT:                          ;All charcters are fetched
        MOV     SI,OFFSET IO:BUFF
        MOV     DH,DL           ;Save # of char
TEXITL:
        MOV     AL,[SI]
        CALL    OUTCHR
        INC     SI
        DEC     DH
        JNZ     TEXITL          ;Output until empty
        DEC     CL              ;Do CX count
        JNZ     TEXIT
        RET

TDRIV:                          ;User defined driver for SGR
        CMP     WORD PTR [DI],OFFSET IO:SGR
        JZ      DRIVOUT
        MOV     AL,0            ;Dummy char
        JMP     OUTCHR

DRIVOUT:
        MOV     BX,OFFSET IO:PARMS
        CMP     BYTE PTR [BX],37H       ;Is it enter mode
        JZ      SGRN
        MOV     AL,'q'          ;Heath exit video mode
        JMP     SENDESC

SGRN:
        MOV     AL,'p'
        JMP     SENDESC         ;Heath enter video mode

;
; Cursor controls translation table. This table below contains that
; actual ASCII code sequences used by your terminal to perform basic
; cursor control commands. MS-DOS 2.0 normally expects to see ANSI
; standard sequences for these commands, however this table is set
; up so that the user can re-define the ASCII codes for his specific
; terminal. The table has some specifiers that will tell the code
; to use certain parameters that are passed, such as row or column
; number, or the number of moves.
;
;       Specifer                action
;         0F1H                  Use parameter #1 here (the row or line #)
;         0F2H                  Use parameter #2 here (the column #)
;         0FEH                  Use special driver routine (User defined)
;         0FFH                  Use parameter #1 as a count
;         00H                   end of code
;         ESCAPE                Outputs the 'esc' character

HEATH:

CUP:    DB      ESCAPE          ;Cursor position
        DB      'Y'
        DB      0F1H
        DB      0F2H
        DB      0

CUU:    DB      ESCAPE          ;Cursor up
        DB      'A'
        DB      0FFH
        DB      0

CUD:    DB      ESCAPE          ;Cursor down
        DB      'B'
        DB      0FFH
        DB      0

CUF:    DB      ESCAPE          ;Cursor forward
        DB      'C'
        DB      0FFH
        DB      0

CUB:    DB      ESCAPE          ;Cursor backward
        DB      'D'
        DB      0FFH
        DB      0

ED:     DB      ESCAPE          ;Erase display
        DB      'E'
        DB      0

EL:     DB      ESCAPE          ;Erase line
        DB      'L'
        DB      0

PSCP:   DB      ESCAPE          ;Save cursor position
        DB      'j'
        DB      0

PRCP:   DB      ESCAPE          ;Set cursor to saved position
        DB      'k'
        DB      0

SGR:    DB      0FEH            ;User defined driver
        DB      0


CODE    ENDS
        END
