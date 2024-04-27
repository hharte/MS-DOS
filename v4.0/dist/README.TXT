README.TXT
October 12, 1988

This document covers topics not included in MS-DOS printed documentation.  
It also lists a small number of corrections.

DEVICE DRIVERS
--------------

Device drivers are programs that let the operating system recognize devices
that are not a part of the computer (for example, a modem, printer, or
mouse).  Some device drivers are already installed with MS-DOS.  Other
device drivers, called installable device drivers, can be installed as you
need them.


ANSI.SYS--Installable Device Driver
-----------------------------------

ANSI.SYS, an installable device driver, lets you use ANSI escape sequences
in real mode.  An ANSI escape sequence is a series of characters developed
by the American National Standards Institute.  You use these escape
sequences to define functions for MS-DOS.  Specifically, you can change
graphics functions and affect the movement of the cursor.

Following is a description of two options you can use with the ANSI.SYS 
device driver.

/L

The function of this option is to retain the number of screen rows for
application programs that return the number of screen rows to the default,
25.  You change the default with the MODE command.

/K

The function of this option is to prevent ANSI.SYS from using extended 
keyboard functions when an enhanced keyboard is installed.

For more information on the ANSI.SYS device driver, and the MODE command, 
please see the Microsoft MS-DOS User's Reference.


HIMEM.SYS--Installable Device Driver for Extended Memory 
---------------------------------------------------------

Capabilities
------------

HIMEM.SYS, an installable device driver, conforms to the XMS (eXtended
Memory Specification) version 2.0.  It allows MS-DOS programs on 80286 and
80386 systems with extended memory to access the extended memory
independent of machine configuration.  It also allows MS-DOS programs to
use an extra 64K region of memory for code and data.  This region is
located just above the 1 MB boundary.  

If you have an EMS (Expanded Memory Specification) board, you can allocate
part of its memory (64K is the recommended optimum amount) to extended
memory by reconfiguring the board and leaving the rest as expanded.  Refer
to your EMS board manual for more information about reconfiguring your
board.

If you are loading other extended memory programs which do not use the XMS
interface to manage the extended memory, they should be configured to 
leave at least 64K of extended memory free.

System Requirements

To use HIMEM.SYS with your computer, you need the following:

o   An IBM PC/AT, PS/2 (except models 25 and 30), or compatible computer

o   Extended memory

Installing HIMEM.SYS

To install HIMEM.SYS, include the following command line in your 
CONFIG.SYS file:

     DEVICE=[d:][path]HIMEM.SYS [/HMAMIN=h] [/NUMHANDLES=n]

When you start your computer, the driver is loaded and the following message 
is displayed:

     HIMEM:  DOS XMS Driver, Version 2.04 - 8/17/88
     Copyright 1988, Microsoft Corp.

If you also want to install other device drivers that use XMS calls, place 
the commands that install them in the CONFIG.SYS file after the 
above command. 


HIMEM.SYS Options

Following is a description of the two options you can use with the HIMEM.SYS 
device driver.

/HMAMIN=h

The function of this option is to specify the minimum amount of memory a 
Terminate and Stay Resident (TSR) program can use in the High Memory Area 
(HMA) allowing controlled access to the HMA.  Specify the amount of memory in 
kilobytes.  Programs requiring less space will not be placed in the HMA.  
To ensure the most effective use of this memory area, set the number to the 
request size of the largest TSR program that will use the HMA.  The minimum 
value is 0, the maximum is 63, and the default is 0.  The 0 default allows 
"first come, first served" access to the HMA.  When you use this option, 
the following message will be displayed:

     Minimum HMA size set to <number>

Please note that you will only use the /HMAMIN option when you run two or 
more TSR programs and/or device drivers that require use of the HMA.

NUMHANDLES=n

The function of this option is to set the maximum number of Extended Memory 
Block (EMB) handles that can be used at any given time.  Specify the amount of 
memory in kilobytes.  The minimum value is 1, the maximum is 128, and the 
default is 32.  Each additional handle requires an additional 6 bytes of 
resident memory.  Because it is possible to exceed the default when running 
several programs, increase the number of allocated EMB handles using the 
/NUMHANDLES option.  When you use this option, the following message 
will be displayed:

     n extended memory handles available.

Examples

The following command line shows the most common configuration of HIMEM.SYS:

     DEVICE=HIMEM.SYS

The following command line shows a configuration of HIMEM.SYS which ensures 
that any program using the High Memory Area must use at least 40K of 
this memory:

     DEVICE=HIMEM.SYS /HMAMIN=40

The following command line shows a configuration of HIMEM.SYS which uses the 
maximum number of Extended Memory Block handles:

     DEVICE=HIMEM.SYS /NUMHANDLES=128

Messages

The following messages may appear when you install the HIMEM.SYS 
device driver.  Most messages indicate a problem that needs correction before 
HIMEM.SYS can be installed properly. 

*     64K High Memory Area is available.

You have installed HIMEM.SYS properly.

*     ERROR: HIMEM.SYS requires DOS 3.00 or higher.
      XMS Driver not installed.

You have tried to install HIMEM.SYS on a machine using a version of MS-DOS 
lower than 3.0.  You can only install HIMEM.SYS on systems using MS-DOS 
Version 3.00 or higher.

*     ERROR: HIMEM.SYS requires an 80x86-based machine.
      XMS Driver not installed.

You have tried to install HIMEM.SYS on a machine other than an 80286 
or 80386.  HIMEM.SYS can only be installed on a computer system which has 
an 80286 or 80386 microprocessor

*    ERROR: An Extended Memory Manager is already installed.
     XMS Driver not installed.

You have tried to install HIMEM.SYS after it has already been installed on 
your system.  HIMEM.SYS can only be installed once. 

*   ERROR: No available extended memory was found.

You have tried to install HIMEM.SYS on a computer without any extended 
memory.  HIMEM.SYS can only be installed on a computer with 
extended memory.

*     ERROR: Unrecognized A20 hardware.

HIMEM.SYS cannot recognize the A20 hardware of your system. If this occurs,
it is probably because the system is not one supported by this release of 
HIMEM.SYS. Contact your computer manufacturer or dealer to see if an XMS 
driver exists for your machine.

*     WARNING: The High Memory Area is unavailable.

HIMEM.SYS cannot find enough memory to use the High Memory Area.  HIMEM.SYS
will not be able to process any requests for the High Memory Area. 
However, HIMEM.SYS will remain installed to process any requests for the
Extended Memory Data Blocks.

*    WARNING: The A20 Line was already enabled.

During the installation process, HIMEM.SYS detected the A20 hardware was 
already enabled.  HIMEM.SYS will remain installed and attempt to work 
properly, however it will not disable the A20 line.


EMM386.SYS--Installable Device Driver
-------------------------------------

EMM386.SYS, an installable device driver, allows MS-DOS programs on 80386
systems to emulate expanded memory in extended memory.  The driver 
supports the Lotus, Intel, and Microsoft (LIM) Expanded Memory 
Specification (EMS) 4.0.


System Requirements

To use EMM386.SYS with your computer, you need the following:

o   A 80386 based computer compatible with the IBM AT standard 
    hardware/software interface, such as Compaq 386 or AST Premium 386.

o   Extended memory

Note: The EMM386.SYS driver detects most boards which utilize memory 
between the addresses A000-E000.  To determine what memory addresses to 
exclude, or where to load its page frame, EMM386.SYS searches between A000
and E000 to find addresses used by these adapters.  It will not load its
page frame at these addresses.  Once it finds a contiguous block of 64K of
memory, it loads the EMM386.SYS page frame segment.


Installing EMM386.SYS

To install EMM386.SYS, include the following command line in your 
CONFIG.SYS file:

DEVICE=[d:][path]emm386.sys [size]  [X:mmmm-nnnn] [Mx]

You should make sure that the EMM386.SYS driver gets loaded before any 
other programs, such as Microsoft RAMDrive, that use expanded memory.

Following is a description of the options in the EMM386.SYS command line:

size

size specifies the amount of extended memory that EMM386.SYS will use.  
Specify the amount in kilobytes.  The recommended amount is 512K and
default is 256K.

X:mmmm-nnnn   (Memory Exclusion Range)

This parameter allows you to specify a range of memory which  will not be 
used for locating the EMM386.SYS page frame or other mappable pages.  Use
this option if an expansion option board (e.g., a network board) is
installed between the addresses A000 and E000. 

Don't use this option unless you detect a conflict between EMM386.SYS and 
an expansion option board.  However, a conflict is not likely to occur, as
EMM386.SYS automatically recognizes the presence of most expansion option
boards and will not try and use the range of memory these boards use for
locating the EMM386.SYS page frame or mappable pages.

Mx    (Page Frame Address Location)

This parameter allows you to directly specify where the EMM386.SYS page
frame should be located in memory.  EMM386.SYS will automatically locate
an address for the EMM386.SYS page frame.  Don't use this option unless
you want to locate the page frame at a different address.  If EMM386.SYS
detects a conflict in the user-specified page frame between itself and an
expansion option board, it will print a warning message to advise you of
the conflict and this effect and subsequent actions are not guaranteed.

To use this option, choose a value from the following list that does not
conflict with any options that you have previously installed.

   x         Specifies Page Frame to Begin at Segment:

   0         C000
   1         C400
   2         C800
   3         CC00
   4         D000
   5         D400
   6         D800
   7         DC00
   8         E000


Examples 

device=emm386.sys 1024

This will load the EMM386.SYS driver and take 1024K of extended memory 
to provide expanded memory.


device=emm386.sys 1024 X:C400-C7FF 

This will produce the same result as in the first example, but it also 
excludes the C400 to C7FF (768K to 832K) from being used by EMM386.SYS to 
locate its page frame or mappable pages.


device=emm386.sys 1024 X:C400-C7FF X:E000-E3FF

This will produce the same result as in the second example, but it excludes 
both C400-C7FF and E000-E3FF (896K to 960K) from being used by EMM386.SYS 
to locate its page frame or mappable pages.


device=emm386.sys 1024 M6

This will load EMM386.SYS and make 1024K of expanded memory available for 
its use.  It also forces EMM386.SYS to locate its page frame at D800.


Messages
     
*     EMM386 Installed.
	      Extended memory allocated:    xxxxx KB
	      System memory allocated:	    xxxxx KB
					 --------
	      Expanded memory available:    xxxxx KB
	      Page frame base address:	    XX000 H

This message appears just after EMM386.SYS is loaded into memory.  The 
message displays the amount of expanded memory available and the address 
where EMM386.SYS has located its page frame.  The amount of expanded memory
available is the sum of the extended memory and system memory EMM386.SYS
has reclaimed.

*     Invalid parameter specified.

During installation, a parameter other than those documented above or an
incorrect parameter has been specified.

*     Size of expanded memory pool adjusted

Less extended memory is available than was requested through the size 
parameter during installation.

*     WARNING - Option ROM or RAM detected within page frame.

This warning occurs when forcing the EMM386.SYS page frame into the 
desired memory location by using the Mx option. You were trying to force
the page frame into an area already used by an expansion option board, and
have created a conflict.  The system will be unstable in this
configuration. You will need to force the page frame in a address location
not used by an option board.

*     EMM386 not installed - insufficient memory.

You will need additional extended memory required to install EMM386.SYS

*     EMM386 not installed - incorrect DOS version.

You have tried to install EMM386.SYS on a machine using a version of MS-DOS
lower than 3.1.  You can only install EMM386.SYS on systems using MS-DOS 
Version 3.1 or higher.

*    EMM386 not installed - incorrect machine type.

EMM386.SYS can only run on 80386 based machines which are compatible with
the IBM AT standard hardware/software interface, such as Compaq 386 or AST
Premium 386.

*     EMM386 not installed - unable to set page frame base address.

This message is displayed when EMM386.SYS cannot find a range of 64K of
free (nonoccupied by BIOS, EGA adapters, or expansion option boards) 
contiguous memory in the 640K to 1 MB range to load its page frame

*     EMM386 already installed.

You cannot install EMM386.SYS twice.


CORRECTIONS
-----------

MS-DOS User's Reference--Command command--Page 48.

The second example should read:

If you want to increase space to 256 bytes, not kilobytes.


MS-DOS User's Reference--Find command--Page 76.

The example should read:

tree /f: | find ".EXE"


MS-DOS User's Reference--Mode command--Page 100.

The second syntax statement should read:

mode [display],shift[,t]
