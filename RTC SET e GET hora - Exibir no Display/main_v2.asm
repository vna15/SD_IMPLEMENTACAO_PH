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
.ORG 0x00

SETUP_LOOP:
LDI		r17, (1<<DDB3) | (1<<DDB5) | (1<<DDB2) | (1<<DDB1)
OUT		DDRB, r17

LDI		r24, 0x59 ; 59min.
LDI		r25, 0x12 ; 12horas
LDI		r26, 0x03 ; Terça-Feira
RCALL RTC_SETUP	;

RCALL DISPLAY_SETUP

MAIN_LOOP:
RCALL	PRINT_DISPLAY
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
	LDI		r17, 0x00
	LDI		r17, (1<<SPE) | (1<<MSTR)
	OUT		SPCR, r17
	RET
;------------------------------------

;************************************
SPI_MODE_1:
	LDI		r17, 0x00
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
	
	LSR		r24
	LSR		r24
	LSR		r24
	LSR		r24 ;deslocar 4x para a direita para enviar as dezenas dos minutos
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
	
	
	LSR		r25
	LSR		r25
	LSR		r25
	LSR		r25 ;deslocar 4x para a direita para enviar as dezenas da hora
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