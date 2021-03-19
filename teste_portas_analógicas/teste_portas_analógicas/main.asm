

start:
	ldi r16, (1 << REFS0)  ; setando referencia de conversão e referencia ADC4
	sts ADMUX, r16						 
	ldi r17, (1 << ADPS1) | (1 << ADPS0)  ; divisão por 8
	sts ADCSRA, r17	 
	ori r17, (1 << ADEN) | (1 << ADSC) 
	sts ADCSRA, r17
	rcall clear_registradores  ; chamada do clear dos r17 até r23
loop_adc:
	lds r20, ADCSRA ; copiando o reg ADCSRA
	sbrc r20, ADIF  ; checando se o ADIF está setado
	rjmp continue	; pula para o continue caso esteja setado o ADIF
	rjmp loop_adc	; colta para o loop caso contrário
continue:
	lds r27, ADCL	; copia o LOW para o r27
	lds r28, ADCH	; copia o HIGH para o r28
	ldi r25, 10		; regista 10
	ldi r26, 1		; registra 1
	ldi r29, 255	; registra 255 para o estou do contador geral
	ldi r30, 0xEF	; registra o LOW do 999
	ldi r31, 0x03	; registra o HIGH do 999
	rcall clear_registradores
conversao_999:
	ldi r24, 0x00	; zera r24
	cpse r27, r17	; compara LOW(ADC), LOW(GERAL)
	adiw r24, 1		; se for diferente soma 1
	cpse r28, r23	; compara HIGH(ADC), HIGH(GERAL)
	adiw r24, 1		; se for diferente soma 1
    cpi r24, 0		; compara r24 com zero
	breq final		; se for igual ele vai para o final do processo
	rcall limitador	; chamada da checagem do limitador, se for igual a 999 ele sai
	cpse r17, r29	; compara LOW(GERAL), 0xFF
	rjmp soma_low	; se o reg GERAL não for 255 ele soma no reg r17
	rjmp soma_high	; se o reg GERAL for 0xFF ele soma no reg r23
soma:
	add r18, r26	; acrescenta reg LOCAL com 1
	mov r19, r18	; move reg LOCAL para reg UNIDADES 
	cpse r18, r25	; compara reg LOCAL com 10
	rjmp conversao_999	; se não for volta para o inicio do processo
	rcall soma_dezena	; se for ele soma dezena
	cpse r20, r25	; compara DEZENAS, 10
	rjmp conversao_999	; se não for volta para o inicio do processo
	rcall soma_centena	; se for ele soma centenas
	rjmp conversao_999	; volta para o início do processo
limitador:
	ldi r24, 0x00	; zera r24
	cpse r17, r30	; compara LOW(GERAL), LOW 999
	adiw r24, 1		; se for diferente soma 1
	cpse r23, r31	; compara HIGH(GERAL), HIGH 999
	adiw r24, 1		; se for diferente soma 1
	cpi r24, 0		; compara r24 com zero
	breq final		; se for igual ele vai para o final do processo
	ret
soma_dezena:
	clr r18		 ; zera LOCAL		
	clr r19		 ; zera UNIDADES
	add r20, r26 ; adiciona DEZENA em 1
	ret
soma_centena:
	clr r20		 ; zera DEZENAS
	add r21, r26 ; adiciona CENTENAS em 1
	ret
soma_low:
	add r17, r26 ; adiciona LOW GERAL em 1
	rjmp soma	 ; volta para a soma
soma_high:
	ldi r17, 0x00 ; zera LOW GERAL
	add r23, r26  ; adiciona HIGH GERAL em 1
	rjmp soma	; volta para a soma
clear_registradores: 
	clr r16		; zera registradores r17 à r23
	clr r17
	clr r18
	clr r19
	clr r20
	clr r21
	clr r22
	clr r23
	ret
final:
	;Inicio de outro processo