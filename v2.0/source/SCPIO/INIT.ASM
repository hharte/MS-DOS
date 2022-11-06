PAGE 60,80
;
; SCP's OEM disk initialization module to link with
; Microsoft's FORMAT.OBJ and FORMES.OBJ disk formatting program.
; Use this for MS-DOS 2.0 disks.
; Revised 3-11-83.
;
        INCLUDE IODEF.ASM

BOOTER  EQU     200H    ; "B" command puts boot sector here.

SEGBIOS SEGMENT AT BIOSSEG
BIOS    LABEL   FAR
SEGBIOS ENDS

CODE    SEGMENT BYTE PUBLIC 'CODE'
ASSUME  CS:CODE,DS:CODE,ES:CODE

        PUBLIC  FATID,STARTSECTOR,SWITCHLIST,FREESPACE,FATSPACE,HARDFLAG
        PUBLIC  INIT,DISKFORMAT,BADSECTOR,WRTFAT,DONE
        EXTRN   SWITCHMAP:WORD,DRIVE:BYTE

;
; *******************************************************************
;

                IF      SCP
DISK            EQU     0E0H
DONEBIT         EQU     01H
SMALLBIT        EQU     10H
BACKBIT         EQU     04H
DDENBIT         EQU     08H
                ENDIF

                IF      TARBELL
DISK            EQU     78H
DONEBIT         EQU     80H
BACKBIT         EQU     40H
DDENBIT         EQU     08H
                ENDIF

GET_DPB         EQU     50
GET_CDPB        EQU     81
RETRY           EQU     3

ONE_BIT         EQU     40H
TWO_BIT         EQU     20H
C_BIT           EQU     10H             ; This must be up here instead of near
D_BIT           EQU     08H             ;  SWITCHLIST because the assembler
O_BIT           EQU     04H             ; Can't handle the forward references
V_BIT           EQU     02H
S_BIT           EQU     01H

INIT:
        IF      SMALLDRV
        CALL    DRIVESELECT
        TEST    AL,SMALLBIT             ; See if small drive
        JZ      INIT3
        OR      [SWITCHMAP],D_BIT       ; Force double-density on 5.25
                                        ; drives because controller can't
                                        ; handle single-density well.
INIT3:
        ENDIF

        IF      (SIDECHK-1)*(LARGEDS OR SMALLDS)
        OR      [SWITCHMAP],TWO_BIT     ; Force double sided if set
        ENDIF

        TEST    [SWITCHMAP],ONE_BIT
        JZ      INIT4
        AND     [SWITCHMAP],NOT TWO_BIT ; Turn off 2 sided line
INIT4:
        TEST    [SWITCHMAP],TWO_BIT     ; Is it double sided
        JZ      INIT1
        OR      BYTE PTR [SIDE],0FFH    ; Set flag

INIT1:
        OR      [SWITCHMAP],V_BIT       ; Always ask for volume ID

        IF      HARD
        MOV     AL,[DRIVE]
        CMP     AL,LDRVMAX+SDRVMAX      ; Is it hard disk ?
        JB      INIT2                   ; Exit
        MOV     HARDFLAG,0FFH           ; Set flag
        ENDIF

INIT2:  CLC                             ; No errors.
        RET

DISKFORMAT:
        MOV     BL,[DRIVE]
        MOV     BH,0
        PUSH    DS
        MOV     AX,BIOSSEG
        MOV     DS,AX
        MOV     BYTE PTR [BX+3],-1      ; Flag disk as unknown
        POP     DS

        IF      HARD
        CMP     BYTE PTR HARDFLAG,0FFH  ; Is it a hard disk ?
        JNZ     FT1
        JMP     HDFORMAT                ; Format the hard disk
FT1:
        ENDIF

        TEST    [SWITCHMAP],C_BIT
        JNZ     CHKDENS
        MOV     DX,OFFSET FRMT_MSG
        CALL    MESSAGE
        JMP     KNOW_DENSITY1
;
; If we are just clearing the disk, it is not necessary for the operator
; to specify the correct density.  Therefore, look at the disk to figure
; out what it really is.
;
CHKDENS:
        MOV     CX,4            ; Try each density twice
CHK:
        CALL    DRIVESELECT     ; Select drive.
        OUT     DISK+4,AL       ; Select disk
        MOV     AL,0C4H         ; READ ADDRESS command
        CALL    DCOM
        AND     AL,98H
        IN      AL,DISK+3       ; Eat last byte to reset DRQ
        JZ      CHK1            ; Jump if no error in reading address.
        XOR     BYTE PTR [SWITCHMAP],D_BIT      ; Try other density
        LOOP    CHK
        MOV     DX,OFFSET READ_ERROR    ; Error message.
        JMP     ERROR
CHK1:
        IF      SIDECHK
        CALL    DRIVESELECT
        AND     AL,SMALLBIT
        JNZ     CHK2            ; Make sure it is not a small drive
        TEST    SWITCHMAP,D_BIT
        JZ      CHK2            ; Make sure it is not single density
        IN      AL,DISK+4
        AND     AL,40H          ; Get side bit
        OR      [SIDE],AL       ; Set it
        ENDIF

CHK2:                           ; Force a disk read to get proper DPB
        MOV     CX,RETRY
CHK3:   PUSH    CX
        MOV     DL,DRIVE
        INC     DL
        MOV     AH,GET_DPB
        INT     21H             ; Media check
        PUSH    CS
        POP     DS
        MOV     AL,DRIVE
        MOV     CX,1
        MOV     DX,1
        MOV     BX,OFFSET PATTERN       ; Temp buffer
        INT     25H             ; Direct read
        POP     DX
        POP     CX
        JNC     CHK4
        LOOP    CHK3            ; Read until good
CHK4:
        JMP     BOOTRET
KNOW_DENSITY1:
        CALL    HEADUNLOAD      ; So I/O system thinks disk may be changed.
KNOW_DENSITY2:
        CALL    DRIVESELECT     ; Select drive.
        OUT     DISK+4,AL       ; Select disk

        IF      SIDECHK
        AND     AL,SMALLBIT     ; Make sure it is not a small drive
        JNZ     KNOW_DENSITY3
        MOV     AL,0C4H         ; READ ADDRESS command
        CALL    DCOM            ; Just read disk, don't care if error
        IN      AL,DISK+4
        AND     AL,40H          ; Get side bit
        OR      [SIDE],AL       ; Set it
KNOW_DENSITY3:
        ENDIF

        MOV     WORD PTR [TKCNT],0
        MOV     BYTE PTR [TKCNT+2],0
        CALL    TABLE           ; SI points to table of info for disk format.
        MOV     AL,[SI+10]      ; Get FATID byte for this format.
        MOV     [FATID],AL
        MOV     AX,[SI+11]      ; Get STARTSECTOR for this format.
        MOV     [STARTSECTOR],AX
DOIT:
        MOV     BX,OFFSET PATTERN
        MOV     DX,[SI+6]       ; DX points to index pattern.
        CALL    MAKE            ; Make pattern for index mark and one sector
        MOV     CL,[SI]         ; Get sector count for this sector.
        DEC     CL              ; Repeat sector pattern for remaining sectors.
MAKSEC:
        MOV     DX,[SI+8]       ; DX points to sector pattern.
        CALL    MAKE
        DEC     CL
        JNZ     MAKSEC
        CALL    MAKE            ; Fill out rest of track.
                                ; Put in sequential sector numbers.
                                ;
        MOV     AL,1            ; Start with sector number 1
        MOV     CL,AL           ; Add one to each succeeding sector number
        MOV     BX,[SI+2]       ; Get offset from beginning of pattern to first
        INC     BX              ;  track number.  Increment to side,
        INC     BX              ;  then sector.
        ADD     BX,OFFSET PATTERN       ; Compute actual memory address.
        CALL    PUTSEC
        CALL    RESTORE         ; Move the head to track 0.
        JZ      TRACK0          ; Jump if no problem with restoring.
        MOV     DX,OFFSET SEEK_ERROR    ; Error message.
        JMP     ERROR
TRACK0:
        XOR     DL,DL           ; Start with track 0.
TRACKLOOP:
        PUSH    BX
        MOV     BX,OFFSET TRK_MSG
        CALL    INCTRK
        POP     BX
        MOV     AL,DL           ; Get track number.
        MOV     BX,[SI+2]       ; Address of first track number in pattern.
        ADD     BX,OFFSET PATTERN
        MOV     CL,0
        CALL    PUTSEC          ; Put track number in each sector.
        CALL    DRIVESELECT     ; Get drive-select byte.
        OUT     DISK+4,AL       ; Select side.
        SUB     DH,DH           ; Start with side 0.
SIDELOOP:
        MOV     AL,DH           ; Get side number.
        MOV     BX,[SI+2]       ; Get offset from beginning of pattern to first
        INC     BX              ;  track number.  Increment to side.
        ADD     BX,OFFSET PATTERN       ; Compute actual memory address.
        MOV     CL,0
        CALL    PUTSEC          ; Put side byte in each sector
;
; Write a track.
;
        CALL    TRACK
        JNC     CHECK_SIDE      ; Jump if no error.
        MOV     DX,OFFSET WRITE_ERROR   ; Error message.
        JMP     ERROR

CHECK_SIDE:
        TEST    BYTE PTR [SIDE],0FFH     ; Check two sided bit
        JZ      NEXTRACK
        CALL    DRIVESELECT     ; Get drive-select byte.
        TEST    AL,DDENBIT      ; See if double-density.
        JZ      NEXTRACK        ; Jump if not (single-density always SS).

CHKS1:
        INC     DH              ; Next side.
        CMP     DH,2            ; See if too big.
        JAE     NEXTRACK        ; Finished this track, on to the next.
        OR      AL,BACKBIT      ; Select back side.
        OUT     DISK+4,AL
        JMP     SHORT SIDELOOP  ; Do the back side.

NEXTRACK:
        INC     DL              ; Next track.
        CMP     DL,[SI+1]       ; See if done.
        JAE     FINIS
        MOV     AL,58H+STPSPD   ; Step in with update, no verify.
        CALL    DCOM
        TEST    AL,098H         ; Check for errors, Not Ready,
        JZ      TRACKLOOP       ;  Seek Error, CRC Error.
        MOV     DX,OFFSET SEEK_ERROR
        JMP     ERROR
FINIS:
        MOV     DX,10
        CALL    CONOUT
        CALL    RESTORE         ; Move the head back.
        MOV     DX,OFFSET SEEK_ERROR    ; Error message in case of error.
        JZ      F2
        JMP     ERROR
F2:
        CALL    HEADUNLOAD      ; Make the I/O system think the disk is changed
F3:     JMP     BOOT_SECTOR

; Set SI to point to a table of data for the selected disk format.
;
; [SI+0] = number of sectors/track
; [SI+1] = number of tracks (or cylindars) on disk.
; [SI+2] = number of bytes from beginning of format pattern track number is.
; [SI+4] = number of bytes in pattern for each sector.
; [SI+6] = address of pattern for index address mark.
; [SI+8] = address of pattern for each sector.
; [SI+10] = FATID byte for this format.
; [SI+11] = STARTSECTOR for this format.
; [SI+13] = number of sectors boot sector should load.
; [SI+15] = number of bytes/sector.
;
TABLE:
        TEST    BYTE PTR HARDFLAG,0FFH
        MOV     AH,6
        JNZ     DENSITYOK

        IF      SCP AND (SMALL OR COMBIN)
        SUB     AH,AH           ; Zero out bit pattern for indexing.
        CALL    DRIVESELECT     ; Get drive-select byte.
        AND     AL,SMALLBIT     ; See if small disk.
        JNZ     SIZEOK          ; Jump if small.
        ENDIF

        TEST    [SWITCHMAP],D_BIT
        MOV     AH,3
        JZ      DENSITYOK       ; It is single density
        MOV     AH,4
        TEST    BYTE PTR [SIDE],0FFH    ; Is it double/sided?
        JZ      DENSITYOK
        MOV     AH,5            ; Set to double/sided
        JMP     DENSITYOK
SIZEOK:
        TEST    [SWITCHMAP],D_BIT
        MOV     AH,0            ; Turn on bit 0 if single-density.
        JZ      DENSITYOK       ; Jump if single-density.
        MOV     AH,1
        TEST    BYTE PTR [SIDE],0FFH    ; Is it double sided?
        JZ      DENSITYOK
        MOV     AH,2            ; Set to double sided
DENSITYOK:
        MOV     AL,AH           ; Computed number to AL.
        MOV     AH,17           ; And multiply by number of bytes in table.
        MUL     AH              ; AX = AL*AH.
        ADD     AX,OFFSET DATATABLE     ; Add the address of the table.
        MOV     SI,AX
        RET

DRIVESELECT:
        MOV     AL,[DRIVE]      ; Get drive-select byte for drive [DRIVE].
        PUSH    BX
        MOV     BX,OFFSET DRVTAB
        XLAT
        TEST    [SWITCHMAP],D_BIT       ; See if double-density.
        JZ      SPUTNIK         ; Jump if not.
        OR      AL,DDENBIT      ; Turn on double-density.
SPUTNIK:
        POP     BX
        RET

PUTSEC:
        PUSH    DX
        MOV     CH,[SI]         ; CH = number of sectors.
        MOV     DX,[SI+4]       ; DX = number of bytes in sector pattern.
SEC:
        MOV     [BX],AL         ; Poke number in sector ID.
        ADD     BX,DX
        ADD     AL,CL           ; Increment sector, side, or track number.
        DEC     CH
        JNZ     SEC
        POP     DX
        RET

MAKE:
        PUSH    SI
        MOV     SI,DX
MAKELOOP:
        CLD                     ; a.k.a. "UP"
        LODSB                   ; Get byte count.
        OR      AL,AL           ; Return if zero.
        JZ      MAKERETURN
        MOV     CH,AL           ; Count to CH.
        LODSB                   ; Get byte for pattern.
PUTPAT:
        MOV     [BX],AL         ; Put byte in pattern.
        INC     BX
        DEC     CH
        JNZ     PUTPAT
        JMP     SHORT MAKELOOP
MAKERETURN:
        MOV     DX,SI
        POP     SI
        RET
;
; Subroutine to restore head to track 0.
; On return, Z flag set if errors.
;
RESTORE:
        MOV     AL,08H+STPSPD   ; Restore without verify
        CALL    DCOM
        TEST    AL,098H         ; Check for errors, Not Ready,
RESTORE_RETURN:                 ;  Seek Error, CRC Error.
        RET

TRACK:
        MOV     DI,SI           ; Save SI (pointer to DATATABLE).
        MOV     SI,OFFSET PATTERN
        MOV     BP,DX           ; Save DX.
        MOV     DX,DISK+3       ; Disk controller data port.
        MOV     AL,0F4H         ; Write Track command.
        CLI                     ; Interrupts off.
        OUT     DISK,AL
WRTLP:
        IF      SCP
        IN      AL,DISK+5       ; Wait for DRQ or INTRQ.
        SHR     AL,1
        LODSB                   ; Get a byte of the pattern.
        OUT     DX,AL           ; Send to controller.
        JNC     WRTLP
        ENDIF

        IF      TARBELL
        IN      AL,DISK+4       ; Wait for DRQ or INTRQ.
        SHL     AL,1
        LODSB                   ; Get a byte of the pattern.
        OUT     DX,AL           ; Send to controller.
        JC      WRTLP
        ENDIF

        STI                     ; Interrupts back on.
        MOV     DX,BP           ; Restore DX.
        MOV     SI,DI           ; Restore SI.
        CALL    WAITS           ; Wait till status ready.
        AND     AL,0E4H         ; Accept "not ready", "write protect", "write
        JZ      WRITERET        ;  fault", & "lost data" errors.
        STC                     ; Set CY flag if error.
WRITERET:
        RET

DCOM:
        OUT     DISK,AL
        AAM                     ; 10 Microsecond delay.
WAITS:
        IN      AL,DISK+4
        TEST    AL,DONEBIT

        IF      SCP
        JZ      WAITS
        ENDIF

        IF      TARBELL
        JNZ     WAITS
        ENDIF

        IN      AL,DISK         ; Get status from disk.
        RET

HEADUNLOAD:
        IN      AL,DISK+1       ; Read current track.
        OUT     DISK+3,AL       ; Make it the track to seek to.
        MOV     AL,10H          ; Seek with head unloaded.
        CALL    DCOM
        RET
;
; Transfer the boot sector to the disk.
;
BOOT_SECTOR:
        TEST    [SWITCHMAP],C_BIT
        JZ      SECTOR1
        JMP     BOOTRET
SECTOR1:
        TEST    SWITCHMAP,D_BIT
        JZ      POKE_SINGLE
        TEST    BYTE PTR [SIDE],0FFH    ; Read 2 sided bit
        JZ      POKE_SINGLE     ; Do single sided boot

POKE_DOUBLE:
        MOV     AX,[SI+13]      ; Poke number of sectors to load into boot.
        MOV     WORD PTR [B2POKE_SECTOR+1],AX
        MOV     AL,[SI+11]      ; Poke STARTSECTOR into boot sector.
        INC     AL              ; First sector on a track is 1, not 0.
        MOV     BYTE PTR [B2POKE_FIRSECT+1],AL
        MOV     AL,[SI]         ; Poke sectors/track two places into boot.
        MOV     BYTE PTR [B2POKE_HALFSECT_1+1],AL
        MOV     BYTE PTR [B2POKE_HALFSECT_2+1],AL
        SAL     AL,1            ; Compute number of sectors/"cylinder".
        MOV     BYTE PTR [B2POKE_MAXSECT_1+2],AL
        MOV     BYTE PTR [B2POKE_MAXSECT_2+2],AL
        CALL    DRIVESELECT     ; Get drive-select byte.

        IF      SCP
        AND     AL,0FCH         ; Force drive 0
        ENDIF

        IF      TARBELL
        AND     AL,0CFH
        ENDIF

        MOV     BYTE PTR [B2POKE_DRIVESELECT+1],AL
        MOV     AX,[SI+15]      ; Poke sector size into boot sector.
        MOV     WORD PTR [B2POKE_SECSIZE+2],AX
        MOV     BX,OFFSET BOOT2SIDED
        JMP     SHORT WRITE_BOOT

POKE_SINGLE:
        MOV     AX,[SI+13]      ; Poke number of sectors to load into boot.
        MOV     WORD PTR [B1POKE_SECTOR+1],AX
        MOV     AL,[SI+11]      ; Poke STARTSECTOR into boot sector.
        INC     AL              ; First sector on a track is 1, not 0.
        MOV     BYTE PTR [B1POKE_FIRSECT+1],AL
        MOV     AL,[SI]         ; Poke sectors/track two places into boot.
        MOV     BYTE PTR [B1POKE_MAXSECT_1+2],AL
        MOV     BYTE PTR [B1POKE_MAXSECT_2+2],AL
        MOV     AX,[SI+15]      ; Poke sector size into boot sector.
        MOV     WORD PTR [B1POKE_SECSIZE+2],AX
        MOV     BX,OFFSET BOOT1SIDED

WRITE_BOOT:
        CALL    HEADUNLOAD
        MOV     CX,RETRY
WRT1:
        PUSH    CX
        MOV     AL,[DRIVE]      ; Which drive to write the boot to.
        PUSH    BX
        PUSH    AX
        MOV     AH,GET_DPB
        MOV     DL,AL
        INC     DL
        INT     21H             ; Force a media check. Set density
        PUSH    CS
        POP     DS
        POP     AX
        POP     BX
        MOV     CX,1            ; One sector.
        MOV     DX,0            ; Write sector number 0.
        INT     38              ; Call I/O system to write boot sector.
        POP     DX
        POP     CX
        JNC     WTRET
        LOOP    WRT1
        MOV     DX,OFFSET BOOT_ERROR    ; Error message in case it didn't work.
        JMP     MESSAGE
WTRET:
        IF      SCP AND (SMALL OR COMBIN)
        CALL    TABLE
        CALL    DRIVESELECT
        AND     AL,SMALLBIT     ; Is it small drive
        JZ      WTRET1
        MOV     BX,OFFSET SMALLDATA
        MOV     AL,[SI+10]
        MOV     [BX],AL         ; Put fatid
        MOV     CX,1
        MOV     DX,1
        MOV     AL,[DRIVE]
        INT     38              ; Write Fatid byte
        POP     DX              ; Restore flags

WTRET1:
        ENDIF

BOOTRET:
; Calculate the number of sectors and buffer size here for bad sector
; checking. Initialize the memory parameters.

        TEST    BYTE PTR HARDFLAG,0FFH
        JNZ     BOOT0
        CALL    RESTORE
BOOT0:
        CALL    TABLE
        MOV     AL,[SI]
        CBW
        MOV     CX,[SI+1]       ; # of tracks on disk
        TEST    BYTE PTR HARDFLAG,0FFH  ; Hard disk has 2 bytes for this parameter
        JNZ     BOOT2
        MOV     CH,0
BOOT2:
        MUL     CX              ; Calculate # of sectors on disk
        MOV     [SCCNT],AX      ; Save
        MOV     AX,[SI+15]      ; Sector size
        MOV     [SECSZ],AX
        MOV     [SCTN],30       ; Start with 30 sectors to try
BOOT1:
        MOV     AX,[SECSZ]
        MOV     CL,[SCTN]       ; #of sectors to read
        MOV     CH,0
        MUL     CX              ; Test for maximum reads
        CMP     AX,4096         ; Don't make buffer any bigger
        JBE     BOOTRET1
        DEC     [SCTN]
        JMP     BOOT1           ; Keep calculating until 4k or smaller

BOOTRET1:
        MOV     [SCTN],CL       ; This is the number of sectors to read
        MOV     DL,[DRIVE]
        INC     DL
        MOV     AH,50
        INT     21H             ; Get DPB
        MOV     AL,[BX+0FH]     ; Get size of fat in sectors
        MOV     AH,[BX+8]       ; Get number of fats
        MOV     DX,[BX+6]       ; First sector of fat
        MOV     BX,[BX+0BH]     ; First sector of data
        PUSH    CS
        POP     DS
        MOV     [STARTSECTOR],BX
        MOV     [STRT],BX
        MOV     CX,[SCCNT]
        SUB     CX,BX
        MOV     [SCCNT],CX      ; Calculate true remaining sectors
        MOV     [FATCNT],AH
        MOV     [FATSTART],DX
        XOR     AH,AH
        MOV     [FATSIZE],AX
        TEST    [SWITCHMAP],C_BIT
        JZ      BOOTEXIT
        MOV     CX,RETRY
RET2:
        PUSH    CX
        MOV     CX,1
        MOV     DX,0
        MOV     BX,OFFSET PATTERN
        MOV     AL,[DRIVE]
        INT     25H
        POP     DX
        POP     CX
        JNC     BOOTEXIT
        LOOP    RET2
BOOTEXIT:
        MOV     DX,OFFSET BDSCT_MSG
        CALL    MESSAGE
        CLC
        RET

SMALLDATA:
        DB      0
        DB      0FFH
        DB      0FFH

ERROR:
        CALL    HEADUNLOAD
MESSAGE:
        MOV     AH,9            ; Function 9, print string.
        INT     33
        STC
        RET

INCTRK:

        PUSH    DX
        PUSH    AX
        PUSH    SI
        MOV     DX,BX
        CALL    MESSAGE
        MOV     SI,OFFSET CODE:TKCNT
        INC     WORD PTR [SI]
        MOV     AX,[SI]
        INC     SI
        INC     SI
        CMP     AL,10
        JB      C2
        ADD     AH,1
C2:     AAM
        CMP     AH,10
        JB      C1
        MOV     AX,0
        MOV     SI,OFFSET CODE:TKCNT
        MOV     [SI],AX
        INC     SI
        INC     SI
        INC     BYTE PTR [SI]
C1:     CMP     BYTE PTR [SI],0 ;Is 100's unit clear ?
        JZ      C3              ; If so,don't print
        PUSH    AX
        MOV     DL,[SI]
        ADD     DL,30H
        CALL    CONOUT
        POP     AX
C3:     ADD     AL,30H
        ADD     AH,30H
        PUSH    AX
        MOV     DL,AH
        CALL    CONOUT
        POP     AX
        MOV     DL,AL
        PUSH    AX
        CALL    CONOUT
        POP     AX
        MOV     DL,13
        CALL    CONOUT
        POP     SI
        POP     AX
        POP     DX
        RET
CONOUT:
        MOV     AH,2
        INT     21H
        RET


;------------------------------------------------------------
        IF      HARD
;Initialize Winchester disk using Morrow HDC-DMA controller


        IF      SCRIBE
NHEADS          EQU     4               ; Number of heads
NSECT           EQU     8               ; Number of sectors per track
NTRACKS         EQU     480             ; Number of cylinders
LCTRK           EQU     0               ; First  track of low write current
PRECOMP         EQU     0               ; First  track to set precomp bit
        ENDIF

        IF      IMI
NHEADS          EQU     6       ; Number of heads
NSECT           EQU     8       ; Number of sectors per track
NTRACKS         EQU     306     ; Number of cylinders
LCTRK           EQU     0       ; First track of low write current
PRECOMP         EQU     256     ; First track to set precomp bit
        ENDIF

;Controller parameters
RESET   EQU     54H
STRTHDC EQU     55H
STATBYT EQU     12
NEXTAD  EQU     13

HDFORMAT:
        MOV     DL,10
        CALL    CONOUT
        MOV     DL,13
        CALL    CONOUT
        MOV     DX,OFFSET HDISK_MSG
        CALL    MESSAGE
        MOV     AH,1
        INT     21H                     ; Console input
        CMP     AL,'Y'                  ; Accept a yes only
        JZ      HFMT2
        JMP     HDFORMAT
HFMT2:
        MOV     DL,10
        CALL    CONOUT
        MOV     DL,13
        CALL    CONOUT
        TEST    [SWITCHMAP],C_BIT
        JZ      BEGIN
        JMP     BOOTRET
BEGIN:
        MOV     DX,OFFSET FRMT_MSG
        CALL    MESSAGE
        MOV     WORD PTR [TKCNT],0
        MOV     BYTE PTR [TKCNT+2],0
        OUT     RESET,AL                ;Reset the HDC
        XOR     AX,AX
        MOV     ES,AX
        MOV     DI,50H                  ;First pointer is at 0:50H
        MOV     DX,OFFSET CODE:LOADCONS
        CALL    SETADDR                 ;Set initial pointer to LOADCONS
        PUSH    DS
        POP     ES
        MOV     DX,OFFSET CODE:HRESTORE
        MOV     DI,OFFSET CODE:LOADCONS+NEXTAD
        CALL    SETADDR                 ;Set chain pointer to RESTORE
        MOV     SI,OFFSET CODE:LOADCONS+STATBYT
        CALL    DOCOM                   ;Execute LOADCONS
        MOV     DX,OFFSET CODE:FORMAT
        MOV     DI,OFFSET CODE:HRESTORE+NEXTAD
        CALL    SETADDR                 ;Set chain pointer to FORMAT
        MOV     DI,OFFSET CODE:FORMAT+NEXTAD
        CALL    SETADDR                 ;Set FORMAT to loop to itself
        MOV     SI,OFFSET CODE:HRESTORE+STATBYT
        CALL    DOCOM                   ;Execute RESTORE
        MOV     DX,OFFSET CODE:FORMATDATA
        MOV     DI,OFFSET CODE:FORMATDMA
        CALL    SETADDR
NEWCYL:
        MOV     BL,0                    ;Initial head number
FORMATLOOP:
        MOV     CX,NSECT
        MOV     SI,OFFSET CODE:FORMATDATA+2;Point to head field
SETHEAD:
        MOV     [SI],BL
        ADD     SI,4
        LOOP    SETHEAD
        MOV     AL,BL
        SHL     AL,1
        SHL     AL,1
        NOT     AL
        AND     AL,1CH
        CMP     BYTE PTR [FORMATDATA],PRECOMP    ; Precomp track?
        JB      STHD1
        OR      AL,80H                  ;Turn it on
STHD1:  CMP     BYTE PTR [FORMATDATA],LCTRK      ;Are we at low current track?
        JAE     LOWCUR
        OR      AL,40H                  ;If not, turn off low write current
LOWCUR:
        MOV     BYTE PTR [HEADSEL],AL
        MOV     SI,OFFSET CODE:FORMAT+STATBYT
        CALL    DOCOM                   ;Format the track
        MOV     BYTE PTR [FORMAT+1],0   ;Zero step count (if any)
        INC     BL
        CMP     BL,NHEADS               ;Completed the cylinder?
        JNZ     FORMATLOOP
        MOV     BYTE PTR [FORMAT+1],1   ;Step in to next track
        MOV     SI,OFFSET CODE:FORMATDATA
        MOV     AX,[SI]                 ;Get current track number
        INC     AX
        MOV     CX,NSECT
SETTRK:
        MOV     [SI],AX
        ADD     SI,4
        LOOP    SETTRK
        PUSH    AX
        PUSH    DX
        PUSH    BX
        MOV     BX,OFFSET TRK_MSG
        CALL    INCTRK
        POP     BX
        POP     DX
        POP     AX
        CMP     AX,NTRACKS              ;All done?
        JNZ     NEWCYL
        MOV     DL,10
        MOV     AH,2
        INT     21H                     ; Output a linefeed
        JMP     BOOTRET

DOCOM:
        MOV     BYTE PTR [SI],0         ;Zero status byte
        OUT     STRTHDC,AL              ;Start up HDC
HWAIT:
        TEST    BYTE PTR [SI],-1        ;Loop until completion
        JZ      HWAIT
        RET

SETADDR:
        MOV     AX,DS                   ;Get current segment
        XOR     CX,CX
        SHL     AX,1                    ;Convert to 20-bit number
        RCL     CX,1
        SHL     AX,1
        RCL     CX,1
        SHL     AX,1
        RCL     CX,1
        SHL     AX,1
        RCL     CX,1
        ADD     AX,DX                   ;Add in offset
        STOSW
        XCHG    AX,CX
        ADC     AL,0                    ;Ripple the carry
        STOSB
        RET

LOADCONS:
        DB      0
        DW      0
        DB      0DCH
        DB      0,0,0
        DB      0,1EH,0,7               ;Set up slow stepping
        DB      4                       ;Load constants
        DB      0                       ;status
        DB      0,0,0                   ;Next address
HRESTORE:
        DB      10H                     ;Step out
        DW      0FFFH                   ;Maximum number of cylinders
        DB      0DCH
        DB      0,0,0
        DB      0,0,0,0
        DB      6                       ;No-op
        DB      0                       ;status
        DB      0,0,0                   ;Next address
FORMAT:
        DB      0                       ;Step in
        DW      0

HEADSEL:
        DB      0DCH
FORMATDMA:
        DB      0,0,0                   ;DMA address (filled in later)
        DB      24                      ;Gap 3
        DB      -NSECT-1                ;Complement of number of sectors
        DB      0F8H                    ;Sector Size code (1024 bytes)
        DB      0                       ;Fill byte
        DB      3                       ;Format opcode
        DB      0                       ;Status
        DB      0,0,0                   ;Next address

FORMATDATA:
;CYL, cyl-H, head, sector for nine sectors
        DB      0,0,0,1
        DB      0,0,0,2
        DB      0,0,0,3
        DB      0,0,0,4
        DB      0,0,0,5
        DB      0,0,0,6
        DB      0,0,0,7
        DB      0,0,0,8
        DB      0,0,0,9

        ENDIF
;----------------------------------------------------------

BADSECTOR:

        MOV     AL,DRIVE
        MOV     CL,[SCTN]
        MOV     CH,0
        MOV     DX,[STRT]
        CMP     [SCCNT],0
        JZ      BDRET
        MOV     BX,OFFSET PATTERN       ; Set up read buffer
        PUSH    CX
        PUSH    DX
        INT     25H             ; Read sectors
        POP     BP
        POP     DX
        POP     CX
        JC      BDRPT           ; Report bad sector
        MOV     AL,SCTN
        CBW
        ADD     [STRT],AX       ; Increment sector start
        SUB     [SCCNT],AX
        MOV     CX,[SCCNT]
        MOV     AL,SCTN
        CBW
        CMP     AX,CX           ; Test for last few sectors
        JB      BADSECTOR
        MOV     SCTN,CL         ; Reset sector count to final sectors
        JMP     BADSECTOR
BDRPT:
        MOV     BX,[STRT]
        MOV     AL,[SCTN]
        CBW
        SUB     AX,CX           ; Find out how sectors were read
        ADD     BX,AX           ; Set up first bad sector
        INC     AX
        ADD     [STRT],AX
        SUB     [SCCNT],AX
        MOV     AX,1
        CLC
        RET

BDRET:
        CALL    HEADUNLOAD
        MOV     AX,0
        CLC
        RET

;------------------------------------------------------------------

WRTFAT:
        MOV     AL,[FATCNT]
        MOV     [CURCNT],AL     ;SET UP FAT COUNT
        MOV     AX,[FATSTART]
        MOV     [CNT],AX
FATLOOP:
        MOV     AL,DRIVE
        CBW
        MOV     CX,[FATSIZE]
        MOV     DX,[CNT]
        MOV     BX,[FATSPACE]
        INT     26H
        POP     AX
        JC      GORET
        MOV     CX,[FATSIZE]
        ADD     [CNT],CX
        DEC     BYTE PTR [CURCNT]
        JNZ     FATLOOP
        CLC
;Good return
GORET:
        CALL    HEADUNLOAD
        RET

DONE:
        CALL    HEADUNLOAD
        CLC                     ; No errors.
        RET

DATATABLE:
        DB      16              ; Number of sectors/track 5.25-inch SD/SS.
        DB      40              ; Number of tracks/disk 5.25-inch SD/SS format.
        DW      11              ; Beginning of pattern to first ID mark.
        DW      186             ; Number of bytes/sector in pattern.
        DW      OFFSET SSINDEX  ; Address of index pattern 5.25-inch SD/SS.
        DW      OFFSET SSSECTOR ; Address of sector pattern 5.25-inch SD/SS.
        DB      0FEH            ; FATID byte for 5.25-inch SD/SS format.
        DW      1+4+4+17        ; STARTSECTOR for 5.25-inch SD/SS format.
        DW      256             ; Number of sectors boot sector should load.
        DW      128             ; Bytes/sector.

        DB      8               ; 5.25-inch DD/SS format.
        DB      40
        DW      162
        DW      652
        DW      OFFSET SDINDEX
        DW      OFFSET SDSECTOR
        DB      0FEH
        DW      1+1+1+4
        DW      64
        DW      512

        DB      8               ; 5.25-inch DD/DS format.
        DB      40
        DW      162
        DW      652
        DW      OFFSET SDINDEX
        DW      OFFSET SDSECTOR
        DB      0FFH
        DW      1+1+1+7
        DW      64
        DW      512

        DB      26              ; 8-inch SD/SS format.
        DB      77
        DW      80
        DW      186
        DW      OFFSET LSINDEX
        DW      OFFSET LSSECTOR
        DB      0FEH
        DW      1+6+6+17
        DW      256
        DW      128

        DB      8               ; 8-inch DD/SS format.
        DB      77
        DW      162
        DW      1138
        DW      OFFSET LDINDEX
        DW      OFFSET LDSECTOR
        DB      0FFH
        DW      1+1+1+3
        DW      32
        DW      1024

        DB      8               ; 8-inch DD/DS format.
        DB      77
        DW      162
        DW      1138
        DW      OFFSET LDINDEX
        DW      OFFSET LDSECTOR
        DB      0FEH
        DW      1+2+2+6
        DW      32
        DW      1024

        IF      HARD
        DB      NSECT           ; Hard disk format
        DW      NTRACKS
        DB      ?
        DW      ?
        DW      ?
        DW      ?
        DB      0FFH
        DW      ?
        DW      ?
        DW      1024
        ENDIF

LDINDEX:                        ; Pattern for 8-inch double-density.
        DB      80,4EH
        DB      12,0
        DB      3,0F6H
        DB      1,0FCH
        DB      50,4EH
LDSECTOR:
        DB      12,0
        DB      3,0F5H
        DB      1,0FEH
        DB      3,0             ; Track, side, and sector
        DB      1,3             ; Sector size=1024
        DB      1,0F7H
        DB      22,4EH
        DB      12,0
        DB      3,0F5H
        DB      1,0FBH
        DB      255,0E5H
        DB      255,0E5H
        DB      255,0E5H
        DB      255,0E5H
        DB      4,0E5H
        DB      1,0F7H
        DB      54,4EH
        DB      0

        DB      255,4EH
        DB      255,4EH
        DB      255,4EH
        DB      0

LSINDEX:                        ; Pattern for 8-inch single-density.
        DB      40,-1
        DB      6,0
        DB      1,0FCH
        DB      26,-1
LSSECTOR:
        DB      6,0
        DB      1,0FEH
        DB      4,0
        DB      1,0F7H
        DB      11,-1
        DB      6,0
        DB      1,0FBH
        DB      128,0E5H
        DB      1,0F7H
        DB      27,-1
        DB      0

        DB      255,-1
        DB      255,-1
        DB      0

SDINDEX:                        ; Pattern for 5.25-inch double-density.
        DB      80,4EH
        DB      12,0
        DB      3,0F6H
        DB      1,0FCH
        DB      50,4EH
SDSECTOR:
        DB      12,0
        DB      3,0F5H
        DB      1,0FEH
        DB      3,0             ; Track, side, and sector.
        DB      1,2             ; Sector size = 512.
        DB      1,0F7H
        DB      22,4EH
        DB      12,0
        DB      3,0F5H
        DB      1,0FBH
        DB      255,0E5H
        DB      255,0E5H
        DB      2,0E5H
        DB      1,0F7H
        DB      80,4EH
        DB      0

        DB      255,4EH
        DB      255,4EH
        DB      255,4EH
        DB      255,4EH
        DB      255,4EH
        DB      255,4EH
        DB      0

SSINDEX:                        ; Pattern for 5.25-inch single-density.
        DB      4,-1            ; No index mark.
SSSECTOR:
        DB      6,0
        DB      1,0FEH
        DB      4,0
        DB      1,0F7H
        DB      11,-1
        DB      6,0
        DB      1,0FBH
        DB      128,0E5H
        DB      1,0F7H
        DB      27,-1
        DB      0

        DB      255,0
        DB      255,0
        DB      255,0
        DB      255,0
        DB      0

        .SALL
BYTELST MACRO   INITVAL,COUNT,INC
        LOCAL   X
X       =       INITVAL
        REPT    COUNT
        DB      X
X       =       X+INC
        ENDM
        ENDM

DRVTAB  LABEL BYTE
        IF      SCP
        BYTELST 0,LDRVMAX,1
        BYTELST 10H,SDRVMAX,1
        ENDIF

        IF      TARBELL
        BYTELST 0,LDRVMAX,10H
        ENDIF


; Error messages.
;
READ_ERROR      DB      "Read Error - can't determine density",13,10,'$'
SEEK_ERROR      DB      'Seek Error - disk not ready',13,10,'$'
WRITE_ERROR     DB      'Write Error - not ready, write protect, '
                DB      'write fault, or lost data',13,10,'$'
BOOT_ERROR      DB      'Error writing boot sector',13,10,'$'
FRMT_MSG        DB      'Formatting',13,10,'$'
TRK_MSG         DB      'Cylinder : $'
BDSCT_MSG       DB      'Testing for bad sectors',13,10,'$'
HDISK_MSG       DB      'Are you sure you want to format this hard disk ? $'

FATSIZE         DW      ?
FATSTART        DW      ?
CNT             DW      ?
STARTSECTOR     DW      ?
SPC             DB      ?               ;SECTORS PER CLUSTER
FATCNT          DB      ?               ;NUMBER OF FATS ON THIS DRIVE
CURCNT          DB      ?
DSKSIZE         DW      ?               ;NUMBER OF SECTORS ON THE DRIVE
STRT            DW      0               ;CURRENT TEST SECTOR
SCCNT           DW      0               ; # of sectors on disk
SCTN            DB      0               ; # of sectors to read
SECSZ           DW      0               ; Sector size
SIDE            DB      0
TKCNT           DW      0
                DB      0

SWITCHLIST      DB      7,'12CDOVS'
FATID           DB      0
FIRSTFLAG       DB      1
HARDFLAG        DB      0
FATSPACE        DW      BUFFER
FREESPACE       DW      FREE

;
; Boot sectors, one for single-sided boot, a second for double-sided boot.
; Both have various variables such as STARTSECTOR and number of sectors to
; load poked in before the boot sector is written to the disk.  The boot
; sectors should be ORGed at 200 hex, but since all jumps and calls are
; reletive, it doesn't matter that it is ORGed at a random location.
;
BOOT1SIDED:
        CLI                     ; Interrupts off.
        XOR     AX,AX
        MOV     DS,AX
        MOV     ES,AX
        MOV     SS,AX
        MOV     SP,BOOTER       ; For debugging purposes.
        CLD                     ; a.k.a. "UP"
        MOV     DI,BIOSSEG*16
B1POKE_SECTOR:
        MOV     CX,0            ; CX = number of sectors/track.
B1POKE_FIRSECT:
        MOV     BL,0            ; BL = first sector to load.
B1SECT:
        MOV     AL,0D0H         ; Force Interrupt command.
        OUT     DISK,AL         ; To force Type I status
        AAM                     ; Give force interrupt time.
        AAM
        AAM
        AAM
B1SEEKLP:
B1POKE_MAXSECT_1:
        CMP     BL,0            ; Compare with number of sectors/track.
        JBE     B1NOSTEP
        MOV     AL,58H          ; Step in with update.
        CALL    B1DCOM
B1POKE_MAXSECT_2:
        SUB     BL,0            ; Subtract number of sectors/track.
        JMP     SHORT B1SEEKLP
B1NOSTEP:
        MOV     AL,BL           ; Get sector number.
        OUT     DISK+2,AL       ; Output sector number to disk controller.
        MOV     DX,DISK+3       ; Disk controller data port.
        PUSH    DI
        MOV     AL,88H          ; Read Sector command.
        OUT     DISK,AL
        JMP     SHORT B1READ
B1READLOOP:
        STOSB                   ; Put in memory.
B1READ:

        IF      TARBELL
        IN      AL,DISK+4
        ROL     AL,1
        IN      AL,DX           ; Read data from disk controller chip.
        JC      B1READLOOP
        ENDIF

        IF      SCP
        IN      AL,DISK+5       ; Input from auto-wait port.
        ROR     AL,1
        IN      AL,DX           ; Read data from disk controller chip.
        JNC     B1READLOOP
        ENDIF

        POP     DI
        CALL    B1STAT
        AND     AL,9CH
        JNZ     B1SECT
B1POKE_SECSIZE:
        ADD     DI,128          ; Add sector size to load next sector.
        INC     BL
        LOOP    B1SECT
        JMP     BIOS

B1DCOM:
        OUT     DISK,AL
        AAM
B1STAT:
        IN      AL,DISK+4
        TEST    AL,DONEBIT

        IF      TARBELL
        JNZ     B1STAT
        ENDIF

        IF      SCP
        JZ      B1STAT
        ENDIF

        IN      AL,DISK
        RET

BOOT2SIDED:
        CLI                     ; Interrupts off.
        XOR     AX,AX
        MOV     DS,AX
        MOV     ES,AX
        MOV     SS,AX
        MOV     SP,BOOTER       ; For debugging purposes.
        CLD                     ; a.k.a. "UP"
        MOV     DI,BIOSSEG*16
B2POKE_SECTOR:
        MOV     CX,0            ; CX = number of sectors/track.
B2POKE_FIRSECT:
        MOV     BL,0            ; BL = first sector to load.
B2SECT:
        MOV     AL,0D0H         ; Force Interrupt command.
        OUT     DISK,AL         ; To force Type I status
        AAM                     ; Give force interrupt time.
        AAM
        AAM
        AAM
B2SEEKLP:
B2POKE_MAXSECT_1:
        CMP     BL,0            ; Compare with number of sectors/track.
        JBE     B2NOSTEP
        MOV     AL,58H          ; Step in with update.
        CALL    B2DCOM
B2POKE_MAXSECT_2:
        SUB     BL,0            ; Subtract number of sectors/track.
        JMP     SHORT B2SEEKLP
B2NOSTEP:
        MOV     AL,BL           ; Get sector number.
        MOV     AH,0            ; Assume side 0.
B2POKE_HALFSECT_1:
        CMP     AL,0            ; Find out which sector and side to use.
        JBE     B2SIDE
B2POKE_HALFSECT_2:
        SUB     AL,0            ; Compute sector number for back side.
        MOV     AH,BACKBIT      ; Side 1 bit.
B2SIDE:
        OUT     DISK+2,AL       ; Output sector number to disk controller.

        MOV     AL,AH           ; Get side-select byte.
B2POKE_DRIVESELECT:
        OR      AL,0            ; Add the rest of the drive-select bits.
        OUT     DISK+4,AL       ; And send the mess out.
        MOV     DX,DISK+3       ; Disk controller data port.
        PUSH    DI
        MOV     AL,88H          ; Read Sector command.
        OUT     DISK,AL
        JMP     SHORT B2READ
B2READLOOP:
        STOSB                   ; Put in memory.
B2READ:

        IF      TARBELL
        IN      AL,DISK+4       ; Input from auto-wait port.
        ROL     AL,1
        IN      AL,DX           ; Read data from disk controller chip.
        JC      B2READLOOP
        ENDIF

        IF      SCP
        IN      AL,DISK+5       ; Input from auto-wait port.
        ROR     AL,1
        IN      AL,DX           ; Read data from disk controller chip.
        JNC     B2READLOOP
        ENDIF

        POP     DI
        CALL    B2STAT
        AND     AL,9CH
        JNZ     B2SECT
B2POKE_SECSIZE:
        ADD     DI,128          ; Add sector size to load next sector.
        INC     BL
        LOOP    B2SECT
        JMP     BIOS

B2DCOM:
        OUT     DISK,AL
        AAM
B2STAT:
        IN      AL,DISK+4
        TEST    AL,DONEBIT

        IF      TARBELL
        JNZ     B2STAT
        ENDIF

        IF      SCP
        JZ      B2STAT
        ENDIF

        IN      AL,DISK
        RET


PATTERN LABEL   BYTE
BUFFER  EQU     PATTERN+12*1024
FREE    EQU     BUFFER+6*1024

CODE    ENDS
        END
