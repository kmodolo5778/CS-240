# Tic-Tac-Toe
# 
# Bitmap Display: units 8 x 8, display 512 x 512,

# Type a choice and press Enter in Run I/O, not in the bitmap.
# Collaboration: developed with OpenAI ChatGPT assistance.
# References: official MARS syscall and BitmapDisplay documentation.


.eqv BG       0x00131F32
.eqv WHITE    0x00EDF4FF
.eqv BLUE     0x006ABEFF
.eqv GOLD     0x00FFCE73
.eqv GREEN    0x0075D9B3
.eqv MUTED    0x006C829E
.eqv INK      0x00131F32
.eqv TEST_SEED -1     # -1 = time seed; nonnegative = repeatable test

.data 0x10010000
framebuffer: .space 16384   # FIRST: 64 * 64 words * 4 bytes
input_buffer: .space 128
invalid_text: .asciiz "Invalid input. Enter one listed digit, then Enter.\n"
replay_text: .asciiz "Play again? 1 = yes, 0 = quit: "
bye_text: .asciiz "Goodbye!\n"
newline: .asciiz "\n"
space_text: .asciiz " "

.align 2
board: .space 36       # nine words: 0=empty, 1=X, 2=O
status_ptr: .word x_turn
win_lines: .byte 0,1,2, 3,4,5, 6,7,8, 0,3,6
           .byte 1,4,7, 2,5,8, 0,4,8, 2,4,6
intro: .ascii "TIC-TAC-TOE: two human players. X goes first.\nChoose 1-9 as "
     .asciiz "shown; 0 quits. Three in a row wins.\n"
x_prompt: .asciiz "X: choose 1-9 (0 = quit): "
o_prompt: .asciiz "O: choose 1-9 (0 = quit): "
occupied: .asciiz "That square is occupied. Same player's turn.\n"
x_result: .asciiz "X wins!\n"
o_result: .asciiz "O wins!\n"
draw_result: .asciiz "Draw: the board is full.\n"
title: .asciiz "TIC TAC TOE"
x_turn: .asciiz "X TURN"
o_turn: .asciiz "O TURN"
x_win: .asciiz "X WINS"
o_win: .asciiz "O WINS"
tie: .asciiz "DRAW"

# ASCII 32..90: each byte stores three horizontal pixel bits.
font:
    .byte 0,0,0,0,0  # 32
    .byte 0,0,0,0,0  # 33
    .byte 0,0,0,0,0  # 34
    .byte 0,0,0,0,0  # 35
    .byte 0,0,0,0,0  # 36
    .byte 0,0,0,0,0  # 37
    .byte 0,0,0,0,0  # 38
    .byte 0,0,0,0,0  # 39
    .byte 0,0,0,0,0  # 40
    .byte 0,0,0,0,0  # 41
    .byte 0,0,0,0,0  # 42
    .byte 0,0,0,0,0  # 43
    .byte 0,0,0,0,0  # 44
    .byte 0,0,0,0,0  # 45
    .byte 0,0,0,0,0  # 46
    .byte 0,0,0,0,0  # 47
    .byte 7,5,5,5,7  # 48
    .byte 2,6,2,2,7  # 49
    .byte 7,1,7,4,7  # 50
    .byte 7,1,7,1,7  # 51
    .byte 5,5,7,1,1  # 52
    .byte 7,4,7,1,7  # 53
    .byte 7,4,7,5,7  # 54
    .byte 7,1,2,2,2  # 55
    .byte 7,5,7,5,7  # 56
    .byte 7,5,7,1,7  # 57
    .byte 0,0,0,0,0  # 58
    .byte 0,0,0,0,0  # 59
    .byte 0,0,0,0,0  # 60
    .byte 0,0,0,0,0  # 61
    .byte 0,0,0,0,0  # 62
    .byte 7,1,3,0,2  # 63
    .byte 0,0,0,0,0  # 64
    .byte 2,5,7,5,5  # 65
    .byte 6,5,6,5,6  # 66
    .byte 7,4,4,4,7  # 67
    .byte 6,5,5,5,6  # 68
    .byte 7,4,6,4,7  # 69
    .byte 7,4,6,4,4  # 70
    .byte 7,4,5,5,7  # 71
    .byte 5,5,7,5,5  # 72
    .byte 7,2,2,2,7  # 73
    .byte 1,1,1,5,7  # 74
    .byte 5,5,6,5,5  # 75
    .byte 4,4,4,4,7  # 76
    .byte 5,7,7,5,5  # 77
    .byte 5,7,7,7,5  # 78
    .byte 7,5,5,5,7  # 79
    .byte 7,5,7,4,4  # 80
    .byte 7,5,5,7,1  # 81
    .byte 6,5,6,5,5  # 82
    .byte 7,4,7,1,7  # 83
    .byte 7,2,2,2,2  # 84
    .byte 5,5,5,5,7  # 85
    .byte 5,5,5,5,2  # 86
    .byte 5,5,7,7,5  # 87
    .byte 5,5,2,5,5  # 88
    .byte 5,5,2,2,2  # 89
    .byte 7,1,2,4,7  # 90

.text
.globl main
main:
    addiu $sp, $sp, -20   # 4-byte alignment + 16 argument bytes
    la $a0, intro
    jal print_str
new_game:
    jal reset_board
    li $s0, 1             # current player
    li $s1, 0             # valid moves made
turn:
    la $t0, x_turn
    beq $s0, 1, set_turn
    la $t0, o_turn
set_turn:
    sw $t0, status_ptr
    jal draw_board
    jal print_board
ask_move:
    la $a0, x_prompt
    beq $s0, 1, prompt_ready
    la $a0, o_prompt
prompt_ready:
    jal print_str
    li $a0, 9
    jal read_choice
    bltz $v0, bad_move
    beqz $v0, quit
    addiu $t0, $v0, -1
    sll $t0, $t0, 2
    la $t1, board
    addu $t1, $t1, $t0
    lw $t2, 0($t1)
    bnez $t2, used_square
    sw $s0, 0($t1)
    addiu $s1, $s1, 1
    jal check_winner
    bnez $v0, game_won
    beq $s1, 9, game_draw
    li $t0, 3
    subu $s0, $t0, $s0   # 1 -> 2, 2 -> 1
    j turn
bad_move:
    la $a0, invalid_text
    jal print_str
    j ask_move
used_square:
    la $a0, occupied
    jal print_str
    j ask_move
game_won:
    la $t0, x_win
    la $a0, x_result
    beq $v0, 1, finish
    la $t0, o_win
    la $a0, o_result
    j finish
game_draw:
    la $t0, tie
    la $a0, draw_result
finish:
    sw $t0, status_ptr
    jal print_str
    jal draw_board
    jal print_board
    jal ask_replay
    bnez $v0, new_game
quit:
    la $a0, bye_text
    jal print_str
    li $v0, 10
    syscall

# reset_board(): clear all nine cells.
reset_board:
    la $t0, board
    li $t1, 9
reset_loop:
    sw $zero, 0($t0)
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    bnez $t1, reset_loop
    jr $ra

# check_winner() -> v0 = 0 (none), 1 (X), or 2 (O).
# The table describes 3 rows, 3 columns, and 2 diagonals.
check_winner:
    la $t0, win_lines
    la $t1, board
    li $t2, 8
    li $v0, 0
check_line:
    lbu $t3, 0($t0)
    sll $t3, $t3, 2
    addu $t3, $t3, $t1
    lw $t4, 0($t3)
    beqz $t4, next_line
    lbu $t3, 1($t0)
    sll $t3, $t3, 2
    addu $t3, $t3, $t1
    lw $t5, 0($t3)
    bne $t4, $t5, next_line
    lbu $t3, 2($t0)
    sll $t3, $t3, 2
    addu $t3, $t3, $t1
    lw $t5, 0($t3)
    bne $t4, $t5, next_line
    move $v0, $t4
    jr $ra
next_line:
    addiu $t0, $t0, 3
    addiu $t2, $t2, -1
    bnez $t2, check_line
    jr $ra

# print_board(): duplicate board in console for accessible text output.
print_board:
    la $t0, board
    li $t1, 0
print_cell:
    lw $t2, 0($t0)
    addiu $a0, $t1, 49
    beqz $t2, print_mark
    li $a0, 88
    beq $t2, 1, print_mark
    li $a0, 79
print_mark:
    li $v0, 11
    syscall
    li $a0, 32
    syscall
    addiu $t0, $t0, 4
    addiu $t1, $t1, 1
    li $t3, 3
    divu $t1, $t3
    mfhi $t4
    bnez $t4, print_continue
    li $a0, 10
    syscall
print_continue:
    blt $t1, 9, print_cell
    jr $ra

# draw_board(): title, grid, digits/marks, and status.
draw_board:
    addiu $sp, $sp, -32
    sw $ra, 28($sp)
    sw $s0, 24($sp)
    sw $s1, 20($sp)
    li $a0, BG
    jal clear_screen
    la $a0, title
    li $a1, 10
    li $a2, 2
    li $a3, WHITE
    jal draw_text
    li $s0, 0
grid_loop:
    sll $t0, $s0, 4
    addiu $a0, $t0, 24
    li $a1, 10
    li $a2, 0x00010030 # width=1, height=48
    li $a3, MUTED
    jal fill_rect
    li $a0, 8
    sll $t0, $s0, 4
    addiu $a1, $t0, 26
    li $a2, 0x00300001
    li $a3, MUTED
    jal fill_rect
    addiu $s0, $s0, 1
    blt $s0, 2, grid_loop
    li $s0, 0
    la $s1, board
board_cell:
    li $t0, 3
    divu $s0, $t0
    mflo $t1             # row
    mfhi $t2             # column
    sll $a1, $t2, 4
    addiu $a1, $a1, 11
    sll $a2, $t1, 4
    addiu $a2, $a2, 11
    lw $t3, 0($s1)
    beqz $t3, empty_cell
    li $a0, 88           # X
    li $a3, BLUE
    beq $t3, 1, occupied_cell
    li $a0, 79           # O
    li $a3, GOLD
occupied_cell:
    jal draw_big_char
    j drawn_cell
empty_cell:
    addiu $a0, $s0, 49
    addiu $a1, $a1, 3
    addiu $a2, $a2, 5
    li $a3, MUTED
    jal draw_char
drawn_cell:
    addiu $s1, $s1, 4
    addiu $s0, $s0, 1
    blt $s0, 9, board_cell
    lw $a0, status_ptr
    li $a1, 20
    li $a2, 59
    li $a3, GREEN
    jal draw_text
    lw $s1, 20($sp)
    lw $s0, 24($sp)
    lw $ra, 28($sp)
    addiu $sp, $sp, 32
    jr $ra

# ---------------- Shared console and random procedures ----------------
# print_str(a0 = address of a zero-terminated string)
print_str:
    li $v0, 4
    syscall
    jr $ra

# print_int(a0 = integer)
print_int:
    li $v0, 1
    syscall
    jr $ra

# read_choice(a0 = largest allowed digit) -> v0 = 0..max, or -1.
# Reading a STRING prevents syscall-5 exceptions for letters/blank input.
# Allow surrounding spaces/tabs; reject signs and multiple characters.
# MARS reads/discards the rest of an overlong input line.
read_choice:
    move $t0, $a0
    la $a0, input_buffer
    li $a1, 128
    li $v0, 8
    syscall
    la $t1, input_buffer
read_skip:
    lbu $t2, 0($t1)
    beq $t2, 32, read_advance
    beq $t2, 9, read_advance
    blt $t2, 48, read_bad
    bgt $t2, 57, read_bad
    addiu $t3, $t2, -48
    bgt $t3, $t0, read_bad
    addiu $t1, $t1, 1
read_tail:
    lbu $t2, 0($t1)
    beqz $t2, read_bad     # no newline means a truncated/overlong line
    beq $t2, 10, read_good
    beq $t2, 13, read_tail_advance
    beq $t2, 32, read_tail_advance
    beq $t2, 9, read_tail_advance
    j read_bad
read_tail_advance:
    addiu $t1, $t1, 1
    j read_tail
read_advance:
    addiu $t1, $t1, 1
    j read_skip
read_good:
    move $v0, $t3
    jr $ra
read_bad:
    li $v0, -1
    jr $ra

# ask_replay() -> v0 = 0 or 1; keeps asking after invalid input.
ask_replay:
    addiu $sp, $sp, -24
    sw $ra, 20($sp)
replay_loop:
    la $a0, replay_text
    jal print_str
    li $a0, 1
    jal read_choice
    bgez $v0, replay_done
    la $a0, invalid_text
    jal print_str
    j replay_loop
replay_done:
    lw $ra, 20($sp)
    addiu $sp, $sp, 24
    jr $ra

# seed_rng(): use a time seed unless TEST_SEED specifies a fixed one.
seed_rng:
    li $t0, TEST_SEED
    bgez $t0, seed_fixed
    li $v0, 30
    syscall
    move $t0, $a0
seed_fixed:
    move $a1, $t0
    li $a0, 0
    li $v0, 40
    syscall
    jr $ra

# random_below(a0 = positive limit) -> v0 in [0, limit).
# MARS syscall 42 returns its answer in a0, NOT v0.
random_below:
    move $a1, $a0
    li $a0, 0
    li $v0, 42
    syscall
    move $v0, $a0
    jr $ra

# ---------------- Bitmap procedures: logical coordinates 0..63 --------
# clear_screen(a0 = 0x00RRGGBB color)
clear_screen:
    la $t0, framebuffer
    li $t1, 4096
clear_loop:
    sw $a0, 0($t0)
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    bnez $t1, clear_loop
    jr $ra

# fill_rect(a0=x, a1=y, a2=(width<<16)|height, a3=color).
# All callers supply rectangles inside the 64x64 screen.
# Combining width/height keeps this helper within four argument registers.
fill_rect:
    srl $t0, $a2, 16
    andi $t1, $a2, 65535
    beqz $t0, rect_done
    beqz $t1, rect_done
    sll $t2, $a1, 6       # y * 64
    addu $t2, $t2, $a0
    sll $t2, $t2, 2       # (y*64+x) * 4 bytes
    la $t3, framebuffer
    addu $t2, $t2, $t3
rect_row:
    move $t3, $t2
    move $t4, $t0
rect_col:
    sw $a3, 0($t3)
    addiu $t3, $t3, 4
    addiu $t4, $t4, -1
    bnez $t4, rect_col
    addiu $t2, $t2, 256   # 64 words per row
    addiu $t1, $t1, -1
    bnez $t1, rect_row
rect_done:
    jr $ra

# draw_char(a0=ASCII, a1=x, a2=y, a3=color): 3x5 pixels.
# draw_big_char has the same arguments and uses 9x15 pixels.
draw_char:
    li $t9, 1
    j glyph_start
draw_big_char:
    li $t9, 3
glyph_start:
    addiu $sp, $sp, -56
    sw $ra, 52($sp)
    sw $s0, 48($sp)
    sw $s1, 44($sp)
    sw $s2, 40($sp)
    sw $s3, 36($sp)
    sw $s4, 32($sp)
    sw $s5, 28($sp)
    sw $s6, 24($sp)
    sw $s7, 20($sp)
    move $s1, $a1
    move $s2, $a2
    move $s3, $a3
    move $s4, $t9
    addiu $t0, $a0, -32
    bltz $t0, glyph_done
    bgt $t0, 58, glyph_done
    li $t1, 5
    mul $t0, $t0, $t1
    la $s0, font
    addu $s0, $s0, $t0
    li $s5, 0
glyph_row:
    lbu $s7, 0($s0)
    li $s6, 0
glyph_col:
    li $t0, 2
    subu $t0, $t0, $s6
    srlv $t1, $s7, $t0
    andi $t1, $t1, 1
    beqz $t1, glyph_next
    mul $a0, $s6, $s4
    addu $a0, $a0, $s1
    mul $a1, $s5, $s4
    addu $a1, $a1, $s2
    sll $a2, $s4, 16
    or $a2, $a2, $s4
    move $a3, $s3
    jal fill_rect
glyph_next:
    addiu $s6, $s6, 1
    blt $s6, 3, glyph_col
    addiu $s0, $s0, 1
    addiu $s5, $s5, 1
    blt $s5, 5, glyph_row
glyph_done:
    lw $s7, 20($sp)
    lw $s6, 24($sp)
    lw $s5, 28($sp)
    lw $s4, 32($sp)
    lw $s3, 36($sp)
    lw $s2, 40($sp)
    lw $s1, 44($sp)
    lw $s0, 48($sp)
    lw $ra, 52($sp)
    addiu $sp, $sp, 56
    jr $ra

# draw_text(a0=uppercase string, a1=x, a2=y, a3=color).
draw_text:
    addiu $sp, $sp, -40
    sw $ra, 36($sp)
    sw $s0, 32($sp)
    sw $s1, 28($sp)
    sw $s2, 24($sp)
    sw $s3, 20($sp)
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    move $s3, $a3
text_loop:
    lbu $a0, 0($s0)
    beqz $a0, text_done
    move $a1, $s1
    move $a2, $s2
    move $a3, $s3
    jal draw_char
    addiu $s0, $s0, 1
    addiu $s1, $s1, 4
    j text_loop
text_done:
    lw $s3, 20($sp)
    lw $s2, 24($sp)
    lw $s1, 28($sp)
    lw $s0, 32($sp)
    lw $ra, 36($sp)
    addiu $sp, $sp, 40
    jr $ra

# draw_number(a0=0..99, a1=x, a2=y, a3=color).
draw_number:
    addiu $sp, $sp, -40
    sw $ra, 36($sp)
    sw $s0, 32($sp)
    sw $s1, 28($sp)
    sw $s2, 24($sp)
    sw $s3, 20($sp)
    move $s1, $a1
    move $s2, $a2
    move $s3, $a3
    li $t0, 10
    divu $a0, $t0
    mflo $t1
    mfhi $s0
    beqz $t1, number_ones
    addiu $a0, $t1, 48
    jal draw_char
    addiu $s1, $s1, 4
number_ones:
    addiu $a0, $s0, 48
    move $a1, $s1
    move $a2, $s2
    move $a3, $s3
    jal draw_char
    lw $s3, 20($sp)
    lw $s2, 24($sp)
    lw $s1, 28($sp)
    lw $s0, 32($sp)
    lw $ra, 36($sp)
    addiu $sp, $sp, 40
    jr $ra