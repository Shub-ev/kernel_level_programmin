# Notes: Bootloader That Prints a String Using BIOS


# Overview

This program is a boot sector.

When the computer starts:

1. BIOS loads the first sector (512 bytes) of the boot device.
2. BIOS places it into memory at address `0x7C00`.
3. BIOS checks for boot signature `55 AA`.
4. BIOS transfers control to our code.
5. Our code prints a message using BIOS video services.
6. The CPU halts forever.

---

# Boot Process

Before our code runs, the following occurs:

```text
Power On
    ↓
CPU Reset
    ↓
BIOS Starts
    ↓
Hardware Initialization
    ↓
Find Boot Device
    ↓
Read First Sector (512 bytes)
    ↓
Load At 0x7C00
    ↓
Check 55 AA Signature
    ↓
Jump To 0x7C00
    ↓
Execute Our Code
```

The first instruction executed is located at memory address:

```text
0x7C00
```

---

# ORG 0x7C00

```asm
ORG 0x7C00
```

## Purpose

`ORG` means Origin.

It tells NASM:

```text
Assume this program starts at address 0x7C00
```

This is important because BIOS loads the boot sector into memory at 0x7C00.

---

## Why We Need It

Suppose a label exists:

```asm
message:
```

NASM must know its address.

Without:

```asm
ORG 0x7C00
```

NASM assumes:

```text
message = offset from 0
```

With:

```asm
ORG 0x7C00
```

NASM assumes:

```text
message = offset from 0x7C00
```

which matches reality.

---

# BITS 16

```asm
BITS 16
```

The BIOS starts the processor in:

```text
Real Mode
```

Real Mode uses:

```text
16-bit instructions
16-bit registers
20-bit addresses
```

Therefore NASM must generate 16-bit machine code.

---

# Main Routine

```asm
main:
```

After BIOS loads your boot sector into memory at 0x7C00 and verifies the boot signature (55 AA), it transfers CPU execution to your bootloader.
The first instruction the CPU executes from your bootloader is the code at the label `main`.

---

# Initializing Segment Registers

```asm
MOV ax, 0
MOV ds, ax
MOV es, ax
MOV ss, ax
```

## What Are Segment Registers?

# Segment Registers

The Intel 8086 processor was originally designed with 16-bit registers. A 16-bit register can represent values from:

0x0000 to 0xFFFF

In Real Mode, memory addresses are formed using:
```text
Segment : Offset
```

Examples:

```text
DS:SI
ES:DI
SS:SP
CS:IP
```

Physical address calculation:

```text
Physical Address =
Segment × 16 + Offset
```

---

## Why Set Them To Zero?

We want a predictable environment.

After BIOS execution, segment registers may contain values left by firmware.

By executing:

```asm
MOV ds, 0
MOV es, 0
MOV ss, 0
```

we guarantee:

```text
DS = 0000h
ES = 0000h
SS = 0000h
```

making address calculations predictable.

---

# Initializing The Stack

```asm
MOV sp, 0x7C00
```

## What Is The Stack?

The stack is a memory area used for:

```text
Function calls
Local storage
Saving registers
Return addresses
```

The stack grows downward.

Example:

```text
SP = 7C00
PUSH AX
SP = 7BFE
```

because a 16-bit push stores 2 bytes.

---

## Why 0x7C00?

Our bootloader occupies memory around:

```text
0x7C00
```

Setting:

```asm
MOV sp, 0x7C00
```

gives a reasonable stack location for this small example.

---

# Loading String Address

```asm
MOV si, print_message
```

After assembly:

```text
SI = address of print_message
```

SI now points to the first character of our string.

---

# Calling The Print Procedure

```asm
CALL print
```

## What Happens Internally?

Suppose execution is:

```asm
CALL print
```

CPU automatically:

1. Pushes return address onto stack.
2. Jumps to `print`.

Stack becomes:

```text
Top
+------------------+
| Return Address   |
+------------------+
```

Later:

```asm
RET
```

will pop this address and continue execution after the call.

---

# Halt Loop

```asm
halt:
    HLT
    JMP halt
```

---

## HLT

```asm
HLT
```

means:

```text
Stop CPU execution until an interrupt occurs
```

The processor enters a low-power waiting state.

---

## Why The Infinite Loop?

An interrupt may wake the CPU.

Without:

```asm
JMP halt
```

execution could continue into random memory.

Therefore:

```asm
JMP halt
```

creates:

```text
HLT
 ↓
Interrupt
 ↓
JMP halt
 ↓
HLT
 ↓
Forever
```

---

# Print Procedure

```asm
print:
```

A procedure used to print a null-terminated string.

---

# Preserving Registers

```asm
PUSH si
PUSH ax
PUSH bx
```

The procedure modifies these registers.

To avoid destroying the caller's values:

```text
Save Before Use
Restore Before Return
```

---

# String Printing Loop

```asm
print_loop:
```

The loop prints one character per iteration.

---

# LODSB

```asm
LODSB
```

Means:

```text
AL = [DS:SI]
SI = SI + 1
```

Example:

```text
String = "ABC"

SI -> A

LODSB
AL = 'A'
SI -> B
```

---

# End Of String Check

```asm
CMP al, 0
JZ done_print
```

---

## Why Compare To Zero?

The string ends with:

```asm
DB "...", 0
```

The final zero is called:

```text
Null Terminator
```

When:

```text
AL = 0
```

the string is finished.

---

## JZ

```asm
JZ done_print
```

means:

```text
If Zero Flag = 1
Jump To done_print
```

The Zero Flag becomes set when:

```asm
CMP al, 0
```

finds AL equal to zero.

---

# BIOS Video Output

```asm
MOV ah, 0x0E
MOV bh, 0
INT 0x10
```

---

## INT 10h

`INT 10h` is a BIOS video service.

It allows bootloaders to display text before an operating system exists.

---

## AH = 0Eh

Function:

```text
Teletype Output
```

Meaning:

```text
Print character stored in AL
Move cursor forward
```

Example:

```text
AL = 'A'
INT 10h
```

Result:

```text
A appears on screen
```

---

## BH = 0

BIOS supports multiple display pages.

```asm
MOV bh, 0
```

selects page 0.

---

# Continue Loop

```asm
JMP print_loop
```

After printing one character:

```text
Read Next Character
Print It
Repeat
```

until a null byte is found.

---

# Procedure Cleanup

```asm
done_print:
```

---

## Restore Registers

```asm
POP bx
POP ax
POP si
```

Restores the original values saved earlier.

Stack becomes exactly as it was before entering the procedure.

---

# RET

```asm
RET
```

RET:

1. Pops return address from stack.
2. Loads it into IP.
3. Continues execution after CALL.

Flow:

```text
CALL print
    ↓
print executes
    ↓
RET
    ↓
return to caller
```

---

# String Definition

```asm
print_message DB "My OS is Booted!", 0x0D, 0x0A, 0
```

---

## DB

DB means:

```text
Define Byte
```

Every character is stored as one byte.

---

## 0x0D

```text
Carriage Return
```

Moves cursor to start of line.

---

## 0x0A

```text
Line Feed
```

Moves cursor down one line.

---

## 0

Null terminator:

```text
Marks end of string
```

Used by the printing loop.

---

# Padding To 512 Bytes

```asm
TIMES 510-($-$$) DB 0
```

BIOS requires:

```text
Boot Sector Size = 512 Bytes
```

This directive fills unused space with zeros.

---

## $

```text
Current Assembly Position
```

---

## $$

```text
Beginning Of Current Section
```

---

## $ - $$

```text
Current Program Size
```

NASM calculates remaining space and fills it with zeros.

---

# Boot Signature

```asm
DW 0AA55h
```

Stored as:

```text
55 AA
```

because x86 is little-endian.

---

# Why It Is Required

BIOS checks:

```text
Byte 510
Byte 511
```

If they contain:

```text
55 AA
```

the sector is considered bootable.

Otherwise BIOS refuses to execute it.

---

# Complete Execution Flow

```text
BIOS Loads Boot Sector
        ↓
Jump To 0x7C00
        ↓
Initialize Segments
        ↓
Initialize Stack
        ↓
Load String Address Into SI
        ↓
CALL print
        ↓
LODSB Reads Character
        ↓
INT 10h Prints Character
        ↓
Repeat Until Null Byte
        ↓
RET
        ↓
HLT
        ↓
Infinite Loop Forever
```

---

# Output

The screen displays:

```text
My OS is Booted!
```

and then the processor remains halted forever.

