;
; ProgramadorHorario.asm
;
; Created: 19/03/2021 07:27:17
; Author : Fantasma
;
;r18 - SPI DATA OUT
;r27 - SPI DATA IN

;r24 - GET/SET MIN.		(RTC_GET_M: r24 <= SPDR) | (RTC_SET_M: SPIDR <= r24)
;r25 - GET/SET HOUR.	(RTC_GET_H: r25 <= SPDR) | (RTC_SET_H: SPIDR <= r25)
;r26 - GET/SET DAY.		(RTC_GET_D: r26 <= SPDR) | (RTC_SET_D: SPIDR <= r26)

;R23 - NUMBER DISPLAYS
.cseg
	.org 0x00						
	rjmp reset
	.org INT0addr
	rjmp INT0_vect
	.org 0x34						 

reset:
	
	; Set Interrupt to trigger when input is at low level
	ldi r16, (1<<ISC01)|(0<<ISC00)	
	sts EICRA, r16					
	
	ldi r16, (1<<INT0)				
	out EIMSK, r16					

	ldi r16, (1<<INTF0)
	out EIFR, r16

	; Sets PORTB as output
	ldi r16, 0x04						
	out DDRB, r16					

	; Resets r18 and PORTB
	clr r18
	out PORTB, r18
	
	; Global Enable Interrupt
	sei								

	RJMP	SETUP_LOOP

	; Interrupt Vector
INT0_vect:
	RCALL	RTC_RESET_ALARMS
	ldi r30, 0x04
	in r17, PORTB
	eor r17, r30
	out PORTB, r17
	reti

SETUP_LOOP:
LDI		r17, (1<<DDB3) | (1<<DDB5) | (1<<DDB2) | (1<<DDB1)
OUT		DDRB, r17

LDI		r24, 0x59 ; 59min.
LDI		r25, 0x12 ; 12horas
LDI		r26, 0x03 ; Terça-Feira
RCALL RTC_SETUP	; Setup Hora, alarmes e interrupção

LDI		r24, 0x00 ; 59min.
LDI		r25, 0x13 ; 12horas
LDI		r26, 0x03 ; Terça-Feira
RCALL	RTC_SETUP_ALARM1

LDI		r24, 0x02 ; 59min.
LDI		r25, 0x13 ; 12horas
LDI		r26, 0x03 ; Terça-Feira
RCALL	RTC_SETUP_ALARM2

RCALL DISPLAY_SETUP

MAIN_LOOP:

;RCALL	RTC_GET_M ; r25 <= SPDR (Resposta do SPI)
;RCALL	PRINT_MINUTO

RCALL	RTC_GET_H ; r25 <= SPDR (Resposta do SPI)
RCALL	PRINT_HORA
JMP	MAIN_LOOP

;************************************
DISPLAY_ON:
	LDI		r17, (0<<PB2) | (1<<PB1)
	OUT		PORTB, r17
	RET
;------------------------------------

;************************************
DISPLAY_OFF:
	LDI		r17, (1<<PB2) | (1<<PB1)
	OUT		PORTB, r17
	RET
;------------------------------------

;************************************
RTC_ON:
	LDI		r17, (1<<PB2) | (0<<PB1)
	OUT		PORTB, r17
	RET
;------------------------------------

;************************************
RTC_OFF:
	LDI		r17, (1<<PB2) | (1<<PB1)
	OUT		PORTB, r17
	RET
;------------------------------------

;************************************
SPI_MODE_0:
	LDI		r17, (1<<SPE) | (1<<MSTR)
	OUT		SPCR, r17
	RET
;------------------------------------

;************************************
SPI_MODE_1:
	LDI		r17, (1<<SPE) | (1<<MSTR) | (1<<CPHA)
	OUT		SPCR, r17
	RET
;------------------------------------

;************************************
SPI_TRANSFER:
	OUT		SPDR, r18
SPI_WAIT_TRANSFER:
	IN		r16, SPSR
	SBRS	r16, SPIF
	RJMP	SPI_WAIT_TRANSFER
	RET
;------------------------------------

;************************************
DISPLAY_SETUP:
	RCALL	SPI_MODE_0
	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	LDI		r18, 0x0C ;shutdown mode
	RCALL	SPI_TRANSFER
	LDI		r18, 0x01
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	LDI		r18, 0x09 ;decode mode
	RCALL	SPI_TRANSFER
	LDI		r18, 0xFF
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	LDI		r18, 0x0A ;intensity
	RCALL	SPI_TRANSFER
	LDI		r18, 0X0F 
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	LDI		r18, 0x0B ;scan limit
	RCALL	SPI_TRANSFER
	LDI		r18, 0x03
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	RET
;------------------------------------

;************************************
RTC_SETUP:
	RCALL	RTC_SET_M
	RCALL	RTC_SET_H
	RCALL	RTC_SET_D
	RCALL	RTC_SET_CONTROL_REGISTER
	RET
;------------------------------------

;************************************
RTC_SETUP_ALARM1:
	RCALL	RTC_SET_M_A1
	RCALL	RTC_SET_H_A1
	RCALL	RTC_SET_D_A1
	RET
;------------------------------------

;************************************
RTC_SETUP_ALARM2:
	RCALL	RTC_SET_M_A2
	RCALL	RTC_SET_H_A2
	RCALL	RTC_SET_D_A2
	RET
;------------------------------------

;************************************
RTC_SET_CONTROL_REGISTER:
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x8E ;CMD Set minutes
	RCALL	SPI_TRANSFER
	LDI		r18, 0x07 ;Set Flag alarm 1 e 2 e habilita interrupção.
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
RTC_RESET_ALARMS:
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x8F ;CMD Set minutes
	RCALL	SPI_TRANSFER
	LDI		r18, 0xC8 ;Set Flag alarm 1 e 2 e habilita interrupção.
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
RTC_SET_M:
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x81 ;CMD Set minutes
	RCALL	SPI_TRANSFER
	MOV		r18, r24 ;Set MINUTO.
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
RTC_SET_M_A1: ;Set Minutos do alarme 1
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x88 ;CMD Set minutes alarme 1
	RCALL	SPI_TRANSFER
	MOV		r18, r24 ;Set MINUTO.
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
RTC_SET_M_A2: ;Set Minutos do alarme 2
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x8B ;CMD Set minutes alarme 2
	RCALL	SPI_TRANSFER
	MOV		r18, r24 ;Set MINUTO.
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
RTC_SET_H:
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x82 ;CMD Set hour
	RCALL	SPI_TRANSFER
	MOV		r18, r25 ;Set HORA.
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
RTC_SET_H_A1: ;Set Horas do alarme 1
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x89 ;CMD Set hour alarme 1
	RCALL	SPI_TRANSFER
	MOV		r18, r25 ;Set HORA.
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
RTC_SET_H_A2: ;Set Horas do alarme 2
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x8C ;CMD Set hour alarme 2
	RCALL	SPI_TRANSFER
	MOV		r18, r25 ;Set HORA.
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
RTC_SET_D:
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x83 ;CMD Set Day week (1:Dom. | 2:Seg. | ... |7:Sab.)
	RCALL	SPI_TRANSFER
	MOV		r18, r26 ;Set DIA.
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
RTC_SET_D_A1: ;Set Dia da semana do alarme 1
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x8A ;CMD Set Day week (1:Dom. | 2:Seg. | ... |7:Sab.)
	RCALL	SPI_TRANSFER
	MOV		r18, r26 ;Set DIA. alarme 1
	ORI		r18, 0x40 ;Set DY/DT~ para Dia da semana
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
RTC_SET_D_A2: ;Set Dia da semana do alarme 2
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x8D ;CMD Set Day week (1:Dom. | 2:Seg. | ... |7:Sab.)
	RCALL	SPI_TRANSFER
	MOV		r18, r26 ;Set DIA. alarme 2
	ORI		r18, 0x40 ;Set DY/DT~ para Dia da semana
	RCALL	SPI_TRANSFER
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
RTC_GET_M:
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x01 ;CMD Set minutes
	RCALL	SPI_TRANSFER
	LDI		r18, 0xFF ;DUMMY BYTE - RESPONSE MINUTO.
	RCALL	SPI_TRANSFER
	IN		r24, SPDR ;GET MINUTO
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
RTC_GET_H:
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x02 ;CMD Set minutes
	RCALL	SPI_TRANSFER
	LDI		r18, 0xFF ;DUMMY BYTE - RESPONSE MINUTO.
	RCALL	SPI_TRANSFER
	IN		r25, SPDR ;GET HORA
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
RTC_GET_D:
	RCALL	SPI_MODE_1
	RCALL	RTC_OFF
	NOP
	RCALL	RTC_ON
	LDI		r18, 0x03 ;CMD Set minutes
	RCALL	SPI_TRANSFER
	LDI		r18, 0xFF ;DUMMY BYTE - RESPONSE MINUTO.
	RCALL	SPI_TRANSFER
	IN		r26, SPDR ;GET DIA
	RCALL	RTC_OFF
	RET
;------------------------------------

;************************************
PRINT_DISPLAY:
	LDI r16, 0x80

	RCALL	RTC_GET_M ; r24 <= SPDR (Resposta do SPI)
	RCALL	RTC_GET_H ; r25 <= SPDR (Resposta do SPI)
	RCALL	SPI_MODE_0
	LDI		r23, 0x04 ;exibir no display 4 as unidades dos minutos
	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	MOV		r18, r23
	RCALL	SPI_TRANSFER
	MOV		r18, r24 ; r27 <= SPDR (Resposta do SPI) unidade
	ADD		R18, R16	; para exibir os dois pontos
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	
	SWAP	r24 ;Trocar nibbles para exibir a dezena do minuto - Nibble mais significativo é ignorado
	LDI		r23, 0x03 ;exibir no display 3 as dezenas dos minutos
	RCALL	DISPLAY_ON
	MOV		r18, r23
	RCALL	SPI_TRANSFER
	MOV		r18, r24 ; r27 <= SPDR (Resposta do SPI) unidade
	ADD		R18, R16	; para exibir os dois pontos
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	
	LDI		r23, 0x02 ;exibir no display 2
	RCALL	DISPLAY_ON
	MOV		r18, r23
	RCALL	SPI_TRANSFER
	MOV		r18, r25
	ADD		R18, R16	; para exibir os dois pontos
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	
	SWAP	r25 ;Trocar nibbles para exibir a dezena da hora - Nibble mais significativo é ignorado
	LDI		r23, 0x01 ;exibir no display 1
	RCALL	DISPLAY_ON
	MOV		r18, r23
	RCALL	SPI_TRANSFER
	MOV		r18, r25 ; r27 <= SPDR (Resposta do SPI) unidade
	ADD		r18, r16	; para exibir os dois pontos
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	RET
;------------------------------------

PRINT_MINUTO:
	RCALL	SPI_MODE_0
	LDI		r23, 0x04 ;exibir no display 4 as unidades dos minutos
	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	MOV		r18, r23
	RCALL	SPI_TRANSFER
	MOV		r18, r24 ; unidade do minuto
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	
	SWAP	r24 ;Trocar nibbles para exibir a dezena do minuto - Nibble mais significativo é ignorado
	LDI		r23, 0x03 ;exibir no display 3 as dezenas dos minutos
	RCALL	DISPLAY_ON
	MOV		r18, r23
	RCALL	SPI_TRANSFER
	MOV		r18, r24 ; dezena do minuto
	ADD		R18, R16	; para exibir os dois pontos
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF

	;***Desligar display 1 e 2***
	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	LDI		r18, 0x02 ;exibir no display 2
	RCALL	SPI_TRANSFER
	LDI		r18, 0x7F ;blank
	RCALL	SPI_TRANSFER

	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	LDI		r18, 0x01 ;exibir no display 1
	RCALL	SPI_TRANSFER
	LDI		r18, 0x7F ;blank
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	;----------------------------
	RET
;------------------------------------

PRINT_HORA:
	RCALL	SPI_MODE_0
	LDI		r23, 0x02 ;exibir no display 2
	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	MOV		r18, r23
	RCALL	SPI_TRANSFER
	MOV		r18, r25 ; unidade da hora
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	
	SWAP	r25 ;Trocar nibbles para exibir a dezena da hora - Nibble mais significativo é ignorado
	LDI		r23, 0x01 ;exibir no display 1
	RCALL	DISPLAY_ON
	MOV		r18, r23
	RCALL	SPI_TRANSFER
	MOV		r18, r25 ; dezena da hora
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF

	;***Desligar display 3 e 4***
	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	LDI		r18, 0x04 ;exibir no display 4
	RCALL	SPI_TRANSFER
	LDI		r18, 0x7F ;blank
	RCALL	SPI_TRANSFER

	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	LDI		r18, 0x03 ;exibir no display 3
	RCALL	SPI_TRANSFER
	LDI		r18, 0x7F ;blank
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	;----------------------------
	RET
;------------------------------------