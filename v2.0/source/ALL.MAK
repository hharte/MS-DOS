#####################################################################
# Makefile for MS-DOS v2.11.                                        #
#                                                                   #
# Copyright (c) 2022 Howard M. Harte.                               #
# https://github.com/hharte                                         #
#                                                                   #
# Module Description:                                               #
#     Makefile to build MSDOS.SYS, COMMAND.COM, and utilities.      #
#                                                                   #
# Toolchain:                                                        #
#     Microsoft (R) Macro Assembler  Version 4.00                   #
#     Microsoft (R) 8086 Object Linker  Version 3.05                #
#     Microsoft (R) Program Maintenance Utility  Version 4.00       #
#                                                                   #
#####################################################################

# Inference rules:
.ASM.OBJ:
    MASM $*.ASM,$@,$*.LST;

.OBJ.EXE:
    LINK $**,$*.EXE,$*.MAP/M;

.EXE.COM:
    EXE2BIN $*.EXE $*.COM
    DEL $*.EXE

# Build CHKDSK.COM
CHKDSK.OBJ: $*.ASM

CHKMES.OBJ: $*.ASM

CHKPROC.OBJ: $*.ASM

CHKDSK.EXE: CHKDSK.OBJ CHKPROC.OBJ CHKMES.OBJ

CHKDSK.COM: CHKDSK.EXE

# Build COMMAND.COM
COMMAND.COM:
    MAKE COMMAND.MAK

#Build DEBUG.COM
DEBUG.OBJ: $*.ASM

DEBASM.OBJ: $*.ASM

DEBUASM.OBJ: $*.ASM

DEBCOM1.OBJ: $*.ASM

DEBCOM2.OBJ: $*.ASM

DEBCONST.OBJ: $*.ASM

DEBDATA.OBJ: $*.ASM

DEBMES.OBJ: $*.ASM

DEBUG.EXE: $*.OBJ DEBCOM1.OBJ DEBCOM2.OBJ DEBUASM.OBJ DEBASM.OBJ \
    DEBCONST.OBJ DEBDATA.OBJ DEBMES.OBJ
    LINK @$*.LRF,$*.EXE,$*.MAP/M;

DEBUG.COM: $*.EXE

# Buils DISKCOPY.COM
DISKCOPY.OBJ: $*.ASM

DISKMES.OBJ: $*.ASM

DISKCOPY.EXE: DISKCOPY.OBJ DISKMES.OBJ

DISKCOPY.COM: $*.EXE

# Build EDLIN.COM
EDLIN.OBJ: $*.ASM

EDLMES.OBJ: $*.ASM

EDLPROC.OBJ: $*.ASM

EDLIN.EXE: EDLIN.OBJ EDLMES.OBJ EDLPROC.OBJ

EDLIN.COM: $*.EXE

# Build EXE2BIN.EXE
EXE2BIN.OBJ: $*.ASM

EXEMES.OBJ: $*.ASM

EXE2BIN.EXE: $*.OBJ EXEMES.OBJ

# Build FC
FC.OBJ: $*.ASM

FCMES.OBJ: $*.ASM

FC.EXE: FC.OBJ FCMES.OBJ

# Build FIND.EXE
FIND.OBJ: $*.ASM

FINDMES.OBJ: $*.ASM

FIND.EXE: FIND.OBJ FINDMES.OBJ

# Build GENFOR (Generic Format)
FORMAT.OBJ: FORMAT.ASM

FORMES.OBJ: FORMES.ASM

GENFOR.OBJ: GENFOR.ASM

GENFOR.EXE: FORMAT.OBJ FORMES.OBJ GENFOR.OBJ

GENFOR.COM: $*.EXE

# Build MORE.COM
MORE.OBJ: $*.ASM

MOREMES.OBJ: $*.ASM

MORE.EXE: MORE.OBJ MOREMES.OBJ

MORE.COM: $*.EXE

MSDOS.SYS:
    MAKE MSDOS.MAK

# Build PRINT.COM
PRINT.OBJ: $*.ASM

PRINT.EXE: $*.OBJ

PRINT.COM: $*.EXE

# Build RECOVER.COM
RECOVER.OBJ: $*.ASM

RECMES.OBJ: $*.ASM

RECOVER.EXE: RECOVER.OBJ RECMES.OBJ

RECOVER.COM: $*.EXE

# Build SORT.EXE
SORT.OBJ: $*.ASM

SORTMES.OBJ: $*.ASM

SORT.EXE: SORT.OBJ SORTMES.OBJ
    LINK $**,$*.EXE,$*.MAP/M;
    EXEMOD $*.EXE /MAX 1 /MIN 1

# Build SYS.COM
SYS.OBJ: $*.ASM

SYSMES.OBJ: $*.ASM

SYS.EXE: SYS.OBJ SYSMES.OBJ

SYS.COM: $*.EXE
