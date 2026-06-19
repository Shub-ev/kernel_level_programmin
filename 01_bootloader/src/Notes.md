# Boot Sector Notes

## Overview

This file contains a minimal x86 boot sector that can be loaded and executed directly by the BIOS.

Source Code:

```asm
ORG 0x7C00
BITS 16

main:
    HLT

halt:
    JMP halt

TIMES 510-($-$$) DB 0
DW 0AA55h
```

The purpose of this program is not to perform useful work, but to demonstrate the complete boot process:

1. BIOS loads the boot sector.
2. CPU begins execution at address `0x7C00`.
3. The processor executes a halt instruction.
4. The processor enters an infinite loop.
5. The sector contains a valid boot signature.

---

# What Happens Before This Code Runs

When a computer is powered on, the CPU does not immediately execute our code.

The boot sequence is:

```text
Power On
    ↓
CPU Reset
    ↓
BIOS Starts
    ↓
Hardware Initialization
    ↓
Boot Device Detection
    ↓
Read First Sector
    ↓
Load Sector At 0x7C00
    ↓
Jump To Loaded Code
```

The BIOS always loads the first sector of the boot device into memory.

A sector is:

```text
512 bytes
```

The memory location used by the BIOS is:

```text
0x7C00
```

Execution begins at that address.

---

# ORG 0x7C00

```asm
ORG 0x7C00
```

## Purpose

`ORG` stands for Origin.

This directive is used by NASM during assembly.

It is not an instruction.

The CPU never executes it.

The BIOS never sees it.

Only NASM uses it.

---

## Why It Is Needed

The BIOS loads our boot sector at:

```text
0x7C00
```

NASM must know this when calculating addresses.

Without:

```asm
ORG 0x7C00
```

NASM assumes:

```text
Program starts at address 0
```

With:

```asm
ORG 0x7C00
```

NASM assumes:

```text
Program starts at address 0x7C00
```

This ensures labels and memory references are calculated correctly.

---

## Example

Suppose we have:

```asm
ORG 0x7C00

message:
    DB "Hello", 0
```

NASM calculates:

```text
message = 0x7C00
```

Without ORG:

```text
message = 0
```

which would be incorrect.

---

## What Happens If ORG Is Removed

Simple boot sectors may still appear to work.

However, any future code using labels, strings, buffers, or data structures will eventually fail because addresses will be wrong.

For this reason almost every boot sector begins with:

```asm
ORG 0x7C00
```

---

# BITS 16

```asm
BITS 16
```

## Purpose

This tells NASM to generate 16-bit machine code.

Again, this is not a CPU instruction.

Only NASM uses it.

---

## Why 16-bit?

When the BIOS starts the CPU, the processor is placed into:

```text
Real Mode
```

Real Mode is the original execution mode of the Intel 8086.

Characteristics:

```text
16-bit registers
16-bit instructions
20-bit addressing
1 MB memory limit
```

Registers available include:

```text
AX
BX
CX
DX
SI
DI
BP
SP
```

---

## Why NASM Must Know

NASM needs to know how instructions should be encoded.

Example:

```asm
MOV AX, BX
```

must be assembled as a 16-bit instruction.

Without:

```asm
BITS 16
```

NASM may generate instructions intended for a different mode.

---

# main Label

```asm
main:
```

A label marks a location in the program.

Think of it as a bookmark.

NASM records:

```text
main = current address
```

Because of:

```asm
ORG 0x7C00
```

the label becomes:

```text
main = 0x7C00
```

The BIOS transfers control to this location after loading the sector.

---

# HLT Instruction

```asm
HLT
```

## Meaning

HLT stands for Halt.

This is the first actual instruction executed by the CPU.

---

## What Happens Internally

Normally the CPU performs:

```text
Fetch Instruction
Decode Instruction
Execute Instruction
```

continuously.

When:

```asm
HLT
```

is executed:

```text
CPU Stops Fetching Instructions
```

and enters a sleeping state.

---

## Why Use HLT?

Our bootloader currently has no useful work to perform.

No kernel exists.

No scheduler exists.

No operating system exists.

Therefore we simply halt the processor.

---

## How CPU Wakes Up

The processor remains halted until an interrupt occurs.

Examples:

```text
Timer Interrupt
Keyboard Interrupt
Hardware Interrupt
```

When an interrupt occurs:

```text
CPU Wakes Up
```

and continues execution with the next instruction.

---

# halt Label

```asm
halt:
```

Another label.

NASM records the current address.

No machine code is generated.

---

# JMP halt

```asm
JMP halt
```

## Meaning

JMP stands for Jump.

This instruction changes the Instruction Pointer.

---

## What Happens Internally

Normally execution flows sequentially:

```text
Instruction A
Instruction B
Instruction C
```

A jump changes this flow.

When:

```asm
JMP halt
```

executes:

```text
IP = address of halt
```

---

## Result

Execution becomes:

```text
halt:
    JMP halt
```

which means:

```text
JMP halt
↓
JMP halt
↓
JMP halt
↓
Forever
```

This creates an infinite loop.

---

## Why Is This Needed?

Without the loop:

```text
CPU would continue executing whatever bytes follow.
```

Eventually it would execute garbage data and crash.

The loop guarantees execution remains under control.

---

# Why HLT And Infinite Loop Together?

A common question is:

```text
Why not just use JMP halt?
```

Because:

```asm
JMP halt
```

keeps the CPU busy forever.

The processor continuously executes instructions.

Using:

```asm
HLT
```

allows the CPU to sleep first.

Only after an interrupt occurs does execution enter the infinite loop.

---

# Boot Sector Size Requirement

The BIOS expects a boot sector to be:

```text
512 bytes
```

exactly.

Not:

```text
256 bytes
1000 bytes
2048 bytes
```

Exactly:

```text
512 bytes
```

---

# Current Program Size

The code currently generates only a few bytes.

Approximate size:

```text
HLT      = 1 byte
JMP halt = 2 bytes
```

Total:

```text
3 bytes
```

Far smaller than:

```text
512 bytes
```

Therefore padding is required.

---

# TIMES Directive

```asm
TIMES 510-($-$$) DB 0
```

This instruction fills the unused portion of the boot sector.

---

# Understanding $

```asm
$
```

Represents:

```text
Current Assembly Position
```

Example:

```asm
DB 1
DB 2
```

After these bytes:

```text
$ = 2
```

---

# Understanding $$

```asm
$$
```

Represents:

```text
Beginning Of Current Section
```

At the start:

```text
$$ = 0
```

---

# Understanding $ - $$

```asm
$ - $$
```

Calculates:

```text
Current Program Size
```

Example:

```text
Current Size = 3 Bytes
```

then:

```text
$ - $$ = 3
```

---

# Padding Calculation

```asm
510 - ($ - $$)
```

becomes:

```text
510 - 3
```

which equals:

```text
507
```

NASM then generates:

```asm
TIMES 507 DB 0
```

which means:

```text
507 bytes containing zero
```

---

# Why 510 And Not 512?

Because the final two bytes are reserved for the boot signature.

Layout:

```text
Bytes 0-509   Program + Padding
Bytes 510-511 Boot Signature
```

---

# Boot Signature

```asm
DW 0AA55h
```

## Meaning

DW stands for:

```text
Define Word
```

A word is:

```text
16 bits
2 bytes
```

---

## Value

```text
AA55h
```

is a hexadecimal number.

---

## Little Endian Storage

x86 uses Little Endian format.

Therefore:

```text
AA55
```

is stored as:

```text
55 AA
```

inside the file.

---

## Final Bytes

The last two bytes become:

```text
Offset 510 = 55
Offset 511 = AA
```

---

# Why The Signature Exists

After loading the sector, the BIOS checks:

```text
Byte 510
Byte 511
```

If they contain:

```text
55 AA
```

the BIOS considers the sector bootable.

If not:

```text
Boot Failed
```

and execution never reaches our code.

---

# Machine Code Generated

The source code is converted into machine code.

Approximate beginning of the sector:

```text
Offset    Bytes
------    -----
0000      F4
0001      EB FE
```

Meaning:

```text
F4     = HLT
EB FE  = JMP halt
```

---

# Memory Layout After BIOS Load

The BIOS loads the sector into memory.

```text
Memory

0x7C00
+------------------+
| HLT              |
| JMP halt         |
| Padding          |
| 55 AA            |
+------------------+
```

Execution begins at:

```text
0x7C00
```

---

# Disk Layout

After creating the floppy image:

```text
main.img

Sector 0
+------------------+
| Boot Sector      |
+------------------+

Sector 1
+------------------+
| Empty            |
+------------------+

Sector 2
+------------------+
| Empty            |
+------------------+
```

The boot sector occupies only the first sector.

---

# What Happens If Lines Are Removed?

## Remove ORG

Addresses become incorrect.

Future data references may fail.

---

## Remove BITS 16

NASM may generate instructions for the wrong execution mode.

---

## Remove HLT

Execution immediately enters the infinite loop.

---

## Remove JMP halt

CPU executes whatever bytes follow in memory.

---

## Remove Boot Signature

BIOS refuses to boot.

---

# Complete Execution Timeline

```text
Power On
    ↓
CPU Reset
    ↓
BIOS Starts
    ↓
Hardware Initialization
    ↓
Boot Device Found
    ↓
Read First Sector
    ↓
Load Sector At 0x7C00
    ↓
Verify 55 AA Signature
    ↓
Jump To 0x7C00
    ↓
Execute HLT
    ↓
CPU Sleeps
    ↓
Interrupt Occurs
    ↓
CPU Wakes Up
    ↓
Execute JMP halt
    ↓
Infinite Loop Forever
```

---

# Summary

```text
ORG 0x7C00
    BIOS load address

BITS 16
    Generate Real Mode instructions

HLT
    Halt the CPU

JMP halt
    Infinite loop

TIMES 510-($-$$) DB 0
    Pad sector to 510 bytes

DW 0AA55h
    Boot signature required by BIOS
```

This program is the smallest practical example of a valid x86 boot sector and demonstrates the complete BIOS-to-CPU boot process.

