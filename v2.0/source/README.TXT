This is MS-DOS 2.11 updated to assemble and run properly on the SIMH/AltairZ80
simulator emulating an SCP Gazelle.

Known Issues:
=============
1. FORMAT /S hangs the simulator.  As a workaround, you can format the disk
   without /S and then use SYS.COM to put the system onto the disk.

2. DEBUG trace ("T") command hangs.

3. It is not possible to boot from the hard disk.  This was a limitation of
   the original SCP distribution as well.  At least one of the issues is that
   there is not enough room in the 2K EPROM on the SCP300F board to fit the
   hard disk boot loader.

4. The disks are not in regular IBM PC-compatible format.  The floppy disks
   are either:
   a. SSSD 8" (77 tracks, 26 sectors per track, one side, 128-byte
      sectors)
   b. DSDD 8" (77 tracks, 8 sectors per track, two sides, 1024-byte
      sectors)

   The hard disk is an IMI 15 MB winchester drive with 480 tracks, 4 heads,
   8 sectors per track, and 1024-byte sectors.

   "Modern" utilities such as WinImage are not able to mount these disks.

5. Any other issues?  Please file a bug!

Building from source:
=====================

To assemble everything from source you will need the following tools:
    * Microsoft (R) Macro Assembler  Version 4.00
    * Microsoft (R) 8086 Object Linker  Version 3.05
    * Microsoft (R) Program Maintenance Utility  Version 4.00

The OEM-specific IO.SYS source code for the Gazelle is in SCPIO/
Seattle Computer Products ROM monitor and utility source code included in MS-
DOS 1.25 is included in SCP/

An MS-DOS 2.11 "distribution" disk can be built from source as follows,
assuming everything from the "source" directory is copied to a hard disk
in the C:\DOS211 directory:

C:\DOS211\ 		- MS-DOS Source Code
C:\DOS211\SCPIO\ 	- OEM-specific IO.SYS and FORMAT.COM
C:\DOS211\SCP\		- SCP utilities (ASM, HEX2BIN, TRANS, MON)

With everyting in the proper location, and the tools in the PATH:

CD \DOS211
MKSCPDOS

To assemble everything and create a bootable floppy from a blank unformatted
floppy disk in drive B:

CD \DOS211
MKSCPDOS B:

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
