#####################################################################
# Makefile for the SCP FORMAT.COM Utility.                          #
#                                                                   #
# Copyright (c) 2022 Howard M. Harte.                               #
# https://github.com/hharte                                         #
#                                                                   #
# Module Description:                                               #
#     Makefile to the SCP FORMAT.COM Utility for the Seattle        #
# Computer Products 8086-based hardware.                            #
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

# Build FORMAT.COM
FORMAT.OBJ: ..\FORMAT.ASM
    MASM /I.. ..\$*.ASM,$@,$*.LST;

FORMES.OBJ: ..\FORMES.ASM
    MASM /I.. ..\$*.ASM,$@,$*.LST;

INIT.OBJ: INIT.ASM

FORMAT.EXE: FORMAT.OBJ FORMES.OBJ INIT.OBJ

FORMAT.COM: FORMAT.EXE
