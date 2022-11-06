PAGE    60,132

; Floppy disk I/O System for MS-DOS version 2.00 and later

        INCLUDE IODEF.ASM

IO      GROUP   CODE

CODE    SEGMENT BYTE PUBLIC 'IOSYS'
        ASSUME  CS:IO,DS:IO

        EXTRN   EXIT:NEAR, CMDERR:NEAR, BUS$EXIT:NEAR, PTRSAV:DWORD
        EXTRN   ERR$EXIT:NEAR
        EXTRN   SELECT:BYTE

        IF      LARGDRV
        PUBLIC  LDSKTBL
LDSKTBL:
        DW      LDSK$INIT
        DW      LMEDIA$CHK
        DW      GET$BPB
        DW      CMDERR
        DW      LDSK$READ
        DW      BUS$EXIT
        DW      EXIT
        DW      EXIT
        DW      LDSK$WRIT
        DW      LDSK$WRIT
        ENDIF

        IF      SMALLDRV
        PUBLIC  SDSKTBL
SDSKTBL:
        DW      SDSK$INIT
        DW      SMEDIA$CHK
        DW      GET$BPB
        DW      CMDERR
        DW      SDSK$READ
        DW      BUS$EXIT
        DW      EXIT
        DW      EXIT
        DW      SDSK$WRIT
        DW      SDSK$WRIT
        ENDIF

; ************ 1793-type controller disk I/O *****************

READCOM EQU     80H
WRITECOM EQU    0A0H

        IF      SCP
SMALLBIT EQU    10H
BACKBIT EQU     04H
DDENBIT EQU     08H
DONEBIT EQU     01H
DISK    EQU     0E0H
        ENDIF

        IF      TARBELL
BACKBIT EQU     40H
DDENBIT EQU     08H
DONEBIT EQU     80H
DISK    EQU     78H
DLYTIM  EQU     10              ; 24 usec delay after force interrupt
        ENDIF


CURDRV  DB      -1
; SIDE has media byte
; Bit 7=1 for 5", 0 for 8" drives
; Bit 6=1 for two-side, 0 for one-side drives
; DDENBIT set for double density, reset for single density
SIDE    DB      0

; Explanation of tables below.

; DRVTAB is a table of bytes which are sent to the disk controller as drive-
; select bytes to choose which physical drive is selected for each disk I/O
; driver.  Always select side 0 in the drive-select byte if
; a side-select bit is available.  Exactly which bits in the drive-select byte
; do what depends on which disk controller is used.

; TRKTAB is a table of bytes used to store which track the read/write
; head of each drive is on.  Each physical drive should have its own
; entry in TRKTAB.

; TRKPT is a table of bytes which indicates which TRKTAB entry each
; disk I/O driver should use.  Drives such as PerSci 277s which use
; the same head positioner for more than one drive should share entrys
; in TRKTAB.


        .SALL
BYTELST MACRO   INITVAL,COUNT,INC,DUPCNT
        LOCAL   X
X       =       INITVAL
        REPT    COUNT
        DB      DUPCNT DUP(X)
X       =       X+INC
        ENDM
        ENDM

DRVTAB  LABEL BYTE
        IF      SCP
        BYTELST 0,LDRVMAX,1,1
        BYTELST 10H,SDRVMAX,1,1
        ENDIF

        IF      TARBELL
        BYTELST 0,LDRVMAX,10H,1
        ENDIF

TRKPT   LABEL   BYTE
        IF      PERSCI
        BYTELST 0,LDRVMAX/2,1,2
        BYTELST LDRVMAX/2,SDRVMAX,1,1
TRKTAB  DB      (LDRVMAX/2+SDRVMAX) DUP (-1)
        ELSE
        BYTELST 0,LDRVMAX+SDRVMAX,1,1
TRKTAB  DB      (LDRVMAX+SDRVMAX) DUP (-1)
        ENDIF


        IF      LARGDRV
LINITTAB LABEL  WORD
        IF      LARGEDS OR SIDECHK
        DW      LDRVMAX DUP(LDSDRIVE)
        ELSE
        DW      LDRVMAX DUP(LSSDRIVE)
        ENDIF
        ENDIF

        IF      SMALLDRV
SINITTAB LABEL  WORD
        DW      SDRVMAX DUP(SDSDRIVE)
        ENDIF


        IF      SMALLDRV
SSSDRIVE:                       ; This is the IBM Personal Computer
        DW      512             ; disk format.
        DB      1
        DW      1
        DB      2
        DW      64
        DW      320
        DB      80H+DDENBIT
        DW      1
        DW      512

SDSDRIVE:                       ; The IBM PC format for double sided disks
        DW      512
        DB      2
        DW      1
        DB      2
        DW      112             ; # of directory entries
        DW      640
        DB      0C0H+DDENBIT    ; Media
        DW      1               ; Sectors for 1 fat
        DW      512             ; Reserve space
        ENDIF

        IF      LARGDRV
LSDRIVE:                        ; Single density / single sided
        DW      128             ;SECTOR SIZE
        DB      4               ;SECTORS/ALLOC UNIT
        DW      1               ;NUMBER OF RESERVED SECTORS
        DB      2               ;NUMBER OF FATS
        DW      68              ;NUMBER OF DIRECTORY ENTRIES
        DW      77*26           ;TOTAL NUMBER OF SECTORS
        DB      0               ;MEDIA BYTE
        DW      6               ;SECTORS FOR ONE FAT

        IF      SIDECHK OR LARGEDS
LDSDRIVE:                       ; Double density / double sided
        DW      1024
        DB      1
        DW      1
        DB      2
        DW      192
        DW      77*8*2
        DB      40H+DDENBIT     ; Media byte
        DW      2
        ENDIF

        IF      SIDECHK OR (LARGEDS-1)
LSSDRIVE:                       ; Double density / single sided
        DW      1024
        DB      1
        DW      1
        DB      2
        DW      96
        DW      77*8
        DB      DDENBIT         ; Media byte
        DW      1
        ENDIF
        ENDIF

;*********************************************************

; Disk change function.
; On entry:
;       AL = disk unit number.
;       AH = media byte
; On exit:
;       AX = status (done or error code)
;       [TRANS] set as follows:
;          = -1 (FF hex) if disk is changed.
;          = 0 if don't know.
;          = 1 if not changed.
;       [SIDE] has media byte for GETBPB call

SMEDIA$CHK:
        IF      COMBIN
        ADD     AL,LDRVMAX      ; Convert unit #
        ENDIF

LMEDIA$CHK:
        MOV     [SIDE],AH
        MOV     AH,0
        MOV     SI,AX
        XCHG    [SELECT+SI],AH  ; Has drive been selected before?
        OR      AH,AH
        JNZ     DENCHECK        ; If no, go check density

; First try head load test. If head is loaded on the drive we want,
; then disk must not have been changed.
        CMP     AL,[CURDRV]     ; Same drive?
        JNZ     CHGCHK          ; Try disk change signal if not
        PUSH    AX              ; Save unit number

        IF      SCP
        IN      AL,DISK+4       ; Head load byte for SCP controller
        ELSE
        IN      AL,DISK         ; Head load byte for Tarbell
        ENDIF

        AND     AL,20H          ; Look at head load bit
        POP     AX
        MOV     AH,1            ; AH = 1, disk not changed.
        JNZ     MEDIA$EXIT
CHGCHK:
; Now look at disk change bit if enabled and not a 5" drive.
        IF      SMALLDRV
        MOV     AH,0            ; Not sure if disk changed
        TEST    [SIDE],80H
        JNZ     MEDIA$EXIT      ; If small drive, don't use disk change signal
        ENDIF

        IF      DSKCHG
        CALL    CHKNEW
        MOV     DL,AL
        MOV     BX,OFFSET IO:DRVTAB
        XLAT                    ; Get drive select byte
        OUT     DISK+4,AL
        IN      AL,DISK+1       ; Get current track number
        OUT     DISK+3,AL       ; Make it the track to seek to
        MOV     AL,18H          ; Seek and load head
        CALL    DCOM
CHKLOOP:
        IN      AL,DISK         ; Read type I status
        TEST    AL,20H          ; Check head load bit
        JZ      CHKLOOP         ; Wait until head-load time out
        TEST    AL,80H          ; Is disk ready? 1= not ready
        JNZ     NOTRDY
        IN      AL,DISK+4       ; Bit 7=1 if disk not changed
        TEST    AL,80H
        MOV     AH,1
        JNZ     MEDIA$EXIT
        MOV     AL,DL           ; Restore unit number
        ENDIF

        MOV     AH,0            ; Disk may not have been changed

; Perform density check on 8" drive
; AH has current disk changed status, either 0 or -1
DENCHECK:
        IF      LARGDRV

        IF      COMBIN
        TEST    [SIDE],80H
        JNZ     MEDIA$EXIT      ; If small drive, don't need density check
        ENDIF

        MOV     DH,AH
        CALL    CHKNEW          ; Unload head if selecting new drive.
        MOV     BX,OFFSET IO:DRVTAB
        XLAT                    ; Get drive select byte
        MOV     DL,[SIDE]
        AND     DL,[DDENBIT]
        OR      DL,AL
        MOV     CX,4            ; Try each density twice
        MOV     AH,0            ; Disk may not have been changed
CHKDENS:
        MOV     AL,DL
        OUT     DISK+4,AL       ; Select disk
        MOV     AL,0C4H         ; READ ADDRESS command
        CALL    DCOM
        PUSH    AX
        IN      AL,DISK+3       ; Eat last byte to reset DRQ
        POP     AX
        AND     AL,98H
        JZ      HAVDENS         ; Jump if no error in reading address.
        NOT     AH
        XOR     DL,DDENBIT      ; Try other density
        LOOP    CHKDENS
        MOV     AH,AL
        JMP     ERROR

HAVDENS:
        AND     DL,DDENBIT

        IF      SIDECHK
        IN      AL,DISK+4
        AND     AL,40H          ; Get side bit (1=two sided)
        OR      DL,AL
        ENDIF

        MOV     [SIDE],DL
        OR      AH,DH
        ENDIF                   ;IF LARGDRV

MEDIA$EXIT:
        LDS     BX,[PTRSAV]
        MOV     BYTE PTR DS:[BX.TRANS],AH
        MOV     AH,1            ;No error
        RET

NOTRDY:
        MOV     AX,8102H        ;Return NOT READY error
        RET

CHKNEW:
        MOV     AH,AL           ; Save disk drive number in AH.
        XCHG    AL,[CURDRV]     ; Make new drive current, AL = previous
        CMP     AL,AH           ; Changing drives?
        JZ      RET3

; Changing drives, unload head so the head load delay one-shot
; will fire again. Do it by seeking to same track the H bit reset.

        IN      AL,DISK+1       ; Get current track number
        OUT     DISK+3,AL       ; Make it the track to seek to
        MOV     AL,10H          ; Seek and unload head
        CALL    DCOM
        MOV     AL,AH           ; Restore current drive number
RET3:   RET


GET$BPB:
; This is the equivalant of the old MAPDEV routine in MS-DOS 1.25.
; Using the media byte and/or FAT ID byte ,set the proper DPT for
; the driver.

        IF      COMBIN
        TEST    [SIDE],80H      ; Is it 5" drive ?
        JZ      GET8INCH
        ENDIF

        IF      SMALLDRV
        MOV     SI,OFFSET IO:SDSDRIVE
        MOV     AL,ES:[DI]      ; Get FAT ID byte
        TEST    AL,1            ; Is it double sided?
        JNZ     SETBPB
        MOV     SI,OFFSET IO:SSSDRIVE
        JMP     SHORT SETBPB
        ENDIF

        IF      LARGDRV
GET8INCH:
        TEST    [SIDE],DDENBIT  ; 0=single density, 1=double density
        MOV     SI,OFFSET IO:LSDRIVE
        JZ      SETBPB

        IF      SIDECHK OR LARGEDS
        MOV     SI,OFFSET IO:LDSDRIVE
        ENDIF

        IF      SIDECHK
        TEST    [SIDE],40H
        JNZ     SETBPB
        ENDIF

        IF      SIDECHK OR LARGEDS-1
        MOV     SI,OFFSET IO:LSSDRIVE
        ENDIF
        ENDIF                   ;IF LARGDRV

SETBPB:
        LDS     BX,[PTRSAV]
SETBPBPT:
        MOV     [BX.COUNT],SI
        MOV     [BX.COUNT+2],CS
        XOR     CX,CX           ; Don't change count field
        MOV     AH,1            ;No error
        RET


; Disk read function.
;
; On entry:
;       AL = Disk I/O driver number
;       AH = Media byte
;       ES:DI = Disk transfer address
;       CX = Number of sectors to transfer
;       DX = Logical record number of transfer
; On exit:
;       CX = number of sectors transferred.
;       AH = 1 if success, 81H if fail
;       AL = disk error code
;               0 = write protect error
;               2 = not ready error
;               4 = CRC error
;               6 = seek error
;               8 = sector not found
;               10 = write fault
;               12 = "data error" (any other error)

SDSK$READ:
        IF      COMBIN
        ADD     AL,LDRVMAX
        ENDIF

LDSK$READ:
        CALL    SEEK            ; Position head
        JC      ERROR
RDLP:
        PUSH    CX
        CALL    READSECT        ;Perform sector read
        POP     CX
        JC      ERROR
        INC     DH              ;Next sector number
        LOOP    RDLP            ;Read each sector requested
        MOV     AH,1            ;No error
        RET


; Disk write function.
; Registers same on entry and exit as read above.

SDSK$WRIT:
        IF      COMBIN
        ADD     AL,LDRVMAX
        ENDIF

LDSK$WRIT:
        CALL    SEEK            ;Position head
        JC      ERROR
WRTLP:
        PUSH    CX
        CALL    WRITESECT       ; Perform sector write
        POP     CX
        JC      ERROR
        INC     DH              ; Bump sector counter
        LOOP    WRTLP           ; Write CX sectors
        MOV     AH,1            ; No error
        RET

ERROR:
        MOV     BL,[CURDRV]
        MOV     BH,0
        MOV     DL,-1
        MOV     [BX+SELECT],DL
        MOV     [SI],DL         ; Indicate we don't know where head is.
        MOV     SI,OFFSET IO:ERRTAB
GETCOD:
        INC     DL              ; Increment to next error code.
        LODSB
        TEST    AH,AL           ; See if error code matches disk status.
        JZ      GETCOD          ; Try another if not.
        MOV     AL,DL           ; Now we've got the code.
        SHL     AL,1            ; Multiply by two.
        MOV     AH,81H          ; Return error code
        RET

ERRTAB  DB      40H             ; Write protect error
        DB      80H             ; Not ready error
        DB      8               ; CRC error
        DB      2               ; Seek error
        DB      10H             ; Sector not found
        DB      20H             ; Write fault
        DB      7               ; Data error

; Function:
;       Seeks to proper track.
; On entry:
;       Same as for disk read or write above.
; On exit:
;       AH = Drive select byte
;       DL = Track number
;       DH = Sector number
;       DI = Disk transfer address in ES
;       SI = pointer to drive's track counter in DS
;       CX unchanged (number of sectors)

SEEK:
        MOV     [SIDE],AH
        MOV     BL,AL
        MOV     BH,0
        CALL    CHKNEW
        MOV     AL,[SIDE]
        AND     AL,DDENBIT
        OR      AL,[DRVTAB+BX]  ;Get drive select byte
        OUT     DISK+4,AL       ;Select drive
        MOV     AH,AL           ; Save drive-select byte in AH.
        XCHG    AX,DX           ; AX = logical sector number.
        MOV     DL,26           ; 26 sectors/track unless changed below
        TEST    DH,DDENBIT      ; Check for double-density.
        JZ      HAVSECT
        MOV     DL,16
        TEST    [SIDE],40H
        JNZ     HAVSECT         ; Disk is double-sided
        MOV     DL,8            ; Disk is single sided
HAVSECT:
        DIV     DL              ; AL = track, AH = sector.
        XCHG    AX,DX           ; AH has drive-select byte, DX = track & sector.
        INC     DH              ; Sectors start at one, not zero.
        MOV     BL,[BX+TRKPT]   ; Get this drive's displacement into track table.
        ADD     BX,OFFSET IO:TRKTAB     ; BX now points to track counter for this drive.
        MOV     SI,BX
        MOV     AL,DL           ; Move new track number into AL.
        XCHG    AL,[SI]         ; Xchange current track with desired track
        OUT     DISK+1,AL       ; Inform controller chip of current track
        CMP     AL,DL           ; See if we're at the right track.
        JZ      RET4
        MOV     BH,2            ; Seek retry count
        CMP     AL,-1           ; Head position known?
        JNZ     NOHOME          ; If not, home head
TRYSK:
        CALL    HOME
        JC      SEEKERR
NOHOME:
        MOV     AL,DL           ; AL = new track number.
        OUT     DISK+3,AL
        MOV     AL,1CH+STPSPD   ; Seek command.
        CALL    MOVHEAD
        AND     AL,98H          ; Accept not ready, seek, & CRC error bits.
        JZ      RET4
        JS      SEEKERR         ; No retries if not ready
        DEC     BH
        JNZ     TRYSK
SEEKERR:
        MOV     AH,AL           ; Put status in AH.
        TEST    AL,80H          ; See if it was a Not Ready error.
        STC
        JNZ     RET4            ; Status is OK for Not Ready error.
        MOV     AH,2            ; Everything else is seek error.
RET4:   RET

SETUP:
        MOV     BL,DH           ; Move sector number to BL to play with
        TEST    AH,DDENBIT      ; Check for double density.
        JZ      CHECK26         ; Not DD.
        MOV     AL,AH           ; Select front side of disk.
        OUT     DISK+4,AL
        CMP     BL,8            ; See if legal DD sector number.
        JBE     PUTSEC          ; Jump if ok.
        TEST    [SIDE],40H      ; Get media byte to see if double sided
        JZ      STEP            ; Must step
        SUB     BL,8            ; Find true sector for back side.
        CMP     BL,8            ; See if ok now.
        JA      STEP            ; Have to step if still too big.
        MOV     AL,AH           ; Move drive select byte into AL.
        OR      AL,BACKBIT      ; Select back side.
        OUT     DISK+4,AL
        JMP     SHORT PUTSEC

CHECK26:
        CMP     BL,26           ; See if legal large SD/SS sector.
        JBE     PUTSEC          ; Jump if ok.
STEP:
        INC     DL              ; Increment track number.
        MOV     AL,58H          ; Step in with update.
        CALL    DCOM
        INC     BYTE PTR CS:[SI]        ; Increment the track pointer.
        MOV     DH,1            ; After step, do first sector.
        MOV     BL,DH           ; Fix temporary sector number also.
PUTSEC:
        MOV     AL,BL           ; Output sector number to controller.
        OUT     DISK+2,AL
RET5:   RET

READSECT:
        CALL    SETUP
        MOV     BL,10
        PUSH    DX
        MOV     DX,DISK+3
RDAGN:
        MOV     AL,READCOM
        CLI
        OUT     DISK,AL
        MOV     BP,DI
        JMP     SHORT RLOOPENTRY
RLOOP:
        STOSB
RLOOPENTRY:

        IF      SCP
        IN      AL,DISK+5
        SHR     AL,1
        IN      AL,DX
        JNC     RLOOP
        ENDIF

        IF      TARBELL
        IN      AL,DISK+4
        SHL     AL,1
        IN      AL,DX
        JC      RLOOP
        ENDIF

        STI                     ; Interrupts OK now
        CALL    GETSTAT
        AND     AL,9CH
        JZ      RDPOP
        MOV     DI,BP
        MOV     BH,AL           ; Save error status for report
        DEC     BL
        JNZ     RDAGN
        MOV     AH,BH           ; Put error status in AH.
        STC
RDPOP:
        POP     DX

        IF      TARBELL
FORCINT:
        MOV     AL,0D0H         ; Tarbell controllers need this force interrupt
        OUT     DISK,AL         ; so that Type I status is always available
        MOV     AL,DLYTIM       ; at the 1793 status port so we can find out
INTDLY:                         ; if the head is loaded. SCP controllers have
        DEC     AL              ; head load status available at the DISK+4
        JNZ     INTDLY          ; status port.
        ENDIF

        RET

WRITESECT:
        CALL    SETUP
        MOV     BL,10
        XCHG    SI,DI
        PUSH    ES
        POP     DS              ;DS must have transfer segment

        ASSUME  DS:NOTHING

        PUSH    DX
        MOV     DX,DISK+3
WRTAGN:
        MOV     AL,WRITECOM
        CLI
        OUT     DISK,AL
        MOV     BP,SI
WRLOOP:

        IF      SCP
        IN      AL,DISK+5
        SHR     AL,1
        LODSB
        OUT     DX,AL
        JNC     WRLOOP
        ENDIF

        IF      TARBELL
        IN      AL,DISK+4
        SHL     AL,1
        LODSB
        OUT     DX,AL
        JC      WRLOOP
        ENDIF

        STI
        DEC     SI
        CALL    GETSTAT
        AND     AL,0FCH
        JZ      WRPOP
        MOV     SI,BP
        MOV     BH,AL
        DEC     BL
        JNZ     WRTAGN
        MOV     AH,BH           ; Error status to AH.
        STC
WRPOP:
        POP     DX
        PUSH    CS
        POP     DS              ;Restore local DS

        ASSUME  DS:IO

        XCHG    SI,DI

        IF      TARBELL
        JMP     FORCINT
        ELSE
        RET
        ENDIF

HOME:
        MOV     BL,3
TRYHOM:
        MOV     AL,0CH+STPSPD
        CALL    DCOM
        AND     AL,98H
        JZ      RET6
        JS      HOMERR          ; No retries if not ready
        MOV     AL,58H+STPSPD   ; Step in with update
        CALL    DCOM
        DEC     BL
        JNZ     TRYHOM
HOMERR:
        STC
RET6:   RET

MOVHEAD:
DCOM:
        OUT     DISK,AL
        PUSH    AX
        AAM                     ; Delay 10 microseconds
        POP     AX
GETSTAT:
        IN      AL,DISK+4
        TEST    AL,DONEBIT

        IF      SCP
        JZ      GETSTAT
        ENDIF

        IF      TARBELL
        JNZ     GETSTAT
        ENDIF

        IN      AL,DISK
        RET

        IF      LARGDRV
LDSK$INIT:
        MOV     AL,LDRVMAX
        MOV     SI,OFFSET IO:LINITTAB
        ENDIF

SETDRV:
        LDS     BX,[PTRSAV]
        MOV     [BX.MEDIA],AL
        JMP     SETBPBPT

        IF      SMALLDRV
SDSK$INIT:
        MOV     AL,SDRVMAX
        MOV     SI,OFFSET IO:SINITTAB
        JMP     SETDRV
        ENDIF

CODE    ENDS
        END
