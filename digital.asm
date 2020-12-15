; HELOISA HUNGARO PRIMOLAN		RA 141026431

; MICROCONTROLADORES 2016

; OBJETIVO: sistema automatizado que controle a temporização de semáforos em um cruzamento, levando em consideração a ocorrência de chuvas. 

; O programa abaixo controla a temporização de dois semáforos em um cruzamento. Cada semáforo é representado por um LED verde, um amarelo e um vermelho:
; RB1 = s1.verde 			(OUTPUT) - 10 segundos
; RB2 = s1.amarelo 			(OUTPUT) - 4 segundos
; RB3 = s1.vermelho 		(OUTPUT) - 16 segundos (10+4+2)
; RB4 = s2.verde 			(OUTPUT) - 10 segundos
; RB5 = s2.amarelo 			(OUTPUT) - 4 segundos
; RB6 = s2.vermelho 		(OUTPUT) - 16 segundos (10+4+2)
; O sistema analisa, por meio do uso de um sensor de água, se está chovendo ou não em determinado momento, e conta se está chovendo na variável TEMPO,
; que começa em 30 e vai a 0: se estiver chovendo há 30 segundos ou mais, então TEMPO = 0 e o tempo dos semáforos é alterado: 
; s1.verde fica aceso por 15 segundos e s2.verde por 5, o que faz com que s1.vermelho fique aceso por 11 seg (5+4+2) e s2.vermelho por 21 (15+4+2)
; se em algum momento para de chover, de modo que RB7 recebe 1 do sensor, voltamos ao ciclo inicial de temporização
; O LED em RB0 indica se está chovendo há 30 ou mais segundos

; RB7 = sinal D do sensor (0 = CHUVA / 1 = SEM CHUVA)	(INPUT)
; RB0 = está chovendo há 30 ou mais seg? 				(OUTPUT)

; Fint = 250
; TMR0 = 131
; Prescaler = 32 = 100

#INCLUDE <P16F873A.INC>

		CBLOCK	0x20
		TIQUES				; var p/ contar a qtde de int do timer p/ saber quando deu 1 seg	
		TEMPO				; var p/ contar ha quantos seg está ocorrendo chuva 
		CONT				; var p/ contar o tempo de cada luz acesa dos semáforo 
		TG1					; tempo do s1.verde
		TG2					; tempo do s2.verde
		TY					; tempo dos s1 e s2.amarelo
		TR					; tempo dos s1 e s2.vermelho
		ENDC

		ORG		0
		GOTO 	INICIO
		
		ORG 	4 			; interrupções (do timer)
										; LED DE TESTE - está chovendo?
		MOVLW	d'0'		; W = 0
		SUBWF	TEMPO,W		; W = TEMPO - W 
		BTFSS	STATUS,Z	; z = 1? -> está chovendo?
		GOTO 	NESTA
		GOTO 	ESTA
NESTA:	BCF		PORTB,RB0	; não está!
		GOTO	CONTI
ESTA:	BSF		PORTB,RB0	; está!
		GOTO 	CONTI					; ATE AQUI É P/ O LED EM RB0 DIZER SE ESTÁ OU NÃO CHOVENDO

CONTI:	
		DECFSZ	TIQUES,F 	; TIQUES-- 
		GOTO	PULAI 		; se ainda não deu 1 seg (250 tiques), sai da int
		MOVLW	d'250' 		; W = 250
		MOVWF	TIQUES 		; TIQUES = W = 250 -> reseta o cont, pois deu 1 seg
		MOVLW	d'0'		; w = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSC	STATUS,Z	; z = 0?
		GOTO	TESTAP		; se não for, CONT já finalizou a contagem atual
		DECF	CONT,F		; CONT--
TESTAP:	BTFSC	PORTB,RB7	; se o sensor envia sinal 0, de chuva, devemos alterar a var TEMPO
		GOTO	ZERAT		; se não há chuva (RB7 = 0), zerar a var TEMPO
		; se houver chuva... (RB0 = 0)
		MOVLW	d'0'		; W = 0
		SUBWF	TEMPO,W		; W = TEMPO - W 
		BTFSC	STATUS,Z	; z = 0?	
		GOTO	PULAI		; z = 1, portanto não faremos TEMPO--; manteremos TEMPO  0
		DECF	TEMPO,F		; se TEMPO <> 0, TEMPO-- , pois deve chover por ao menos 30 seg para alterarmos o tempo dos semáforos
		GOTO	PULAI
ZERAT:	MOVLW	d'30'		; W = 30
		MOVWF	TEMPO		; TEMPO = W = 30
PULAI:	MOVLW 	d'131' 		; W = 131
		MOVWF	TMR0 		; TMR0 = W -> reseta o valor inicial p/ o timer
		BCF		INTCON,T0IF	; dá o clear no T0IF
		RETFIE 				; sai da interrupção



INICIO:
		MOVLW	d'250' 		; W = 250 -> 250 tiques correpondem a 1 segundo de int do timer
		MOVWF	TIQUES 		; TIQUES = W = 250 
		MOVLW	d'30'		; W = 30
		MOVWF	TEMPO		; TEMPO = W = 30
		BANKSEL	TRISB 		
		MOVLW 	b'10000000' ; W = b10000000 -> bit RB7 é input (1), os outros são output (0)
		MOVWF 	TRISB 		; TRISB = W
		MOVLW	b'00000100' ; W = b00000100 -: TOCs = 0 (clock do timer É Fosc/4), PSA = 0 (Prescaler associado ao timer) e Prescaler = 100 (32)
		MOVWF	OPTION_REG 	; OPTION_REG = W
		BANKSEL PORTB 	
		MOVLW	b'00000000'	; W = b00000000
		MOVWF	PORTB		; PORTB = W
		MOVLW	d'131' 		; W = 131 -> valor do TMR0 para Fint = 250 e Prescaler = 32
		MOVWF	TMR0 		; TMR0 = W = 131
		BSF		INTCON,GIE 	; GIE = 1 ("chave geral" de interrupção)
		BSF 	INTCON,5 	; T0IE = 1 (habilita a int do timer)
		BCF		INTCON,T0IF ; T0IF = 0 dá o start do timer! (se = 1, ocorreu int do timer, então dar clear)
		; fim das configurações de timer e input/output
		
		MOVLW	d'4'
		MOVWF	TY
		MOVLW	d'2'
		MOVWF	TR

VOLTA:	MOVLW	d'0'		; W = 0
		SUBWF	TEMPO,W		; W = TEMPO - W 
		BTFSS	STATUS,Z	; z = 1? -> está chovendo? (quando TEMPO = 0, está chovendo há mais de 30 segundos)
		GOTO	SEMC		; não está!
		GOTO	COMC		; está!


SEMC:	MOVLW	d'10'		; W = 10
		MOVWF	TG1			; TG1 = W = 10
		MOVWF	TG2			; TG2 = W = 10
		CALL	SEMAF		
		GOTO	VOLTA		; novo ciclo

COMC:	MOVLW	d'15'		; W = 15
		MOVWF	TG1			; TG1 = W = 15
		MOVLW	d'5'		; W = 5
		MOVWF	TG2			; TG2 = W = 5
		CALL	SEMAF		
		GOTO	VOLTA		; novo ciclo

SEMAF:	BSF		PORTB,RB6	; RB6 = 1 (semáforo 2 VERMELHO acende)
		BSF		PORTB,RB1	; RB1 = 1 (semáforo 1 VERDE acende)
		MOVF	TG1,W		; W = TG1 = 10
		MOVWF	CONT		; CONT = W
TSG1:	MOVLW	d'0'		; W = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSS	STATUS,Z	; C = 1 ? ou seja, CONT - 10 >= 0?
		GOTO	TSG1		; caso não seja, testar novamente
		; caso seja, semáforo 1 fica amarelo
		BCF		PORTB,RB1	; RB1 = 0 (semáforo 1 VERDE apaga)
		BSF		PORTB,RB2	; RB2 = 1 (semáforo 1 AMARELO acende)
		MOVF	TY,W		; W = TY = 4
		MOVWF	CONT		; CONT = W
TSY1:	MOVLW	d'0'		; W = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSS	STATUS,Z	; C = 1 ? ou seja, CONT - 4 >= 0?
		GOTO	TSY1		; caso não seja, testar novamente
		; caso seja, semáforo 1 fica vermelho
		BCF		PORTB,RB2	; RB2 = 0 (semáforo 1 AMARELO apaga)
		BSF		PORTB,RB3	; RB3 = 1 (semáforo 1 VERMELHO acende)
		; fica dois seg com s1 e s2 vermelho, por segurança
		MOVF	TR,W		; W = TR = 2
		MOVWF	CONT		; CONT = W
TSR1:	MOVLW	d'0'		; W = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSS	STATUS,Z	; C = 1 ? ou seja, CONT - 2 >= 0?
		GOTO	TSR1		; caso não seja, testar novamente
		; caso seja, semáforo 2 fica verde
		BCF		PORTB,RB6	; RB6 = 0 (semáforo 2 VERMELHO apaga)
		BSF		PORTB,RB4	; RB4 = 1 (semáforo 2 VERDE acende)
		MOVF	TG2,W		; W = TG2 = 15
		MOVWF	CONT		; CONT = W
TSG2:	MOVLW	d'0'		; W = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSS	STATUS,Z	; C = 1 ? ou seja, CONT - 10 >= 0?
		GOTO	TSG2		; caso não seja, testar novamente
		; caso seja, semáforo 2 fica amarelo
		BCF		PORTB,RB4	; RB4 = 0 (semáforo 2 VERDE apaga)
		BSF		PORTB,RB5	; RB5 = 1 (semáforo 2 AMARELO acende)
		MOVF	TY,W		; W = TY = 4
		MOVWF	CONT		; CONT = W
TSY2:	MOVLW	d'0'		; W = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSS	STATUS,Z	; C = 1 ? ou seja, CONT - 4 >= 0?
		GOTO	TSY2		; caso não seja, testar novamente
		; caso seja, semáforo 1 fica vermelho
		BCF		PORTB,RB5	; RB5 = 0 (semáforo 2 AMARELO apaga)
		BSF		PORTB,RB6	; RB6 = 1 (semáforo 2 VERMELHO acende)
		; fica dois seg com s1 e s2 vermelho, por segurança
		MOVF	TR,W		; W = TR = 2
		MOVWF	CONT		; CONT = W
TSR2:	MOVLW	d'0'		; W = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSS	STATUS,Z	; C = 1 ? ou seja, CONT - 2 >= 0?
		GOTO	TSR2		; caso não seja, testar novamente
		BCF		PORTB,RB3	; RB3 = 0 (semáforo 1 VERMELHO apaga)
		; caso seja, semáforo 2 fica verde (na proxima execução da função)
		RETURN
	
		END