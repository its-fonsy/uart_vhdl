# UART Core in VHDL

This is an implementation of an UART Core written in VHDL. The architecture is
briefly described in the block diagram below

<p align="center">
    <img width="80%" src="/uart.png">
</p>

The configuration can set:

* Baudrate, that ranges from 9600 to 115200;
* Data length, that ranges from 5 to 9;
* Parity mode, even or odd;

Everything has been done for learning purposes and has been developed using
Modelsim 2020.1 as Simulator.

### Project structure

Inside the `src` folder there is the code for every component and its relative
testbench (e.g. `fifo.vhdl` and `fifo_tb.vhdl`).

#### Testbench of the UART Core

The testbench for the UART can be found inside `src/uart_tb.vhdl` and test both
the transmission and reception of the Core.

The test consists in sending/receiving 10 random values for every combinations
of baud rate and data length. For each value parity is choosen randomly. The
received/sent data is checked to be correct.

## Simulate the project

Ensure to have Modelsim installed and its binaries inside the `$PATH` system variable.

To simulate the project clone the repo

    git clone git@github.com:its-fonsy/uart_vhdl.git

navigate inside the directory and run the simulation

    cd uart_vhdl
    make sim

It can also be run without the GUI

    make batch
