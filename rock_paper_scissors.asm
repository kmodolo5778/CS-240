# Rock-Paper-Scissors
#
# Bitmap Display: units 8 x 8, display 512 x 512,
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
player_choice: .word 0
cpu_choice: .word 0
wins: .word 0
losses: .word 0
ties: .word 0
status_ptr: .word ready
names: .word unknown, rock, paper, scissors
letters: .byte 63,82,80,83
intro: .ascii "ROCK-PAPER-SCISSORS vs computer.\nRock beats scissors; paper "
     .asciiz "beats rock; scissors beat paper.\n"
prompt: .asciiz "1 = rock, 2 = paper, 3 = scissors, 0 = quit: "
you_text: .asciiz "You: "
cpu_text: .asciiz "  Computer: "
win_text: .asciiz "You win this round!\n"
lose_text: .asciiz "Computer wins this round.\n"
tie_text: .asciiz "Tie!\n"
score_text: .asciiz "Score - wins: "
loss_text: .asciiz "  losses: "
ties_text: .asciiz "  ties: "
unknown: .asciiz "CHOOSE"
rock: .asciiz "ROCK"
paper: .asciiz "PAPER"
scissors: .asciiz "SCISSORS"
title1: .asciiz "ROCK PAPER"
title2: .asciiz "SCISSORS"
you_label: .asciiz "YOU"
cpu_label: .asciiz "CPU"
ready: .asciiz "CHOOSE 1 2 3"
win_label: .asciiz "YOU WIN"
lose_label: .asciiz "CPU WINS"
tie_label: .asciiz "TIE"

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
    addiu $sp, $sp, -20   # align sp and reserve argument space
    jal seed_rng
    la $a0, intro
    jal print_str
    jal draw_rps
round_loop:
    la $a0, prompt
    jal print_str
    li $a0, 3
    jal read_choice
    bltz $v0, bad_choice
    beqz $v0, quit
    sw $v0, player_choice
    li $a0, 3
    jal random_below
    addiu $v0, $v0, 1
    sw $v0, cpu_choice
    lw $a0, player_choice
    move $a1, $v0
    jal rps_winner
    beqz $v0, round_tie
    bltz $v0, round_lost
    lw $t0, wins
    addiu $t0, $t0, 1
    sw $t0, wins
    la $t0, win_label
    la $s0, win_text
    j round_finish
round_lost:
    lw $t0, losses
    addiu $t0, $t0, 1
    sw $t0, losses
    la $t0, lose_label
    la $s0, lose_text
    j round_finish
round_tie:
    lw $t0, ties
    addiu $t0, $t0, 1
    sw $t0, ties
    la $t0, tie_label
    la $s0, tie_text
round_finish:
    sw $t0, status_ptr
    jal draw_rps
    la $a0, you_text
    jal print_str
    lw $t0, player_choice
    sll $t0, $t0, 2
    lw $a0, names($t0)
    jal print_str
    la $a0, cpu_text
    jal print_str
    lw $t0, cpu_choice
    sll $t0, $t0, 2
    lw $a0, names($t0)
    jal print_str
    la $a0, newline
    jal print_str
    move $a0, $s0
    jal print_str
    jal print_score
    j round_loop
bad_choice:
    la $a0, invalid_text
    jal print_str
    j round_loop
quit:
    jal print_score
    la $a0, bye_text
    jal print_str
    li $v0, 10
    syscall

# rps_winner(a0=player 1..3, a1=CPU 1..3)
# -> v0 = 1 player wins, 0 tie, -1 CPU wins.
rps_winner:
    li $v0, 0
    beq $a0, $a1, rps_return
    subu $t0, $a0, $a1
    addiu $t0, $t0, 3
    li $t1, 3
    divu $t0, $t1
    mfhi $t0
    li $v0, 1
    beq $t0, 1, rps_return
    li $v0, -1
rps_return:
    jr $ra

# print_score(): all round counters live in memory.
print_score:
    addiu $sp, $sp, -24
    sw $ra, 20($sp)
    la $a0, score_text
    jal print_str
    lw $a0, wins
    jal print_int
    la $a0, loss_text
    jal print_str
    lw $a0, losses
    jal print_int
    la $a0, ties_text
    jal print_str
    lw $a0, ties
    jal print_int
    la $a0, newline
    jal print_str
    lw $ra, 20($sp)
    addiu $sp, $sp, 24
    jr $ra

# draw_rps(): left=human, right=computer; R/P/S and full names.
draw_rps:
    addiu $sp, $sp, -24
    sw $ra, 20($sp)
    li $a0, BG
    jal clear_screen
    la $a0, title1
    li $a1, 12
    li $a2, 2
    li $a3, WHITE
    jal draw_text
    la $a0, title2
    li $a1, 16
    li $a2, 9
    li $a3, WHITE
    jal draw_text
    la $a0, you_label
    li $a1, 8
    li $a2, 20
    li $a3, BLUE
    jal draw_text
    la $a0, cpu_label
    li $a1, 44
    li $a2, 20
    li $a3, GOLD
    jal draw_text
    lw $t0, player_choice
    lbu $a0, letters($t0)
    li $a1, 10
    li $a2, 29
    li $a3, BLUE
    jal draw_big_char
    lw $t0, cpu_choice
    lbu $a0, letters($t0)
    li $a1, 44
    li $a2, 29
    li $a3, GOLD
    jal draw_big_char
    lw $t0, player_choice
    sll $t0, $t0, 2
    lw $a0, names($t0)
    li $a1, 1
    li $a2, 47
    li $a3, BLUE
    jal draw_text
    lw $t0, cpu_choice
    sll $t0, $t0, 2
    lw $a0, names($t0)
    li $a1, 33
    li $a2, 47
    li $a3, GOLD
    jal draw_text
    lw $a0, status_ptr
    li $a1, 8
    li $a2, 57
    li $a3, GREEN
    jal draw_text
    lw $ra, 20($sp)
    addiu $sp, $sp, 24
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
