;
; timer_programador_horario.asm
;
; Created: 18/03/2021 10:23:24
; Author : lucas
;
;r18 - SPI DATA OUT
;r27 - SPI DATA IN

;r24 - GET/SET MIN.		(RTC_GET_M: r24 <= SPDR) | (RTC_SET_M: SPIDR <= r24)
;r25 - GET/SET HOUR.	(RTC_GET_H: r25 <= SPDR) | (RTC_SET_H: SPIDR <= r25)
;r26 - GET/SET DAY.		(RTC_GET_D: r26 <= SPDR) | (RTC_SET_D: SPIDR <= r26)

;R23 - NUMBER DISPLAYS

.cseg	
		.INCLUDE "m328Pdef.inc"
		.org 0x00 
			rjmp setup_interrupt  
		.org INT0addr
			rjmp INT0_vect
		.org 0x34        
		.org 0x0016 
			rjmp TIMER1_COMPA

;********* CONFIG INT. EXTER *****************
setup_interrupt:
		ldi r16, (1<<ISC01)|(1<<ISC00)	
		sts EICRA, r16					
	
		ldi r16, (1<<INT0)				
		out EIMSK, r16					

		ldi r16, (1<<INTF0)
		out EIFR, r16

		ldi r16, 0xFF
		out DDRB, r16

		ldi r17, 0b11110111
		out DDRD, r17

;********** FIM CONFIG INT. EXTER *************		
setup_botoes_led:
		
	ldi r28, 0x00
	ldi r29, 0x00
	
	ldi r17,0xF0; PC0 = 0, PC1 = 0, PC2 = 0, PC3 = 0
	out DDRC,r17; PCO = R, PC1 = A, PC2 = UP, PC3 = DOWN

	ldi r22, 0b00010000 ; LED T
	ldi r23, 0b00100000 ; LED W
	ldi r30, 0b01000000 ; LED O
	ldi r31, 0b10000000 ; LED F
;----------------------------------------------
;*********** SETUP INÍCIO DO RTC **************
		LDI		r24, 0x30 ; 0min.
		LDI		r25, 0x12 ; 0horas
		LDI		r26, 0x01 ; DOMINGO
		RCALL RTC_SETUP	 

		LDI		r24, 0x00 ; 0min.
		LDI		r25, 0x12 ; 12horas
		LDI		r26, 0x02 ; Segunda-Feira
		RCALL	RTC_SETUP_ALARM1

		LDI		r24, 0x00 ; 0min.
		LDI		r25, 0x12 ; 12horas
		LDI		r26, 0x03 ; Terça-Feira
		RCALL	RTC_SETUP_ALARM2
		
		RCALL	DISPLAY_SETUP	
;--------------------------------------------------
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
	
setup_Incrementos:
	clr r28
	clr r29
	clr r16
	rjmp loop

;**************** LOOP PRINCIPAL *****************		
loop:
	loop_exec_run:
		rcall led_run
	loop_cp_check_buttons:
		cpi r28, 0
		brne loop_button_R
		cpi r29, 0
		brne loop_button_A
	loop_exec_check_buttons:
		loop_button_R:
			sbic PINC, PC0	; R
			rcall incrementeA
			clr r16	
			cpse r28, r16
			rjmp cp_timer_H
		loop_button_A:
			sbic PINC, PC1	; A
			call incrementeB
			rjmp cp_timer_H
	cp_timer_H:
		cpi r28, 1
		breq exec_timer_H
		rjmp cp_timer_M
	exec_timer_H:
		rcall timer_H
	cp_timer_M:
		cpi r28, 2
		breq exec_timer_M
		rjmp cp_Week
	exec_timer_M:
		rcall timer_M
	cp_Week:
		cpi r28, 3
		breq exec_Week
		rjmp cp_On_H
	exec_Week:
		rcall Week
	cp_On_H:
		cpi r29, 1
		breq exec_On_H
		rjmp cp_On_M
	exec_On_H:
		rcall On_H
	cp_On_M:
		cpi r29, 2
		breq exec_On_M
		rjmp cp_Week_On
	exec_On_M:
		rcall On_M
	cp_Week_On:
		cpi r29, 3
		breq exec_Week_On
		rjmp cp_Off_H
	exec_Week_On:
		rcall Week_On
	cp_Off_H:
		cpi r29, 4
		breq exec_Off_H
		rjmp cp_Off_M
	exec_Off_H:
		rcall Off_H
	cp_Off_M:
		cpi r29, 5
		breq exec_Off_M
		rjmp cp_Week_Off
	exec_Off_M:
		rcall Off_M
	cp_Week_Off:
		cpi r29, 6
		breq exec_Week_Off
		rjmp cp_testaIntervalo
	exec_Week_Off:
		rcall Week_Off
	cp_testaIntervalo:
		cpi r29, 7
		breq exec_testaIntervalo
		rjmp end_loop
	exec_testaIntervalo:
		rcall testaIntervalo
	end_loop:
		rjmp loop
;-------------------------------------------------	
;*************** incrementeA *********************
incrementeA:
	sbic PINC, PC0
	rjmp incrementeA
	inc r28
	call delay
	ret
;-------------------------------------------------
;*************** incrementeB *********************
incrementeB:
	sbic PINC, PC1
	rjmp incrementeB
	inc r29
	call delay
	ret
;-------------------------------------------------
;**************** zera_LEDs **********************
zera_Leds:
	clr r16
	out PORTD, r16
	ret
;-------------------------------------------------
;***************** Timer_H ***********************
timer_H:
	sbic PINC, PC0
	rjmp timer_H
	rcall zera_Leds
	rcall rtc_get_H	
loop_timer_H:
	sbic PINC, PC2
	rcall seta_cima_H
	sbic PINC, PC3
	rcall seta_baixo_H
 	rcall rtc_set_H
	rcall print_hora
	sbis PINC, PC0
	rjmp loop_timer_H
	rcall delay
	rcall incrementeA
	ret
;-------------------------------------------------
;***************** Timer_M ***********************
timer_M:
	sbic PINC, PC0
	rjmp timer_M
	rcall zera_Leds
	rcall rtc_get_M
	rcall print_minuto
loop_timer_M:
	sbic PINC, PC2
	rcall seta_cima_M
	sbic PINC, PC3
	rcall seta_baixo_M
	rcall rtc_set_M
	rcall print_minuto
	sbis PINC, PC0
	rjmp loop_timer_M
	rcall delay
	rcall incrementeA
	ret
;-------------------------------------------------
;***************** Week **************************
Week:
	sbic PINC, PC0
	rjmp Week
	rcall zera_Leds
	ldi r26, 0x01
	out PORTB, r26
loop_Week:
	sbic PINC, PC2
	rcall seta_cima_D
	sbic PINC, PC3
	rcall seta_baixo_D
	rcall rtc_set_D
	out PORTB, r26
	sbis PINC, PC0
	rjmp loop_Week
	rcall delay
	rcall incrementeA
	ret
;-------------------------------------------------
;******************** ON_H ***********************
On_H:
	sbic PINC, PC1
	rjmp On_H
	rcall zera_Leds
	rcall rtc_get_H	
loop_On_H:
	sbic PINC, PC2
	rcall seta_cima_H
	sbic PINC, PC3
	rcall seta_baixo_H
 	rcall rtc_set_H
	rcall print_hora
	sbis PINC, PC1
	rjmp loop_On_H
	rcall delay
	rcall incrementeB
	ret
;-------------------------------------------------
;******************** ON_M ***********************
On_M:
	sbic PINC, PC1
	rjmp On_M
	rcall zera_Leds
	rcall rtc_get_H	
loop_On_M:
	sbic PINC, PC2
	rcall seta_cima_H
	sbic PINC, PC3
	rcall seta_baixo_H
 	rcall rtc_set_H
	rcall print_hora
	sbis PINC, PC1
	rjmp loop_On_M
	rcall delay
	rcall incrementeB
	ret
;-------------------------------------------------
;****************** Week_On **********************
Week_On:
	sbic PINC, PC1
	rjmp Week_On
	rcall zera_Leds
	rcall rtc_get_H	
loop_Week_On:
	sbic PINC, PC2
	rcall seta_cima_H
	sbic PINC, PC3
	rcall seta_baixo_H
 	rcall rtc_set_H
	rcall print_hora
	sbis PINC, PC1
	rjmp loop_Week_On
	rcall delay
	rcall incrementeB
	ret
;-------------------------------------------------
;******************* Off_H ***********************
Off_H:
	sbic PINC, PC1
	rjmp Off_H
	rcall zera_Leds
	rcall rtc_get_H	
loop_Off_H:
	sbic PINC, PC2
	rcall seta_cima_H
	sbic PINC, PC3
	rcall seta_baixo_H
 	rcall rtc_set_H
	rcall print_hora
	sbis PINC, PC1
	rjmp loop_Off_H
	rcall delay
	rcall incrementeB
	ret
;-------------------------------------------------
;******************* Off_M ***********************
Off_M:
	sbic PINC, PC1
	rjmp Off_M
	rcall zera_Leds
	rcall rtc_get_H	
loop_Off_M:
	sbic PINC, PC2
	rcall seta_cima_H
	sbic PINC, PC3
	rcall seta_baixo_H
 	rcall rtc_set_H
	rcall print_hora
	sbis PINC, PC1
	rjmp loop_Off_M
	rcall delay
	rcall incrementeB
	ret
;-------------------------------------------------
;****************** Week_Off *********************
Week_Off:
	sbic PINC, PC1
	rjmp Week_Off
	rcall zera_Leds
	rcall rtc_get_H	
loop_Week_Off:
	sbic PINC, PC2
	rcall seta_cima_H
	sbic PINC, PC3
	rcall seta_baixo_H
 	rcall rtc_set_H
	rcall print_hora
	sbis PINC, PC1
	rjmp loop_Week_Off
	rcall delay
	rcall incrementeB
	ret
;-------------------------------------------------
;*************** testaIntervalo ******************
testaIntervalo:
	sbic PINC, PC1
	rjmp testaIntervalo
loop_testaIntervalo:
	sbis PINC, PC1
	rjmp loop_testaIntervalo
	rcall delay
	ret
;-------------------------------------------------
;***************** clearR ************************
clearR:
	rcall led_clearR
	ret
;-------------------------------------------------
;***************** clearA ************************
clearA:
	rcall led_clearA
	ret
;-------------------------------------------------
; LEDS ------------LEDS ------------LEDS----------
;***************** led_run ***********************
led_run:
	out PORTB, r26 ;
ret
;-------------------------------------------------
;**************** led_timerH *********************
led_timerH:
	sbi PORTD, PD4 ; LIGA O LED T
	ret	
;-------------------------------------------------
;**************** led_timerM *********************
led_timerM:
	; TOGGLE LED T
	in r17, PORTD
	eor r17, r22
	out PORTD, r17		
	ret
;-------------------------------------------------
;*************** led_Week ************************
led_Week:
	sbi PORTD, PD4 ; LIGA O LED T
	; TOGGLE LED W
	in r17, PORTD
	eor r17, r23
	out PORTD, r17 
	ret
;-------------------------------------------------
;***************** led_OnH ***********************
led_OnH:
	sbi PORTD, PD6 ; LIGA O LED O
	ret
;-------------------------------------------------
;***************** led_OnM ***********************
led_OnM:		
	; TOGGLE LED O
	in r17, PORTD
	eor r17, r30
	out PORTD, r17 
	ret
;-------------------------------------------------
;**************** led_WeekOn *********************
led_WeekOn:
	sbi PORTD, PD6 ; LIGA O LED O
	; TOGGLE LED W
	in r17, PORTD
	eor r17, r23
	out PORTD, r17 
	ret
;-------------------------------------------------
;***************** led_OffH **********************
led_OffH:
	sbi PORTD, PD7 ; LIGA O LED F
	ret
;-------------------------------------------------
;***************** led_OffM **********************				
led_OffM:
	; TOGGLE LED F
	in r17, PORTD
	eor r17, r31
	out PORTD, r17 
	ret
;-------------------------------------------------
;*************** led_WeekOff *********************
led_WeekOff:
	sbi PORTD, PD7 ; LIGA O LED F
	; TOGGLE LED W
	in r17, PORTD
	eor r17, r23
	out PORTD, r17
	ret
;-------------------------------------------------
;************* led_testaIntervalo ****************
led_testaIntervalo:
	clr r29
	out PORTD, r29
	ret
;-------------------------------------------------
;*************** led_clearR **********************
led_clearR:
	clr r28
	out PORTD, r28
	ret
;-------------------------------------------------
;*************** led_clearA **********************
led_clearA:
	clr r29
	out PORTD, r29
	ret
;-------------------------------------------------
;**************** seta_cima_H ********************
seta_cima_H:
	cpi r25, 0x23
	breq hora_min
	rcall soma_Hexa_H
	rjmp seta_cima_hora_end
hora_min:
	ldi r25, 0x00	
seta_cima_hora_end:
	rcall delay
	rcall delay
	ret
;-------------------------------------------------
;*************** seta_cima_M ********************
seta_cima_M:
	cpi r24, 0x59
	breq minuto_min
	rcall soma_Hexa_M
	rjmp seta_cima_minuto_end
minuto_min:
	ldi r25, 0x00	
seta_cima_minuto_end:
	rcall delay
	rcall delay
	ret
;-------------------------------------------------
;*************** seta_cima_D ********************
seta_cima_D:
	cpi r26, 0x07
	breq dia_min
	inc r26
	rjmp seta_cima_dia_end
dia_min:
	ldi r25, 0x01	
seta_cima_dia_end:
	rcall delay
	rcall delay
	ret
;-------------------------------------------------
;*************** seta_baixo_H ********************
seta_baixo_H:
	sbic PINC, PC3
	rjmp seta_baixo_H
	cpi r25, 0x00
	breq hora_max
	rcall subtrai_Hexa_H
	rjmp seta_baixo_hora_end
hora_max:
	ldi r25, 0x23	
seta_baixo_hora_end:
	;rcall delay
	ret
;-------------------------------------------------
;*************** seta_baixo_M ********************
seta_baixo_M:
	sbic PINC, PC3
	rjmp seta_baixo_M
	cpi r24, 0x00
	breq minuto_max
	rcall subtrai_Hexa_M
	rjmp seta_baixo_minuto_end
minuto_max:
	ldi r25, 0x59	
seta_baixo_minuto_end:
	rcall delay
	ret
;-------------------------------------------------
;*************** seta_baixo_D ********************
seta_baixo_D:
	sbic PINC, PC3
	rjmp seta_baixo_D
	cpi r26, 0x01
	breq dia_max
	dec r26
	rjmp seta_baixo_dia_end
dia_max:
	ldi r25, 0x07	
seta_baixo_dia_end:
	rcall delay
	ret
;-------------------------------------------------
;*************** soma_hexa_H *********************
soma_hexa_H:
	mov r18, r25
	lsr	r18
	lsr	r18
	lsr	r18
	lsr	r18
	cpi r18, 0x90 
	breq MSH_H
	inc r25
	rjmp soma_hexa_hora_end
MSH_H:
	ldi r16, 0x07
	add r25, r16
	
soma_hexa_hora_end:
	ret
;-------------------------------------------------
;*************** soma_hexa_M *********************
soma_hexa_M:
	mov r18, r24
	lsr	r18
	lsr	r18
	lsr	r18
	lsr	r18
	cpi r18, 0x90
	breq MSH_M
	inc r24
	rjmp soma_hexa_minuto_end
MSH_M:
	ldi r16, 0x10
	add r24, r16
	subi r24, 0x09
soma_hexa_minuto_end:
	ret
;-------------------------------------------------
;*************** subtrai_hexa_H ******************
subtrai_hexa_H:
	mov r18, r25
	lsr	r18
	lsr	r18
	lsr	r18
	lsr	r18
	cpi r18, 0x00
	breq LSH_H
	dec r25
	rjmp subtrai_hexa_hora_end
LSH_H:
	subi r25, 0x10
	ldi  r16, 0x09
	add  r25, r16
subtrai_hexa_hora_end:
	ret
;-------------------------------------------------
;*************** subtrai_hexa_M ******************
subtrai_hexa_M:
	mov r18, r24
	lsr	r18
	lsr	r18
	lsr	r18
	lsr	r18
	cpi r18, 0x00
	breq LSH_M
	dec r24
	rjmp subtrai_hexa_minuto_end
LSH_M:
	subi r24, 0x10
	ldi	r16, 0x09
	add r24, r16
subtrai_hexa_minuto_end:
	ret
;-------------------------------------------------

;************** VETOR INTERRUPÇÂO ****************
TIMER1_COMPA:
	t_cp_OnH:
		cpi r29, 1
		breq t_exec_OnH
		rjmp t_cp_OnM
	t_exec_OnH:
		rcall led_OnH
	t_cp_OnM:
		cpi r29, 2
		breq t_exec_OnM
		rjmp t_cp_WeekOn
	t_exec_OnM:
		rcall led_OnM
	t_cp_WeekOn:
		cpi r29, 3
		breq t_exec_WeekOn
		rjmp t_cp_OffH
	t_exec_WeekOn:
		rcall led_WeekOn
	t_cp_OffH:
		cpi r29, 4
		breq t_exec_OffH
		rjmp t_cp_OffM
	t_exec_OffH:
		rcall led_OffH
	t_cp_OffM:
		cpi r29, 5
		breq t_exec_OffM
		rjmp t_cp_WeekOff
	t_exec_OffM:
		rcall led_OffM
	t_cp_WeekOff:
		cpi r29, 6
		breq t_exec_WeekOff
		rjmp t_cp_testaIntervalo
	t_exec_WeekOff:
		rcall led_WeekOff
	t_cp_testaIntervalo:
		cpi r29, 7
		breq t_exec_testaIntervalo
		rjmp t_cp_timerH
	t_exec_testaIntervalo:
		rcall led_clearA
		rcall led_testaIntervalo
	t_cp_timerH:	
		cpi r28, 1
		breq t_exec_timerH
		rjmp t_cp_timerM
	t_exec_timerH:
		rcall led_timerH
	t_cp_timerM:
		cpi r28, 2
		breq t_exec_timerM
		rjmp t_cp_Week
	t_exec_timerM:
		rcall led_timerM
	t_cp_Week:
		cpi r28, 3
		breq t_exec_Week
		rjmp t_cp_clearR
	t_exec_Week:
		rcall led_Week
	t_cp_clearR:
		cpi r28, 4
		breq t_exec_clearR
		rjmp t_fim
	t_exec_clearR:
		rcall led_clearR
	t_fim:	
		reti
;-------------------------------------------------

;****** INTERRUPÇÃO EXTERNA NO PIN D2 ***************
INT0_vect:
	;call led_OnM
reti
;******* FIM DE INTERRUPÇÃO EXTERNA NO PIN D2 *************


;************* DELAY *****************************
delay:	
	ldi  r18, 10
    ldi  r19, 255
	ldi  r20, 255

L1: dec  r20
    brne L1
	dec  r19
    brne L1
    dec  r18
    brne L1

	ret

; ************ FIM DELAY *********************
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
	LDI		r17, 0x04 ;exibir no display 4 as unidades dos minutos
	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	MOV		r18, r17
	RCALL	SPI_TRANSFER
	MOV		r18, r24 ; r27 <= SPDR (Resposta do SPI) unidade
	ADD		R18, R16	; para exibir os dois pontos
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	
	SWAP	r24 ;Trocar nibbles para exibir a dezena do minuto - Nibble mais significativo é ignorado
	LDI		r17, 0x03 ;exibir no display 3 as dezenas dos minutos
	RCALL	DISPLAY_ON
	MOV		r18, r17
	RCALL	SPI_TRANSFER
	MOV		r18, r24 ; r27 <= SPDR (Resposta do SPI) unidade
	ADD		R18, R16	; para exibir os dois pontos
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	
	LDI		r17, 0x02 ;exibir no display 2
	RCALL	DISPLAY_ON
	MOV		r18, r17
	RCALL	SPI_TRANSFER
	MOV		r18, r25
	ADD		R18, R16	; para exibir os dois pontos
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	
	SWAP	r25 ;Trocar nibbles para exibir a dezena da hora - Nibble mais significativo é ignorado
	LDI		r17, 0x01 ;exibir no display 1
	RCALL	DISPLAY_ON
	MOV		r18, r17
	RCALL	SPI_TRANSFER
	MOV		r18, r25 ; r27 <= SPDR (Resposta do SPI) unidade
	ADD		r18, r16	; para exibir os dois pontos
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	RET
;------------------------------------

PRINT_MINUTO:
	RCALL	SPI_MODE_0
	LDI		r17, 0x04 ;exibir no display 4 as unidades dos minutos
	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	MOV		r18, r17
	RCALL	SPI_TRANSFER
	MOV		r18, r24 ; unidade do minuto
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	
	SWAP	r24 ;Trocar nibbles para exibir a dezena do minuto - Nibble mais significativo é ignorado
	LDI		r17, 0x03 ;exibir no display 3 as dezenas dos minutos
	RCALL	DISPLAY_ON
	MOV		r18, r17
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
	LDI		r17, 0x02 ;exibir no display 2
	RCALL	DISPLAY_OFF
	NOP
	RCALL	DISPLAY_ON
	MOV		r18, r17
	RCALL	SPI_TRANSFER
	MOV		r18, r25 ; unidade da hora
	RCALL	SPI_TRANSFER
	RCALL	DISPLAY_OFF
	
	SWAP	r25 ;Trocar nibbles para exibir a dezena da hora - Nibble mais significativo é ignorado
	LDI		r17, 0x01 ;exibir no display 1
	RCALL	DISPLAY_ON
	MOV		r18, r17
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

