;
; delay.asm
;
; Created: 18/03/2021 18:27:30
; Author : lucas
;
; Replace with your application code
start:
	ldi r16, 0x04
	ldi r21, 0x04
	out DDRD, r16
while:	
	ldi  r18, 10
    ldi  r19, 255
	ldi  r20, 255
L1: dec  r20
    brne L1
	dec  r19
    brne L1
    dec  r18
    brne L1
	in r17, PORTD
	eor r17, r21
	out PORTD, r17
	rjmp while