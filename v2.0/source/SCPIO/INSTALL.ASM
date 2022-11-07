TITLE   SCP IO.SYS INSTALL Program
; INSTALL - Copies system program IO.SYS

FALSE   EQU     0
TRUE    EQU     NOT FALSE

.xlist
.xcref
        INCLUDE DOSSYM.ASM
.cref
.list

CODE    SEGMENT PUBLIC
        ORG     100H
ASSUME  CS:CODE,DS:CODE,ES:CODE,SS:CODE

Start:
        MOV     AL,BYTE PTR DS:[06CH]
        MOV     BYTE PTR [IOFCB2],AL
        MOV     SI,05CH
        MOV     DI,OFFSET DS:IOFCB1
        MOV     CX,6
        REPZ    MOVSW
        MOV     DX,OFFSET DS:DAT_0000_01e3 ; = FFh
        MOV     AH,FCB_Open
        INT     21H
        OR      AL,AL
        JNZ     IO_NOT_FOUND
        MOV     word ptr [IOFCB1_EXT],1

        MOV     CX,word ptr DS:[6]
        MOV     DX,OFFSET DS:BUF
        SUB     CX,DX
        MOV     AH,Set_DMA
        INT     21H
        MOV     DX,OFFSET DS:DAT_0000_01e3     ; = FFh
        MOV     AH,FCB_Random_Read_Block
        INT     21H
        CMP     AL,1
        JNZ     IO_TOO_BIG
        MOV     DX,OFFSET DS:DAT_0000_020f     ; = FFh
        MOV     AH,FCB_Open
        INT     21H
        OR      AL,AL
        JNZ     IO_NOT_PRESENT
        MOV     word ptr [IOFCB2_EXT],1

        PUSH    CX
        MOV     DL,byte ptr [IOFCB2]
        MOV     AH,01CH
        PUSH    DS
        INT     21H
        POP     DS
        MOV     AH,0
        MUL     CX
        POP     CX
        OR      DX,DX
        JNZ     LAB_0000_0173
        MOV     BX,AX
        MOV     AX,WORD PTR [IOFCB2_REC_SIZE]
        DIV     BX
        OR      DX,DX
        JZ      LAB_0000_016b
        INC     AX
LAB_0000_016b: ;                                   XREF[1]:     0000:0168(j)
        MUL     BX
        CMP     AX,CX
        JC      IO_TOO_BIG
        MOV     CX,AX
LAB_0000_0173: ;                                   XREF[1]:     0000:015d(j)
        MOV     AH,FCB_Random_Write_Block
        MOV     DX,OFFSET DS:DAT_0000_020f
        INT     21H
        MOV     SI,OFFSET DS:IOFCB1_FSIZEL
        MOV     DI,OFFSET DS:IOFCB2_REC_DATE
        MOVSW
        MOVSW
        MOV     AH,FCB_Close
        INT     21H
        INT     20H                     ; old style exit for compatability
IO_NOT_FOUND:
        MOV     DX,OFFSET DS:NOTFMSG
ERREXIT:
        MOV     AH,STD_CON_STRING_OUTPUT    ; standard output device
        INT     21H
        INT     20H                     ; old style exit for compatability
IO_NOT_PRESENT:
        MOV     DX,OFFSET DS:IONOTP_MSG
        JMP     ERREXIT

IO_TOO_BIG:
    MOV        DX,OFFSET DS:IOBIG_MSG
    JMP        ERREXIT

NOTFMSG:
        DB      "File not found$"

IONOTP_MSG:
        DB      "IO.SYS not present on destination$"

IOBIG_MSG:                                          ;XREF[1]:     0000:0196(*)
        DB      "New I/O system too big$"

DAT_0000_01e3:                                  ;XREF[2]:     0000:0111(*), 0000:012f(*)
        DB      0FFh
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      06h
IOFCB1:                             ;XREF[1]:     0000:0109(*)
        DB      00h
        DB      "IO      SYS"

        DW      0000h
IOFCB1_EXT:                                  ;XREF[1]:     0000:011c(*)
        DW      0000h
        DW      0000h
        DW      0000h
;fixme
IOFCB1_FSIZEL:                      ; File Size low word.
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h ; hh
DAT_0000_020f:                                  ;XREF[2]:     0000:013a(*), 0000:0175(*)
        DB      0FFh
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      06h

IOFCB2: DB      00h                 ; FCB Drive indicator
        dB      "IO      SYS"       ; Filename

        DW      0000h               ; Current Extent
;fixme
IOFCB2_EXT:                         ;XREF[1]:     0000:0145(*)
                                  ;XREF[1]:     0000:0161(*)
        DW      0000h               ; Record Size
;fixme
IOFCB2_REC_SIZE:
        DW      0000h               ; File Size (two words.)
        DW      0000h
IOFCB2_REC_DATE:                    ;XREF[1]:     0000:017d(*)
        DW      0000h               ; Date of last writing
        DW      0000h               ; Time of last writing

        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h
        DB      00h                     ; End of FCB
BUF     DB      0FFH                    ; beginning of area for file reads

CODE    ENDS
        END     START
