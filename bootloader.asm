[org 0x7c00]
[bits 16]

start:
    cli
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    mov ax, 0x0003
    int 0x10

    mov si, msg1
    call print

    ; загрузка ядра (сектор 2, 40 секторов – достаточно)
    mov ax, 0x1000
    mov es, ax
    xor bx, bx
    mov ah, 0x02
    mov al, 40
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0
    int 0x13
    jc error

    mov si, msg2
    call print

    ; передаём управление ядру
    jmp 0x1000:0x0000

error:
    mov si, msg_error
    call print
    jmp $

print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp print
.done:
    ret

msg1       db 'Loading kernel...', 0x0d, 0x0a, 0
msg2       db 'Kernel loaded! Starting...', 0x0d, 0x0a, 0
msg_error  db 'ERROR!', 0x0d, 0x0a, 0

times 510 - ($ - $$) db 0
dw 0xaa55