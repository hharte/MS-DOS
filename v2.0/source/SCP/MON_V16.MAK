#####################################################################
# Makefile for the SCP Monitor v1.6.                                #
#                                                                   #
# Copyright (c) 2022 Howard M. Harte.                               #
# https://github.com/hharte                                         #
#                                                                   #
# Module Description:                                               #
#     Makefile to build the SCP Monitor v1.6.                       #
#                                                                   #
# Toolchain:                                                        #
#     Seattle Computer Products 8086 Assembler Version 2.44         #
#     Seattle Computer Products HEX2BIN utility.                    #
#                                                                   #
#####################################################################

# Inference rules:
.ASM.HEX:
    ASM $*

.HEX.COM:
    HEX2BIN $*

# Build Monitor
MON_V16.HEX: $*.ASM
    R $*.ASM
    ASM $*

MON_V16.COM: $*.HEX
    HEX2BIN $*
    W $*.COM
    W $*.PRN
    DEL $*.COM
    DEL $*.HEX
