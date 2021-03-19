.INCLUDE "m328Pdef.inc"

.ORG   0x0000                  // Tells the next instruction to be written
rjmp   main                    // State that the program begins at the main label

main:
	ldi r16, 0xFF             
	out DDRB, r16 
	out DDRD, r16             
	

	
	ldi r19, 0b00000000
	ldi r20, 0b00000000
	

loop:

	
	
	

rjmp loop

delay:
	dec r18 ; decremente r18
	brne delay ; salte para delay_loop se r18 n~ao ´e 0
	dec r17 ; decremente r17
	brne delay ; salte para delay_loop se r17 n~ao ´e 0
	dec r19 ; decrament r19
	brne delay ; salte para delay_loop se r19 n~ao ´e 0
	ret ; retorne


led_run:

	out PORTB, r19


led_timerH:

	sbi PORTD, PD4 ; LIGA O LED T

	led_timerM:
		
	sbi PORTD, PD4 ; LIGA O LED T
	call delay
	cbi PORTD, PD4 ; DESLIGA O LED T
	call delay
		
	rjmp led_timerM

led_Week:

	sbi PORTD, PD4 ; LIGA O LED T
	sbi PORTB, PB0 ; LIGA O LED D1

	sbi PORTD, PD5 ; LIGA O LED W
	call delay
	cbi PORTD, PD5 ; DESLIGA O LED W
	call delay

	rjmp led_Week


led_OnH:

	sbi PORTD, PD6 ; LIGA O LED O


led_OnM:

	sbi PORTD, PD6 ; LIGA O LED O
	call delay
	cbi PORTD, PD6 ; DESLIGA O LED O
	call delay

		
		

led_WeekOn:

		
	sbi PORTD, PD6 ; LIGA O LED O

	sbi PORTB, PB0 ; LIGA O LED D1

	sbi PORTD, PD5 ; LIGA O LED W
	call delay
	cbi PORTD, PD5 ; DESLIGA O LED W
	call delay

		

led_OffM:

	sbi PORTD, PD7 ; LIGA O LED F
	call delay
	cbi PORTD, PD7 ; DESLIGA O LED F
	call delay

	rjmp led_OffM

led_OffH:

		sbi PORTD, PD7 ; LIGA O LED F

led_WeekOff:

		sbi PORTD, PD7 ; LIGA O LED F
		sbi PORTB, PB0 ; LIGA O LED D1

		sbi PORTD, PD5 ; LIGA O LED W
		call delay
		cbi PORTD, PD5 ; DESLIGA O LED W
		call delay

		rjmp led_WeekOff
