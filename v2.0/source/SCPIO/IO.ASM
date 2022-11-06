; I/O System for MS-DOS version 2.00 and later. Revised 12-22-82.
; Contains data packets and init code only

BIOSIZ  EQU     8*400H          ;Size of BIOS in bytes
BIOSIZS EQU     BIOSIZ/10H      ;Size of BIOS in Paragraphs
MAXBUF  EQU     10              ; # of buffers for files
MAXFIL  EQU     10              ; # of files to be opened at one time

        INCLUDE IODEF.ASM

        PUBLIC  PTRSAV,EXIT,BUS$EXIT,CMDERR,ERR$EXIT
        PUBLIC  RE_INIT
        PUBLIC  SELECT

EXTRN   SYSINIT:FAR
EXTRN   CURRENT_DOS_LOCATION:WORD
EXTRN   FINAL_DOS_LOCATION:WORD
EXTRN   DEVICE_LIST:DWORD
EXTRN   MEMORY_SIZE:WORD
EXTRN   DEFAULT_DRIVE:BYTE
EXTRN   BUFFERS:BYTE,FILES:BYTE
EXTRN   CONTBL:WORD,AUXTBL:WORD,TIMTBL:WORD,PRNTBL:WORD

        IF      LARGDRV
EXTRN   LDSKTBL:WORD
        ENDIF

        IF      SMALLDRV
EXTRN   SDSKTBL:WORD
        ELSE
SDSKDEV EQU     HDSKDEV
        ENDIF

        IF      HARD AND (INSTALL-1)
EXTRN   HDSKTBL:WORD
        ELSE
HDSKDEV EQU     -1
        ENDIF

IO      GROUP   CODE,INITSEG,LASTSEG

CODE    SEGMENT BYTE PUBLIC 'IOSYS'
        ASSUME  CS:IO,DS:IO

        ORG     0
ZERO:
        JMP     INIT

SELECT  DB      (LDRVMAX+SDRVMAX+HARD) DUP (-1)

; ************ DEVICE HEADERS *****************************************

DEVSTART LABEL WORD

CONDEV:  ;Header for device CON
        DW      AUXDEV,BIOSSEG  ;Link to next device
        DW      8013H           ;Attributes - console input, output device
        DW      STRATEGY        ;Interrupt service (Used in future versions)
        DW      CON$IN          ;Entry point
        DB      "CON     "      ;Device name

AUXDEV:  ;Header for device AUX
        DW      PRNDEV,BIOSSEG
        DW      8000H
        DW      STRATEGY
        DW      AUX$IN
        DB      "AUX     "

PRNDEV:  ;Header for device PRN
        DW      TIMDEV,BIOSSEG
        DW      8000H
        DW      STRATEGY
        DW      PRN$IN
        DB      "PRN     "

TIMDEV:  ;Header for clock device
        DW      DSKDEV,BIOSSEG
        DW      8008H
        DW      STRATEGY
        DW      TIM$IN
        DB      "CLOCK   "

DSKDEV:  ;Header for floppy disk device
        IF      LARGDRV
        DW      SDSKDEV,BIOSSEG
        DW      2000H
        DW      STRATEGY
        DW      LDSK$IN
        DB      ?
        ENDIF

        IF      SMALLDRV
SDSKDEV:
        DW      HDSKDEV,BIOSSEG
        DW      0               ; IBM compatable
        DW      STRATEGY
        DW      SDSK$IN
        DB      ?
        ENDIF

        IF      HARD AND (INSTALL-1)
HDSKDEV: ;Header for 5.25 hard disk device
        DW      -1,BIOSSEG
        DW      2000H
        DW      STRATEGY
        DW      HDSK$IN
        DB      ?
        ENDIF

;************************************************************************

PTRSAV  DD      0

STRATEGY PROC   FAR
        MOV     WORD PTR CS:[PTRSAV],BX
        MOV     WORD PTR CS:[PTRSAV+2],ES
RE_INIT:
        RET
STRATEGY ENDP

;********************************************************

CON$IN:
        PUSH    SI
        MOV     SI,OFFSET IO:CONTBL
        JMP     SHORT ENTRY

AUX$IN:
        PUSH    SI
        MOV     SI,OFFSET IO:AUXTBL
        JMP     SHORT ENTRY

PRN$IN:
        PUSH    SI
        MOV     SI,OFFSET IO:PRNTBL
        JMP     SHORT ENTRY

TIM$IN:
        PUSH    SI
        MOV     SI,OFFSET IO:TIMTBL
        JMP     SHORT ENTRY

        IF      LARGDRV
LDSK$IN:
        PUSH    SI
        MOV     SI,OFFSET IO:LDSKTBL
        JMP     SHORT ENTRY
        ENDIF

        IF      SMALLDRV
SDSK$IN:
        PUSH    SI
        MOV     SI,OFFSET IO:SDSKTBL
        JMP     SHORT ENTRY
        ENDIF

        IF      HARD AND (INSTALL-1)
HDSK$IN:
        PUSH    SI
        MOV     SI,OFFSET IO:HDSKTBL
        JMP     SHORT ENTRY
        ENDIF

DISPATCH PROC   FAR
ENTRY:
        PUSH    AX
        PUSH    CX
        PUSH    DX
        PUSH    DI
        PUSH    BP
        PUSH    DS
        PUSH    ES
        PUSH    BX

        LDS     BX,CS:[PTRSAV]  ;GET POINTER TO I/O PACKET

        MOV     AL,[BX.UNIT]    ;AL = UNIT CODE
        MOV     AH,[BX.MEDIA]   ;AH = MEDIA DESCRIP
        MOV     CX,[BX.COUNT]   ;CX = COUNT
        MOV     DX,[BX.START]   ;DX = START SECTOR

        XCHG    DI,AX
        MOV     AL,[BX.CMD]
        XOR     AH,AH
        ADD     SI,AX
        ADD     SI,AX
        CMP     AL,11
        JA      CMDERR
        XCHG    AX,DI
        LES     DI,[BX.TRANS]
        PUSH    CS
        POP     DS

        CALL    [SI]                    ;GO DO COMMAND

        LDS     BX,CS:[PTRSAV]
        MOV     [BX.STATUS],AX          ;MARK OPERATION COMPLETE
        SUB     [BX.COUNT],CX           ;Subtract amount transfered
        POP     BX
        POP     ES
        POP     DS
        POP     BP
        POP     DI
        POP     DX
        POP     CX
        POP     AX
        POP     SI
        RET                             ;RESTORE REGS AND RETURN
DISPATCH ENDP

; Standard return types used by all functions

EXIT:
        XOR     CX,CX                   ;Transfer complete
        MOV     AH,00000001B            ;All done
        RET

BUS$EXIT:                               ;DEVICE BUSY EXIT
        MOV     AH,00000011B
        RET

CMDERR:
        MOV     AL,3                    ;UNKNOWN COMMAND ERROR
ERR$EXIT:
        MOV     AH,10000001B            ;MARK ERROR RETURN
        RET

CODE    ENDS

;***********************************************
; INIT CODE


INITSEG SEGMENT PARA PUBLIC 'IOSYS'
        ASSUME  CS:IO,DS:IO

INIT:
        XOR     BP,BP           ; Set up stack just below I/O system.
        MOV     SS,BP
        MOV     SP,BIOSSEG*16
        PUSH    CS
        POP     DS
;Fall into init code of other modules

INITSEG ENDS


LASTSEG SEGMENT BYTE PUBLIC 'IOSYS'
        ASSUME  CS:IO, DS:SEG SYSINIT

;Fall into this segment from init code of other modules
        MOV     AX,SEG SYSINIT
        MOV     DS,AX
        MOV     AX,CS
        ADD     AX,BIOSIZS
        MOV     [CURRENT_DOS_LOCATION],AX
        MOV     WORD PTR [DEVICE_LIST],OFFSET IO:DEVSTART
        MOV     WORD PTR [DEVICE_LIST+2],CS
        MOV     [FINAL_DOS_LOCATION],INITSEG
        MOV     [FILES],MAXFIL
        MOV     [BUFFERS],MAXBUF
        JMP     SYSINIT

LASTSEG ENDS
        END
