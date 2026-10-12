[org 0x0000]
[bits 16]

start:
    cli
    cld
    mov [cs:boot_drive], dl
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFF00
    sti

    call clear_dir_buffer
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
    call run_autoexec
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
; CLEAR DIR BUFFER
; =============================================
clear_dir_buffer:
    push ax
    push cx
    push di
    mov di, fs_dir_buffer
    mov cx, 512
    xor al, al
    rep stosb
    pop di
    pop cx
    pop ax
    ret

; =============================================
; THEME
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
; CORE I/O
; =============================================

print_char_al:
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
    ret

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
    je .cr
    cmp al, 0x0a
    je .lf
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
.cr:
    mov ah, 0x03
    mov bh, 0
    int 0x10
    mov dl, 0
    mov ah, 0x02
    int 0x10
    jmp .loop
.lf:
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
    je .cr
    cmp al, 0x0a
    je .lf
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
.cr:
    mov ah, 0x03
    mov bh, 0
    int 0x10
    mov dl, 0
    mov ah, 0x02
    int 0x10
    jmp .loop
.lf:
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

starts_with:
    push si
    push di
    push ax
.loop:
    mov al, [di]
    test al, al
    jz .match
    mov al, [si]
    cmp al, [di]
    jne .no
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

copy_string:
    push ax
.loop:
    lodsb
    stosb
    test al, al
    jnz .loop
    pop ax
    ret

; =============================================
; FILE SYSTEM
; =============================================

lba_to_chs:
    push bx
    push bp
    xor dx, dx
    cmp byte [boot_drive], 0x80
    jae .hdd
    mov bx, 18
    mov bp, 2
    jmp .calc
.hdd:
    mov bx, 63
    mov bp, 16
.calc:
    div bx
    inc dl
    mov cl, dl
    xor dx, dx
    div bp
    mov dh, dl
    mov ch, al
    pop bp
    pop bx
    ret

read_sector_lba:
    push ax
    push bx
    push cx
    push dx
    call lba_to_chs
    mov ah, 0x02
    mov al, 1
    mov dl, [boot_drive]
    int 0x13
    pop dx
    pop cx
    pop bx
    pop ax
    ret

write_sector_lba:
    push ax
    push bx
    push cx
    push dx
    call lba_to_chs
    mov ah, 0x03
    mov al, 1
    mov dl, [boot_drive]
    int 0x13
    pop dx
    pop cx
    pop bx
    pop ax
    ret

fs_load_dir:
    push ax
    push bx
    push cx
    push di
    mov di, fs_dir_buffer
    mov cx, 512
    xor al, al
    rep stosb
    mov ax, 1
    mov bx, fs_dir_buffer
    call read_sector_lba
    pop di
    pop cx
    pop bx
    pop ax
    ret

fs_save_dir:
    mov ax, 1
    mov bx, fs_dir_buffer
    call write_sector_lba
    ret

fs_match_name:
    push cx
    push si
    push di
    mov cx, 11
.m_loop:
    mov al, [si]
    mov ah, [di]
    or al, al
    jnz .cmp_direct
    cmp ah, ' '
    je .adv_di
    cmp ah, 0
    je .adv_di
    jmp .no_match
.adv_di:
    inc di
    jmp .check_end
.cmp_direct:
    cmp al, ah
    jne .no_match
    inc si
    inc di
.check_end:
    loop .m_loop
    stc
    jmp .m_done
.no_match:
    clc
.m_done:
    pop di
    pop si
    pop cx
    ret

do_dir:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    call fs_load_dir
    jc .err
    mov si, fs_dir_title
    call print_string
    mov di, fs_dir_buffer
    mov cx, 32
    xor dx, dx
.loop:
    cmp byte [di + 15], 1
    jne .skip
    inc dx
    push cx
    mov cx, 11
    mov si, di
.pname:
    lodsb
    or al, al
    jz .pspace
    call print_char_al
    jmp .pcont
.pspace:
    mov al, ' '
    call print_char_al
.pcont:
    loop .pname
    pop cx
    mov si, fs_col_sep
    call print_string
    mov ax, [di + 13]
    call print_number_ax
    mov si, fs_bytes_lbl
    call print_string
.skip:
    add di, 16
    dec cx
    jnz .loop
    test dx, dx
    jnz .done
    mov si, fs_empty_lbl
    call print_string
    jmp .done
.err:
    mov si, fs_err_read
    call print_string
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

do_type:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov si, fs_prompt_name
    call print_string
    call read_line
    cmp byte [input_buffer], 0
    je .done
    call fs_load_dir
    jc .disk_err
    mov di, fs_dir_buffer
    mov cx, 32
.search:
    cmp byte [di + 15], 1
    jne .next_search
    push cx
    push di
    mov si, input_buffer
    call fs_match_name
    pop di
    pop cx
    jc .found
.next_search:
    add di, 16
    dec cx
    jnz .search
    mov si, fs_not_found
    call print_string
    jmp .done
.found:
    mov ax, [di + 11]
    mov bx, fs_file_buffer
    call read_sector_lba
    jc .disk_err
    inc ax
    add bx, 512
    call read_sector_lba
    mov si, [di + 13]
    cmp si, 1023
    jbe .term_ok
    mov si, 1023
.term_ok:
    mov byte [fs_file_buffer + si], 0
    mov si, fs_file_buffer
    call print_string
    call newline
    jmp .done
.disk_err:
    mov si, fs_err_read
    call print_string
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

do_save:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    cmp word [editor_len], 0
    jne .has_data
    mov si, fs_err_empty_buf
    call print_string
    jmp .done
.has_data:
    mov si, fs_prompt_save
    call print_string
    call read_line
    cmp byte [input_buffer], 0
    je .done
    call fs_load_dir
    jc .disk_err
    mov di, fs_dir_buffer
    mov cx, 32
    mov bx, 0xFFFF
    xor dx, dx
.scan:
    cmp byte [di + 15], 1
    je .check_exist
    cmp bx, 0xFFFF
    jne .advance
    mov bx, dx
    jmp .advance
.check_exist:
    push cx
    push di
    mov si, input_buffer
    call fs_match_name
    pop di
    pop cx
    jc .overwrite
.advance:
    add di, 16
    inc dx
    dec cx
    jnz .scan
    cmp bx, 0xFFFF
    je .disk_full
    mov ax, bx
    shl ax, 4
    mov di, fs_dir_buffer
    add di, ax
    mov dx, bx
.overwrite:
    mov ax, dx
    shl ax, 1
    add ax, 2
    mov [di + 11], ax
    mov ax, [editor_len]
    mov [di + 13], ax
    mov byte [di + 15], 1
    push di
    mov si, input_buffer
    mov cx, 11
.copy_name:
    lodsb
    or al, al
    jz .pad_spaces
    stosb
    loop .copy_name
    jmp .copy_done
.pad_spaces:
    mov al, ' '
    rep stosb
.copy_done:
    pop di
    mov ax, [di + 11]
    mov bx, editor_buffer
    call write_sector_lba
    jc .disk_err
    inc ax
    add bx, 512
    call write_sector_lba
    jc .disk_err
    call fs_save_dir
    jc .disk_err
    mov si, fs_save_ok
    call print_string
    jmp .done
.disk_full:
    mov si, fs_err_full
    call print_string
    jmp .done
.disk_err:
    mov si, fs_err_write
    call print_string
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; =============================================
; EDITOR
; =============================================

do_editor:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    call clear_screen
    mov ah, 0x02
    xor bh, bh
    xor dx, dx
    int 0x10
    mov bl, 0x70
    mov si, editor_bar
    call print_attr
    mov word [editor_len], 0
    mov ah, 0x02
    xor bh, bh
    mov dh, 2
    mov dl, 0
    int 0x10
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10
.editor_loop:
    xor ax, ax
    int 0x16
    cmp al, 27
    je .editor_exit
    cmp al, 0x08
    je .editor_backspace
    cmp al, 0x0D
    je .editor_enter
    cmp al, 32
    jb .editor_loop
    cmp al, 126
    ja .editor_loop
    cmp word [editor_len], 1020
    jae .editor_loop
    mov di, editor_buffer
    add di, [editor_len]
    stosb
    inc word [editor_len]
    push ax
    mov ah, 0x09
    xor bh, bh
    mov bl, [theme_color]
    mov cx, 1
    int 0x10
    pop ax
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
    mov ax, 0x0601
    mov bh, [theme_color]
    mov ch, 2
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
; GRAPHICS
; =============================================

do_graphics:
    push ax
    push bx
    push cx
    push dx
    push es
    push di
    push si
    mov ax, 0x0013
    int 0x10
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov cx, 32000
    mov ax, 0x0101
    rep stosw
    mov dx, 20
.bar_y:
    push dx
    mov ax, dx
    mov bx, 320
    mul bx
    mov di, ax
    pop dx
    xor cx, cx
.bar_x:
    mov al, cl
    mov [es:di], al
    inc di
    inc cx
    cmp cx, 320
    jb .bar_x
    inc dx
    cmp dx, 60
    jb .bar_y
    mov dx, 80
.box_y:
    push dx
    mov ax, dx
    mov bx, 320
    mul bx
    add ax, 110
    mov di, ax
    pop dx
    mov al, 10
    mov cx, 100
    rep stosb
    inc dx
    cmp dx, 150
    jb .box_y
    mov ah, 0x02
    xor bh, bh
    mov dh, 1
    mov dl, 9
    int 0x10
    mov bl, 14
    mov si, gfx_title
    call print_gfx_str
    mov ah, 0x02
    xor bh, bh
    mov dh, 14
    mov dl, 15
    int 0x10
    mov bl, 0
    mov si, gfx_box_text
    call print_gfx_str
    mov ah, 0x02
    xor bh, bh
    mov dh, 22
    mov dl, 7
    int 0x10
    mov bl, 15
    mov si, gfx_hint
    call print_gfx_str
    xor ax, ax
    int 0x16
    mov ax, 0x0003
    int 0x10
    call clear_screen
    pop si
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_gfx_str:
    push ax
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .loop
.done:
    pop ax
    ret

; =============================================
; SHELL
; =============================================

shell:
    mov si, prompt
    call print_string
    call read_line
    mov si, input_buffer
    cmp byte [si], 0
    je shell
    call shell_execute_line
    jmp shell

shell_execute_line:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov si, input_buffer
    cmp byte [si], 0
    je .ret

    mov di, cmd_dir
    call strcmp
    jc .dir
    mov di, cmd_type
    call strcmp
    jc .type
    mov di, cmd_save
    call strcmp
    jc .save
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
    mov di, cmd_gfx
    call strcmp
    jc .gfx
    mov di, cmd_visual16
    call strcmp
    jc .visual16

    mov si, input_buffer
    mov di, cmd_theme
    call starts_with
    jc .theme_cmd

    mov si, input_buffer
    mov di, cmd_run
    call starts_with
    jc .run

    mov si, unknown_msg
    call print_string
    jmp .ret

.dir:
    call do_dir
    jmp .ret
.type:
    call do_type
    jmp .ret
.save:
    call do_save
    jmp .ret
.theme_cmd:
    call do_theme
    jmp .ret
.help:
    mov si, help_msg
    call print_string
    jmp .ret
.time:
    call do_time
    jmp .ret
.clear:
    call clear_screen
    jmp .ret
.info:
    call do_info
    jmp .ret
.reboot:
    mov si, reboot_msg
    call print_string
    int 0x19
.neofetch:
    call do_neofetch
    jmp .ret
.calc:
    call do_calc
    jmp .ret
.snake:
    call do_snake
    jmp .ret
.edit:
    call do_editor
    call clear_screen
    mov si, banner
    call print_string
    jmp .ret
.gfx:
    call do_graphics
    call clear_screen
    mov si, banner
    call print_string
    jmp .ret
.visual16:
    call do_visual16
    call clear_screen
    mov si, banner
    call print_string
    jmp .ret
.run:
    call do_run
    jmp .ret
.ret:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; =============================================
; SCRIPT ENGINE
; =============================================

do_run:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, input_buffer
    add si, 3
.skip_sp:
    cmp byte [si], ' '
    je .next
    cmp byte [si], 0
    je .no_name
    jmp .have
.next:
    inc si
    jmp .skip_sp
.have:
    call fs_load_dir
    jc .disk_err
    mov di, fs_dir_buffer
    mov cx, 32
.search:
    cmp byte [di + 15], 1
    jne .next_entry
    push cx
    push di
    mov si, input_buffer
    add si, 3
.skip2:
    cmp byte [si], ' '
    jne .cmp
    inc si
    jmp .skip2
.cmp:
    call fs_match_name
    pop di
    pop cx
    jc .found
.next_entry:
    add di, 16
    dec cx
    jnz .search
    mov si, run_not_found
    call print_string
    jmp .done

.found:
    mov ax, [di + 11]
    mov bx, script_buffer
    call read_sector_lba
    jc .disk_err
    inc ax
    add bx, 512
    call read_sector_lba
    jc .disk_err
    mov si, [di + 13]
    cmp si, 1023
    jbe .term
    mov si, 1023
.term:
    mov byte [script_buffer + si], 0

    mov byte [var_count], 0
    mov byte [if_depth], 0

    mov word [script_ptr], script_buffer

.line_loop:
    mov si, [script_ptr]
    mov al, [si]
    test al, al
    jz .script_end

    mov di, si
    xor cx, cx
.count_indent:
    mov al, [di]
    cmp al, ' '
    jne .indent_done
    inc di
    inc cx
    jmp .count_indent
.indent_done:
    mov [cur_indent], cx

    mov al, [di]
    cmp al, 0x0D
    je .next_line
    cmp al, 0x0A
    je .next_line
    cmp al, 0
    je .script_end
    cmp al, '#'
    je .next_line

    mov si, di
    mov di, line_buffer
.copy:
    mov al, [si]
    cmp al, 0x0D
    je .copy_done
    cmp al, 0x0A
    je .copy_done
    cmp al, 0
    je .copy_done
    stosb
    inc si
    jmp .copy
.copy_done:
    mov byte [di], 0

    mov si, line_buffer
    mov di, kw_if
    call starts_with
    jc .do_if

    mov si, line_buffer
    mov di, kw_else
    call starts_with
    jc .do_else

    call in_skip
    cmp al, 1
    je .next_line

    mov si, line_buffer
    mov di, kw_print
    call starts_with
    jc .do_print

    mov si, line_buffer
    mov di, kw_input
    call starts_with
    jc .do_input

    call do_assign
    jmp .next_line

.do_if:
    call ends_with_colon
    cmp al, 0
    je .next_line
    mov si, line_buffer
    add si, 3
    mov di, cond_buffer
.copy_cond:
    mov al, [si]
    test al, al
    jz .cond_done
    cmp al, ':'
    je .cond_done
    stosb
    inc si
    jmp .copy_cond
.cond_done:
    mov byte [di], 0

    call in_skip
    cmp al, 1
    je .push_skip_if

    call eval_cond
    mov ah, al
    mov al, [if_depth]
    cmp al, 8
    jae .next_line
    xor bh, bh
    mov bl, al
    mov [if_stack + bx], ah
    inc byte [if_depth]
    jmp .next_line

.push_skip_if:
    mov al, [if_depth]
    cmp al, 8
    jae .next_line
    xor bh, bh
    mov bl, al
    mov byte [if_stack + bx], 1
    inc byte [if_depth]
    jmp .next_line

.do_else:
    call ends_with_colon
    cmp byte [if_depth], 0
    je .next_line
    mov al, [if_depth]
    dec al
    xor bh, bh
    mov bl, al
    mov al, [if_stack + bx]
    xor al, 1
    mov [if_stack + bx], al
    jmp .next_line

.do_print:
    mov si, line_buffer
.find_open:
    mov al, [si]
    test al, al
    jz .next_line
    cmp al, '('
    je .print_args
    inc si
    jmp .find_open
.print_args:
    inc si
    call print_expr_list
    jmp .next_line

.do_input:
    mov si, line_buffer
.find_open2:
    mov al, [si]
    test al, al
    jz .next_line
    cmp al, '('
    je .input_args
    inc si
    jmp .find_open2
.input_args:
    inc si
.input_prompt:
    mov al, [si]
    cmp al, '"'
    jne .input_read
    inc si
.input_prompt_loop:
    mov al, [si]
    cmp al, '"'
    je .input_prompt_end
    test al, al
    jz .input_prompt_end
    call print_char_al
    inc si
    jmp .input_prompt_loop
.input_prompt_end:
    inc si
.input_read:
    call read_line
    mov si, var_input_name
    mov di, input_buffer
    call var_set
    jmp .next_line

.next_line:
    mov si, [script_ptr]
.skip_eol:
    mov al, [si]
    test al, al
    jz .script_end
    cmp al, 0x0A
    je .advance
    inc si
    jmp .skip_eol
.advance:
    inc si
    mov [script_ptr], si
    jmp .line_loop

.script_end:
    mov si, run_done
    call print_string
    jmp .done

.no_name:
    mov si, run_usage
    call print_string
    jmp .done
.disk_err:
    mov si, fs_err_read
    call print_string
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

in_skip:
    push bx
    cmp byte [if_depth], 0
    je .no
    mov bl, [if_depth]
    dec bl
    xor bh, bh
    cmp byte [if_stack + bx], 0
    jne .yes
.no:
    xor al, al
    pop bx
    ret
.yes:
    mov al, 1
    pop bx
    ret

ends_with_colon:
    push si
    push cx
    mov si, line_buffer
    xor cx, cx
.len:
    mov al, [si]
    test al, al
    jz .check
    inc si
    inc cx
    jmp .len
.check:
    test cx, cx
    jz .no
    dec si
    mov al, [si]
    cmp al, ':'
    jne .no
    mov al, 1
    pop cx
    pop si
    ret
.no:
    xor al, al
    pop cx
    pop si
    ret

eval_cond:
    push bx
    push cx
    push dx
    push si
    push di

    mov si, cond_buffer
.skip_l:
    cmp byte [si], ' '
    jne .l_start
    inc si
    jmp .skip_l
.l_start:
    call parse_number
    mov bx, ax

.find_op:
    mov al, [si]
    test al, al
    jz .err
    cmp al, '<'
    je .op_lt
    cmp al, '>'
    je .op_gt
    cmp al, '='
    je .op_eq
    cmp al, '!'
    je .op_ne
    inc si
    jmp .find_op

.op_eq:
    inc si
    cmp byte [si], '='
    jne .err
    inc si
    jmp .cmp_eq
.op_ne:
    inc si
    cmp byte [si], '='
    jne .err
    inc si
    jmp .cmp_ne
.op_lt:
    inc si
    cmp byte [si], '='
    je .cmp_le
    jmp .cmp_lt
.op_gt:
    inc si
    cmp byte [si], '='
    je .cmp_ge
    jmp .cmp_gt

.cmp_eq:
    call parse_number
    cmp bx, ax
    jne .false
    jmp .true
.cmp_ne:
    call parse_number
    cmp bx, ax
    je .false
    jmp .true
.cmp_lt:
    call parse_number
    cmp bx, ax
    jae .false
    jmp .true
.cmp_gt:
    call parse_number
    cmp bx, ax
    jbe .false
    jmp .true
.cmp_le:
    call parse_number
    cmp bx, ax
    ja .false
    jmp .true
.cmp_ge:
    call parse_number
    cmp bx, ax
    jb .false
    jmp .true
.true:
    mov al, 1
    jmp .done
.false:
    xor al, al
    jmp .done
.err:
    xor al, al
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

print_expr_list:
    push ax
    push si
    push di
.loop:
    mov al, [si]
    test al, al
    jz .done
    cmp al, ')'
    je .done
    cmp al, ' '
    je .skip
    cmp al, ','
    je .skip
    cmp al, '"'
    je .str
    call print_var_or_num
    jmp .loop
.str:
    inc si
.str_loop:
    mov al, [si]
    cmp al, '"'
    je .str_end
    test al, al
    jz .done
    call print_char_al
    inc si
    jmp .str_loop
.str_end:
    inc si
    jmp .loop
.skip:
    inc si
    jmp .loop
.done:
    call newline
    pop di
    pop si
    pop ax
    ret

; =============================================
; print_var_or_num - ИСПРАВЛЕНО (без push si / pop si)
; =============================================
print_var_or_num:
    push ax
    push bx
    push cx
    push di

    mov di, arg1_buffer
    xor cx, cx
.copy:
    mov al, [si]
    test al, al
    jz .done_copy
    cmp al, ','
    je .done_copy
    cmp al, ')'
    je .done_copy
    cmp al, ' '
    je .done_copy
    stosb
    inc si
    inc cx
    cmp cx, 15
    jb .copy
.done_copy:
    mov byte [di], 0
    mov [print_tmp_si], si

    mov al, [arg1_buffer]
    cmp al, '0'
    jb .lookup
    cmp al, '9'
    ja .lookup
    mov si, arg1_buffer
    call parse_number
    call print_number_ax
    jmp .restore

.lookup:
    mov si, arg1_buffer
    call var_get
    test ax, ax
    jz .restore
    mov si, ax
    call print_string

.restore:
    mov si, [print_tmp_si]
    pop di
    pop cx
    pop bx
    pop ax
    ret

do_assign:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov si, line_buffer
    mov di, arg1_buffer
    xor cx, cx
.name:
    mov al, [si]
    test al, al
    jz .done
    cmp al, '='
    je .eq
    cmp al, ' '
    je .skip_sp
    stosb
    inc si
    inc cx
    cmp cx, 15
    jb .name
    jmp .done
.skip_sp:
    inc si
    jmp .name

.eq:
    inc si
.skip_sp2:
    cmp byte [si], ' '
    jne .val
    inc si
    jmp .skip_sp2
.val:
    cmp byte [si], '"'
    je .string_val

    mov di, arg2_buffer
    xor cx, cx
.val_copy:
    mov al, [si]
    test al, al
    jz .val_done
    stosb
    inc si
    inc cx
    cmp cx, 31
    jb .val_copy
.val_done:
    mov byte [di], 0

    mov al, [arg2_buffer]
    cmp al, '0'
    jb .try_var
    cmp al, '9'
    ja .try_var
    jmp .store
.try_var:
    mov si, arg2_buffer
    call var_get
    test ax, ax
    jz .store
    mov si, ax
    mov di, arg2_buffer
    call copy_string
.store:
    mov si, arg1_buffer
    mov di, arg2_buffer
    call var_set
    jmp .done

.string_val:
    inc si
    mov di, arg2_buffer
    xor cx, cx
.str_copy:
    mov al, [si]
    cmp al, '"'
    je .str_end
    test al, al
    jz .str_end
    stosb
    inc si
    inc cx
    cmp cx, 31
    jb .str_copy
.str_end:
    mov byte [di], 0
    jmp .store

.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; =============================================
; VARIABLES
; =============================================

var_set:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov [tmp_si], si
    mov [tmp_di], di

    mov cx, 16
    mov bx, var_names
.loop:
    push cx
    push bx
    mov si, [tmp_si]
    mov di, bx
    call strcmp
    pop bx
    pop cx
    jc .update
    add bx, 16
    loop .loop

    mov al, [var_count]
    cmp al, 16
    jae .done
    mov bl, al
    shl bl, 4
    xor bh, bh
    mov di, var_names
    add di, bx
    mov si, [tmp_si]
.copy_name:
    lodsb
    stosb
    test al, al
    jnz .copy_name

    mov al, [var_count]
    shl al, 4
    xor ah, ah
    mov di, var_values
    add di, ax
    mov si, [tmp_di]
.copy_val:
    lodsb
    stosb
    test al, al
    jnz .copy_val

    inc byte [var_count]
    jmp .done

.update:
    mov ax, bx
    sub ax, var_names
    mov di, var_values
    add di, ax
    mov si, [tmp_di]
.copy_upd:
    lodsb
    stosb
    test al, al
    jnz .copy_upd

.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

var_get:
    push bx
    push cx
    push si
    push di
    mov cx, 16
    mov bx, var_names
.loop:
    push cx
    push si
    push di
    mov di, bx
    call strcmp
    pop di
    pop si
    pop cx
    jc .found
    add bx, 16
    loop .loop
    xor ax, ax
    jmp .done
.found:
    mov ax, bx
    sub ax, var_names
    add ax, var_values
.done:
    pop di
    pop si
    pop cx
    pop bx
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
; COMMANDS
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

do_theme:
    push si
    push di
    mov si, input_buffer
    add si, 6
.skip_spaces:
    cmp byte [si], ' '
    je .next
    jmp .check
.next:
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
; SNAKE
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
; VISUAL16
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
    cmp byte [v16_selected], 9
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
    je .app_graphics
    cmp byte [v16_selected], 8
    je .app_files
    cmp byte [v16_selected], 9
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
.app_graphics:
    call do_graphics
    jmp .visual_loop
.app_files:
    call v16_show_files
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
    jmp .i9
.i8n:
    mov si, v16_item8
    call print_string
.i9:
    cmp byte [v16_selected], 8
    jne .i9n
    mov si, v16_item9_sel
    call print_string
    jmp .i10
.i9n:
    mov si, v16_item9
    call print_string
.i10:
    cmp byte [v16_selected], 9
    jne .i10n
    mov si, v16_item10_sel
    call print_string
    jmp .bot
.i10n:
    mov si, v16_item10
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

v16_show_files:
    push si
    call clear_screen
    call do_dir
    mov si, v16_press_key
    call print_string
    xor ax, ax
    int 0x16
    pop si
    ret

; =============================================
; AUTOEXEC
; =============================================

run_autoexec:
    push si
    push di
    push cx
    call fs_load_dir
    jc .done
    mov di, fs_dir_buffer
    mov cx, 32
.search:
    cmp byte [di + 15], 1
    jne .next
    push cx
    push di
    mov si, autoexec_name
    call fs_match_name
    pop di
    pop cx
    jc .found
.next:
    add di, 16
    dec cx
    jnz .search
    jmp .done
.found:
    mov si, autoexec_cmd
    mov di, input_buffer
.copy:
    lodsb
    stosb
    test al, al
    jnz .copy
    call do_run
.done:
    pop cx
    pop di
    pop si
    ret

autoexec_name db 'AUTOEXEC', 0
autoexec_cmd  db 'run AUTOEXEC', 0

; =============================================
; DATA
; =============================================

menu_selected db 0

menu_top:
db 0x0d, 0x0a
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a, 0

menu_title:
db 0xBA, '                    microDOS v0.9.2 Boot Menu               ', 0xBA, 0x0d, 0x0a, 0

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

v16_selected db 0

v16_top:
db 0x0d, 0x0a
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a, 0

v16_title_line:
db 0xBA, '                    microDOS Visual16 v0.9.2                ', 0xBA, 0x0d, 0x0a, 0

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
db 0xBA, '    [ 8 ]  Graphics                                         ', 0xBA, 0x0d, 0x0a, 0
v16_item8_sel:
db 0xBA, ' >> [ 8 ]  Graphics                                         ', 0xBA, 0x0d, 0x0a, 0

v16_item9:
db 0xBA, '    [ 9 ]  Files (DIR)                                      ', 0xBA, 0x0d, 0x0a, 0
v16_item9_sel:
db 0xBA, ' >> [ 9 ]  Files (DIR)                                      ', 0xBA, 0x0d, 0x0a, 0

v16_item10:
db 0xBA, '    [ 10]  Exit to Text Mode                                ', 0xBA, 0x0d, 0x0a, 0
v16_item10_sel:
db 0xBA, ' >> [ 10]  Exit to Text Mode                                ', 0xBA, 0x0d, 0x0a, 0

v16_bot:
db 0xC8
times 60 db 0xCD
db 0xBC, 0x0d, 0x0a, 0

v16_hint:
db 0x0d, 0x0a
db '  UP/DOWN - select, ENTER - open, ESC - exit', 0x0d, 0x0a, 0

v16_clock_top:
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a, 0
v16_clock_title:
db 0xBA, '                        CLOCK APP                           ', 0xBA, 0x0d, 0x0a, 0
v16_clock_sep:
db 0xCC
times 60 db 0xCD
db 0xB9, 0x0d, 0x0a, 0
v16_clock_empty:
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a, 0
v16_clock_label:
db 0xBA, '                        Time: ', 0
v16_clock_pad:
db '                         ', 0xBA, 0x0d, 0x0a, 0
v16_clock_hint:
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xBA, '                  Press any key to return...                ', 0xBA, 0x0d, 0x0a, 0
v16_clock_bot:
db 0xC8
times 60 db 0xCD
db 0xBC, 0x0d, 0x0a, 0

v16_hello_screen:
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a
db 0xBA, '                        HELLO APP                           ', 0xBA, 0x0d, 0x0a
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xBA, '                  Welcome to microDOS!                      ', 0xBA, 0x0d, 0x0a
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xBA, '                  Press any key to return...                ', 0xBA, 0x0d, 0x0a
db 0xC8
times 60 db 0xCD
db 0xBC, 0x0d, 0x0a, 0

v16_info_screen:
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a
db 0xBA, '                       SYSTEM INFO                          ', 0xBA, 0x0d, 0x0a
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xBA, '                     microDOS v0.9.2                        ', 0xBA, 0x0d, 0x0a
db 0xBA, '                      16-bit Real Mode                      ', 0xBA, 0x0d, 0x0a
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xBA, '                  Press any key to return...                ', 0xBA, 0x0d, 0x0a
db 0xC8
times 60 db 0xCD
db 0xBC, 0x0d, 0x0a, 0

v16_calc_screen:
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a
db 0xBA, '                     CALCULATOR APP                         ', 0xBA, 0x0d, 0x0a
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xC8
times 60 db 0xCD
db 0xBC, 0x0d, 0x0a, 0

v16_neofetch_screen:
db 0xC9
times 60 db 0xCD
db 0xBB, 0x0d, 0x0a
db 0xBA, '                      NEOFETCH APP                          ', 0xBA, 0x0d, 0x0a
db 0xBA, '                                                            ', 0xBA, 0x0d, 0x0a
db 0xC8
times 60 db 0xCD
db 0xBC, 0x0d, 0x0a, 0

v16_press_key:
db 0x0d, 0x0a, 'Press any key to return...', 0

editor_bar:
db ' microDOS Editor | ESC: Exit | "save" to store            ', 0

banner          db 'microDOS v0.9.2 PyShell - 16-bit OS', 0x0d, 0x0a
                db 'type "help", "run FILE" for scripts', 0x0d, 0x0a, 0
prompt          db '> ', 0
unknown_msg     db 'unknown command', 0x0d, 0x0a, 0
help_msg        db 'commands:', 0x0d, 0x0a
                db '  help dir type save edit run', 0x0d, 0x0a
                db '  time clear info neofetch calc', 0x0d, 0x0a
                db '  snake gfx visual16 theme reboot', 0x0d, 0x0a
                db '', 0x0d, 0x0a
                db 'script example:', 0x0d, 0x0a
                db '  x = 5', 0x0d, 0x0a
                db '  name = "World"', 0x0d, 0x0a
                db '  print("Hi ", name)', 0x0d, 0x0a
                db '  if x > 3:', 0x0d, 0x0a
                db '      print("big")', 0x0d, 0x0a
                db '  else:', 0x0d, 0x0a
                db '      print("small")', 0x0d, 0x0a
                db '  input("name? ")', 0x0d, 0x0a, 0
time_msg        db 'time: ', 0
colon           db ':', 0
reboot_msg      db 'reboot...', 0x0d, 0x0a, 0
info_msg        db 'microDOS v0.9.2 PyShell', 0x0d, 0x0a
                db '16-bit Real Mode, FlatFS', 0x0d, 0x0a
                db 'Python-like script engine', 0x0d, 0x0a, 0
crlf            db 0x0d, 0x0a, 0

neo_logo        db 0x0d, 0x0a
                db '_   _  ____ ____  ____  ____  ____  ____ ', 0x0d, 0x0a
                db '/ \__/|/ \/   _Y  __\/  _ \/  _ \/  _ \/ ___\\', 0x0d, 0x0a
                db '| |\/||| ||  / |  \/|| / \|| | \|| / \||    \\', 0x0d, 0x0a
                db '| |  ||| ||  \_|    /| \_/|| |_/|| \_/|\___ |', 0x0d, 0x0a
                db '\_/  \|\_/\____|_/\_\\____/\____/\____/\____/', 0x0d, 0x0a
                db 0
neo_os          db 'OS:           microDOS 0.9.2', 0x0d, 0x0a, 0
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
theme_ok_white  db 'Theme: WHITE', 0x0d, 0x0a, 0
theme_ok_black  db 'Theme: BLACK', 0x0d, 0x0a, 0
theme_unknown   db 'Unknown theme.', 0x0d, 0x0a, 0
theme_help      db 'Usage: theme white / theme black', 0x0d, 0x0a, 0

snake_over_msg  db 'Game Over! Press any key...', 0x0d, 0x0a, 0
snake_len       db 4
snake_dir       db 1
apple_x         db 20
apple_y         db 8
snake_x         times 64 db 0
snake_y         times 64 db 0

cmd_dir         db 'dir', 0
cmd_type        db 'type', 0
cmd_save        db 'save', 0
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
cmd_gfx         db 'gfx', 0
cmd_visual16    db 'visual16', 0
cmd_run         db 'run', 0

kw_if           db 'if ', 0
kw_else         db 'else', 0
kw_print        db 'print(', 0
kw_input        db 'input(', 0

run_not_found   db 'Script not found.', 0x0d, 0x0a, 0
run_usage       db 'Usage: run FILENAME', 0x0d, 0x0a, 0
run_done        db 'Script finished.', 0x0d, 0x0a, 0

var_input_name  db 'v_input', 0

fs_dir_title    db ' microDOS FlatFS Directory:', 0x0d, 0x0a
                db ' NAME        SIZE', 0x0d, 0x0a
                db ' -----------------------', 0x0d, 0x0a, 0
fs_col_sep      db '  ', 0
fs_bytes_lbl    db ' B', 0x0d, 0x0a, 0
fs_empty_lbl    db ' (no files on disk)', 0x0d, 0x0a, 0
fs_prompt_name  db 'Filename: ', 0
fs_prompt_save  db 'Save as filename: ', 0
fs_not_found    db 'File not found!', 0x0d, 0x0a, 0
fs_save_ok      db 'File saved.', 0x0d, 0x0a, 0
fs_err_full     db 'Directory full!', 0x0d, 0x0a, 0
fs_err_empty_buf db 'Editor empty! Write text first.', 0x0d, 0x0a, 0
fs_err_read     db 'Disk read error!', 0x0d, 0x0a, 0
fs_err_write    db 'Disk write error!', 0x0d, 0x0a, 0

boot_drive      db 0x00

input_buffer    times 64 db 0

editor_len      dw 0
editor_buffer   times 1024 db 0

fs_dir_buffer   times 512 db 0
fs_file_buffer  times 1024 db 0

gfx_title       db 'microDOS 0.9.2 Graphics', 0
gfx_box_text    db 'Mode 13h', 0
gfx_hint        db 'Press any key to return...', 0

script_buffer   times 1024 db 0
script_ptr      dw 0

line_buffer     times 128 db 0
cur_indent      dw 0

if_stack        times 8 db 0
if_depth        db 0

cond_buffer     times 64 db 0
arg1_buffer     times 32 db 0
arg2_buffer     times 32 db 0

tmp_si          dw 0
print_tmp_si    dw 0
tmp_di          dw 0

var_count       db 0
var_names       times 16 * 16 db 0
var_values      times 16 * 16 db 0
