	.INCLUDE "m328Pdef.inc"

	.org 0x00 
	rjmp reset  
	.org INT0addr
	rjmp INT0_vect
	.org 0x34     
	    
	.org 0x0016 jmp TIMER1_COMPA




	reset:
;***** CONFIG INT. EXTER ********************
; Set Interrupt to trigger when input is at low level

	ldi r16, (1<<ISC01)|(1<<ISC00)	
	sts EICRA, r16					
	
	ldi r16, (1<<INT0)				
	out EIMSK, r16					

	ldi r16, (1<<INTF0)
	out EIFR, r16

	; Sets PORTB as output
	ldi r16, 0x04						
	out DDRB, r16					

	; Sets PORTD as input						
 	ldi r17, 0x04						
	out DDRD, r17

	; Resets r18 and PORTB
	clr r18
	out PORTB, r18
	ldi r18, 0x04
	; Global Enable Interrupt
	sei								
	
;******* FIM CONFIG INT. EXTER *************		

	main:

	
		ldi r16, 0xFF
		out DDRD, r16
		out DDRB, r16 

		ldi r22, 0b00010000 ; LED T
		ldi r23, 0b00100000 ; LED W
		ldi r24, 0b01000000 ; LED O
		ldi r25, 0b10000000 ; LED F

;***** CONFIG. TIMER ************************
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
;******** FIM COFIG TIMER ********************
	
		ldi r19, 0x00
		out PORTB, r19  ; DESLIGA OS 7 LEDS
		
		ldi r19, 0b00000001  
				; 0b00000001 - LIGA D1  
				; 0b00000011 - LIGA D2       
				; 0b00000101 - LIGA D3 
				; 0b00000111 - LIGA D4
				; 0b00001001 - LIGA D5
				; 0b00001011 - LIGA D6
				; 0b00001101 - LIGA D7

	
		
	

loop:	
	

rjmp loop

	
led_run:

		out PORTB, r19 ; RECEBE O CONTEÚDO DE r19 
ret


led_timerH:

		sbi PORTD, PD4 ; LIGA O LED T

ret

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
ret
		

led_WeekOn:

		
		sbi PORTD, PD6 ; LIGA O LED O

		sbi PORTB, PB0 ; LIGA O LED D1

		 ; TOGGLE LED W
			in r17, PORTD
			eor r17, r23
		out PORTD, r17 
ret
		

led_OffM:

		 ; TOGGLE LED F
			in r17, PORTD
			eor r17, r25
			out PORTD, r17 

ret

led_OffH:

			sbi PORTD, PD7 ; LIGA O LED F

ret

led_WeekOff:

			sbi PORTD, PD7 ; LIGA O LED F
			sbi PORTB, PB0 ; LIGA O LED D1

		  ; TOGGLE LED W
			in r17, PORTD
			eor r17, r23
			out PORTD, r17 
		
ret


; ***** TIMER *************
TIMER1_COMPA:
		
		call led_OffM
reti
;****** FIM TIMER *********

;****** INT ***************
INT0_vect:
	
	call led_OffH
reti
