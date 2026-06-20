# Segment Registers

## Introduction

The Intel 8086 processor was designed as a 16-bit processor. Since a 16-bit register can only represent values from `0x0000` to `0xFFFF`, a single register can directly address only:

```text
65,536 bytes = 64 KB
```

However, the 8086 was designed to access:

```text
1 MB = 1,048,576 bytes
```

of memory.

To overcome this limitation, Intel introduced **memory segmentation**.

---

# What Is Segmentation?

Segmentation is a memory management technique that divides memory addresses into two parts:

```text
Segment : Offset
```

Instead of storing a complete memory address in a single register, the processor stores:

* A segment value
* An offset value

The CPU combines these two values to calculate the actual physical memory address.

---

# Why Segmentation Was Needed

Without segmentation:

```text
16-bit register
↓
Maximum address = 0xFFFF
↓
64 KB memory
```

This would severely limit the amount of usable RAM.

Using segmentation:

```text
Segment + Offset
↓
20-bit Physical Address
↓
1 MB Address Space
```

The processor can access much more memory while still using 16-bit registers internally.

---

# Segment Registers

The 8086 provides four primary segment registers:

| Register | Name          | Purpose                        |
| -------- | ------------- | ------------------------------ |
| CS       | Code Segment  | Stores executable instructions |
| DS       | Data Segment  | Stores program data            |
| SS       | Stack Segment | Stores stack memory            |
| ES       | Extra Segment | Additional data segment        |

Each segment register is 16 bits wide.

---

# Physical Address Calculation

The CPU computes a physical address using:

```text
Physical Address =
(Segment × 16) + Offset
```

or:

```text
Physical Address =
(Segment << 4) + Offset
```

because multiplying by 16 is equivalent to shifting left by 4 bits.

---

# Example 1

Suppose:

```text
DS = 1000h
SI = 0020h
```

The physical address becomes:

```text
1000h × 10h + 20h

= 10000h + 20h

= 10020h
```

Therefore:

```text
DS:SI = 1000:0020
```

points to:

```text
0x10020
```

in physical memory.

---

# Example 2

Suppose:

```text
CS = 07C0h
IP = 0000h
```

Then:

```text
Physical Address

= 07C0h × 10h + 0000h

= 07C00h
```

which corresponds to:

```text
0x7C00
```

the location where BIOS loads the boot sector.

---

# Multiple Segment:Offset Pairs Can Point To The Same Address

An interesting property of Real Mode addressing is that multiple segment-offset combinations may produce the same physical address.

Example:

```text
1000:0020
1001:0010
1002:0000
```

All calculate to:

```text
10020h
```

This happens because segment values overlap every 16 bytes.

---

# Code Segment (CS)

The Code Segment register identifies where executable machine instructions are located.

The CPU fetches instructions using:

```text
CS:IP
```

where:

```text
CS = Code Segment
IP = Instruction Pointer
```

Example:

```text
CS = 07C0h
IP = 0000h
```

Physical address:

```text
07C00h
```

The CPU reads and executes the next instruction from this location.

---

# Data Segment (DS)

The Data Segment register contains the segment where program data resides.

Many instructions automatically use DS when accessing memory.

Example:

```asm
MOV AL, [SI]
```

The CPU interprets this as:

```text
AL = Memory[DS:SI]
```

If:

```text
DS = 0000h
SI = 7C50h
```

then the processor reads from:

```text
0000:7C50
```

which corresponds to physical address:

```text
0x7C50
```

---

# Stack Segment (SS)

The Stack Segment register defines where the stack is located.

The stack is accessed using:

```text
SS:SP
```

where:

```text
SS = Stack Segment
SP = Stack Pointer
```

Example:

```text
SS = 0000h
SP = 7C00h
```

Physical address:

```text
0000:7C00

= 0x7C00
```

---

# Extra Segment (ES)

ES stands for Extra Segment.

It provides an additional data segment and is commonly used by string instructions.

Many string operations use:

```text
Source      = DS:SI
Destination = ES:DI
```

Example:

```asm
MOVSB
```

Internally performs:

```text
Copy byte from DS:SI
to ES:DI
```

This makes block memory operations efficient.

---

# Segment Registers In Bootloaders

When BIOS transfers control to a bootloader, the values stored in:

```text
DS
ES
SS
```

are not guaranteed to be what the bootloader expects.

Therefore bootloaders usually initialize them:

```asm
MOV AX, 0

MOV DS, AX
MOV ES, AX
MOV SS, AX
```

This creates a known and predictable memory environment.

---

# Why DS Must Be Initialized

Suppose a bootloader contains:

```asm
MOV SI, message
LODSB
```

`LODSB` reads:

```text
DS:SI
```

If DS contains an unexpected value left by BIOS, the processor may read from an incorrect memory location.

Setting:

```asm
MOV DS, 0
```

ensures the string is read from the intended address.

---

# Segment Registers In Our Bootloader

Consider:

```asm
MOV AX, 0
MOV DS, AX
MOV ES, AX
MOV SS, AX

MOV SI, print_message
```

After execution:

```text
DS = 0000h
ES = 0000h
SS = 0000h
```

Suppose:

```text
print_message = 7C50h
```

When:

```asm
LODSB
```

executes, the processor accesses:

```text
DS:SI

0000:7C50
```

Physical address:

```text
0x7C50
```

which correctly points to the string stored inside the bootloader.

---

# Summary

Segment registers allow a 16-bit processor to access up to 1 MB of memory by dividing addresses into:

```text
Segment : Offset
```

The CPU calculates the physical address using:

```text
Physical Address =
(Segment × 16) + Offset
```

The four primary segment registers are:

```text
CS - Code Segment
DS - Data Segment
SS - Stack Segment
ES - Extra Segment
```

Together with offset registers such as:

```text
IP
SI
DI
SP
```

they allow the processor to locate instructions, data, strings, and stack memory throughout the system.

