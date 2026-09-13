#define VGA_WIDTH  320
#define VGA_HEIGHT 200
#define VGA_MEM    ((volatile unsigned char *)0xA0000)

#define COLOR_BLACK       0x00
#define COLOR_BLUE        0x01
#define COLOR_GREEN       0x02
#define COLOR_CYAN        0x03
#define COLOR_RED         0x04
#define COLOR_MAGENTA     0x05
#define COLOR_BROWN       0x06
#define COLOR_LIGHT_GRAY  0x07
#define COLOR_DARK_GRAY   0x08
#define COLOR_LIGHT_BLUE  0x09
#define COLOR_LIGHT_GREEN 0x0A
#define COLOR_LIGHT_CYAN  0x0B
#define COLOR_LIGHT_RED   0x0C
#define COLOR_YELLOW      0x0E
#define COLOR_WHITE       0x0F
#define COLOR_DESKTOP_BG  0x37

#define KBD_DATA_PORT    0x60
#define KBD_STATUS_PORT  0x64
#define TERM_BUF_SIZE    32

static inline void outb(unsigned short port, unsigned char val) {
    __asm__ volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

static inline unsigned char inb(unsigned short port) {
    unsigned char ret;
    __asm__ volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

void put_pixel(int x, int y, unsigned char color) {
    if (x >= 0 && x < VGA_WIDTH && y >= 0 && y < VGA_HEIGHT) {
        VGA_MEM[y * VGA_WIDTH + x] = color;
    }
}

void fill_rect(int x, int y, int w, int h, unsigned char color) {
    for (int i = 0; i < h; i++) {
        int py = y + i;
        if (py < 0 || py >= VGA_HEIGHT) continue;
        int row = py * VGA_WIDTH;
        for (int j = 0; j < w; j++) {
            int px = x + j;
            if (px >= 0 && px < VGA_WIDTH) {
                VGA_MEM[row + px] = color;
            }
        }
    }
}

void draw_rect(int x, int y, int w, int h, unsigned char color) {
    for (int i = 0; i < w; i++) {
        put_pixel(x + i, y, color);
        put_pixel(x + i, y + h - 1, color);
    }
    for (int j = 0; j < h; j++) {
        put_pixel(x, y + j, color);
        put_pixel(x + w - 1, y + j, color);
    }
}

static const unsigned char font_5x7[96][7] = {
    [' ' - 32] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
    ['-' - 32] = {0x00, 0x00, 0x00, 0x1F, 0x00, 0x00, 0x00},
    ['.' - 32] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x0C},
    [':' - 32] = {0x00, 0x0C, 0x0C, 0x00, 0x0C, 0x0C, 0x00},
    ['>' - 32] = {0x10, 0x08, 0x04, 0x02, 0x04, 0x08, 0x10},
    ['0' - 32] = {0x0E, 0x11, 0x13, 0x15, 0x19, 0x11, 0x0E},
    ['1' - 32] = {0x04, 0x0C, 0x04, 0x04, 0x04, 0x04, 0x0E},
    ['2' - 32] = {0x0E, 0x11, 0x01, 0x02, 0x04, 0x08, 0x1F},
    ['3' - 32] = {0x1F, 0x02, 0x04, 0x02, 0x01, 0x11, 0x0E},
    ['4' - 32] = {0x02, 0x06, 0x0A, 0x12, 0x1F, 0x02, 0x02},
    ['5' - 32] = {0x1F, 0x10, 0x1E, 0x01, 0x01, 0x11, 0x0E},
    ['6' - 32] = {0x06, 0x08, 0x10, 0x1E, 0x11, 0x11, 0x0E},
    ['7' - 32] = {0x1F, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08},
    ['8' - 32] = {0x0E, 0x11, 0x11, 0x0E, 0x11, 0x11, 0x0E},
    ['9' - 32] = {0x0E, 0x11, 0x11, 0x0F, 0x01, 0x02, 0x0C},
    ['A' - 32] = {0x0E, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11},
    ['B' - 32] = {0x1E, 0x11, 0x11, 0x1E, 0x11, 0x11, 0x1E},
    ['C' - 32] = {0x0E, 0x11, 0x10, 0x10, 0x10, 0x11, 0x0E},
    ['D' - 32] = {0x1C, 0x12, 0x11, 0x11, 0x11, 0x12, 0x1C},
    ['E' - 32] = {0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x1F},
    ['F' - 32] = {0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x10},
    ['G' - 32] = {0x0E, 0x11, 0x10, 0x17, 0x11, 0x11, 0x0F},
    ['H' - 32] = {0x11, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11},
    ['I' - 32] = {0x0E, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0E},
    ['J' - 32] = {0x02, 0x02, 0x02, 0x02, 0x12, 0x12, 0x0C},
    ['K' - 32] = {0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11},
    ['L' - 32] = {0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1F},
    ['M' - 32] = {0x11, 0x1B, 0x15, 0x15, 0x11, 0x11, 0x11},
    ['N' - 32] = {0x11, 0x11, 0x19, 0x15, 0x13, 0x11, 0x11},
    ['O' - 32] = {0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E},
    ['P' - 32] = {0x1E, 0x11, 0x11, 0x1E, 0x10, 0x10, 0x10},
    ['Q' - 32] = {0x0E, 0x11, 0x11, 0x11, 0x15, 0x12, 0x0D},
    ['R' - 32] = {0x1E, 0x11, 0x11, 0x1E, 0x14, 0x12, 0x11},
    ['S' - 32] = {0x0E, 0x11, 0x10, 0x0E, 0x01, 0x11, 0x0E},
    ['T' - 32] = {0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04},
    ['U' - 32] = {0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E},
    ['V' - 32] = {0x11, 0x11, 0x11, 0x11, 0x11, 0x0A, 0x04},
    ['W' - 32] = {0x11, 0x11, 0x11, 0x15, 0x15, 0x15, 0x0A},
    ['X' - 32] = {0x11, 0x11, 0x0A, 0x04, 0x0A, 0x11, 0x11},
    ['Y' - 32] = {0x11, 0x11, 0x0A, 0x04, 0x04, 0x04, 0x04},
    ['Z' - 32] = {0x1F, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1F},
    ['[' - 32] = {0x0E, 0x08, 0x08, 0x08, 0x08, 0x08, 0x0E},
    [']' - 32] = {0x0E, 0x02, 0x02, 0x02, 0x02, 0x02, 0x0E},
    ['_' - 32] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1F}
};

void draw_char(int x, int y, char c, unsigned char color) {
    if (c >= 'a' && c <= 'z') c -= 32;
    if (c < 32 || c > 126) return;
    const unsigned char *glyph = font_5x7[c - 32];
    for (int row = 0; row < 7; row++) {
        unsigned char bits = glyph[row];
        for (int col = 0; col < 5; col++) {
            if (bits & (0x10 >> col)) {
                put_pixel(x + col, y + row, color);
            }
        }
    }
}

void draw_string(int x, int y, const char *str, unsigned char color) {
    int cur_x = x;
    while (*str) {
        draw_char(cur_x, y, *str, color);
        cur_x += 6;
        str++;
    }
}

void draw_3d_box(int x, int y, int w, int h, int sunken) {
    unsigned char top_left = sunken ? COLOR_DARK_GRAY : COLOR_WHITE;
    unsigned char bot_right = sunken ? COLOR_WHITE : COLOR_DARK_GRAY;

    for (int i = 0; i < w; i++) {
        put_pixel(x + i, y, top_left);
        put_pixel(x + i, y + h - 1, bot_right);
    }
    for (int j = 0; j < h; j++) {
        put_pixel(x, y + j, top_left);
        put_pixel(x + w - 1, y + j, bot_right);
    }
}

void draw_window(int x, int y, int w, int h, const char *title) {
    fill_rect(x, y, w, h, COLOR_LIGHT_GRAY);
    draw_3d_box(x, y, w, h, 0);

    fill_rect(x + 2, y + 2, w - 4, 11, COLOR_BLUE);
    draw_string(x + 5, y + 4, title, COLOR_WHITE);

    fill_rect(x + w - 13, y + 3, 9, 9, COLOR_LIGHT_GRAY);
    draw_3d_box(x + w - 13, y + 3, 9, 9, 0);
    draw_string(x + w - 11, y + 4, "X", COLOR_BLACK);
}

void draw_icon(int x, int y, const char *label, int selected) {
    if (selected) {
        fill_rect(x - 2, y - 2, 36, 40, COLOR_BLUE);
    }
    fill_rect(x + 4, y, 24, 20, COLOR_WHITE);
    draw_rect(x + 4, y, 24, 20, COLOR_DARK_GRAY);
    fill_rect(x + 8, y + 4, 16, 2, COLOR_BLUE);
    fill_rect(x + 8, y + 8, 16, 2, COLOR_BLUE);
    fill_rect(x + 8, y + 12, 10, 2, COLOR_BLUE);

    draw_string(x - 2, y + 24, label, COLOR_WHITE);
}

int current_app = 0;
int window_open = 0;

char term_buf[TERM_BUF_SIZE];
int term_len = 0;
char term_output[32] = "TYPE HELP";

char scancode_to_ascii(unsigned char scancode) {
    switch (scancode) {
        case 0x1E: return 'A'; case 0x30: return 'B'; case 0x2E: return 'C';
        case 0x20: return 'D'; case 0x12: return 'E'; case 0x21: return 'F';
        case 0x22: return 'G'; case 0x23: return 'H'; case 0x17: return 'I';
        case 0x24: return 'J'; case 0x25: return 'K'; case 0x26: return 'L';
        case 0x32: return 'M'; case 0x31: return 'N'; case 0x18: return 'O';
        case 0x19: return 'P'; case 0x10: return 'Q'; case 0x13: return 'R';
        case 0x1F: return 'S'; case 0x14: return 'T'; case 0x16: return 'U';
        case 0x2F: return 'V'; case 0x11: return 'W'; case 0x2D: return 'X';
        case 0x15: return 'Y'; case 0x2C: return 'Z';
        case 0x39: return ' ';
        case 0x02: return '1'; case 0x03: return '2'; case 0x04: return '3';
        case 0x05: return '4'; case 0x06: return '5'; case 0x07: return '6';
        case 0x08: return '7'; case 0x09: return '8'; case 0x0A: return '9';
        case 0x0B: return '0';
        default: return 0;
    }
}

int str_equal(const char *s1, const char *s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char *)s1 - *(const unsigned char *)s2;
}

void copy_str(char *dest, const char *src) {
    while (*src) {
        *dest++ = *src++;
    }
    *dest = '\0';
}

void execute_terminal_command(void) {
    term_buf[term_len] = '\0';

    if (str_equal(term_buf, "HELP") == 0) {
        copy_str(term_output, "CMDS: HELP, INFO, CLR, REBOOT");
    } else if (str_equal(term_buf, "INFO") == 0) {
        copy_str(term_output, "MICRODOS 32-BIT PMODE OK");
    } else if (str_equal(term_buf, "CLR") == 0) {
        term_output[0] = '\0';
    } else if (str_equal(term_buf, "REBOOT") == 0) {
        outb(0x64, 0xFE);
    } else if (term_len > 0) {
        copy_str(term_output, "UNKNOWN COMMAND");
    }

    term_len = 0;
    term_buf[0] = '\0';
}

void render_desktop() {
    fill_rect(0, 0, VGA_WIDTH, VGA_HEIGHT - 20, COLOR_DESKTOP_BG);

    draw_icon(20, 20, "TERM", current_app == 0);
    draw_icon(20, 70, "FILE", current_app == 1);
    draw_icon(20, 120, "INFO", current_app == 2);

    if (window_open) {
        if (current_app == 0) {
            draw_window(80, 25, 220, 130, "TERMINAL 32-BIT");
            fill_rect(84, 40, 212, 110, COLOR_BLACK);
            draw_string(88, 45, "MICRODOS V1 made in Earth", COLOR_LIGHT_GREEN);
            draw_string(88, 60, term_output, COLOR_WHITE);
            draw_string(88, 80, ">", COLOR_LIGHT_CYAN);
            term_buf[term_len] = '\0';
            draw_string(98, 80, term_buf, COLOR_LIGHT_CYAN);
            draw_char(98 + term_len * 6, 80, '_', COLOR_WHITE);
        } else if (current_app == 1) {
            draw_window(90, 30, 200, 120, "FILE EXPLORER");
            fill_rect(94, 45, 192, 100, COLOR_WHITE);
            draw_3d_box(94, 45, 192, 100, 1);
            draw_string(100, 52, "KERNEL.BIN   128 KB", COLOR_BLACK);
            draw_string(100, 64, "BOOT.SYS       2 KB", COLOR_BLACK);
            draw_string(100, 76, "CONFIG.CFG     1 KB", COLOR_BLACK);
        } else if (current_app == 2) {
            draw_window(100, 40, 180, 100, "ABOUT MICRODOS");
            draw_string(110, 60, "MICRODOS 32-BIT", COLOR_BLACK);
            draw_string(110, 72, "GUI DESKTOP EDITION", COLOR_DARK_GRAY);
            draw_string(110, 84, "WRITTEN IN C & NASM", COLOR_BLUE);
        }
    }

    fill_rect(0, VGA_HEIGHT - 20, VGA_WIDTH, 20, COLOR_LIGHT_GRAY);
    draw_3d_box(0, VGA_HEIGHT - 20, VGA_WIDTH, 20, 0);

    fill_rect(3, VGA_HEIGHT - 17, 44, 14, COLOR_LIGHT_GRAY);
    draw_3d_box(3, VGA_HEIGHT - 17, 44, 14, 0);
    draw_string(8, VGA_HEIGHT - 13, "START", COLOR_BLACK);

    fill_rect(VGA_WIDTH - 65, VGA_HEIGHT - 17, 60, 14, COLOR_LIGHT_GRAY);
    draw_3d_box(VGA_WIDTH - 65, VGA_HEIGHT - 17, 60, 14, 1);
    draw_string(VGA_WIDTH - 55, VGA_HEIGHT - 13, "32-BIT", COLOR_BLACK);
}

void kernel_main(void) {
    term_buf[0] = '\0';
    render_desktop();

    while (1) {
        if (inb(KBD_STATUS_PORT) & 0x01) {
            unsigned char scancode = inb(KBD_DATA_PORT);

            if (!(scancode & 0x80)) {
                if (window_open && current_app == 0) {
                    if (scancode == 0x01) {
                        window_open = 0;
                    } else if (scancode == 0x1C) {
                        execute_terminal_command();
                    } else if (scancode == 0x0E) {
                        if (term_len > 0) {
                            term_len--;
                            term_buf[term_len] = '\0';
                        }
                    } else {
                        char c = scancode_to_ascii(scancode);
                        if (c && term_len < TERM_BUF_SIZE - 1) {
                            term_buf[term_len++] = c;
                            term_buf[term_len] = '\0';
                        }
                    }
                } else {
                    switch (scancode) {
                        case 0x48:
                        case 0x11:
                            if (current_app > 0) current_app--;
                            break;
                        case 0x50:
                        case 0x1F:
                            if (current_app < 2) current_app++;
                            break;
                        case 0x1C:
                            window_open = 1;
                            break;
                        case 0x01:
                            window_open = 0;
                            break;
                        default:
                            break;
                    }
                }
                render_desktop();
            }
        }
    }
}
