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

    call set_theme_black
    call clear_screen
    call boot_menu

; =============================================
; BOOT MENU
; =============================================

boot_menu:
    push ax
    push bx
    push cx
    push dx
    push si

    mov byte [menu_selected], 0

.menu_loop:
    call clear_screen
    call menu_draw

    xor ax, ax
    int 0x16

    cmp al, 27
    je .go_visual
    cmp ah, 0x48
    je .up
    cmp ah, 0x50
    je .down
    cmp al, 0x0d
    je .select
    jmp .menu_loop

.up:
    cmp byte [menu_selected], 0
    je .menu_loop
    dec byte [menu_selected]
    jmp .menu_loop

.down:
    cmp byte [menu_selected], 1
    je .menu_loop
    inc byte [menu_selected]
    jmp .menu_loop

.select:
    cmp byte [menu_selected], 0
    je .go_visual
    call clear_screen
    mov si, banner
    call print_string
    call shell
    jmp .menu_loop

.go_visual:
    call do_visual16
    jmp .menu_loop

.exit:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

menu_draw:
    push si
    call clear_screen

    mov si, menu_top
    call print_string
    mov si, menu_title
    call print_string
    mov si, menu_sep
    call print_string

    cmp byte [menu_selected], 0
    jne .item1_normal
    mov si, menu_item1_sel
    call print_string
    jmp .item2
.item1_normal:
    mov si, menu_item1
    call print_string

.item2:
    cmp byte [menu_selected], 1
    jne .item2_normal
    mov si, menu_item2_sel
    call print_string
    jmp .done
.item2_normal:
    mov si, menu_item2
    call print_string

.done:
    mov si, menu_bot
    call print_string
    mov si, menu_hint
    call print_string
    pop si
    ret

; =============================================
; THEME VARIABLES
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
; CORE FUNCTIONS
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
; TEXT EDITOR
; =============================================

do_editor:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    call clear_screen

    ; Top status bar
    mov ah, 0x02
    xor bh, bh
    xor dx, dx
    int 0x10

    mov bl, 0x70
    mov si, editor_bar
    call print_attr

    mov word [editor_len], 0

    ; Cursor to text area (row 2, col 0)
    mov ah, 0x02
    xor bh, bh
    mov dh, 2
    mov dl, 0
    int 0x10

    ; Show cursor
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10

.editor_loop:
    xor ax, ax
    int 0x16

    cmp al, 27                  ; ESC - exit
    je .editor_exit

    cmp al, 0x08                ; Backspace
    je .editor_backspace

    cmp al, 0x0D                ; Enter
    je .editor_enter

    ; Printable ASCII only (32..126)
    cmp al, 32
    jb .editor_loop
    cmp al, 126
    ja .editor_loop

    cmp word [editor_len], 1020
    jae .editor_loop

    ; Save char to buffer
    mov di, editor_buffer
    add di, [editor_len]
    stosb
    inc word [editor_len]

    ; Print char
    push ax
    mov ah, 0x09
    xor bh, bh
    mov bl, [theme_color]
    mov cx, 1
    int 0x10
    pop ax

    ; Advance cursor
    mov ah, 0x03
    xor bh, bh
    int 0x10
    inc dl
    cmp dl, 80
    jb .set_cur
    xor dl, dl
    inc dh
    cmp dh, 24
    jb .set_cur
    call editor_scroll
    mov dh, 23
.set_cur:
    mov ah, 0x02
    xor bh, bh
    int 0x10
    jmp .editor_loop

.editor_enter:
    cmp word [editor_len], 1018
    jae .editor_loop

    mov di, editor_buffer
    add di, [editor_len]
    mov al, 0x0D
    stosb
    mov al, 0x0A
    stosb
    add word [editor_len], 2

    mov ah, 0x03
    xor bh, bh
    int 0x10
    xor dl, dl
    inc dh
    cmp dh, 24
    jb .set_cur_enter
    call editor_scroll
    mov dh, 23
.set_cur_enter:
    mov ah, 0x02
    xor bh, bh
    int 0x10
    jmp .editor_loop

.editor_backspace:
    cmp word [editor_len], 0
    je .editor_loop

    mov di, editor_buffer
    add di, [editor_len]
    dec di
    cmp byte [di], 0x0A
    jne .normal_bs

    dec word [editor_len]
    dec di
    cmp byte [di], 0x0D
    jne .skip_cr
    dec word [editor_len]
.skip_cr:
    mov ah, 0x03
    xor bh, bh
    int 0x10
    cmp dh, 2
    jbe .editor_loop
    dec dh
    mov dl, 79
    mov ah, 0x02
    xor bh, bh
    int 0x10
    jmp .editor_loop

.normal_bs:
    dec word [editor_len]
    mov ah, 0x03
    xor bh, bh
    int 0x10
    cmp dl, 0
    je .wrap_bs
    dec dl
    mov ah, 0x02
    xor bh, bh
    int 0x10
    mov ax, 0x0920
    mov bl, [theme_color]
    mov cx, 1
    int 0x10
    jmp .editor_loop

.wrap_bs:
    cmp dh, 2
    jbe .editor_loop
    dec dh
    mov dl, 79
    mov ah, 0x02
    xor bh, bh
    int 0x10
    mov ax, 0x0920
    mov bl, [theme_color]
    mov cx, 1
    int 0x10
    jmp .editor_loop

.editor_exit:
    mov di, editor_buffer
    add di, [editor_len]
    mov byte [di], 0

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

editor_scroll:
    push ax
    push bx
    push cx
    push dx
    mov ax, 0x0601              ; Scroll up 1 line
    mov bh, [theme_color]
    mov ch, 2                   ; Preserve top status bar
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; =============================================
; COMMAND SHELL (TEXT MODE)
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

    mov di, cmd_edit
    call strcmp
    jc .edit

    mov di, cmd_visual16
    call strcmp
    jc .visual16

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

.edit:
    call do_editor
    call clear_screen
    mov si, banner
    call print_string
    jmp shell

.visual16:
    call do_visual16
    call clear_screen
    mov si, banner
    call print_string
    jmp shell

; =============================================
; COMMAND IMPLEMENTATIONS
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
    mov si, colon
    call print_string
    mov al, dh
    call print_hex
    call newline
    pop si
    pop dx
    pop cx
    pop ax
    ret

do_time_real:
    push ax
    push cx
    push dx
    push si
    mov ah, 0x02
    int 0x1a
    mov al, ch
    call print_hex
    mov si, colon
    call print_string
    mov al, cl
    call print_hex
    mov si, colon
    call print_string
    mov al, dh
    call print_hex
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

do_neofetch:
    push si
    push ax
    push bx

    mov bl, [theme_color]
    cmp bl, 0x0F
    je .dark

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
; SNAKE GAME
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
; VISUAL16 v0.6
; =============================================

do_visual16:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov byte [v16_selected], 0

.visual_loop:
    call v16_draw_screen
    call v16_wait_key

    cmp al, 27
    je .exit
    cmp ah, 0x48
    je .up
    cmp ah, 0x50
    je .down
    cmp al, 0x0d
    je .select
    jmp .visual_loop

.up:
    cmp byte [v16_selected], 0
    je .visual_loop
    dec byte [v16_selected]
    jmp .visual_loop

.down:
    cmp byte [v16_selected], 7
    je .visual_loop
    inc byte [v16_selected]
    jmp .visual_loop

.select:
    cmp byte [v16_selected], 0
    je .app_clock
    cmp byte [v16_selected], 1
    je .app_hello
    cmp byte [v16_selected], 2
    je .app_info
    cmp byte [v16_selected], 3
    je .app_calc
    cmp byte [v16_selected], 4
    je .app_snake
    cmp byte [v16_selected], 5
    je .app_neofetch
    cmp byte [v16_selected], 6
    je .app_editor
    cmp byte [v16_selected], 7
    je .exit
    jmp .visual_loop

.app_clock:
    call v16_show_clock
    jmp .visual_loop
.app_hello:
    call v16_show_hello
    jmp .visual_loop
.app_info:
    call v16_show_info
    jmp .visual_loop
.app_calc:
    call v16_show_calc
    jmp .visual_loop
.app_snake:
    call v16_show_snake
    jmp .visual_loop
.app_neofetch:
    call v16_show_neofetch
    jmp .visual_loop
.app_editor:
    call do_editor
    jmp .visual_loop

.exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

v16_draw_screen:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    call clear_screen

    mov si, v16_top
    call print_string
    mov si, v16_title_line
    call print_string
    mov si, v16_sep
    call print_string

    cmp byte [v16_selected], 0
    jne .i1n
    mov si, v16_item1_sel
    call print_string
    jmp .i2
.i1n:
    mov si, v16_item1
    call print_string

.i2:
    cmp byte [v16_selected], 1
    jne .i2n
    mov si, v16_item2_sel
    call print_string
    jmp .i3
.i2n:
    mov si, v16_item2
    call print_string

.i3:
    cmp byte [v16_selected], 2
    jne .i3n
    mov si, v16_item3_sel
    call print_string
    jmp .i4
.i3n:
    mov si, v16_item3
    call print_string

.i4:
    cmp byte [v16_selected], 3
    jne .i4n
    mov si, v16_item4_sel
    call print_string
    jmp .i5
.i4n:
    mov si, v16_item4
    call print_string

.i5:
    cmp byte [v16_selected], 4
    jne .i5n
    mov si, v16_item5_sel
    call print_string
    jmp .i6
.i5n:
    mov si, v16_item5
    call print_string

.i6:
    cmp byte [v16_selected], 5
    jne .i6n
    mov si, v16_item6_sel
    call print_string
    jmp .i7
.i6n:
    mov si, v16_item6
    call print_string

.i7:
    cmp byte [v16_selected], 6
    jne .i7n
    mov si, v16_item7_sel
    call print_string
    jmp .i8
.i7n:
    mov si, v16_item7
    call print_string

.i8:
    cmp byte [v16_selected], 7
    jne .i8n
    mov si, v16_item8_sel
    call print_string
    jmp .bot
.i8n:
    mov si, v16_item8
    call print_string

.bot:
    mov si, v16_bot
    call print_string
    mov si, v16_hint
    call print_string

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

v16_wait_key:
    xor ax, ax
    int 0x16
    ret

; =============================================
; V16 APPS
; =============================================

v16_show_clock:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

.clock_loop:
    call clear_screen
    mov si, v16_clock_top
    call print_string
    mov si, v16_clock_title
    call print_string
    mov si, v16_clock_sep
    call print_string
    mov si, v16_clock_empty
    call print_string
    mov si, v16_clock_label
    call print_string
    call do_time_real
    mov si, v16_clock_pad
    call print_string
    mov si, v16_clock_empty
    call print_string
    mov si, v16_clock_hint
    call print_string
    mov si, v16_clock_bot
    call print_string

    mov cx, 0x000F
    mov dx, 0x4240
    mov ah, 0x86
    int 0x15

    mov ah, 0x01
    int 0x16
    jz .clock_loop
    xor ax, ax
    int 0x16

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

v16_show_hello:
    push si
    call clear_screen
    mov si, v16_hello_screen
    call print_string
    xor ax, ax
    int 0x16
    pop si
    ret

v16_show_info:
    push si
    call clear_screen
    mov si, v16_info_screen
    call print_string
    xor ax, ax
    int 0x16
    pop si
    ret

v16_show_calc:
    push si
    call clear_screen
    mov si, v16_calc_screen
    call print_string
    call do_calc
    xor ax, ax
    int 0x16
    pop si
    ret

v16_show_snake:
    call do_snake
    ret

v16_show_neofetch:
    push si
    call clear_screen
    mov si, v16_neofetch_screen
    call print_string
    call do_neofetch
    mov si, v16_press_key
    call print_string
    xor ax, ax
    int 0x16
    pop si
    ret

; =============================================
; MENU DATA
; =============================================

menu_selected db 0

menu_top:
db 0x0d, 0x0a
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a, 0

menu_title:
db 0xBA, '                    microDOS v0.6 Boot Menu                 ', 0xBA, 0x0d, 0x0a, 0

menu_sep:
db 0xCC
times 60 db 0xCD
db 0xB9, 0x0d, 0x0a, 0

menu_item1:
db 0xBA, '    [ 1 ]  Visual16 (All Apps)                              ', 0xBA, 0x0d, 0x0a, 0
menu_item1_sel:
db 0xBA, ' >> [ 1 ]  Visual16 (All Apps)                              ', 0xBA, 0x0d, 0x0a, 0

menu_item2:
db 0xBA, '    [ 2 ]  Text Mode (Command Shell)                        ', 0xBA, 0x0d, 0x0a, 0
menu_item2_sel:
db 0xBA, ' >> [ 2 ]  Text Mode (Command Shell)                        ', 0xBA, 0x0d, 0x0a, 0

menu_bot:
db 0xC8
times 60 db 0xCD
db 0xBC, 0x0d, 0x0a, 0

menu_hint:
db 0x0d, 0x0a
db '  Use UP/DOWN arrows, ENTER to select', 0x0d, 0x0a, 0

; =============================================
; VISUAL16 DATA
; =============================================

v16_selected db 0

v16_top:
db 0x0d, 0x0a
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a, 0

v16_title_line:
db 0xBA, '                    microDOS Visual16 v0.6                  ', 0xBA, 0x0d, 0x0a, 0

v16_sep:
db 0xCC
times 60 db 0xCD
db 0xB9, 0x0d, 0x0a, 0

v16_item1:
db 0xBA, '    [ 1 ]  Clock                                            ', 0xBA, 0x0d, 0x0a, 0
v16_item1_sel:
db 0xBA, ' >> [ 1 ]  Clock                                            ', 0xBA, 0x0d, 0x0a, 0

v16_item2:
db 0xBA, '    [ 2 ]  Hello                                            ', 0xBA, 0x0d, 0x0a, 0
v16_item2_sel:
db 0xBA, ' >> [ 2 ]  Hello                                            ', 0xBA, 0x0d, 0x0a, 0

v16_item3:
db 0xBA, '    [ 3 ]  Info                                             ', 0xBA, 0x0d, 0x0a, 0
v16_item3_sel:
db 0xBA, ' >> [ 3 ]  Info                                             ', 0xBA, 0x0d, 0x0a, 0

v16_item4:
db 0xBA, '    [ 4 ]  Calc                                             ', 0xBA, 0x0d, 0x0a, 0
v16_item4_sel:
db 0xBA, ' >> [ 4 ]  Calc                                             ', 0xBA, 0x0d, 0x0a, 0

v16_item5:
db 0xBA, '    [ 5 ]  Snake                                            ', 0xBA, 0x0d, 0x0a, 0
v16_item5_sel:
db 0xBA, ' >> [ 5 ]  Snake                                            ', 0xBA, 0x0d, 0x0a, 0

v16_item6:
db 0xBA, '    [ 6 ]  Neofetch                                         ', 0xBA, 0x0d, 0x0a, 0
v16_item6_sel:
db 0xBA, ' >> [ 6 ]  Neofetch                                         ', 0xBA, 0x0d, 0x0a, 0

v16_item7:
db 0xBA, '    [ 7 ]  Editor                                           ', 0xBA, 0x0d, 0x0a, 0
v16_item7_sel:
db 0xBA, ' >> [ 7 ]  Editor                                           ', 0xBA, 0x0d, 0x0a, 0

v16_item8:
db 0xBA, '    [ 8 ]  Exit to Text Mode                                ', 0xBA, 0x0d, 0x0a, 0
v16_item8_sel:
db 0xBA, ' >> [ 8 ]  Exit to Text Mode                                ', 0xBA, 0x0d, 0x0a, 0

v16_bot:
db 0xC8
times 60 db 0xCD
db 0xBC, 0x0d, 0x0a, 0

v16_hint:
db 0x0d, 0x0a
db '  UP/DOWN - select, ENTER - open, ESC - exit to text', 0x0d, 0x0a, 0

; Clock
v16_clock_top:
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a, 0
v16_clock_title:
db 0xBA, '                       CLOCK APP                            ', 0xBA, 0x0d, 0x0a, 0
v16_clock_sep:
db 0xCC
times 60 db 0xCD
db 0xB9, 0x0d, 0x0a, 0
v16_clock_empty:
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a, 0
v16_clock_label:
db 0xBA, '                       Time: ', 0
v16_clock_pad:
db '                        ', 0xBA, 0x0d, 0x0a, 0
v16_clock_hint:
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xBA, '                 Press any key to return...                 ', 0xBA, 0x0d, 0x0a, 0
v16_clock_bot:
db 0xC8
times 60 db 0xCD
db 0xBC, 0x0d, 0x0a, 0

; Hello
v16_hello_screen:
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a
db 0xBA, '                       HELLO APP                            ', 0xBA, 0x0d, 0x0a
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xBA, '                 Welcome to microDOS!                       ', 0xBA, 0x0d, 0x0a
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xBA, '                 Press any key to return...                 ', 0xBA, 0x0d, 0x0a
db 0xC8
times 60 db 0xCD
db 0xBC, 0x0d, 0x0a, 0

; Info
v16_info_screen:
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a
db 0xBA, '                      SYSTEM INFO                           ', 0xBA, 0x0d, 0x0a
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xBA, '                     microDOS v0.6                          ', 0xBA, 0x0d, 0x0a
db 0xBA, '                     16-bit Real Mode                       ', 0xBA, 0x0d, 0x0a
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xBA, '                 Press any key to return...                 ', 0xBA, 0x0d, 0x0a
db 0xC8
times 60 db 0xCD
db 0xBC, 0x0d, 0x0a, 0

; Calc
v16_calc_screen:
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a
db 0xBA, '                    CALCULATOR APP                          ', 0xBA, 0x0d, 0x0a
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xC8
times 60 db 0xCD
db 0xBC, 0x0d, 0x0a, 0

; Neofetch
v16_neofetch_screen:
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a
db 0xBA, '                    NEOFETCH APP                            ', 0xBA, 0x0d, 0x0a
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xC8
times 60 db 0xCD
db 0xBC, 0x0d, 0x0a, 0

v16_press_key:
db 0x0d, 0x0a, 'Press any key to return...', 0

; Editor bar
editor_bar:
db ' microDOS Text Editor | ESC: Exit to Shell/Menu                               ', 0

; =============================================
; MAIN DATA
; =============================================

banner          db 'microDOS v0.6 - 16-bit OS', 0x0d, 0x0a
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
                db '  edit      - simple text editor', 0x0d, 0x0a
                db '  visual16  - enter Visual16 shell', 0x0d, 0x0a
                db '  theme white/black - change theme', 0x0d, 0x0a
                db '  reboot    - restart computer', 0x0d, 0x0a, 0
time_msg        db 'time: ', 0
colon           db ':', 0
reboot_msg      db 'reboot...', 0x0d, 0x0a, 0
info_msg        db 'microDOS v0.6', 0x0d, 0x0a
                db '16-bit, Real mode', 0x0d, 0x0a
                db 'written in NASM', 0x0d, 0x0a, 0
crlf            db 0x0d, 0x0a, 0

neo_logo        db 0x0d, 0x0a
                db '_     _  ____ ____  ____  ____  ____  ____ ', 0x0d, 0x0a
                db '/ \__/|/ \/   _Y  __\/  _ \/  _ \/  _ \/ ___\\', 0x0d, 0x0a
                db '| |\/||| ||  / |  \/|| / \|| | \|| / \||    \\', 0x0d, 0x0a
                db '| |  ||| ||  \_|    /| \_/|| |_/|| \_/|\___ |', 0x0d, 0x0a
                db '\_/  \|\_/\____|_/\_\\____/\____/\____/\____/', 0x0d, 0x0a
                db 0
neo_os          db 'OS:           microDOS 0.6', 0x0d, 0x0a, 0
neo_kernel      db 'Kernel:       16-bit x86', 0x0d, 0x0a, 0
neo_arch        db 'Architecture: 8086/80286', 0x0d, 0x0a, 0
neo_time_label  db 'Time:         ', 0
neo_mem_label   db 'Memory:       ', 0
neo_mem_unit    db ' KB', 0x0d, 0x0a, 0
neo_bios_label  db 'BIOS:         ', 0
neo_bios_ok     db 'IBM PC/AT compatible', 0x0d, 0x0a, 0

calc_prompt     db 'Calc: ', 0
calc_result     db '= ', 0
calc_error      db 'Error!', 0x0d, 0x0a, 0
calc_divzero    db 'Division by zero!', 0x0d, 0x0a, 0

theme_white     db 'white', 0
theme_black     db 'black', 0
theme_ok_white  db 'Theme: WHITE (black on white)', 0x0d, 0x0a, 0
theme_ok_black  db 'Theme: BLACK (white on black)', 0x0d, 0x0a, 0
theme_unknown   db 'Unknown theme. Use: theme white / theme black', 0x0d, 0x0a, 0
theme_help      db 'Usage: theme white / theme black', 0x0d, 0x0a, 0

snake_over_msg  db 'Game Over! Press any key...', 0x0d, 0x0a, 0
snake_len       db 4
snake_dir       db 1
apple_x         db 20
apple_y         db 8
snake_x         times 64 db 0
snake_y         times 64 db 0

cmd_help        db 'help', 0
cmd_time        db 'time', 0
cmd_clear       db 'clear', 0
cmd_info        db 'info', 0
cmd_reboot      db 'reboot', 0
cmd_neofetch    db 'neofetch', 0
cmd_calc        db 'calc', 0
cmd_snake       db 'snake', 0
cmd_theme       db 'theme', 0
cmd_edit        db 'edit', 0
cmd_visual16    db 'visual16', 0

input_buffer    times 64 db 0
num_buffer      times 16 db 0

editor_len      dw 0
editor_buffer   times 1024 db 0
