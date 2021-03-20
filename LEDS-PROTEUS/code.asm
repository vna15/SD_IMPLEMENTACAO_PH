	.INCLUDE "m328Pdef.inc"

	.org 0x00 rjmp   main            
	.org 0x0016 jmp TIMER1_COMPA


	main:

	//*****INICIO TIMER ************************
		ldi r16, 0xFF
		ldi r22, 0b00010000 ; LED T
		ldi r23, 0b00100000 ; LED W
		ldi r24, 0b01000000 ; LED O
		ldi r25, 0b10000000 ; LED F

		out DDRD, r16
		ldi r16, 0x7A											;31250 (HIGH)
		ldi r17, 0x12											;31250 (LOW)
		sts OCR1AH, r16
		sts OCR1AL, r17
		ldi r16, (1 << OCIE1A)
		sts TIMSK1, r16
		ldi r16, (1 << WGM12)
		sts TCCR1B, r16
		sei
		ori r16, (1 << CS10) | (1 << CS11)
		sts TCCR1B, r16
	//******** FIM TIMER ***********************

		ldi r16, 0xFF             
		out DDRB, r16 
	

	
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
		ret


	led_timerH:

		sbi PORTD, PD4 ; LIGA O LED T

		led_timerM:

		 ; TOGGLE LED T
		in r17, PORTD
		eor r17, r22
		out PORTD, r17 
		
		
		ret

	led_Week:

		sbi PORTD, PD4 ; LIGA O LED T
		sbi PORTB, PB0 ; LIGA O LED D1

		 ; TOGGLE LED W
			in r17, PORTD
			eor r17, r23
			out PORTD, r17 

		ret


	led_OnH:

		sbi PORTD, PD6 ; LIGA O LED O

		ret


	led_OnM:

		 ; TOGGLE LED O
			in r17, PORTD
			eor r17, r24
			out PORTD, r17 

		
		

	led_WeekOn:

		
		sbi PORTD, PD6 ; LIGA O LED O

		sbi PORTB, PB0 ; LIGA O LED D1

		 ; TOGGLE LED W
			in r17, PORTD
			eor r17, r23
			out PORTD, r17 

		

	led_OffM:


		 ; TOGGLE LED F
			in r17, PORTD
			eor r17, r25
			out PORTD, r17 

		  rjmp led_OffM

	led_OffH:

			sbi PORTD, PD7 ; LIGA O LED F

	led_WeekOff:

			sbi PORTD, PD7 ; LIGA O LED F
			sbi PORTB, PB0 ; LIGA O LED D1

		  ; TOGGLE LED W
			in r17, PORTD
			eor r17, r23
			out PORTD, r17 
		
			ret


	// ***** TIMER *************
	TIMER1_COMPA:
		
		call led_WeekOff
		reti
