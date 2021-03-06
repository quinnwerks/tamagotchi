.equ ADDR_VGA, 0x08000000
.equ VGATIMER, 0xff202020
.equ HPTIMER, 0xff202000
.equ SECOND, 50000000
.equ FIVE, 500000000
.equ POINTFIVE, 25000000
.equ PS2, 0xFF200100
.equ ADC, 0xFF204000

.section .exceptions, "ax"
ISR:
	addi sp, sp, -8
	stw r16, 0(sp)
	stw r17, 4(sp)
	rdctl et, ipending
	andi et, et, 0x80
	bne et, r0, PS2Input
	rdctl et, ipending
	andi et, et, 0b1
	bne et, r0, LoseHP
	br exit

PS2Input:
	addi sp, sp, -8
	stw r2, 0(sp)
	stw ra, 4(sp)
	#exit if not break code 0xF0
	call readPS2
	movi et, 0xF0
	beq r2, et, BREAK
	movia r17, PS2_BREAK
	ldw r16, (r17)
	movi r17, 1
	bne r16, r17, dealloc
	movi r16, 0x2B
	#check feed
	beq r2, r16, feed
	movi r16, 0x4D
	beq r2, r16, pet
	br dealloc

	#write 1 into break if 0xf0
	BREAK:
		movia r17, PS2_BREAK
		movi r16, 1
		stw r16, 0(r17)
		br dealloc

	feed:
		movia r17, VGATIMER
		movi r16, 0b1000
		stw r16, 0(r17)
		#change vga state to 5
		movia r17, VGA_STATE
		movi r16, 5
		stw r16, 0(r17)
		#restore 20 hp
		movia r17, PET_HP
		ldw r16, (r17)
		addi r16, r16, 20
		stw r16, (r17)
		#reset breaking status to 0
		movia r17, PS2_BREAK
		stw r0, 0(r17)
		movia r17, VGATIMER
		movi r16, 0b100
		stw r16, 0(r17)
		br dealloc

	pet:
		addi sp, sp, -4
		stw r4, 0(sp)

		#draw new frame and wait
		movi r4, 1
		call getToScreen

		INIT_TIMER:
		#poll adc after 0.5s
		#set up polling timer for 0.1s period
		movia r17, VGATIMER
		movui r16, %lo(POINTFIVE)
		stwio r16, 8(r17)
		movui r16, %hi(POINTFIVE)
		stwio r16, 12(r17)
		stwio r0, 0(r17)
		movi r16, 0b100
		stwio r16, 4(r17)

		#poll1
		poll1:
			ldwio r16, 0(r17)
			andi r16, r16, 1
			beq r16, r0, poll1

		#read adc value from channel 0
		movia r17, ADC
		movi r16, 1
		stwio r16, 0(r17)
		ldwio r16, 0(r17)

		#if less than 0x100, poll again
		movi r17, 0x100
		blt r16, r17, INIT_TIMER

		#if force too much, set HURT to 1
		movi r17, 0xB00
		blt r16, r17, petting
		movia r17, HURT
		movi r16, 1
		stw r16, (r17)
		#and subtract HP by 20
		movia r17, PET_HP
		ldw r16, (r17)
		subi r16, r16, 20
		stw r16, (r17)
		br pet_ready

		petting:
			movia r17, HURT
			stw r0, 0(r17)
			#increase HP by 10
			movia r17, PET_HP
			ldw r16, (r17)
			addi r16, r16, 10
			stw r16, (r17)

		pet_ready:
			movia r17, VGA_STATE
			movi r16, 12
			stw r16, (r17)

		#reset VGA timer
		movia r17, VGATIMER
		movui r16, %lo(SECOND)
		stwio r16, 8(r17)
		movui r16, %hi(SECOND)
		stwio r16, 12(r17)
		stwio r0, 0(r17)
		movi r16, 0b100
		stwio r16, 4(r17)

		ldw r4, 0(sp)
		addi sp, sp, 4
		br dealloc

	dealloc:
    	ldw r2, 0(sp)
    	ldw ra, 4(sp)
    	addi sp, sp, 8
		br exit

LoseHP:
	movia r17, VGATIMER
	movi r16, 0b1000
	stw r16, 0(r17)
	movia r17, PET_HP
	ldw r16, 0(r17)
	subi r16, r16, 10
	stw r16, 0(r17)

	#reset timer
	movia r17, HPTIMER
	stwio r0, 0(r17)
	movia r17, VGATIMER
	movi r16, 0b100
	stw r16, 0(r17)
	br exit

exit:
	ldw r16, 0(sp)
	ldw r17, 4(sp)
	addi sp, sp, 8
	addi ea, ea, -4
	eret

# global variables and address's used
.section .data
.align 2
IMAGE0:
.incbin "frame0.bin"

IMAGE1:
.incbin "frame1.bin"

IMAGE2:
.incbin "frame2.bin"

IMAGE3:
.incbin "frame3.bin"

FEED0:
.incbin "feed0.bin"

FEED1:
.incbin "feed1.bin"

FEED2:
.incbin "feed2.bin"

FEED3:
.incbin "feed3.bin"

FEED4:
.incbin "feed4.bin"

FEED5:
.incbin "feed5.bin"

FEED6:
.incbin "feed6.bin"


PET0:
.incbin "pet0.bin"

PET1:
.incbin "pet1.bin"

PET2:
.incbin "pet2.bin"

PET3:
.incbin "pet3.bin"

PET4:
.incbin "pet4.bin"

PET5:
.incbin "pet5.bin"

PET6:
.incbin "pet6.bin"

PET7:
.incbin "pet7.bin"

PET8:
.incbin "pet8.bin"

PET9:
.incbin "pet9.bin"

PREPET0:
.incbin "prepet0.bin"

DEATH:
.incbin "gameover.bin"


.align 2
VGA_STATE:
 .word 0
PET_HP:
.word 100

PS2_BREAK:
.word 0

HURT:
.word 0

.section .text
.global _start
_start:
# stack
movia sp, 0x03FFFFFC

#init HP
movia r8, PET_HP
movi r9, 100
stw r9, (r8)

#init hurt
movia r8, HURT
stw r0, 0(r8)

#initialize keyboard
movia r8, PS2
movi r9, 1
stwio r9, 4(r8)

#VGA Timer 2
movia r14, VGATIMER
stwio r0, 0(r14)
movui r10, %lo(SECOND)
stwio r10,  8(r14)
movui r10, %hi(SECOND)
stwio r10, 12(r14)

#HP timer 1
movia r8, HPTIMER
stwio r0, 0(r8)
movui r10, %lo(FIVE)
stwio r10, 8(r8)
movui r10, %hi(FIVE)
stwio r10, 12(r8)
movi r10, 0b111
stwio r10, 4(r8)

#set timer 1 and keyboard interrupt
#movi r10, 0x81
movi r10, 0x81
wrctl ienable, r10
movi r10, 0b1
wrctl status, r10

# set initial vga state to zero
movia r9, VGA_STATE
movi  r8, 0
stw r8, 0(r9)

loop:

movia r9, VGA_STATE
ldw r8, 0(r9)
movi r9, 5
bge r8, r9, ISR_DIS

ISR_EN:
	movi r9, 1
	wrctl status, r9
	movia r8, HPTIMER
	movi r10, 0b111
	stwio r10, 4(r8)
	br next

ISR_DIS:
	movia r8, HPTIMER
	movi r10, 0b1000
	stwio r10, 4(r8)
	wrctl status, r0

next:
# load the image
call getToScreen
# start the timer
ldwio r15, 4(r14)
movi r15, 0b110
stwio r15, 4(r14)

# poll the vga timer (creates a SECOND delay)
pollVGA:
ldwio r15, (r14)
andi r15, r15, 1
beq r0, r15, pollVGA

call choosenext

stwio r0, 0(r14)

movia r9, VGA_STATE
ldw r8, (r9)
addi r8, r8, -4
beq r8, r0, DEATH_TIME
br loop

DEATH_TIME:

# DISABLE PIE
movia r8, HPTIMER
movi r10, 0b1000
stwio r10, 4(r8)
wrctl status, r0

mov r4, r0
call getToScreen
#VGA Timer 2
movia r14, VGATIMER
stwio r0, 0(r14)
movui r10, %lo(FIVE)
stwio r10,  8(r14)
movui r10, %hi(FIVE)
stwio r10, 12(r14)

# start the timer
ldwio r15, 4(r14)
movi r15, 0b110
stwio r15, 4(r14)

pollDEATH:
ldwio r15, (r14)
andi r15, r15, 1
beq r0, r15, pollDEATH

stwio r0, 0(r14)

br _start


.global choosenext
choosenext:
# state table cheat sheet
/*
 0 = default frame 0
 1 = default frame 1
 3 = low hp frame 0
 4 = low hp frame 1
 */

addi sp, sp, -20
stw sp,  0(sp)
stw r16,  4(sp)
stw r17,  8(sp)
stw r18, 12(sp)
stw r19, 16(sp)


movia r16, PET_HP
ldw r19, (r16)
blt r19, r0, HAS_DIED
addi r19, r19, -50



movia r16, VGA_STATE
ldw r17, (r16)

movi r18, 5
# move to special state table if not in default loop
bge r17, r18, CHECK_SPECIAL


# else determine HP level
bge r19, r0, CHECK_DEFAULT
blt r19, r0, CHECK_DEFAULT_LOW

CHECK_DEFAULT:
movi r18, 0
beq r17, r18, SET_TO_ONE
br SET_TO_ZERO

CHECK_DEFAULT_LOW:
movi r18, 2
beq r17, r18, SET_LOW_THREE
br SET_LOW_TWO
CHECK_SPECIAL:
# states 5, 6, 7, 8, 9, 10, 11 are feed states
movi r18, 11
ble r17, r18, SET_FEED
bgt r17, r18, SET_PET
br SET_TO_ZERO

# #####################################################
SET_TO_ONE:
movi r18, 1
stw r18, 0(r16)
br DONE
SET_TO_ZERO:
stw r0, 0(r16)
br DONE
# ######################################################
SET_LOW_THREE:
movi r18, 3
stw r18, 0(r16)
br DONE
SET_LOW_TWO:
movi r18, 2
stw r18, 0(r16)
br DONE
# #######################################################
SET_FEED:
# load VGA state again
ldw r17, 0(r16)
movi r18, 11
# if state is less than 10 increment
blt r17, r18, INC_FEED
br SET_TO_ZERO
INC_FEED:
addi r17, r17, 1
stw r17, 0(r16)
br DONE
# #######################################################
SET_PET:
ldw r17, 0(r16)

movi r18, 19
bgt r17, r18, SET_TO_ZERO
beq r17, r18, SET_Y_N_HURT
# else increment
addi r17, r17,1
stw r17, 0 (r16)
br DONE
SET_Y_N_HURT:
movia r18, HURT
ldw r17, (r18)
beq r17, r0, SET_TWENTY

movi r18, 21
stw r18, 0(r16)
br DONE

SET_TWENTY:
movi r18, 20
stw r18, 0(r16)


br DONE

HAS_DIED:
movi r18, 4
movia r16, VGA_STATE
stw r18, (r16)
br DONE

DONE:


# DEATH CHECK?
ldw sp,  0(sp)
ldw r16,  4(sp)
ldw r17,  8(sp)
ldw r18, 12(sp)
ldw r19, 16(sp)
addi sp, sp, 20


ret


.global getToScreen
getToScreen:
addi sp, sp, -24
stw ra,   0(sp)
stw r16,  4(sp)
stw r17,  8(sp)
stw r18,  12(sp)
stw r19,  16(sp)
stw r20,  20(sp)

mov r17, r0
movia r16, ADDR_VGA
movia r18, 0x25800
add r19, r17, r18



STARTWRTIE:
movi r20, 1

beq r4, r20, PREPET


movia r16, VGA_STATE

# r17 is now vga_state
ldw r17, (r16)


# state stable, to load to memory
beq r17, r0, NORM_0
addi r17, r17, -1

beq r17, r0, NORM_1
addi r17, r17, -1

beq r17, r0, LOW_2
addi r17, r17, -1

beq r17, r0, LOW_3
addi r17, r17, -1

beq r17, r0, DEATH_4
addi r17, r17, -1

beq r17, r0, FEED_5
addi r17, r17, -1

beq r17, r0, FEED_6
addi r17, r17, -1

beq r17, r0, FEED_7
addi r17, r17, -1

beq r17, r0, FEED_8
addi r17, r17, -1

beq r17, r0, FEED_9
addi r17, r17, -1

beq r17, r0, FEED_10
addi r17, r17, -1

beq r17, r0, FEED_11
addi r17, r17, -1

beq r17, r0, PET_12
addi r17, r17, -1

beq r17, r0, PET_13
addi r17, r17, -1

beq r17, r0, PET_14
addi r17, r17, -1

beq r17, r0, PET_15
addi r17, r17, -1

beq r17, r0, PET_16
addi r17, r17, -1

beq r17, r0, PET_17
addi r17, r17, -1

beq r17, r0, PET_18
addi r17, r17, -1

beq r17, r0, PET_19
addi r17, r17, -1

beq r17, r0, PET_20
addi r17, r17, -1

beq r17, r0, PET_21
addi r17, r17, -1

br NORM_0

PREPET:
movia r17, PREPET0
br WRITE_SCREEN

NORM_0:
movia r17, IMAGE0
br WRITE_SCREEN
NORM_1:
movia r17, IMAGE1
br WRITE_SCREEN
LOW_2:
movia r17, IMAGE2
br WRITE_SCREEN
LOW_3:
movia r17, IMAGE3
br WRITE_SCREEN
DEATH_4:
movia r17, DEATH
br WRITE_SCREEN
FEED_5:
movia r17, FEED0
br WRITE_SCREEN
FEED_6:
movia r17, FEED1
br WRITE_SCREEN
FEED_7:
movia r17, FEED2
br WRITE_SCREEN
FEED_8:
movia r17, FEED3
br WRITE_SCREEN
FEED_9:
movia r17, FEED4
br WRITE_SCREEN
FEED_10:
movia r17, FEED5
br WRITE_SCREEN
FEED_11:
movia r17, FEED6
br WRITE_SCREEN
PET_12:
movia r17, PET0
br WRITE_SCREEN
PET_13:
movia r17, PET1
br WRITE_SCREEN
PET_14:
movia r17, PET2
br WRITE_SCREEN
PET_15:
movia r17, PET3
br WRITE_SCREEN
PET_16:
movia r17, PET4
br WRITE_SCREEN
PET_17:
movia r17, PET5
br WRITE_SCREEN
PET_18:
movia r17, PET6
br WRITE_SCREEN
PET_19:
movia r17, PET7
br WRITE_SCREEN
PET_20:
movia r17, PET9
br WRITE_SCREEN
PET_21:
movia r17, PET8
br WRITE_SCREEN

# Now the address is found load the image, pixel by pixel onto the screen
WRITE_SCREEN:


movia r16, ADDR_VGA

# clear VGA
WRITE_LOOP:
ldh   r18, (r17)
sthio r18, (r16)
addi r16, r16, 2
addi r17, r17, 2
srli r19, r16, 1
andi r19, r19, 0x1FF

movi r20, 320
blt r19, r20, WRITE_LOOP
slli r19, r19, 1
sub r16, r16, r19
addi r16, r16, 0x400

srli r19, r16, 10
andi r19, r19 , 0xFF
movi r20, 240
blt r19, r20 , WRITE_LOOP

RETURN:
# return and restore stack
ldw ra,   0(sp)
ldw r16,  4(sp)
ldw r17,  8(sp)
ldw r18,  12(sp)
ldw r19,  16(sp)
ldw r20,  20(sp)
addi sp, sp, 24

ret
