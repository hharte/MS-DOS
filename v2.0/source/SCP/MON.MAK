#####################################################################
# Makefile for the SCP Monitor v1.5.                                #
#                                                                   #
# Copyright (c) 2022 Howard M. Harte.                               #
# https://github.com/hharte                                         #
#                                                                   #
# Module Description:                                               #
#     Makefile to build the Seattle Computer Products 8086 Monitor  #
# v1.5.                                                             #
#                                                                   #
# Toolchain:                                                        #
#     Seattle Computer Products 8086 Assembler Version 2.44         #
#                                                                   #
#####################################################################

# Inference rules:
.ASM.HEX:
    ASM $*

# Build Monitor
MON.HEX: $*.ASM

MON.BIN: $*.HEX
    HEX2BIN $*
    COPY $*.COM $*.BIN
    DEL $*.COM

