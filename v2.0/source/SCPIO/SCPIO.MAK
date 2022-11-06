#####################################################################
# Makefile for the SCP Gazelle MS-DOS 2.x BIOS.                     #
#                                                                   #
# Copyright (c) 2022 Howard M. Harte.                               #
# https://github.com/hharte                                         #
#                                                                   #
# Module Description:                                               #
#     Makefile to build IO.SYS, FORMAT.COM, and HDISK.DEV for the   #
# Seattle Computer Products 8086-based hardware.  This BIOS works   #
# with MS-DOS 2.00 and 2.11.                                        #
#                                                                   #
# Toolchain:                                                        #
#     Microsoft (R) Macro Assembler  Version 4.00                   #
#     Microsoft (R) 8086 Object Linker  Version 3.05                #
#     Microsoft (R) Program Maintenance Utility  Version 4.00       #
#                                                                   #
#####################################################################


# Inference rules:
.ASM.OBJ:
    MASM /I.. $*.ASM,$@,$*.LST;

.OBJ.EXE:
    LINK $**,$*.EXE,$*.MAP/M;

.EXE.COM:
    EXE2BIN $*.EXE $*.COM
    DEL $*.EXE

# Build IO.SYS
IO.OBJ: $*.ASM

FDISK.OBJ: FDISK.ASM

CONIO.OBJ: CONIO.ASM

AUXIO.OBJ: AUXIO.ASM

PRNIO.OBJ: PRNIO.ASM

TIME.OBJ: TIME.ASM

SYSINIT.OBJ: ..\SYSINIT.ASM
    MASM /I.. ..\$*.ASM,$@,$*.LST;

SYSIMES.OBJ: ..\SYSIMES.ASM
    MASM /I.. ..\$*.ASM,$@,$*.LST;

IO.EXE: IO.OBJ FDISK.OBJ CONIO.OBJ PRNIO.OBJ AUXIO.OBJ TIME.OBJ SYSINIT.OBJ SYSIMES.OBJ

IO.SYS: $*.EXE
    EXE2BIN $*.EXE $*.SYS <IOSEG
    DEBUG IO.SYS <IO8K
    DEL $*.EXE

# Build FORMAT.COM
FORMAT.COM:
    MAKE FORMAT.MAK

# Build DJ/DMA Hard Disk Driver
HDISK.OBJ: HDISK.ASM

HDISK.EXE: HDISK.OBJ

HDISK.DEV: HDISK.EXE
    EXE2BIN $*.EXE $*.DEV
    DEL $*.EXE

# Build INSTALL.COM
INSTALL.OBJ: $*.ASM

INSTALL.EXE: $*.OBJ

INSTALL.COM: $*.EXE
