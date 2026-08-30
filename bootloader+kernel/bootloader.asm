[org 0x0000]
[bits 16]

start:
    cli                 ; Отключаем прерывания при настройке сегментов и стека
    cld                 ; Сбрасываем флаг направления 
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFF00
    sti                 ; Включаем прерывания обратно

    call clear_screen

    mov si, banner
    call print_string

    call shell

; базовые функции

print_string:
    push ax
    push bx
    push cx
    push dx
    push si
.loop:
    lodsb
    or al, al
    jz .done
    cmp al, 0x0d
    je .handle_cr
    cmp al, 0x0a
    je .handle_lf
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0F
    mov cx, 1
    int 0x10
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    jmp .loop
.handle_cr:
    mov ah, 0x03
    mov bh, 0
    int 0x10
    mov dl, 0
    mov ah, 0x02
    int 0x10
    jmp .loop
.handle_lf:
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dh
    cmp dh, 25
    jb .set_cursor
    mov ax, 0x0601
    mov bh, 0x0F
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    mov dh, 24
.set_cursor:
    mov ah, 0x02
    mov bh, 0
    int 0x10
    jmp .loop
.done:
    pop si
    pop dx
    pop cx
    pop bx
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
    push bx
    push dx
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
    jae .loop
    stosb
    inc cx
    push ax
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0F
    push cx
    mov cx, 1
    int 0x10
    pop cx
    pop ax
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    jmp .loop
.backspace:
    cmp cx, 0
    je .loop
    dec cx
    dec di
    mov byte [di], 0
    mov ah, 0x03
    mov bh, 0
    int 0x10
    dec dl
    mov ah, 0x02
    int 0x10
    mov ax, 0x0920
    mov bh, 0
    mov bl, 0x0F
    push cx
    mov cx, 1
    int 0x10
    pop cx
    jmp .loop
.enter:
    xor al, al
    stosb
    call newline
    pop cx
    pop di
    pop dx
    pop bx
    pop ax
    ret

strcmp:
    push si
    push di
    push ax
.loop:
    mov al, [si]
    mov ah, [di]
    cmp al, ah
    jne .no
    test al, al
    jz .match
    inc si
    inc di
    jmp .loop
.match:
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
    push ax
    and al, 0x0f
    call print_nibble
    pop ax
    ret

print_nibble:
    push ax
    push bx
    push cx
    push dx
    add al, '0'
    cmp al, '9'
    jle .digit
    add al, 7
.digit:
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0F
    mov cx, 1
    int 0x10
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; командная оболочка

shell:
    mov si, prompt
    call print_string
    call read_line

    ; help
    mov si, input_buffer
    mov di, cmd_help
    call strcmp
    jc .help

    ; time
    mov si, input_buffer
    mov di, cmd_time
    call strcmp
    jc .time

    ; clear
    mov si, input_buffer
    mov di, cmd_clear
    call strcmp
    jc .clear

    ; info
    mov si, input_buffer
    mov di, cmd_info
    call strcmp
    jc .info

    ; reboot
    mov si, input_buffer
    mov di, cmd_reboot
    call strcmp
    jc .reboot

    ; neofetch
    mov si, input_buffer
    mov di, cmd_neofetch
    call strcmp
    jc .neofetch

    ; calc
    mov si, input_buffer
    mov di, cmd_calc
    call strcmp
    jc .calc

    ; snake
    mov si, input_buffer
    mov di, cmd_snake
    call strcmp
    jc .snake

    ; unknown
    cmp byte [input_buffer], 0
    je shell
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

.snake:
    call do_snake
    jmp shell

; как команды будут выглядеть

; змейка
do_snake:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    call clear_screen

    mov ah, 0x01
    mov cx, 0x2607
    int 0x10

    mov byte [snake_len], 3
    mov byte [snake_dir], 1
    mov byte [snake_x], 40
    mov byte [snake_y], 12
    mov byte [snake_x + 1], 39
    mov byte [snake_y + 1], 12
    mov byte [snake_x + 2], 38
    mov byte [snake_y + 2], 12
    mov byte [apple_x], 20
    mov byte [apple_y], 8

.game_loop:
    mov ah, 0x02
    mov bh, 0
    mov dl, [apple_x]
    mov dh, [apple_y]
    int 0x10
    mov ax, 0x092A
    mov bl, 0x0F
    mov cx, 1
    int 0x10

    xor cx, cx
    mov cl, [snake_len]
    xor si, si
.draw_snake:
    mov ah, 0x02
    mov bh, 0
    mov dl, [snake_x + si]
    mov dh, [snake_y + si]
    int 0x10
    mov ax, 0x0923
    mov bl, 0x0F
    push cx
    mov cx, 1
    int 0x10
    pop cx
    inc si
    loop .draw_snake

    mov cx, 1
    mov dx, 0x8000
    mov ah, 0x86
    int 0x15

    mov ah, 0x01
    int 0x16
    jz .move_snake
    xor ax, ax
    int 0x16
    cmp al, 27
    je .exit_game
    cmp ah, 0x48
    je .key_up
    cmp ah, 0x50
    je .key_down
    cmp ah, 0x4B
    je .key_left
    cmp ah, 0x4D
    je .key_right
    cmp al, 'w'
    je .key_up
    cmp al, 's'
    je .key_down
    cmp al, 'a'
    je .key_left
    cmp al, 'd'
    je .key_right
    jmp .move_snake

.key_up:
    cmp byte [snake_dir], 2
    je .move_snake
    mov byte [snake_dir], 0
    jmp .move_snake
.key_right:
    cmp byte [snake_dir], 3
    je .move_snake
    mov byte [snake_dir], 1
    jmp .move_snake
.key_down:
    cmp byte [snake_dir], 0
    je .move_snake
    mov byte [snake_dir], 2
    jmp .move_snake
.key_left:
    cmp byte [snake_dir], 1
    je .move_snake
    mov byte [snake_dir], 3
    jmp .move_snake

.move_snake:
    ; Стираем последний сегмент хвоста перед сдвигом
    xor ah, ah
    mov al, [snake_len]
    dec ax
    mov si, ax
    mov ah, 0x02
    mov bh, 0
    mov dl, [snake_x + si]
    mov dh, [snake_y + si]
    int 0x10
    mov ax, 0x0920
    mov bl, 0x0F
    mov cx, 1
    int 0x10

    ; Сдвиг координат тела (от хвоста к голове)
    xor ch, ch
    mov cl, [snake_len]
    dec cx
    mov si, cx
.shift_body:
    mov al, [snake_x + si - 1]
    mov [snake_x + si], al
    mov al, [snake_y + si - 1]
    mov [snake_y + si], al
    dec si
    loop .shift_body

    ; Движение головы
    mov al, [snake_x]
    mov ah, [snake_y]
    cmp byte [snake_dir], 0
    je .go_up
    cmp byte [snake_dir], 1
    je .go_right
    cmp byte [snake_dir], 2
    je .go_down
    cmp byte [snake_dir], 3
    je .go_left

.go_up:
    dec ah
    jmp .apply_pos
.go_right:
    inc al
    jmp .apply_pos
.go_down:
    inc ah
    jmp .apply_pos
.go_left:
    dec al

.apply_pos:
    cmp al, 80
    jae .game_over
    cmp ah, 25
    jae .game_over
    mov [snake_x], al
    mov [snake_y], ah

    mov cl, [snake_len]
    dec cl
    xor ch, ch
    mov si, 1
.check_self:
    mov al, [snake_x]
    cmp al, [snake_x + si]
    jne .next_seg
    mov ah, [snake_y]
    cmp ah, [snake_y + si]
    je .game_over
.next_seg:
    inc si
    loop .check_self

    mov al, [snake_x]
    cmp al, [apple_x]
    jne .game_loop
    mov al, [snake_y]
    cmp al, [apple_y]
    jne .game_loop

    cmp byte [snake_len], 60
    jae .spawn_apple
    inc byte [snake_len]

.spawn_apple:
    mov ah, 0x00
    int 0x1a
    mov ax, dx
    and ax, 0x00FF
    xor dx, dx
    mov bx, 76
    div bx
    inc dl
    inc dl
    mov [apple_x], dl

    mov ah, 0x00
    int 0x1a
    mov ax, dx
    shr ax, 4
    and ax, 0x00FF
    xor dx, dx
    mov bx, 21
    div bx
    inc dl
    inc dl
    mov [apple_y], dl

    jmp .game_loop

.game_over:
    call clear_screen
    mov si, snake_over_msg
    call print_string
    xor ax, ax
    int 0x16

.exit_game:
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10
    call clear_screen

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; время
do_time:
    push ax
    push cx
    push dx
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
    pop dx
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
    mov bx, 10
    xor cx, cx
    cmp ax, 0
    jne .convert
    mov al, '0'
    push ax
    push bx
    push cx
    push dx
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0F
    mov cx, 1
    int 0x10
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop dx
    pop cx
    pop bx
    pop ax
    jmp .done
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
    push ax
    push bx
    push cx
    push dx
    mov ah, 0x09
    mov bh, 0
    mov bl, 0x0F
    mov cx, 1
    int 0x10
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    pop dx
    pop cx
    pop bx
    pop ax
    loop .print
.done:
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
    pop ax
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
    pop ax
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
    xor cx, cx
.skip_spaces:
    mov al, [si]
    cmp al, ' '
    jne .loop
    inc si
    jmp .skip_spaces
.loop:
    lodsb
    cmp al, '0'
    jb .done
    cmp al, '9'
    ja .done
    sub al, '0'
    xor ah, ah
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
                db '  snake     - play snake game', 0x0d, 0x0a
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
neo_bios_ok     db 'IBM PC/AT compatible', 0x0d, 0x0a, 0

; калькулятор функции
calc_prompt     db 'Calc: ', 0
calc_result     db '= ', 0
calc_error      db 'Error!', 0x0d, 0x0a, 0
calc_divzero    db 'Division by zero!', 0x0d, 0x0a, 0

; змейка данные
snake_over_msg  db 'Game Over! Press any key...', 0x0d, 0x0a, 0
snake_len       db 3
snake_dir       db 1
apple_x         db 20
apple_y         db 8
snake_x         times 64 db 0
snake_y         times 64 db 0

; команды (имена)
cmd_help        db 'help', 0
cmd_time        db 'time', 0
cmd_clear       db 'clear', 0
cmd_info        db 'info', 0
cmd_reboot      db 'reboot', 0
cmd_neofetch    db 'neofetch', 0
cmd_calc        db 'calc', 0
cmd_snake       db 'snake', 0

; буферы
input_buffer    times 64 db 0
num_buffer      times 16 db 0
