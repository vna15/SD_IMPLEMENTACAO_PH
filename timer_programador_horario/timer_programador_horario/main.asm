;
; timer_programador_horario.asm
;
; Created: 18/03/2021 10:23:24
; Author : lucas
;
.include "m328pdef.inc"
.org 0x0000 jmp main
.org 0x0016 jmp TIMER1_COMPA

main:
	ldi r16, 0x04
	ldi r18, 0x04
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

wait:
	andi r20, 1
	rjmp wait

TIMER1_COMPA:
    in r17, PORTD
	eor r17, r18
	out PORTD, r17
	reti
