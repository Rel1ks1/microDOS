[org 0x0000]
[bits 16]

start:
    cli
    cld
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFF00
    sti

    call clear_screen
    call auto_theme          ; автоматически выбираем тему по времени
    mov si, banner
    call print_string
    call shell

; =============================================
; ПЕРЕМЕННЫЕ ТЕМЫ
; =============================================

theme_color db 0x0F
theme_bg    db 0x00

set_theme_white:
    mov byte [theme_color], 0x70
    mov byte [theme_bg], 0x07
    ret

set_theme_black:
    mov byte [theme_color], 0x0F
    mov byte [theme_bg], 0x00
    ret

; =============================================
; АВТОМАТИЧЕСКАЯ ТЕМА (по времени)
; =============================================

auto_theme:
    push ax
    push cx
    push si

    ; Получаем время (AH=0x02, CH=часы BCD, CL=минуты BCD)
    mov ah, 0x02
    int 0x1a

    ; Конвертируем BCD часы в обычное число
    mov al, ch
    call bcd_to_bin
    mov ch, al          ; CH = часы (0-23)

    ; Если часы >= 6 и < 18 → белая тема, иначе чёрная
    cmp ch, 6
    jb .night
    cmp ch, 18
    jb .day

.night:
    call set_theme_black
    mov si, auto_black_msg
    call print_string
    jmp .done

.day:
    call set_theme_white
    mov si, auto_white_msg
    call print_string

.done:
    pop si
    pop cx
    pop ax
    ret

; Конвертация BCD в двоичное число (AL = BCD, возвращает AX)
bcd_to_bin:
    push bx
    mov bl, al
    and al, 0x0F          ; единицы
    mov bh, bl
    shr bh, 4             ; десятки
    mov bl, 10
    mul bl                ; AL = десятки * 10
    add al, bh            ; AL = десятки*10 + единицы
    pop bx
    ret

; =============================================
; БАЗОВЫЕ ФУНКЦИИ
; =============================================

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
    mov bl, [theme_color]
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
    push ax
    push bx
    push cx
    push dx
    mov ax, 0x0601
    mov bh, [theme_color]
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    mov dh, 24
    pop dx
    pop cx
    pop bx
    pop ax
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

; Печать с заданным атрибутом
print_attr:
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
    push ax
    push bx
    push cx
    push dx
    mov ax, 0x0601
    mov bh, 0x07
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    mov dh, 24
    pop dx
    pop cx
    pop bx
    pop ax
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
    push bx
    push cx
    push dx
    mov ax, 0x0600
    mov bh, [theme_color]
    xor cx, cx
    mov dx, 0x184F
    int 0x10
    mov ah, 0x02
    xor bh, bh
    xor dx, dx
    int 0x10
    pop dx
    pop cx
    pop bx
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
    mov bl, [theme_color]
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
    mov bl, [theme_color]
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
    mov bl, [theme_color]
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
    mov bl, [theme_color]
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
    mov bl, [theme_color]
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

; =============================================
; КОМАНДНАЯ ОБОЛОЧКА
; =============================================

shell:
    mov si, prompt
    call print_string
    call read_line

    mov si, input_buffer
    cmp byte [si], 0
    je shell

    mov di, cmd_theme
    call strcmp
    jc .theme_cmd

    mov di, cmd_help
    call strcmp
    jc .help

    mov di, cmd_time
    call strcmp
    jc .time

    mov di, cmd_clear
    call strcmp
    jc .clear

    mov di, cmd_info
    call strcmp
    jc .info

    mov di, cmd_reboot
    call strcmp
    jc .reboot

    mov di, cmd_neofetch
    call strcmp
    jc .neofetch

    mov di, cmd_calc
    call strcmp
    jc .calc

    mov di, cmd_snake
    call strcmp
    jc .snake

    mov si, unknown_msg
    call print_string
    jmp shell

.theme_cmd:
    call do_theme
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

; =============================================
; РЕАЛИЗАЦИЯ КОМАНД
; =============================================

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

do_info:
    push si
    mov si, info_msg
    call print_string
    pop si
    ret

; =============================================
; NEOFETCH
; =============================================

do_neofetch:
    push si
    push ax
    push bx

    mov bl, [theme_color]
    cmp bl, 0x0F
    je .dark

    ; ===== БЕЛАЯ ТЕМА =====
    mov bl, 0x7A
    mov si, neo_logo
    call print_attr

    mov bl, 0x7B
    mov si, neo_os
    call print_attr

    mov bl, 0x7D
    mov si, neo_kernel
    call print_attr

    mov bl, 0x79
    mov si, neo_arch
    call print_attr

    mov bl, 0x7B
    mov si, neo_time_label
    call print_attr
    call do_time

    mov bl, 0x7D
    mov si, neo_mem_label
    call print_attr
    int 0x12
    call print_number_ax
    mov si, neo_mem_unit
    call print_string

    mov bl, 0x7A
    mov si, neo_bios_label
    call print_attr
    mov si, neo_bios_ok
    call print_string

    jmp .done

.dark:
    ; ===== ЧЁРНАЯ ТЕМА =====
    mov bl, 0x0B
    mov si, neo_logo
    call print_attr

    mov bl, 0x0E
    mov si, neo_os
    call print_attr

    mov bl, 0x0C
    mov si, neo_kernel
    call print_attr

    mov bl, 0x0A
    mov si, neo_arch
    call print_attr

    mov bl, 0x09
    mov si, neo_time_label
    call print_attr
    call do_time

    mov bl, 0x0D
    mov si, neo_mem_label
    call print_attr
    int 0x12
    call print_number_ax
    mov si, neo_mem_unit
    call print_string

    mov bl, 0x07
    mov si, neo_bios_label
    call print_attr
    mov si, neo_bios_ok
    call print_string

.done:
    call newline
    call newline

    pop bx
    pop ax
    pop si
    ret

; =============================================
; КАЛЬКУЛЯТОР
; =============================================

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
    call parse_number
    push ax

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

; =============================================
; ТЕМА
; =============================================

do_theme:
    push si
    push di

    mov si, input_buffer
    add si, 6

.skip_spaces:
    cmp byte [si], ' '
    je .skip_spaces_next
    jmp .check
.skip_spaces_next:
    inc si
    jmp .skip_spaces

.check:
    cmp byte [si], 0
    je .show_help

    mov di, theme_white
    call strcmp
    jc .set_white

    mov di, theme_black
    call strcmp
    jc .set_black

    mov si, theme_unknown
    call print_string
    jmp .done

.show_help:
    mov si, theme_help
    call print_string
    jmp .done

.set_white:
    call set_theme_white
    call clear_screen
    mov si, banner
    call print_string
    mov si, theme_ok_white
    call print_string
    jmp .done

.set_black:
    call set_theme_black
    call clear_screen
    mov si, banner
    call print_string
    mov si, theme_ok_black
    call print_string

.done:
    pop di
    pop si
    ret

; =============================================
; ЗМЕЙКА
; =============================================

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

    mov byte [snake_len], 4
    mov byte [snake_dir], 1
    mov byte [snake_x], 40
    mov byte [snake_y], 12
    mov byte [snake_x + 1], 39
    mov byte [snake_y + 1], 12
    mov byte [snake_x + 2], 38
    mov byte [snake_y + 2], 12
    mov byte [snake_x + 3], 37
    mov byte [snake_y + 3], 12

    call spawn_apple

.game_loop:
    call draw_apple
    call draw_snake

    mov cx, 1
    mov dx, 0x86A0
    mov ah, 0x86
    int 0x15

    mov ah, 0x01
    int 0x16
    jz .move
    xor ax, ax
    int 0x16
    cmp al, 27
    je .exit
    cmp ah, 0x48
    je .up
    cmp ah, 0x50
    je .down
    cmp ah, 0x4B
    je .left
    cmp ah, 0x4D
    je .right
    jmp .move

.up:
    cmp byte [snake_dir], 2
    je .move
    mov byte [snake_dir], 0
    jmp .move
.right:
    cmp byte [snake_dir], 3
    je .move
    mov byte [snake_dir], 1
    jmp .move
.down:
    cmp byte [snake_dir], 0
    je .move
    mov byte [snake_dir], 2
    jmp .move
.left:
    cmp byte [snake_dir], 1
    je .move
    mov byte [snake_dir], 3

.move:
    call clear_tail

    mov cl, [snake_len]
    dec cl
    mov si, cx
.shift:
    dec si
    mov al, [snake_x + si]
    mov [snake_x + si + 1], al
    mov al, [snake_y + si]
    mov [snake_y + si + 1], al
    cmp si, 0
    jne .shift

    mov al, [snake_x]
    mov ah, [snake_y]
    cmp byte [snake_dir], 0
    je .up_move
    cmp byte [snake_dir], 1
    je .right_move
    cmp byte [snake_dir], 2
    je .down_move
    cmp byte [snake_dir], 3
    je .left_move

.up_move:
    dec ah
    jmp .check
.right_move:
    inc al
    jmp .check
.down_move:
    inc ah
    jmp .check
.left_move:
    dec al

.check:
    cmp al, 79
    jae .game_over
    cmp ah, 24
    jae .game_over
    mov [snake_x], al
    mov [snake_y], ah

    mov cl, [snake_len]
    dec cl
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
    jae .spawn
    inc byte [snake_len]
.spawn:
    call spawn_apple
    jmp .game_loop

.game_over:
    call clear_screen
    mov si, snake_over_msg
    call print_string
    xor ax, ax
    int 0x16

.exit:
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

clear_tail:
    push ax
    push bx
    push cx
    push dx
    push di
    xor ah, ah
    mov al, [snake_len]
    dec al
    mov si, ax
    mov ah, 0x02
    mov bh, 0
    mov dl, [snake_x + si]
    mov dh, [snake_y + si]
    int 0x10
    mov ax, 0x0920
    mov bl, [theme_color]
    mov cx, 1
    int 0x10
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_snake:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    xor si, si
    mov cl, [snake_len]
    xor ch, ch
.draw:
    mov ah, 0x02
    mov bh, 0
    mov dl, [snake_x + si]
    mov dh, [snake_y + si]
    int 0x10
    mov ax, 0x0923
    mov bl, 0x0A
    push cx
    mov cx, 1
    int 0x10
    pop cx
    inc si
    loop .draw
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_apple:
    push ax
    push bx
    push cx
    push dx
    push di
    mov ah, 0x02
    mov bh, 0
    mov dl, [apple_x]
    mov dh, [apple_y]
    int 0x10
    mov ax, 0x092A
    mov bl, 0x0C
    mov cx, 1
    int 0x10
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

spawn_apple:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
.generate:
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

    xor si, si
    mov cl, [snake_len]
    xor ch, ch
.check:
    mov al, [apple_x]
    cmp al, [snake_x + si]
    jne .next
    mov al, [apple_y]
    cmp al, [snake_y + si]
    je .generate
.next:
    inc si
    loop .check
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; =============================================
; ДАННЫЕ
; =============================================

banner          db 'microDOS v0.5 - 16-bit OS', 0x0d, 0x0a
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
                db '  theme white/black  - change theme (auto by time)', 0x0d, 0x0a
                db '  reboot    - restart computer', 0x0d, 0x0a, 0
time_msg        db 'time: ', 0
colon           db ':', 0
reboot_msg      db 'reboot...', 0x0d, 0x0a, 0
info_msg        db 'microDOS v0.5', 0x0d, 0x0a
                db '16-bit, Real mode', 0x0d, 0x0a
                db 'written in NASM', 0x0d, 0x0a, 0
crlf            db 0x0d, 0x0a, 0

; Автотема сообщения
auto_white_msg  db 'Auto theme: WHITE (Day mode)', 0x0d, 0x0a, 0
auto_black_msg  db 'Auto theme: BLACK (Night mode)', 0x0d, 0x0a, 0

; neofetch
neo_logo        db 0x0d, 0x0a
                db '_      _  ____ ____  ____  ____  ____  ____ ', 0x0d, 0x0a
                db '/ \__/|/ \/   _Y  __\/  _ \/  _ \/  _ \/ ___\\', 0x0d, 0x0a
                db '| |\/||| ||  / |  \/|| / \|| | \|| / \||    \\', 0x0d, 0x0a
                db '| |  ||| ||  \_|    /| \_/|| |_/|| \_/|\___ |', 0x0d, 0x0a
                db '\_/  \|\_/\____|_/\_\\____/\____/\____/\____/', 0x0d, 0x0a
                db 0
neo_os          db 'OS:           microDOS 0.5', 0x0d, 0x0a, 0
neo_kernel      db 'Kernel:       16-bit x86', 0x0d, 0x0a, 0
neo_arch        db 'Architecture: 8086/80286', 0x0d, 0x0a, 0
neo_time_label  db 'Time:         ', 0
neo_mem_label   db 'Memory:       ', 0
neo_mem_unit    db ' KB', 0x0d, 0x0a, 0
neo_bios_label  db 'BIOS:         ', 0
neo_bios_ok     db 'IBM PC/AT compatible', 0x0d, 0x0a, 0

; calc
calc_prompt     db 'Calc: ', 0
calc_result     db '= ', 0
calc_error      db 'Error!', 0x0d, 0x0a, 0
calc_divzero    db 'Division by zero!', 0x0d, 0x0a, 0

; theme
theme_white     db 'white', 0
theme_black     db 'black', 0
theme_ok_white  db 'Theme: WHITE (black on white)', 0x0d, 0x0a, 0
theme_ok_black  db 'Theme: BLACK (white on black)', 0x0d, 0x0a, 0
theme_unknown   db 'Unknown theme. Use: theme white / theme black', 0x0d, 0x0a, 0
theme_help      db 'Usage: theme white / theme black (auto theme by time)', 0x0d, 0x0a, 0

; snake
snake_over_msg  db 'Game Over! Press any key...', 0x0d, 0x0a, 0
snake_len       db 4
snake_dir       db 1
apple_x         db 20
apple_y         db 8
snake_x         times 64 db 0
snake_y         times 64 db 0

; команды
cmd_help        db 'help', 0
cmd_time        db 'time', 0
cmd_clear       db 'clear', 0
cmd_info        db 'info', 0
cmd_reboot      db 'reboot', 0
cmd_neofetch    db 'neofetch', 0
cmd_calc        db 'calc', 0
cmd_snake       db 'snake', 0
cmd_theme       db 'theme', 0

; буферы
input_buffer    times 64 db 0
num_buffer      times 16 db 0