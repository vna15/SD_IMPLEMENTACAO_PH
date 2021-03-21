;
; ProgramadorHorárioSD.asm
;
; Created: 17/03/2021 16:55:26
; Author : vnaze
;

.ORG 0x00


SPI_CONFIG:

	LDI		r17, (1<<DDB3) | (1<<DDB5) | (1<<DDB2) | (1<<DDB1) | (0<<DDB4)
	OUT		DDRB, r17
	
	LDI		r17, (1<<SPE) | (1<<MSTR) 
	OUT		SPCR, r17
	
	RCALL	DISPLAY_SETUP
	RCALL	RTC_SETUP
	RCALL	READ_TIME
	RJMP	JUMP
	//RJMP	SET_NUMBERS_DIF
	//RJMP	LOOP_NUMBERS

DISPLAY_ON:

	LDI		r17, (0<<PB2) | (1<<PB1)
	OUT		PORTB, r17
	RET

DISPLAY_OFF:
	
	LDI		r17, (1<<PB2) | (1<<PB1)
	OUT		PORTB, r17
	RET

DISPLAY_SETUP:
	
	RCALL	DISPLAY_ON
	LDI		r18, 0x0C ;shutdown mode
	RCALL	SPI_TRANSFER
	LDI		r18, 0x01
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF

	RCALL	DISPLAY_ON
	LDI		r18, 0x09 ;decode mode
	RCALL	SPI_TRANSFER
	LDI		r18, 0xFF
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF

	RCALL	DISPLAY_ON
	LDI		r18, 0x0A ;intensity
	RCALL	SPI_TRANSFER
	LDI		r18, 0X0F 
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF

	RCALL	DISPLAY_ON
	LDI		r18, 0x0B ;scan limit
	RCALL	SPI_TRANSFER
	LDI		r18, 0x03
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF

	RET

RTC_ON:

	LDI		r17, (1<<PB2) | (0<<PB1)
	OUT		PORTB, r17
	RET

RTC_OFF:

	LDI		r17, (1<<PB2) | (1<<PB1)
	OUT		PORTB, r17
	RET

RTC_SETUP:
	
	RCALL	RTC_ON
	LDI		r18, 0x8E ; control register
	RCALL	SPI_TRANSFER
	LDI		r18, 0b01011000
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF	

	RCALL	RTC_ON
	LDI		r18, 0x82 ; hora atual
	RCALL	SPI_TRANSFER
	LDI		r18, 0b00010111
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF

	RCALL	RTC_ON
	LDI		r18, 0x81 ; minuto atual
	RCALL	SPI_TRANSFER
	LDI		r18, 0b01001000
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF

	RCALL	RTC_ON
	LDI		r18, 0x83 ; dia atual
	RCALL	SPI_TRANSFER
	LDI		r18, 0b00000101
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF

	RET

READ_TIME:

	RCALL	RTC_ON
	LDI		r18, 0x02
	RCALL	SPI_TRANSFER
	RCALL	SPI_RECEIVE
	RCALL	RTC_OFF
	RCALL	DISPLAY_ON
	LDI		r18, 0x01
	RCALL	SPI_TRANSFER
	MOV		r18, r24
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF




SPI_RECEIVE:
    
	//SBIS	SPSR, SPIF
	RJMP	SPI_RECEIVE
	IN		r24, SPDR
	RET	
		
SPI_TRANSFER:

	OUT		SPDR, r18
	RJMP	SPI_WAIT_TRANSFER

SPI_WAIT_TRANSFER:

	IN		r16, SPSR
	SBRS	r16, SPIF
	RJMP	SPI_WAIT_TRANSFER
	RET

LOOP_NUMBERS_1:
	CPI		r22, 138
	BREQ	LOOP_NUMBERS
	RJMP	LOOP_NUMBERS_2

LOOP_NUMBERS_2:
	RCALL	DISPLAY_ON
	MOV		r18, r23
	RCALL	SPI_TRANSFER
	MOV		r18, r22
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	CPI		r23, 4
	BREQ	LOOP_NUMBERS_INC
	INC		r23
	RJMP	LOOP_NUMBERS_2

LOOP_NUMBERS:
	LDI		r22, 0x80
	LDI		r23, 0x01
	RJMP	LOOP_NUMBERS_1

LOOP_NUMBERS_INC:
	INC		r22
	LDI		r23, 0x01
	RCALL	delay
	RJMP	LOOP_NUMBERS_1

JUMP:
	RJMP	JUMP

SET_NUMBERS_DIF:
	
	RCALL	DISPLAY_ON
	LDI		R18, 0x01
	RCALL	SPI_TRANSFER
	LDI		R18, 0XF1
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF

	RCALL	DISPLAY_ON
	LDI		R18, 0x02
	RCALL	SPI_TRANSFER
	LDI		R18, 0XF2
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF

	RCALL	DISPLAY_ON
	LDI		R18, 0x03
	RCALL	SPI_TRANSFER
	LDI		R18, 0XF3
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF

	RCALL	DISPLAY_ON
	LDI		R18, 0x04
	RCALL	SPI_TRANSFER
	LDI		R18, 0XF4
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	
	RJMP	JUMP

init_timer:


	ldi r16, (1<<OCF1A)   
	out TIFR1, r16			; Clear OCF1A/clear pending interrupts

	lds    r18, 0x00		; Reseta o timer para 0  ;
	lds    r19, 0x00

	sts    TCNT1H, r18
	sts    TCNT1L, r19

	ldi r16, (1<<COM1A0)|(1<<COM1A1)	; As configurações do registrador TCCR1A				;
	sts TCCR1A, r16						; Em seguida armazenamos o valor no registrador TCCR1A	;

	ldi r16, 0x88				; Carregando o valor 5000 no OCR1A ;
	ldi r17, 0x13


	sts OCR1AL, r16
	sts OCR1AH, r17

	ldi r17, (1<<CS12)|(1<<CS10)|(0<<CS11)|(1 << WGM12)		; Precisamos definir qual vai ser o prescaler do clock, aqui será de clk/1024 e habilita o modo CTC ;														;
	sts TCCR1B, r17									; Em seguida armazenaos o valor no registrador TCCR1B

	ldi r16, (1<<OCIE1A)	; Habilita interrupção por comparação	;
	sts TIMSK1, r16			; Armazena no registrador TIMSK1		;

	ret
	
wait_timer:  

	sbis TIFR1, OCF1A		; Enquato a flag OCF1A não for igual a 1 se manterá no loop 
	rjmp wait_timer

	ret


end_timer:

	lds    r18, TCNT1L		; Carrega o valor do timer no r16 e 17 ;
	lds    r19, TCNT1H

	lds    r20, TCNT1L		; Carrega o valor do timer no r16 e 17 ;
	lds    r21, TCNT1H

	sts    TCNT1H, r18
	sts    TCNT1L, r19

	ldi r17, (0<<CS12)|(0<<CS10)|(0 << WGM12)		; desativa o timer ;														;
	sts TCCR1B, r17
	
	ret

timer:
	rcall init_timer
	rcall wait_timer
	rcall end_timer
	ret


delay:
	ldi  r16, 0x80
L3: ldi  r17, 0x80
L2: ldi  r25, 0x0A
L1: dec  r25
	CPI	 r25, 0
    brne L1
    dec  r17
	CPI	 r17, 0
    brne L2
    dec  r16
	CPI	r16, 0
    brne L3
	RET



    
