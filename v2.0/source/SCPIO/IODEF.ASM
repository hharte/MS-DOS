; Basic I/O System definition - INCLUDEd in each module
; Assumes a CPU Support card at F0 hex for character I/O

; Select whether console input is interrupt-driven or polled.
INTINP          EQU     1
QSIZE           EQU     100             ; Input queue size.

; Select whether the auxiliary port is the Support Card parallel port
; or the second channel of a Multiport Serial card addressed at 10H.

PARALLELAUX     EQU     0
SERIALAUX       EQU     1

; Select whether the printer is connected to the Support card parallel
; output port (standard) or the first channel of a Multiport Serial card
; addressed at 10H.

PARALLELPRN     EQU     0
SERIALPRN       EQU     1

; If the Multiport Serial was chosen for either the auxiliary or the
; printer, select the baud rate here, using a hex value from this table:
;
;         50    0        150    4       1800    8       4800    C
;         75    1        300    5       2000    9       7200    D
;        110    2        600    6       2400    A       9600    E
;        134.5  3       1200    7       3600    B      19200    F

PRNBAUD EQU     0EH             ; 9600 baud
AUXBAUD EQU     0EH             ; 9600 baud


; Disk options for MS-DOS 2.0 selected here
;************************************************************

; If you have a hard disk select it here. If you want the driver
; to be installable (installed at boot time) then select INSTALL
; also.

IMI     EQU     0
SCRIBE  EQU     1
HARD    EQU     IMI OR SCRIBE

INSTALL EQU     1

;************************************************************

; Select disk controller here.

SCP             EQU     0
TARBELL         EQU     1       ;Select only LARGE below

; Select disk configuration:

LARGE   EQU     1               ; Two large drives.
COMBIN  EQU     0               ; Two 8-inch and one 5-inch.
SMALL   EQU     0               ; Three 5-inch drives.

MAXLARGE        EQU     2       ;Number of 8" when LARGE is selected
MAXSMALL        EQU     3       ;Number of 5" when SMALL is selected
MAXLARGECOMB    EQU     2       ;Number of 8" when COMBIN is selected
MAXSMALLCOMB    EQU     1       ;Number of 5" when COMBIN is selected

LARGDRV EQU     LARGE OR COMBIN
SMALLDRV EQU    SMALL OR COMBIN

LDRVMAX EQU     MAXLARGE*LARGE+MAXLARGECOMB*COMBIN      ; # of 8" drives
SDRVMAX EQU     MAXSMALL*SMALL+MAXSMALLCOMB*COMBIN      ; # of 5" drives
HDRVMAX EQU     HARD            ; # of hard disk drives

;************************************************************

; If your disk drives support DISKCHANGE signal and 2 SIDED signal and
; you have a SCP disk controller, then select these options here.
; MS-DOS will use these signals to automatically select single or
; double sided drives.  These are ignored for PerSci drives.

DISKCHG EQU     0
TWOSIDE EQU     0

;*************************************************************

; Select double-sided operation of 8-inch disks in double-density mode.
; Select this option only if TWOSIDE is not used (or PERSCI is set).

LARGEDS  EQU    1

;************************************************************

; Select whether FORMAT defaults to single- or double-sided for 5" disks.
; (This can always be overridden with the /1 or /2 switches.)

SMALLDS  EQU    1

;***********************************************************
; If 8-inch drives are PerSci, select here:

PERSCI  EQU     0

;************************************************************


; Use table below to select head step speed. Step times for 5" drives
; are double that shown in the table. Times for Fast Seek mode (using
; PerSci drives) is very small - 200-400 microseconds.
;
; Step value    1771    1793
;
;       0         6ms   3ms
;       1         6ms   6ms
;       2        10ms   10ms
;       3        20ms   15ms

STPSPD  EQU     0

;************************************************************

SIDECHK EQU     TWOSIDE AND (PERSCI-1) AND SCP AND LARGDRV
DSKCHG  EQU     DISKCHG AND (PERSCI-1) AND SCP AND LARGDRV

BIOSSEG EQU     40H             ; I/O system segment.
BASE    EQU     0F0H
SIOBASE EQU     10H
STAT    EQU     BASE+7
DATA    EQU     BASE+6
DAV     EQU     2
TBMT    EQU     1
SERIAL  EQU     SERIALPRN+SERIALAUX
STCDATA EQU     BASE+4    ; Ports for 9513 Timer chip.
STCCOM  EQU     BASE+5

        IF      SERIALAUX
AUXSTAT EQU     SIOBASE+3
AUXDATA EQU     SIOBASE+2
        ENDIF

        IF      PARALLELAUX
AUXSTAT EQU     BASE+13
AUXDATA EQU     BASE+12
        ENDIF

        IF      SERIALPRN
PRNSTAT EQU     SIOBASE+1
PRNDATA EQU     SIOBASE+0
        ENDIF

        IF      PARALLELPRN
PRNSTAT EQU     BASE+13
PRNDATA EQU     BASE+12
        ENDIF

;define offsets for IO data packet
IODAT   STRUC
CMDLEN  DB      ?       ;LENGTH OF THIS COMMAND
UNIT    DB      ?       ;SUB UNIT SPECIFIER
CMD     DB      ?       ;COMMAND CODE
STATUS  DW      ?       ;STATUS
        DD      2 DUP (?)
MEDIA   DB      ?       ;MEDIA DESCRIPTOR
TRANS   DD      ?       ;TRANSFER ADDRESS
COUNT   DW      ?       ;COUNT OF BLOCKS OR CHARACTERS
START   DW      ?       ;FIRST BLOCK TO TRANSFER
IODAT   ENDS
