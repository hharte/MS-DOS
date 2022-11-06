#####################################################################
# Makefile for MS-DOS v2.11 MSDOS.SYS.                              #
#                                                                   #
# Copyright (c) 2022 Howard M. Harte.                               #
# https://github.com/hharte                                         #
#                                                                   #
# Module Description:                                               #
#     Makefile to build MSDOS.SYS.                                  #
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

.EXE.SYS:
    EXE2BIN $*.EXE $*.SYS
    DEL $*.EXE

ALLOC.OBJ: ALLOC.ASM

DIRCALL.OBJ: DIRCALL.ASM

DEV.OBJ: DEV.ASM

DIR.OBJ: DIR.ASM

DISK.OBJ: DISK.ASM

DOSMES.OBJ: DOSMES.ASM

FAT.OBJ: FAT.ASM

GETSET.OBJ: GETSET.ASM

MISC.OBJ: MISC.ASM

MSCODE.OBJ: MSCODE.ASM

MSDOS.OBJ: MSDOS.ASM

ROM.OBJ: ROM.ASM

STDBUF.OBJ: STDBUF.ASM

STDCALL.OBJ: STDCALL.ASM

STDCTRLC.OBJ: STDCTRLC.ASM

STDFCB.OBJ: STDFCB.ASM

STDIO.OBJ: STDIO.ASM

STDPROC.OBJ: STDPROC.ASM

TIME.OBJ: TIME.ASM

XENIX.OBJ: XENIX.ASM

XENIX2.OBJ: XENIX2.ASM

MSDOS.EXE: MSDOS.OBJ MSCODE.OBJ DOSMES.OBJ MISC.OBJ GETSET.OBJ DIRCALL.OBJ \
    ALLOC.OBJ DEV.OBJ DIR.OBJ DISK.OBJ FAT.OBJ ROM.OBJ STDBUF.OBJ STDCALL.OBJ \
    STDCTRLC.OBJ STDFCB.OBJ STDPROC.OBJ STDIO.OBJ TIME.OBJ XENIX.OBJ XENIX2.OBJ
    LINK @MSDOS.LRF,MSDOS.EXE,MSDOS.MAP/M;

MSDOS.SYS: MSDOS.EXE
