#####################################################################
# Makefile for MS-DOS v2.11 COMMAND.COM.                            #
#                                                                   #
# Copyright (c) 2022 Howard M. Harte.                               #
# https://github.com/hharte                                         #
#                                                                   #
# Module Description:                                               #
#     Makefile to build COMMAND.COM.                                #
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

.EXE.COM:
    EXE2BIN $*.EXE $*.COM
    DEL $*.EXE

COMMAND.OBJ: $*.ASM

RUCODE.OBJ: $*.ASM

RDATA.OBJ: $*.ASM

INIT.OBJ: $*.ASM

UINIT.OBJ: $*.ASM

TCODE.OBJ: $*.ASM

TCODE2.OBJ: $*.ASM

TCODE3.OBJ: $*.ASM

TCODE4.OBJ: $*.ASM

TCODE5.OBJ: $*.ASM

TUCODE.OBJ: $*.ASM

COPY.OBJ: $*.ASM

COPYPROC.OBJ: $*.ASM

CPARSE.OBJ: $*.ASM

TDATA.OBJ: $*.ASM

TSPC.OBJ: $*.ASM

COMMAND.EXE: COMMAND.OBJ RUCODE.OBJ RDATA.OBJ INIT.OBJ UINIT.OBJ \
    TCODE.OBJ TCODE2.OBJ TCODE3.OBJ TCODE4.OBJ TCODE5.OBJ \
    TUCODE.OBJ COPY.OBJ COPYPROC.OBJ CPARSE.OBJ TDATA.OBJ TSPC.OBJ
    LINK @COMMAND.LRF,COMMAND.EXE,COMMAND.MAP/M;

COMMAND.COM: $*.EXE
