#####################################################################
# Makefile for the SCP INSTALL Utility.                             #
#                                                                   #
# Copyright (c) 2022 Howard M. Harte.                               #
# https://github.com/hharte                                         #
#                                                                   #
# Module Description:                                               #
#     Makefile to build INSTALL.COM.  INSTALL.COM is used to copy   #
# IO.SYS to the the first file in the disk to make it bootable.     #
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

# Build INSTALL.COM
INSTALL.OBJ: $*.ASM

INSTALL.EXE: $*.OBJ

INSTALL.COM: $*.EXE
