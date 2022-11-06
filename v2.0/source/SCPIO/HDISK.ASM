; Hard disk I/O for MS-DOS 2.0

        PAGE    60,132

        INCLUDE  IODEF.ASM

IO      GROUP   CODE

CODE    SEGMENT BYTE PUBLIC 'IOSYS'
        ASSUME  CS:IO, DS:IO

;----------------------------------------

        IF      INSTALL

HDSKDEV:        ;Header for hard disk
        DD      -1
        DW      2000H
        DW      STRATEGY
        DW      HDSK$IN
        DB      ?

        ELSE

        PUBLIC  HDSKTBL

        EXTRN   EXIT:NEAR, CMDERR:NEAR, BUS$EXIT:NEAR, PTRSAV:DWORD
        ENDIF

;-----------------------------------------

HDSKTBL:
        DW      HDSK$INIT
        DW      HARDCHG
        DW      GET$HBPB
        DW      CMDERR
        DW      HARDREAD
        DW      BUS$EXIT
        DW      EXIT
        DW      EXIT
        DW      HARDWRITE
        DW      HARDWRITE

;*************************************************************

DIRENT          EQU     96
ALLOCSIZ        EQU     4
FATSIZ          EQU     6


                IF      IMI
NHEADS          EQU     6       ; Number of heads
NSECT           EQU     8       ; Number of sectors per track
NTRACKS         EQU     306     ; Number of cylinders
LOWCURTRK       EQU     0       ; First track of low write current
PRECOMTRK       EQU     256     ; First track to set precomp bit
                ENDIF


                IF      SCRIBE
NHEADS          EQU     4       ; Number of heads
NSECT           EQU     8       ; Number of sectors per track
NTRACKS         EQU     480     ; Number of cylinders
LOWCURTRK       EQU     0       ; First track of low write current
PRECOMTRK       EQU     0       ; First track to set precomp bit
                ENDIF


RESETHDC        EQU     54H
STARTHDC        EQU     55H
HARDRDOP        EQU     0
HARDWROP        EQU     1
RETRY           EQU     3       ; # of times to try disk command
TIMEOUT         EQU     10      ; 0.2 sec/loop--set 2 seconds for 10 MHZ CPU

HDCPARAM:
HDIR            DB      0       ; Direction
HSTEP           DW      1       ; Amount to step
HDRIVE          DB      0DCH    ; Drive/head select
DMAAD           DW      0       ; DMA address
DMAHI           DB      0
ARG1:
HCYL            DW      -1      ; Current cylinder
HHEAD           DB      0       ; Current head
HSECT           DB      0       ; Current sector
OPCODE          DB      0       ; Read/write code
HSTAT           DB      0       ; Return status

                IF      INSTALL
NEXTAD          DW      HDCPARAM
                ELSE
NEXTAD          DW      HDCPARAM+10H*BIOSSEG
                ENDIF

NEXTADHI        DB      0
;---------------------------------------------
        IF      INSTALL

PTRSAV          DD      0

STRATP  PROC     FAR
STRATEGY:
        MOV     WORD PTR CS:[PTRSAV],BX
        MOV     WORD PTR CS:[PTRSAV+2],ES
        RET
STRATP  ENDP


HDSK$IN:
        PUSH    SI
        MOV     SI,OFFSET IO:HDSKTBL

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

; Standard return types

EXIT:
        XOR     CX,CX                   ;Transfer complete
        MOV     AH,00000001B            ;All done
        RET

BUS$EXIT:                               ;DEVICE BUSY EXIT
        MOV     AH,00000011B
        RET

CMDERR:
        MOV     AL,3                    ;UNKNOWN COMMAND ERROR
        MOV     AH,10000001B            ;MARK ERROR RETURN
        RET

        ENDIF

;---------------------------------------

HARDCHG:
        LDS     BX,[PTRSAV]
        MOV     BYTE PTR [BX.TRANS],1   ;Disk not changed
        JMP     EXIT

HARDREAD:
        MOV     OPCODE,HARDRDOP
        JMP     SHORT HARDIO

HARDWRITE:
        MOV     OPCODE,HARDWROP

HARDIO:
        PUSH    DS
        XOR     SI,SI
        MOV     BP,[NEXTAD]
        MOV     AL,[NEXTADHI]
        MOV     DS,SI
        MOV     WORD PTR [SI+50H],BP
        MOV     BYTE PTR [SI+52H],AL

        OUT     RESETHDC,AL     ; Reset hard disk controller
        POP     DS
        MOV     AX,ES
        SHL     AX,1
        RCL     SI,1
        SHL     AX,1
        RCL     SI,1
        SHL     AX,1
        RCL     SI,1
        SHL     AX,1
        RCL     SI,1
        ADD     AX,DI
        MOV     DMAAD,AX
        XCHG    AX,SI
        ADC     AL,0
        MOV     DMAHI,AL
        CMP     HCYL,-1         ; Is current track invalid?
        JNZ     COMPPOS
        CALL    RESTORE         ; Home disk head
COMPPOS:
        PUSH    DX
        MOV     SI,NSECT        ; Sector/track on hard disk
        XCHG    AX,DX
        XOR     DX,DX
        DIV     SI              ; AX=track, DX=sector
        INC     DX              ; Sector numbers start with 1
        MOV     HSECT,DL
        MOV     SI,NHEADS
        XOR     DX,DX
        DIV     SI              ; AX=cylinder, DX=head
        MOV     HHEAD,DL
        SHL     DL,1
        SHL     DL,1
        NOT     DL
        AND     DL,9CH
        CMP     AX,PRECOMTRK
        JB      SAVHEAD1
        OR      DL,80H          ; Turn on precomp
SAVHEAD1:
        CMP     AX,LOWCURTRK    ; Need low write current?
        JAE     SAVHEAD
        OR      DL,40H          ; Turn off low write current
SAVHEAD:
        MOV     HDRIVE,DL       ; Drive/head select byte
        MOV     DX,AX
        XCHG    HCYL,AX         ; Set current cyl, get previous
        SUB     DX,AX           ; Amount to move
        MOV     AL,0            ; Assume movement IN
        JAE     HAVSTEP
        NEG     DX              ; Get absolute value
        MOV     AL,10H          ; Set movement OUT
HAVSTEP:
        MOV     HDIR,AL
        MOV     HSTEP,DX
        POP     DX              ; BX,CX,DX have orignal command parameters

; All set for hard disk operation!

HARDREADWRITE:
        MOV     AH,RETRY        ; Retry count
HCOM:
        CALL    HDCCOM
        JNZ     NOTNEXT         ; If not successful, don't bump to next sector
        ADD     DMAAD,1024
        ADC     DMAHI,0
        INC     DX
        MOV     AL,HSECT
        INC     AL
        CMP     AL,NSECT+1      ; Stay on this track?
        MOV     HSECT,AL
        LOOPNZ  HARDREADWRITE
        JCXZ    OKRET
        JMP     COMPPOS         ; Re-compute everything

OKRET:
        MOV     AH,1            ;No error
        RET

NOTNEXT:
        CMP     AL,1            ; Is drive not ready?
        JBE     HARDERR         ; Don't retry if not ready or time out
        DEC     AH
        JNZ     HCOM

; Hard disk error on hard disk. AL has the error code. Convert disk
; error code to MSDOS 2.0 error code

HARDERR:
        MOV     HCYL,-1         ; Force restore next time
        CMP     AL,10           ; Is it a reasonable error code?
        JB      NEXT1
        MOV     AL,0            ; General disk failure
NEXT1:
        MOV     BX,OFFSET IO:ERRTAB     ; Set DOS error table
        XLAT
        MOV     AH,81H          ; ERROR
        RET                     ; CX = number of sectors to go

ERRTAB:
        DB      12              ; General failure
        DB      2               ; Drive not ready
        DB      12
        DB      12
        DB      8               ; Sector not found
        DB      8               ; Data not found
        DB      12              ; Data overrun
        DB      4               ; Data CRC error
        DB      10              ; Write fault
        DB      4               ; Header CRC error

;Restore head on hard disk.
RESTORE:
        MOV     ARG1+1,30       ; 3 ms step time, no head settle delay
        MOV     AX,7+100H*4     ; 1024 byte sector, LOAD CONSTANTS command
        XCHG    AX,ARG1+3       ; Previous opcode in AH
        MOV     BL,1
        CALL    QUICKCOM        ; Execute command
        JNZ     EXITREST        ; Abort if controller failure
        MOV     ARG1+1,0        ; Set to fast step (after restore)
        MOV     HSTEP,0FFFH     ; Maximum number of steps
        MOV     HDIR,10H        ; Step out
        CALL    HDCCOM          ; Restore and set fast seek
        MOV     HCYL,0          ; Now on track zero
EXITREST:
        MOV     OPCODE,AH
        RET

HDCCOM:
        MOV     BL,TIMEOUT
QUICKCOM:
        PUSH    CX
        XOR     CX,CX
        MOV     HSTAT,0
        OUT     STARTHDC,AL
HWAIT:
        MOV     AL,HSTAT
        OR      AL,AL
        LOOPZ   HWAIT           ; Try for 2 seconds
        JNZ     HRET
        DEC     BL
        JNZ     HWAIT
HRET:
        POP     CX
        MOV     HSTEP,0
        CMP     AL,-1
        RET

GET$HBPB:
;  Set up BPB for Hard disk controller. Real simple isn't it?
        MOV     SI,OFFSET IO:HARDDRIVE  ; Hard disk Parm table
SETBPB:
        LDS     BX,[PTRSAV]
        MOV     [BX.MEDIA],1            ;One hard disk
        MOV     [BX.COUNT],SI
        MOV     [BX.COUNT+2],CS
        JMP     EXIT


; ***************************************************************************

HINITTAB:
        DW      HARDDRIVE

HARDDRIVE:
        DW      1024            ; Sector size
        DB      ALLOCSIZ        ; Allocation unit
        DW      1               ; Reserved sectors
        DB      2
        DW      DIRENT          ; Directory entries
        DW      NSECT*NHEADS*NTRACKS
        DB      1               ; Media descriptor
        DW      FATSIZ          ; Number of sectors for 1 Fat

BREAK   LABEL   BYTE            ; Break address

;**************************************************************
; Code below this point is thrown away for installable versions

HDSK$INIT:

        IF      INSTALL
        MOV     AX,CS
        MOV     BX,AX
        MOV     CL,4
        SHL     AX,CL
        ROL     BX,CL
        AND     BL,0FH
        ADD     [NEXTAD],AX
        ADC     [NEXTADHI],BL
        LDS     BX,[PTRSAV]
        MOV     WORD PTR [BX.TRANS],OFFSET IO:BREAK
        MOV     WORD PTR [BX.TRANS+2],CS
        PUSH    CS
        POP     DS
        ENDIF

        MOV     SI,OFFSET IO:HINITTAB
        JMP     SETBPB

CODE    ENDS
        END
