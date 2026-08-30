[org 0x0000]
[bits 16]

start:
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFF00

    call clear_screen

    mov si, banner
    call print_string

    call shell

; базовые функции

print_string:
    push ax
    push si
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp .loop
.done:
    pop si
    pop ax
    ret

clear_screen:
    push ax
    mov ax, 0x0003
    int 0x10
    pop ax
    ret

newline:
    push si
    mov si, crlf
    call print_string
    pop si
    ret

read_line:
    push ax
    push di
    push cx
    xor cx, cx
    mov di, input_buffer
.loop:
    xor ax, ax
    int 0x16
    cmp al, 0x0d
    je .enter
    cmp al, 0x08
    je .backspace
    cmp cl, 63
    je .loop
    stosb
    inc cx
    mov ah, 0x0e
    int 0x10
    jmp .loop
.backspace:
    cmp cx, 0
    je .loop
    dec cx
    dec di
    mov ah, 0x0e
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .loop
.enter:
    xor al, al
    stosb
    call newline
    pop cx
    pop di
    pop ax
    ret

strcmp:
    push si
    push di
    push ax
.loop:
    lodsb
    or al, al
    jz .check
    cmp al, [di]
    jne .no
    inc di
    jmp .loop
.check:
    cmp byte [di], 0
    jne .no
    stc
    jmp .done
.no:
    clc
.done:
    pop ax
    pop di
    pop si
    ret

print_hex:
    push ax
    push cx
    mov cl, 4
    shr al, cl
    call print_nibble
    pop cx
    pop ax
    and al, 0x0f
    call print_nibble
    ret

print_nibble:
    add al, '0'
    cmp al, '9'
    jle .digit
    add al, 7
.digit:
    mov ah, 0x0e
    int 0x10
    ret

; командная оболочка

shell:
    mov si, prompt
    call print_string
    call read_line

    mov si, input_buffer

    ; help
    mov di, cmd_help
    call strcmp
    jc .help

    ; time
    mov di, cmd_time
    call strcmp
    jc .time

    ; clear
    mov di, cmd_clear
    call strcmp
    jc .clear

    ; info
    mov di, cmd_info
    call strcmp
    jc .info

    ; reboot
    mov di, cmd_reboot
    call strcmp
    jc .reboot

    ; neofetch
    mov di, cmd_neofetch
    call strcmp
    jc .neofetch

    ; calc
    mov di, cmd_calc
    call strcmp
    jc .calc

    ; unknown
    mov si, unknown_msg
    call print_string
    jmp shell

.help:
    mov si, help_msg
    call print_string
    jmp shell

.time:
    call do_time
    jmp shell

.clear:
    call clear_screen
    jmp shell

.info:
    call do_info
    jmp shell

.reboot:
    mov si, reboot_msg
    call print_string
    int 0x19

.neofetch:
    call do_neofetch
    jmp shell

.calc:
    call do_calc
    jmp shell

; как команды будут выглядеть

; время
do_time:
    push ax
    push cx
    push si
    mov ah, 0x02
    int 0x1a
    mov si, time_msg
    call print_string
    mov al, ch
    call print_hex
    mov si, colon
    call print_string
    mov al, cl
    call print_hex
    call newline
    pop si
    pop cx
    pop ax
    ret

; инфо
do_info:
    push si
    mov si, info_msg
    call print_string
    pop si
    ret

; неофетч
do_neofetch:
    push si
    push ax

    ; Логотип (упрощенный)
    mov si, neo_logo
    call print_string

    ; ос
    mov si, neo_os
    call print_string

    ; ядро
    mov si, neo_kernel
    call print_string

    ; архитектура
    mov si, neo_arch
    call print_string

    ; время
    mov si, neo_time_label
    call print_string
    call do_time   ; выводит время

    ; память (через int 0x12 – размер в КБ)
    int 0x12
    mov si, neo_mem_label
    call print_string
    call print_number_ax
    mov si, neo_mem_unit
    call print_string
    call newline

    ; BIOS (проверяем)
    mov si, neo_bios_label
    call print_string
    mov si, neo_bios_ok
    call print_string
    call newline

    call newline
    pop ax
    pop si
    ret

; вывод числа из AX (десятичное)
print_number_ax:
    push ax
    push bx
    push cx
    push dx
    push di
    mov di, num_buffer
    mov bx, 10
    xor cx, cx
    cmp ax, 0
    jne .convert
    mov al, '0'
    stosb
    inc cx
    jmp .print
.convert:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .convert
.print:
    pop dx
    add dl, '0'
    mov al, dl
    mov ah, 0x0e
    int 0x10
    loop .print
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; калькулятор
do_calc:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, calc_prompt
    call print_string
    call read_line

    mov si, input_buffer

    ; Парсим первое число
    call parse_number
    push ax          ; сохраняем первое число

    ; Ищем оператор
.skip_op:
    lodsb
    cmp al, '+'
    je .add
    cmp al, '-'
    je .sub
    cmp al, '*'
    je .mul
    cmp al, '/'
    je .div
    cmp al, 0
    je .error
    jmp .skip_op

.add:
    call parse_number
    pop bx
    add ax, bx
    jmp .print_result

.sub:
    call parse_number
    pop bx
    sub bx, ax
    mov ax, bx
    jmp .print_result

.mul:
    call parse_number
    pop bx
    mul bx
    jmp .print_result

.div:
    call parse_number
    pop bx
    cmp ax, 0
    je .div_zero
    xchg ax, bx
    xor dx, dx
    div bx
    jmp .print_result

.div_zero:
    mov si, calc_divzero
    call print_string
    jmp .done

.print_result:
    mov si, calc_result
    call print_string
    call print_number_ax
    call newline
    jmp .done

.error:
    mov si, calc_error
    call print_string
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; парсинг числа (возвращает AX)
parse_number:
    push bx
    push cx
    xor ax, ax
    xor cx, cx
    xor bx, bx
.loop:
    lodsb
    cmp al, '0'
    jb .done
    cmp al, '9'
    ja .done
    sub al, '0'
    mov bx, ax
    mov ax, cx
    mov cx, 10
    mul cx
    add ax, bx
    mov cx, ax
    jmp .loop
.done:
    dec si
    mov ax, cx
    pop cx
    pop bx
    ret

; данные

banner          db 'microDOS v0.3 - 16-bit OS', 0x0d, 0x0a
                db 'help for commands', 0x0d, 0x0a, 0
prompt          db '> ', 0
unknown_msg     db 'unknown command', 0x0d, 0x0a, 0
help_msg        db 'commands:', 0x0d, 0x0a
                db '  help      - show this help', 0x0d, 0x0a
                db '  time      - show system time', 0x0d, 0x0a
                db '  clear     - clear screen', 0x0d, 0x0a
                db '  info      - system information', 0x0d, 0x0a
                db '  neofetch  - pretty system info', 0x0d, 0x0a
                db '  calc      - calculator (e.g., 5+3)', 0x0d, 0x0a
                db '  reboot    - restart computer', 0x0d, 0x0a, 0
time_msg        db 'time: ', 0
colon           db ':', 0
reboot_msg      db 'reboot...', 0x0d, 0x0a, 0
info_msg        db 'microDOS v3.0', 0x0d, 0x0a
                db '16-bit, Real mode', 0x0d, 0x0a
                db 'written in NASM', 0x0d, 0x0a, 0
crlf            db 0x0d, 0x0a, 0

; неофетч (типо) функции
neo_logo        db 0x0d, 0x0a
                db '          microDOS            ', 0x0d, 0x0a
                db '       16-bit rezhim       ', 0x0d, 0x0a, 0
neo_os          db 'OS:           microDOS 0.3', 0x0d, 0x0a, 0
neo_kernel      db 'Kernel:       16-bit x86', 0x0d, 0x0a, 0
neo_arch        db 'Architecture: 8086/80286', 0x0d, 0x0a, 0
neo_time_label  db 'Time:         ', 0
neo_mem_label   db 'Memory:       ', 0
neo_mem_unit    db ' KB', 0x0d, 0x0a, 0
neo_bios_label  db 'BIOS:         ', 0
neo_bios_ok     db 'IBM PC/AT compatible', 0

; калькулятор функции
calc_prompt     db 'Calc: ', 0
calc_result     db '= ', 0
calc_error      db 'Error!', 0x0d, 0x0a, 0
calc_divzero    db 'Division by zero!', 0x0d, 0x0a, 0

; команды (имена)
cmd_help        db 'help', 0
cmd_time        db 'time', 0
cmd_clear       db 'clear', 0
cmd_info        db 'info', 0
cmd_reboot      db 'reboot', 0
cmd_neofetch    db 'neofetch', 0
cmd_calc        db 'calc', 0

; буферы
input_buffer    times 64 db 0
num_buffer      times 16 db 0
