# MIPS 5-Stage Pipelined Processor (Verilog Implementation)

## Overview

This project implements a simplified 32-bit MIPS processor using a
5-stage pipeline architecture in Verilog HDL.\
The design uses a two-phase clocking scheme (`clk1` and `clk2`) to model
pipeline behavior.

The processor supports arithmetic, logical, memory access, branch, and
halt instructions.

------------------------------------------------------------------------

## Pipeline Stages

### 1. Instruction Fetch (IF)

-   Fetches instruction from memory using Program Counter (PC).
-   Handles branch redirection.
-   Updates PC.
-   Pipeline registers: `IF_ID_IR`, `IF_ID_NPC`.

### 2. Instruction Decode (ID)

-   Reads register operands.
-   Sign-extends immediate values.
-   Determines instruction type.
-   Pipeline registers: `ID_EX_A`, `ID_EX_B`, `ID_EX_IMM`, `ID_EX_TYPE`.

### 3. Execute (EX)

-   Performs ALU operations.
-   Calculates branch target address.
-   Evaluates branch condition.
-   Pipeline registers: `EX_MEM_ALUOUT`, `EX_MEM_TYPE`, `EX_MEM_COND`.

### 4. Memory (MEM)

-   Performs memory read/write operations.
-   Handles HALT instruction.
-   Pipeline registers: `MEM_WB_ALUOUT`, `MEM_WB_LMB`, `MEM_WB_TYPE`.

### 5. Write Back (WB)

-   Writes results back into register file.

------------------------------------------------------------------------

## Supported Instructions

### R-Type (Register-Register ALU)

-   ADD
-   SUB
-   AND
-   OR
-   SLT
-   MUL

### I-Type (Register-Immediate ALU)

-   ADI
-   SUBI
-   SLTI

### Memory Instructions

-   LW (Load Word)
-   SW (Store Word)

### Branch Instructions

-   BEQZ (Branch if Equal to Zero)
-   BNEQZ (Branch if Not Equal to Zero)

### Control Instruction

-   HLT (Halts processor execution)

------------------------------------------------------------------------

## Internal Components

### Memory

-   1024 x 32-bit word memory
-   Modeled as: `reg [31:0] MEM[0:1023]`

### Register File

-   32 general-purpose 32-bit registers
-   Modeled as: `reg [31:0] REG[0:31]`

------------------------------------------------------------------------

## Special Signals

-   `HALTED` -- Indicates processor stop after HLT instruction.
-   `TAKEN_BRANCH` -- Used to disable invalid instruction after branch.
-   Two-phase clock:
    -   `clk1` → IF, EX, WB
    -   `clk2` → ID, MEM

------------------------------------------------------------------------

## Features

-   5-stage pipeline architecture
-   Separate pipeline registers for each stage
-   Branch handling mechanism
-   Sign-extension for immediate values
-   Memory-mapped instruction/data storage
-   Simple hazard handling through branch control flag

------------------------------------------------------------------------

## Limitations

-   No explicit data hazard detection unit
-   No stall mechanism
-   No jump instruction

------------------------------------------------------------------------

## Possible Improvements

-   Add hazard detection and stall logic
-   Implement jump instruction
-   Add testbench with automated verification
-   Convert to single-clock synchronous pipeline
-   Implement cache support

--------------

## Author

Juriel