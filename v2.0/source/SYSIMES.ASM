SYSINITSEG      SEGMENT PUBLIC BYTE 'SYSTEM_INIT'

        PUBLIC  BADOPM,CRLFM,BADSIZ_PRE,BADLD_PRE,BADCOM,SYSSIZE
        PUBLIC  BADSIZ_POST,BADLD_POST,BADCOUNTRY

BADOPM      DB      13,10,"Unrecognized command in CONFIG.SYS"
CRLFM       DB      13,10,'$'
BADSIZ_PRE  DB      13,10,"Sector size too large in file $"
BADSIZ_POST EQU     $
BADLD_PRE   DB      13,10,"Bad or missing $"
BADLD_POST  EQU     $
BADCOM      DB      "Command Interpreter",0
BADCOUNTRY  DB      13,10,"Invalid country code",13,10,"$"

SYSSIZE LABEL   BYTE

SYSINITSEG      ENDS
        END
