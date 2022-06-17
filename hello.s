mov ax ,0xb800
mov ds,ax
mov byte [0],'a'

halt:
    jmp halt

times 510 - ($ - $$) db 0

db 0x55,0xaa

