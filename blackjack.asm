# Blackjack
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
deck: .space 208       # 52 ranks: four of each 1..13
deck_pos: .word 0
player_hand: .space 208
dealer_hand: .space 208
player_count: .word 0
dealer_count: .word 0
show_dealer: .word 0
status_ptr: .word playing_label
rank_names: .word r0,rA,r2,r3,r4,r5,r6,r7,r8,r9,r10,rJ,rQ,rK
r0: .asciiz "?"
rA: .asciiz "A"
r2: .asciiz "2"
r3: .asciiz "3"
r4: .asciiz "4"
r5: .asciiz "5"
r6: .asciiz "6"
r7: .asciiz "7"
r8: .asciiz "8"
r9: .asciiz "9"
r10: .asciiz "10"
rJ: .asciiz "J"
rQ: .asciiz "Q"
rK: .asciiz "K"
intro: .ascii "BLACKJACK vs dealer. Closest to 21 without going over.\nAces "
     .ascii "count 1 or 11; J/Q/K count 10. Dealer stands on all 17s.\nA "
     .ascii "two-card 21 is a natural. No betting, splitting, or "
     .ascii "doubling.\nOne shuffled 52-card deck per round; suits do not "
     .asciiz "affect scoring.\n"
prompt: .asciiz "1 = hit, 2 = stand, 0 = quit: "
dealer_text: .asciiz "Dealer: "
player_text: .asciiz "You:    "
total_text: .asciiz "  total = "
hidden_text: .asciiz "[hidden] "
win_text: .asciiz "You win: your total is higher.\n"
lose_text: .asciiz "Dealer wins: dealer total is higher.\n"
push_text: .asciiz "Push: equal totals.\n"
p_bust_text: .asciiz "You bust. Dealer wins.\n"
d_bust_text: .asciiz "Dealer busts. You win!\n"
p_natural_text: .asciiz "Blackjack! Your two-card 21 wins.\n"
d_natural_text: .asciiz "Dealer has blackjack. Dealer wins.\n"
both_natural_text: .asciiz "Both have blackjack. Push.\n"
deck_error: .asciiz "Deck exhausted; round cancelled.\n"
title: .asciiz "BLACKJACK"
dealer_label: .asciiz "DEALER"
player_label: .asciiz "YOU"
playing_label: .asciiz "HIT OR STAND"
win_label: .asciiz "YOU WIN"
lose_label: .asciiz "DEALER WINS"
push_label: .asciiz "PUSH"

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
new_round:
    sw $zero, player_count
    sw $zero, dealer_count
    sw $zero, show_dealer
    la $t0, playing_label
    sw $t0, status_ptr
    jal shuffle_deck
    li $a0, 0             # deal P, D, P, D
    jal give_card
    li $a0, 1
    jal give_card
    li $a0, 0
    jal give_card
    li $a0, 1
    jal give_card
    jal refresh
    la $a0, player_hand
    lw $a1, player_count
    jal hand_total
    move $s0, $v0
    la $a0, dealer_hand
    lw $a1, dealer_count
    jal hand_total
    move $s1, $v0
    beq $s0, 21, player_natural
    beq $s1, 21, dealer_natural
player_turn:
    la $a0, prompt
    jal print_str
    li $a0, 2
    jal read_choice
    bltz $v0, bad_choice
    beqz $v0, quit
    beq $v0, 2, dealer_turn
    li $a0, 0
    jal give_card
    beqz $v0, exhausted
    jal refresh
    la $a0, player_hand
    lw $a1, player_count
    jal hand_total
    move $s0, $v0
    bgt $s0, 21, player_bust
    beq $s0, 21, dealer_turn
    j player_turn
bad_choice:
    la $a0, invalid_text
    jal print_str
    j player_turn
dealer_turn:
    li $t0, 1
    sw $t0, show_dealer
dealer_loop:
    la $a0, dealer_hand
    lw $a1, dealer_count
    jal hand_total
    move $s1, $v0
    bge $s1, 17, compare_hands
    li $a0, 1
    jal give_card
    beqz $v0, exhausted
    j dealer_loop
compare_hands:
    bgt $s1, 21, dealer_bust
    bgt $s0, $s1, player_win
    blt $s0, $s1, dealer_win
    la $a0, push_text
    j result_push
player_natural:
    beq $s1, 21, both_natural
    la $a0, p_natural_text
    j result_win
dealer_natural:
    la $a0, d_natural_text
    j result_lose
both_natural:
    la $a0, both_natural_text
    j result_push
player_bust:
    la $a0, p_bust_text
    j result_lose
dealer_bust:
    la $a0, d_bust_text
    j result_win
player_win:
    la $a0, win_text
    j result_win
dealer_win:
    la $a0, lose_text
result_lose:
    la $t0, lose_label
    j finish
result_win:
    la $t0, win_label
    j finish
result_push:
    la $t0, push_label
finish:
    sw $t0, status_ptr
    jal print_str
    li $t0, 1
    sw $t0, show_dealer
    jal refresh
    jal ask_replay
    bnez $v0, new_round
quit:
    la $a0, bye_text
    jal print_str
    li $v0, 10
    syscall
exhausted:
    la $a0, deck_error
    jal print_str
    jal ask_replay
    bnez $v0, new_round
    j quit

# shuffle_deck(): build ranks 1..13 four times; Fisher-Yates shuffle.
shuffle_deck:
    addiu $sp, $sp, -32
    sw $ra, 28($sp)
    sw $s0, 24($sp)
    sw $s1, 20($sp)
    sw $zero, deck_pos
    la $s1, deck
    li $t0, 0
deck_fill:
    li $t1, 13
    divu $t0, $t1
    mfhi $t2
    addiu $t2, $t2, 1
    sll $t3, $t0, 2
    addu $t3, $t3, $s1
    sw $t2, 0($t3)
    addiu $t0, $t0, 1
    blt $t0, 52, deck_fill
    li $s0, 51
shuffle_loop:
    addiu $a0, $s0, 1
    jal random_below
    sll $t0, $s0, 2
    addu $t0, $t0, $s1
    sll $t1, $v0, 2
    addu $t1, $t1, $s1
    lw $t2, 0($t0)
    lw $t3, 0($t1)
    sw $t3, 0($t0)
    sw $t2, 0($t1)
    addiu $s0, $s0, -1
    bgtz $s0, shuffle_loop
    lw $s1, 20($sp)
    lw $s0, 24($sp)
    lw $ra, 28($sp)
    addiu $sp, $sp, 32
    jr $ra

# deal_card() -> v0=next rank, or 0 if deck empty.
deal_card:
    lw $t0, deck_pos
    li $v0, 0
    bge $t0, 52, deal_done
    sll $t1, $t0, 2
    lw $v0, deck($t1)
    addiu $t0, $t0, 1
    sw $t0, deck_pos
deal_done:
    jr $ra

# give_card(a0=0 player / 1 dealer) -> v0=rank or 0 on failure.
give_card:
    addiu $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    move $s0, $a0
    jal deal_card
    beqz $v0, give_done
    la $t0, player_hand
    la $t1, player_count
    beqz $s0, give_store
    la $t0, dealer_hand
    la $t1, dealer_count
give_store:
    lw $t2, 0($t1)
    sll $t3, $t2, 2
    addu $t3, $t3, $t0
    sw $v0, 0($t3)
    addiu $t2, $t2, 1
    sw $t2, 0($t1)
give_done:
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addiu $sp, $sp, 24
    jr $ra

# hand_total(a0=array address, a1=count) -> v0=best total.
# First count aces as 11, then subtract 10 per ace while over 21.
hand_total:
    li $v0, 0
    li $t0, 0             # number of aces currently counted as 11
    move $t1, $a0
    move $t2, $a1
total_loop:
    beqz $t2, adjust_aces
    lw $t3, 0($t1)
    beq $t3, 1, count_ace
    ble $t3, 10, add_value
    li $t3, 10
    j add_value
count_ace:
    li $t3, 11
    addiu $t0, $t0, 1
add_value:
    addu $v0, $v0, $t3
    addiu $t1, $t1, 4
    addiu $t2, $t2, -1
    j total_loop
adjust_aces:
    ble $v0, 21, total_done
    beqz $t0, total_done
    addiu $v0, $v0, -10
    addiu $t0, $t0, -1
    j adjust_aces
total_done:
    jr $ra

# print_hand(a0=array, a1=count, a2=hide second card).
print_hand:
    addiu $sp, $sp, -40
    sw $ra, 36($sp)
    sw $s0, 32($sp)
    sw $s1, 28($sp)
    sw $s2, 24($sp)
    sw $s3, 20($sp)
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    li $s3, 0
hand_print_loop:
    beq $s3, $s1, hand_print_done
    beqz $s2, hand_print_rank
    bne $s3, 1, hand_print_rank
    la $a0, hidden_text
    jal print_str
    j hand_print_next
hand_print_rank:
    sll $t0, $s3, 2
    addu $t0, $t0, $s0
    lw $t0, 0($t0)
    sll $t0, $t0, 2
    lw $a0, rank_names($t0)
    jal print_str
    la $a0, space_text
    jal print_str
hand_print_next:
    addiu $s3, $s3, 1
    j hand_print_loop
hand_print_done:
    bnez $s2, hand_print_newline
    la $a0, total_text
    jal print_str
    move $a0, $s0
    move $a1, $s1
    jal hand_total
    move $a0, $v0
    jal print_int
hand_print_newline:
    la $a0, newline
    jal print_str
    lw $s3, 20($sp)
    lw $s2, 24($sp)
    lw $s1, 28($sp)
    lw $s0, 32($sp)
    lw $ra, 36($sp)
    addiu $sp, $sp, 40
    jr $ra

# refresh(): draw and print both hands, respecting the hidden card.
refresh:
    addiu $sp, $sp, -24
    sw $ra, 20($sp)
    jal draw_blackjack
    la $a0, dealer_text
    jal print_str
    la $a0, dealer_hand
    lw $a1, dealer_count
    lw $t0, show_dealer
    xori $a2, $t0, 1
    jal print_hand
    la $a0, player_text
    jal print_str
    la $a0, player_hand
    lw $a1, player_count
    li $a2, 0
    jal print_hand
    lw $ra, 20($sp)
    addiu $sp, $sp, 24
    jr $ra

# draw_hand(a0=array, a1=count, a2=top y, a3=hide second).
# Six cards per row, up to two rows. At most 12 can be reached:
# the lowest-valued 12 cards in one deck already total 24.
draw_hand:
    addiu $sp, $sp, -48
    sw $ra, 44($sp)
    sw $s0, 40($sp)
    sw $s1, 36($sp)
    sw $s2, 32($sp)
    sw $s3, 28($sp)
    sw $s4, 24($sp)
    sw $s5, 20($sp)
    sw $s6, 16($sp)
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    move $s3, $a3
    li $s4, 0
draw_hand_loop:
    bge $s4, $s1, draw_hand_done
    li $t0, 6
    divu $s4, $t0
    mflo $t1
    mfhi $t2
    li $t0, 10
    mul $s5, $t2, $t0
    addiu $s5, $s5, 2   # left x
    sll $s6, $t1, 3
    addu $s6, $s6, $s2 # top y
    move $a0, $s5
    move $a1, $s6
    li $a2, 0x00090007 # card is 9 by 7
    li $a3, WHITE
    beqz $s3, card_background
    bne $s4, 1, card_background
    li $a3, BLUE
card_background:
    jal fill_rect
    sll $t0, $s4, 2
    addu $t0, $t0, $s0
    lw $t0, 0($t0)
    beqz $s3, card_rank
    bne $s4, 1, card_rank
    li $t0, 0          # rank zero maps to ?
card_rank:
    sll $t0, $t0, 2
    lw $a0, rank_names($t0)
    addiu $a1, $s5, 1
    addiu $a2, $s6, 1
    li $a3, INK
    jal draw_text
    addiu $s4, $s4, 1
    j draw_hand_loop
draw_hand_done:
    lw $s6, 16($sp)
    lw $s5, 20($sp)
    lw $s4, 24($sp)
    lw $s3, 28($sp)
    lw $s2, 32($sp)
    lw $s1, 36($sp)
    lw $s0, 40($sp)
    lw $ra, 44($sp)
    addiu $sp, $sp, 48
    jr $ra

# draw_blackjack(): title, labels, totals, card rectangles, status.
draw_blackjack:
    addiu $sp, $sp, -24
    sw $ra, 20($sp)
    li $a0, BG
    jal clear_screen
    la $a0, title
    li $a1, 14
    li $a2, 2
    li $a3, WHITE
    jal draw_text
    la $a0, dealer_label
    li $a1, 2
    li $a2, 10
    li $a3, GOLD
    jal draw_text
    la $a0, player_label
    li $a1, 2
    li $a2, 35
    li $a3, BLUE
    jal draw_text
    la $a0, dealer_hand
    lw $a1, dealer_count
    li $a2, 17
    lw $t0, show_dealer
    xori $a3, $t0, 1
    jal draw_hand
    la $a0, player_hand
    lw $a1, player_count
    li $a2, 42
    li $a3, 0
    jal draw_hand
    lw $t0, show_dealer
    bnez $t0, draw_dealer_total
    li $a0, 63          # ? hides the total as well as the card
    li $a1, 38
    li $a2, 10
    li $a3, GOLD
    jal draw_char
    j draw_player_total
draw_dealer_total:
    la $a0, dealer_hand
    lw $a1, dealer_count
    jal hand_total
    move $a0, $v0
    li $a1, 38
    li $a2, 10
    li $a3, GOLD
    jal draw_number
draw_player_total:
    la $a0, player_hand
    lw $a1, player_count
    jal hand_total
    move $a0, $v0
    li $a1, 38
    li $a2, 35
    li $a3, BLUE
    jal draw_number
    lw $a0, status_ptr
    li $a1, 8
    li $a2, 58
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