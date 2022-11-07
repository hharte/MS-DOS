This is the OEM-specific source code for the Seattle Computer Products Gazelle.

Source code in this directory is used to build MS-DOS IO.SYS and FORMAT.COM.

An MS-DOS 2.11 "distribution" disk can be built from source as follows,
assuming everything from the "source" directory is copied to a hard disk
in the C:\DOS211 directory:

C:\DOS211\ 		- MS-DOS Source Code
C:\DOS211\SCPIO\ 	- OEM-specific IO.SYS and FORMAT.COM
C:\DOS211\SCP\		- SCP utilities (ASM, HEX2BIN, TRANS, MON)

1. Build MS-DOS v2.11
   CD \DOS211
   MAKE ALL.MAK
2. Build SCP Utilities
   CD \DOS211\SCP
   MAKE SCPUTIL.MAK
3. Build IO.SYS
   CD \DOS211\SCPIO
   MAKE SCPIO.MAK
4. Create MS-DOS v2.11 Boot disk from an unformatted floppy disk in drive B:
   MKBOOT.BAT B:

The resulting disk should contain the following:

 Volume in drive A is SCPMSDOS211
 Directory of  A:\

COMMAND  COM    15957  11-06-22   2:11a
HDISK    DEV      541  11-06-22   2:11a
CONFIG   SYS       20  11-06-22   2:12a
AUTOEXEC BAT      166  11-06-22   1:11p
FORMAT   COM     6410  11-06-22   2:11a
INSTALL  COM      892  11-06-22   2:11a
CHKDSK   COM     6468  11-06-22   2:11a
DEBUG    COM    12146  11-06-22   2:11a
DISKCOPY COM     1409  11-06-22   2:11a
EDLIN    COM     8168  11-06-22   2:11a
GENFOR   COM     4344  11-06-22   2:11a
MORE     COM     4364  11-06-22   2:11a
PRINT    COM     7872  11-06-22   2:11a
RECOVER  COM     2295  11-06-22   2:11a
SYS      COM      922  11-06-22   2:11a
EXE2BIN  EXE     2798  11-06-22   2:11a
FC       EXE     2585  11-06-22   2:11a
FIND     EXE     6331  11-06-22   2:11a
SORT     EXE     1632  11-06-22   2:11a
HEX2BIN  COM      470  11-06-22   2:11a
ASM      COM     8208  11-06-22   2:11a
TRANS    COM     3079  11-06-22   2:11a
MON      ASM    43590  11-06-22  12:44p
MON      HEX     5077  11-06-22   2:11a
MON      BIN     2047  11-06-22   2:11a
