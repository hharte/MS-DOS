ECHO OFF
REM Create a bootable MS-DOS 2.11 Floppy for the Seattle Computer Products Gazelle
REM
REM Usage: MKBOOT d: [/D]
REM
REM Where: d: is the floppy drive.
REM        /D optionally creates a double-sided disk.
REM
REM System files are hidden only when drive B is used as the destination.
REM Hiding the system files is accomplished with the DEBUG utility, by directly
REM manipulating the directory on the disk.

BREAK ON
IF "%1"=="" GOTO USAGE

FORMAT %1 %2<FMT
COPY IO.SYS %1
INSTALL IO.SYS %1
COPY ..\MSDOS.SYS %1
COPY ..\COMMAND.COM %1
COPY HDISK.DEV %1
COPY CONFIG.SYS %1
COPY AUTOEXEC.BAT %1
COPY FORMAT.COM %1
COPY INSTALL.COM %1
COPY ..\*.COM %1
COPY ..\*.EXE %1
COPY ..\SCP\*.COM %1
COPY ..\SCP\MON.ASM %1
COPY ..\SCP\MON.HEX %1
COPY ..\SCP\MON.BIN %1
REM ONLY HIDE SYSTEM FILES IF DRIVE B IS USED.
if "%1"=="B:" GOTO HIDESYS
if "%1"=="b:" GOTO HIDESYS
GOTO DONE

:HIDESYS
REM Single-sided, single-density floppy.
if "%2"=="" DEBUG <HIDESYS
REM Double-sided, double-density floppy.
if "%2"=="/D" DEBUG <HIDESYSD
if "%2"=="/d" DEBUG <HIDESYSD

:DONE
ECHO Boot disk created in drive %1
GOTO END

:USAGE
ECHO Usage: MKBOOT B:
ECHO Destination drive must be specified.

:END
