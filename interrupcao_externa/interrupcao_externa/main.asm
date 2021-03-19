.cseg
	.org 0x00						
	rjmp reset
	.org INT0addr
	rjmp INT0_vect
	.org 0x34						 

reset:
	
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

	; Main Loop
main:								
	rjmp main							

	; Interrupt Vector
INT0_vect:
	in r17, PORTB
	eor r17, r18
	out PORTB, r17
	reti