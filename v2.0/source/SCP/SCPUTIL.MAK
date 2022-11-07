#####################################################################
# Makefile for the SCP Utilities.                                   #
#                                                                   #
# Copyright (c) 2022 Howard M. Harte.                               #
# https://github.com/hharte                                         #
#                                                                   #
# Module Description:                                               #
#     Makefile to build HEX2BIN.COM, ASM.COM, and TRANS.COM.        #
# The SCP assembler outputs .HEX files.  This makefile bootstraps   #
# HEX2BIN.COM using MS-DOS DEBUG.COM to load the HEX file and save  #
# it as a .COM file.  Subsequent utilities are converted from HEX   #
# to BIN using HEX2BIN.                                             #
#                                                                   #
# Toolchain:                                                        #
#     Seattle Computer Products 8086 Assembler Version 2.44         #
#     MS-DOS v2.11 DEBUG.COM                                        #
#                                                                   #
#####################################################################

# Inference rules:
.ASM.HEX:
    ASM $*

.HEX.COM:
    HEX2BIN $*

# Build HEX2BIN.COM
HEX2BIN.HEX: $*.ASM
    ASM $*

HEX2BIN.COM: $*.HEX
    DEBUG $*.HEX <GENCOM
    COPY OUT.COM $*.COM
    DEL OUT.COM
    HEX2BIN $*

# Build ASM.COM
ASM.HEX: $*.ASM

ASM.COM: $*.HEX

# Build TRANS.COM
TRANS.HEX: $*.ASM

TRANS.COM: $*.HEX
