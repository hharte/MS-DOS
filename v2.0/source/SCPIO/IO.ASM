; I/O System for MS-DOS version 2.00 and later. Revised 12-22-82.
; Contains data packets and init code only

       TITLE   IO.SYS for the SCP300F.

; I/O system for Version 2.x of MSDOS.

;This BIOS designed to be linked with the SYSINIT module provided by
;Microsoft

BIOSIZ  EQU     8*400H          ;Size of BIOS in bytes.
BIOSIZS EQU     BIOSIZ/10H      ;Size of BIOS in Paragraphs.
MAXBUF  EQU     10              ; # of buffers for files
MAXFIL  EQU     10              ; # of files to be opened at one time

        INCLUDE IODEF.ASM

        PUBLIC  PTRSAV,EXIT,BUS$EXIT,CMDERR,ERR$EXIT
        PUBLIC  RE_INIT
        PUBLIC  SELECT

;Things needed to communicate with SYSINIT

EXTRN   SYSINIT:FAR                   ;The entry point of SYSINIT
EXTRN   CURRENT_DOS_LOCATION:WORD     ;Where the DOS is when SYSINIT called
EXTRN   FINAL_DOS_LOCATION:WORD       ;Where I want SYSINIT to put the DOS
EXTRN   DEVICE_LIST:DWORD             ;Pointer to the DEVICE list.
EXTRN   MEMORY_SIZE:WORD              ;Size in paragraphs of Physical memory.
EXTRN   DEFAULT_DRIVE:BYTE            ;Default Drive to use when system booted
EXTRN   BUFFERS:BYTE                  ;Number of default buffers.
                                      ; Leave as is and SYSINIT uses only 2.
EXTRN   FILES:BYTE
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

        ORG     0               ;Starts at an offset of zero.

INIT:   JMP     HWINIT

        PAGE

        SUBTTL  Device driver tables.
SELECT  DB      (LDRVMAX+SDRVMAX+HARD) DUP (-1)

;-----------------------------------------------+
;     DWORD pointer to next device              | 1 word offset.
;         (-1,-1 if last device)                | 1 word segement.
;-----------------------------------------------+
;     Device attribute WORD                     ; 1 word.
;       Bit 15 = 1 for chacter devices.         ;
;                0 for Block devices.           ;
;                                               ;
;       Charcter devices. (Bit 15=1)            ;
;         Bit 0 = 1  current sti device.        ;
;         Bit 1 = 1  current sto device.        ;
;         Bit 2 = 1  current NUL device.        ;
;         Bit 3 = 1  current Clock device.      ;
;                                               ;
;         Bit 13 = 1 for non IBM machines.      ;
;                  0 for IBM machines only.     ;
;         Bit 14 = 1 IOCTL control bit.         ;
;-----------------------------------------------+
;     Device strategy pointer.                  ; 1 word offset.
;-----------------------------------------------+
;     Device interrupt pointer.                 ; 1 word offset.
;-----------------------------------------------+
;     Device name field.                        ; 8 bytes.
;       Character devices are any valid name    ;
;         left justified, in a space filled     ;
;         field.                                ;
;       Block devices contain # of units in     ;
;         the first byte.                       ;
;-----------------------------------------------+

DEVSTART LABEL WORD
CONDEV:  ;Header for device CON
        DW      AUXDEV,BIOSSEG  ;Link to next device
        DW      8013H           ;Attributes - console input, output device
        DW      STRATEGY        ;Srategy entry point
        DW      CON$IN          ;Interrupt entry point
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

TIMDEV:                         ;Header for device CLOCK
        DW      DSKDEV,BIOSSEG
        DW      8008H
        DW      STRATEGY
        DW      TIM$IN
        DB      "CLOCK   "

DSKDEV:  						;Header for disk devices
        IF      LARGDRV
        DW      SDSKDEV,BIOSSEG
        DW      2000H           ;Is a block device
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

;
; Console interrupt routine for processing I/O packets.
;

CON$IN:
        PUSH    SI
        MOV     SI,OFFSET IO:CONTBL
        JMP     SHORT ENTRY

;
; Auxilary interrupt routine for processing I/O packets.
;

AUX$IN:
        PUSH    SI
        MOV     SI,OFFSET IO:AUXTBL
        JMP     SHORT ENTRY

;
; Printer interrupt routine for processing I/O packets.
;

PRN$IN:
        PUSH    SI
        MOV     SI,OFFSET IO:PRNTBL
        JMP     SHORT ENTRY

;
; Clock interrupt routine for processing I/O packets.
;

TIM$IN:
        PUSH    SI
        MOV     SI,OFFSET IO:TIMTBL
        JMP     SHORT ENTRY

;
; Disk interrupt routine for processing I/O packets.
;

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

;
; Common program for handling the simplistic I/O packet
;   processing scheme in MSDOS 2.0
;

DISPATCH PROC   FAR
ENTRY:  PUSH    AX              ;Save all nessacary registers.
        PUSH    CX
        PUSH    DX
        PUSH    DI
        PUSH    BP
        PUSH    DS
        PUSH    ES
        PUSH    BX

        LDS     BX,CS:[PTRSAV]  ;Retrieve pointer to I/O Packet.

        MOV     AL,[BX.UNIT]    ;AL = Unit code.
        MOV     AH,[BX.MEDIA]   ;AH = Media descriptor.
        MOV     CX,[BX.COUNT]   ;CX = Contains byte/sector count.
        MOV     DX,[BX.START]   ;DX = Starting Logical sector.

        XCHG    DI,AX           ;Move Unit & Media into DI temporarily.
        MOV     AL,[BX.CMD]     ;Retrieve Command type. (1 => 11)
        XOR     AH,AH           ;Clear upper half of AX for calculation.
        ADD     SI,AX           ;Compute entry pointer in dispatch table.
        ADD     SI,AX
        CMP     AL,11           ;Verify that not more than 11 commands.
        JA      CMDERR          ;Ah, well, error out.
        XCHG    AX,DI           ;Move Unit & Media back where they belong.
        LES     DI,[BX.TRANS]   ;DI contains addess of Transfer address.
                                ;ES contains segment.
        PUSH    CS
        POP     DS              ;Data segment same as Code segment.

        CALL    [SI]            ;Perform I/O packet command.

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

HWINIT:
        XOR     BP,BP           ; Set up stack just below I/O system.
        MOV     SS,BP
        MOV     SP,BIOSSEG*16
        PUSH    CS
        POP     DS
;Fall into init code of other modules

INITSEG ENDS


LASTSEG SEGMENT BYTE PUBLIC 'IOSYS'
ASSUME  CS:IO
ASSUME  DS:SEG SYSINIT

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
