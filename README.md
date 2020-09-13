iceGDROM
========

This is an implementation of IDE and the "Sega Packet Interface"
as used by the Dreamcast GD-ROM drive, using an iCE40 FPGA.

In addition to the IDE interface itself, and the accompanying CD-DA
interface, the FPGA bitstream implements an RV32EMC-compatible CPU and
an SD Card interface.  Software running on the CPU responds to
disc access commands from the Dreamcast by fetching data from disc
images on an SD Card.

For more detailed information, please see [the webpage][1].

This is free software (and hardware) licensed under the GNU
General Public License version 3.


Hardware
--------

The hardware is based on the Lattice iCE40-HX8K Breakout Board.
In order to connect this board to the Dreamcast motherboard, a
custom "riser board" with the appropriate connectors and some
additional components is used.  The design files for this can be
found in the `pcb/riser` directory.  The bill of materials can be
found in the file `pcb/riser/bom.txt`.  The pin headers with a `J`
designation should be soldered to the Breakout Board (pins facing downwards).

The components CN4, R8, D1, and JP2 through JP4 are optional.  They
are a passthrough for a slave hard drive, and not used by the GD-ROM
emulator.

For the hardware to be complete, the following additional things are
needed:

* A USB-mini cable to connect CN6 to the Breakout Board.  This is how
  the Breakout Board is powered when not attached to a host computer.
* An SD Card module, to connect to CN5.
* Rubber feet or similar to support the weight of the board in the
  corners not resting on CN1.


Required tools
--------------

To build the FPGA bitstream, the following tools are needed:

* Yosys 0.6
* arachne-pnr
* icestorm

To build the RISC-V software, the following tools are needed:

* riscv32-unknown-elf gcc 10.2.0
* riscv32-unknown-elf binutils 2.34.0


Building
--------

Building is done by running GNU make.  Running make at the top level
will build everything, running it in a subdir will build that part.
Note that building in fpga requires the rv32 stuff to be built first.

The file `rv32/source/config.h` can be modified to adapt to the polarity
of the CD signal on the chosen SD Card module, or to enable debug traces
on the serial port of the FTDI chip.

In order to flash the FPGA bitstream to the breakout board, run
`make flash`.


Making image files
------------------

Building the project will also create a host tool in `tools/obj/makegdimg`
which can create image files from either `.gdi` files (for GD-ROM images)
or from `.nrg` or `.cdi` files (for MIL-CD and audio CD images).  The
image files should be named `DISC0000.GI0`, `DISC0001.GI0` etc on the
SD Card.  To switch between images, extract and reinsert the SD Card.


Acknowledgements
----------------

* RISC-V softcore "VexRiscv" was developed by Charles Papon
* GD-ROM connector pinout was provided by OzOnE
* SD Card and FAT code based on sdfatlib by Bill Greiman
* DiscJuggler reader code based on CDIrip by DeXT/Lawrence Williams


[1]: http://mc.pp.se/dc/gdromemu.html
