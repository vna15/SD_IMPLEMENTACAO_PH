
	.INCLUDE "m328Pdef.inc"

	.ORG   0x0000                  // Tells the next instruction to be written
	RJMP   MAIN                    // State that the program begins at the main label

	MAIN:
	LDI R16, 0xFF               // Load the immedate value 0xFF (all bits 1) into register 16
	OUT DDRB, R16               // Set Data Direction Register B to output for all pins
	OUT DDRD, R16

	
	
	; 124

	LOOP:
	
	sbi PORTB, PB0
	cbi PORTB, PB1
	cbi PORTB, PB2
	cbi PORTB, PB3
	call DELAY


	sbi PORTB, PB0
	sbi PORTB, PB1
	cbi PORTB, PB2
	cbi PORTB, PB3
	call DELAY

	sbi PORTB, PB0
	cbi PORTB, PB1
	sbi PORTB, PB2
	cbi PORTB, PB3
	call DELAY


	RJMP LOOP

	DELAY:
    dec r18 ; decremente r18
    brne DELAY ; salte para delay_loop se r18 n~ao ´e 0
    dec r17 ; decremente r17
    brne DELAY ; salte para delay_loop se r17 n~ao ´e 0
    dec r19 ; decrament r19
    brne DELAY ; salte para delay_loop se r19 n~ao ´e 0
    ret ; retorne
