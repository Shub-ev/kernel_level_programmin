ORG 0x7C00
BITS 16

main:
    MOV ax, 0       ; setting these regs to 0
    MOV ds, ax      ; to get consistent starting point
    MOV es, ax
    MOV ss, ax

    MOV sp, 0x7C00
    MOV si, print_message
    CALL print

halt:
    HLT
    JMP halt

print:
    PUSH si         ; preserve regs as we are going to
    PUSH ax         ; use and update them
    PUSH bx

print_loop:
    LODSB
    CMP al, 0
    JZ done_print

    MOV ah, 0x0E    ; code used to print a char to screen
    MOV bh, 0       ; page number
    INT 0x10        ; video interrupt (BIOS will handle this)
    JMP print_loop

done_print:
    POP bx
    POP ax
    POP si
    RET

print_message DB "My OS is Booted!", 0x0D, 0x0A, 0


TIMES 510-($-$$) DB 0
DW 0AA55h
