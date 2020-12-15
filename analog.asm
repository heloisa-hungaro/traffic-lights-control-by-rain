; HELOISA HUNGARO PRIMOLAN		RA 141026431

; MICROCONTROLADORES 2016

; OBJETIVO: sistema automatizado que controle a temporiza��o de sem�foros em um cruzamento, levando em considera��o a ocorr�ncia de chuvas. 


; O programa abaixo controla a temporiza��o de dois sem�foros em um cruzamento. Cada sem�foro � representado por um LED verde, um amarelo e um vermelho:
; RB1 = s1.verde 			(OUTPUT) - 10 segundos
; RB2 = s1.amarelo 			(OUTPUT) - 4 segundos
; RB3 = s1.vermelho 		(OUTPUT) - 16 segundos (10+4+2)
; RB4 = s2.verde 			(OUTPUT) - 10 segundos
; RB5 = s2.amarelo 			(OUTPUT) - 4 segundos
; RB6 = s2.vermelho 		(OUTPUT) - 16 segundos (10+4+2)
; O sistema analisa, por meio do uso de um sensor de �gua, se est� chovendo ou n�o em determinado momento, e conta se est� chovendo na vari�vel TEMPO,
; que come�a em 30 e vai a 0: se estiver chovendo h� 30 segundos ou mais, ent�o TEMPO = 0 e o tempo dos sem�foros � alterado
; os LEDS em RC0, RC1 e RC2 indicam, respectivamente, se n�o est� chovendo (ou est� chovendo muito pouco), se est� com chuva m�dia e se est� chovendo bastante
; caso j� esteja chovendo h� 30 segundos ou mais (TEMPO = 0) e esteja com chuva m�dia (RC1 aceso), ent�o o tempo dos sem�foros � alterado para: 
; s1.verde fica aceso por 12 segundos e s2.verde por 8, o que faz com que s1.vermelho fique aceso por 14 seg (8+4+2) e s2.vermelho por 18 (12+4+2)
; caso j� esteja chovendo h� 30 segundos ou mais (TEMPO = 0) e esteja com bastante chuva (RC2 aceso), ent�o o tempo dos sem�foros � alterado para:  
; s1.verde fica aceso por 15 segundos e s2.verde por 5, o que faz com que s1.vermelho fique aceso por 11 seg (5+4+2) e s2.vermelho por 21 (15+4+2)
; se em algum momento para de chover, de modo que RB0 apague, voltamos ao ciclo inicial de temporiza��o

; RA0/AN0 = sinal ANAL�GICO do sensor		(INPUT)
; RB0 = est� chovendo h� 30 ou mais seg? 	(OUTPUT)

;	- O VALOR RECEBIDO (RA0/AN0) A CADA 1 SEGUNDO DA SA�DA ANAL�GICA DO SENSOR � EXIBIDA NA TELA VIA SERIAL, intercalando o resultado
; das convers�es A/D pelo valor 111 na tela
; EXEMPLO:
; 3		(ADRESH)
; 221	(ADRESL)
; 111	(111 para separar valor recebido da pr�xima convers�o A/D)
; 2		(ADRESH)
; 123	(ADRESL)



; DETALHES DE A/D: 
; SEM CHUVA / POUCA CHUVA : ADRESH=3 
; CHUVA M�DIA : ADRESH = 2 ou ADRESH = 1 e ADRESL > = 200
; CHUVA FORTE : ADRESH = 1 e ADRESL < 200 ou ADRESH = 0



; Fint = 250
; TMR0 = 131
; Prescaler = 32 = 100

#INCLUDE <P16F873A.INC>

		CBLOCK 0x20
		TIQUES				; var p/ contar a qtde de int do timer p/ saber quando deu 1 seg	
		TEMPO				; var p/ contar ha quantos seg est� ocorrendo chuva 
		CONT				; var p/ contar o tempo de cada luz acesa dos sem�foro 
		TG1					; tempo do s1.verde
		TG2					; tempo do s2.verde
		TY					; tempo dos s1 e s2.amarelo
		TR					; tempo dos s1 e s2.vermelho
		ENDC

		ORG		0
		GOTO 	INICIO
		

		ORG 	4 			; interrup��es (do timer)
					
		BANKSEL	PORTB
										; LED em RB0 - est� chovendo?
		MOVLW	d'0'		; W = 0
		SUBWF	TEMPO,W		; W = TEMPO - W 
		BTFSS	STATUS,Z	; z = 1? -> est� chovendo?
		GOTO 	NESTA
		GOTO 	ESTA
NESTA:	BCF		PORTB,RB0	; n�o est�!
		GOTO	CONTI
ESTA:	BSF		PORTB,RB0	; est�!
		GOTO 	CONTI					; ATE AQUI � P/ O LED EM RB0 DIZER SE EST� OU N�O CHOVENDO

CONTI:	DECFSZ	TIQUES,F 	; TIQUES-- 
		GOTO	PULAI 		; se ainda n�o deu 1 seg (250 tiques), sai da int
		MOVLW	d'250' 		; W = 250
		MOVWF	TIQUES 		; TIQUES = W = 250 -> reseta o cont, pois deu 1 seg
		MOVLW	d'0'		; w = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSC	STATUS,Z	; z = 0?
		GOTO	CONVAD		; se n�o for, CONT j� finalizou a contagem atual
		DECF	CONT,F		; CONT--

CONVAD:	BTFSC	ADCON0,2	; GO/DONE = 0 ? (ou seja, a convers�o atual foi finalizada?)
		GOTO	CONVAD		; caso n�o, espere at� que finalize
		; aqui o valor anal�gico j� foi convertido e se encontra nos regs ADRESH e ADRESL

		; vamos mostrar sempre o valor 111 para separar os valores na tela a cada 1 seg
		BANKSEL	TXSTA
ESPX:	BTFSS 	TXSTA,TRMT	; o buffer est� livre?
		GOTO	ESPX		; se o buffer n�o est� livre, vamos esperar at� que fique
		BANKSEL	TXREG	
		MOVLW	d'111'		; W = 111
		MOVWF	TXREG		; TXREG = W para enviar o que h� em W

		; vamos ler o que h� em ADRESH e exibir na tela
		BANKSEL	ADRESH
		MOVF	ADRESH,W	; W = ADRESH
		BANKSEL	TXSTA		
ESPH:	BTFSS 	TXSTA,TRMT	; o buffer est� livre?
		GOTO	ESPH		; se o buffer n�o est� livre, vamos esperar at� que fique
		BANKSEL	TXREG
		MOVWF	TXREG		; TXREG = W para enviar o que h� em W

		; vamos ler o que h� em ADRESL e exibir na tela
		BANKSEL	ADRESL
		MOVF	ADRESL,W	; W = ADRESL
		BANKSEL	TXSTA
ESPL:	BTFSS 	TXSTA,TRMT	; o buffer est� livre?
		GOTO	ESPL		; se o buffer n�o est� livre, vamos esperar at� que fique
		BANKSEL	TXREG
		MOVWF	TXREG		; TXREG = W para enviar o que h� em W
		
		CALL	TAD			; vai p/ rotina TAD
		BSF		ADCON0,2	; GO/DONE = 1 para iniciar nova convers�o

		BANKSEL	PORTC
		BTFSC	PORTC,RC0	; se houver chuva m�dia/forte, devemos alterar a var TEMPO -> RC0 = 0
		GOTO	ZERAT		; se n�o h� chuva (RC7 = 0), zerar a var TEMPO
		; se houver chuva... (RC1 = 1 OU RC2 = 1)
		MOVLW	d'0'		; W = 0
		SUBWF	TEMPO,W		; W = TEMPO - W 
		BTFSC	STATUS,Z	; z = 0?	
		GOTO	PULAI		; z = 1, portanto n�o faremos TEMPO--; manteremos TEMPO  0
		DECF	TEMPO,F		; se TEMPO <> 0, TEMPO-- , pois deve chover por ao menos 30 seg para alterarmos o tempo dos sem�foros
		GOTO	PULAI

ZERAT:	MOVLW	d'30'		; W = 30
		MOVWF	TEMPO		; TEMPO = W = 30
PULAI:	MOVLW 	d'131' 		; W = 131
		MOVWF	TMR0 		; TMR0 = W -> reseta o valor inicial p/ o timer
		BCF		INTCON,T0IF	; d� o clear no T0IF
		RETFIE 				; sai da interrup��o

INICIO: MOVLW	b'01000001'	; W = b01000001
		BANKSEL	ADCON0		
		MOVWF	ADCON0		; ADCON0 = W
		BANKSEL	ADCON1
		MOVLW	b'10001110'	; W = b10001110
		MOVWF	ADCON1		; ADCON1 = W
		; neste ponto convers�o A/D j� est� configurada
		
		BANKSEL	TXSTA		
		MOVLW	b'00100110'	; W = b00100110
		MOVWF	TXSTA		; TXSTA = W
		MOVLW	d'25'		; W = 25
		MOVWF	SPBRG		; SPBRG = W = 25 -> 9600 bps
		BANKSEL	RCSTA 		
		MOVLW	b'10010000'	; W = b10010000
		MOVWF	RCSTA		; RCSTA = W
		; neste ponto a serial j� est� configurada

		MOVLW	d'250' 		; W = 250 -> 250 tiques correpondem a 1 segundo de int do timer
		MOVWF	TIQUES 		; TIQUES = W = 250 
		MOVLW	d'30'		; W = 30
		MOVWF	TEMPO		; TEMPO = W = 30
		BANKSEL	TRISA 		
		MOVLW	b'00000001'	; W = b00000001
		MOVWF	TRISA		; TRISA = W -> RA0 (AN0) � input 	
		MOVLW 	b'00000000' ; W = b00000000 -> bits RB0 - RB6 s�o output (0)
		MOVWF 	TRISB 		; TRISB = W	
		BCF		TRISC,0		; RC0 = 0 (output)
		BCF		TRISC,1		; RC1 = 0 (output)
		BCF		TRISC,2		; RC2 = 0 (output)
		MOVLW	b'00000100' ; W = b00000100 -: TOCs = 0 (clock do timer � Fosc/4), PSA = 0 (Prescaler associado ao timer) e Prescaler = 100 (32)
		MOVWF	OPTION_REG 	; OPTION_REG = W
		BANKSEL PORTB 	
		CLRF	PORTB	 	; PORTB = 00000000
		CLRF	PORTC		; PORTC = 00000000
		MOVLW	d'131' 		; W = 131 -> valor do TMR0 para Fint = 250 e Prescaler = 32
		MOVWF	TMR0 		; TMR0 = W = 131
		BSF		INTCON,GIE 	; GIE = 1 ("chave geral" de interrup��o)
		BSF 	INTCON,5 	; T0IE = 1 (habilita a int do timer)
		; neste ponto o timer e input/output j� est�o configurados

		BSF		ADCON0,2	; GO/DONE = 1 para iniciar nova convers�o
		BCF		INTCON,T0IF ; T0IF = 0 d� o start do timer! (se = 1, ocorreu int do timer, ent�o dar clear)

		MOVLW	d'4'		; W = 4
		MOVWF	TY			; TY = W = 4
		MOVLW	d'2'		; W = 2
		MOVWF	TR			; TR = W = 2

VOLTA:	NOP
		NOP
		NOP
		CLRF	PORTB
		MOVLW	d'0'		; W = 0
		SUBWF	TEMPO,W		; W = TEMPO - W 
		BTFSS	STATUS,Z	; z = 1? -> est� chovendo? (quando TEMPO = 0, est� chovendo h� mais de 30 segundos)
		GOTO	CHUVA0		; n�o est� chovendo h� mais de 30 seg!
		BTFSS	PORTC,RC2	; RC2 = 1? ou seja, est� com chuva forte / chovendo muito?
		GOTO	CHUVA1		; n�o est� com chuva forte / bastante chuva! -> ent�o est� com chuva m�dia (RC1 = 0)
		GOTO	CHUVA2		; est� com chuva forte / bastante chuva!

CHUVA0:	MOVLW	d'10'		; W = 10
		MOVWF	TG1			; TG1 = W = 10
		MOVWF	TG2			; TG2 = W = 10
		CALL	SEMAF		; vai p/ rotina SEMAF
		GOTO	VOLTA		; novo ciclo

CHUVA1:	MOVLW	d'12'		; W = 12
		MOVWF	TG1			; TG1 = W = 12
		MOVLW	d'8'		; W = 8
		MOVWF	TG2			; TG2 = W = 8
		CALL	SEMAF		; vai p/ rotina SEMAF
		GOTO	VOLTA		; novo ciclo

CHUVA2:	MOVLW	d'15'		; W = 15
		MOVWF	TG1			; TG1 = W = 15
		MOVLW	d'5'		; W = 5
		MOVWF	TG2			; TG2 = W = 5
		CALL	SEMAF		; vai p/ rotina SEMAF
		GOTO	VOLTA		; novo ciclo

SEMAF:	BSF		PORTB,RB6	; RB6 = 1 (sem�foro 2 VERMELHO acende)
		BSF		PORTB,RB1	; RB1 = 1 (sem�foro 1 VERDE acende)
		MOVF	TG1,W		; W = TG1 = 10
		MOVWF	CONT		; CONT = W
TSG1:	MOVLW	d'0'		; W = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSS	STATUS,Z	; C = 1 ? ou seja, CONT - 10 >= 0?
		GOTO	TSG1		; caso n�o seja, testar novamente
		; caso seja, sem�foro 1 fica amarelo
		BCF		PORTB,RB1	; RB1 = 0 (sem�foro 1 VERDE apaga)
		BSF		PORTB,RB2	; RB2 = 1 (sem�foro 1 AMARELO acende)
		MOVF	TY,W		; W = TY = 4
		MOVWF	CONT		; CONT = W
TSY1:	MOVLW	d'0'		; W = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSS	STATUS,Z	; C = 1 ? ou seja, CONT - 4 >= 0?
		GOTO	TSY1		; caso n�o seja, testar novamente
		; caso seja, sem�foro 1 fica vermelho
		BCF		PORTB,RB2	; RB2 = 0 (sem�foro 1 AMARELO apaga)
		BSF		PORTB,RB3	; RB3 = 1 (sem�foro 1 VERMELHO acende)
		; fica dois seg com s1 e s2 vermelho, por seguran�a
		MOVF	TR,W		; W = TR = 2
		MOVWF	CONT		; CONT = W
TSR1:	MOVLW	d'0'		; W = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSS	STATUS,Z	; C = 1 ? ou seja, CONT - 2 >= 0?
		GOTO	TSR1		; caso n�o seja, testar novamente
		; caso seja, sem�foro 2 fica verde
		BCF		PORTB,RB6	; RB6 = 0 (sem�foro 2 VERMELHO apaga)
		BSF		PORTB,RB4	; RB4 = 1 (sem�foro 2 VERDE acende)
		MOVF	TG2,W		; W = TG2 = 15
		MOVWF	CONT		; CONT = W
TSG2:	MOVLW	d'0'		; W = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSS	STATUS,Z	; C = 1 ? ou seja, CONT - 10 >= 0?
		GOTO	TSG2		; caso n�o seja, testar novamente
		; caso seja, sem�foro 2 fica amarelo
		BCF		PORTB,RB4	; RB4 = 0 (sem�foro 2 VERDE apaga)
		BSF		PORTB,RB5	; RB5 = 1 (sem�foro 2 AMARELO acende)
		MOVF	TY,W		; W = TY = 4
		MOVWF	CONT		; CONT = W
TSY2:	MOVLW	d'0'		; W = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSS	STATUS,Z	; C = 1 ? ou seja, CONT - 4 >= 0?
		GOTO	TSY2		; caso n�o seja, testar novamente
		; caso seja, sem�foro 1 fica vermelho
		BCF		PORTB,RB5	; RB5 = 0 (sem�foro 2 AMARELO apaga)
		BSF		PORTB,RB6	; RB6 = 1 (sem�foro 2 VERMELHO acende)
		; fica dois seg com s1 e s2 vermelho, por seguran�a
		MOVF	TR,W		; W = TR = 2
		MOVWF	CONT		; CONT = W
TSR2:	MOVLW	d'0'		; W = 0
		SUBWF	CONT,W		; W = CONT - W
		BTFSS	STATUS,Z	; C = 1 ? ou seja, CONT - 2 >= 0?
		GOTO	TSR2		; caso n�o seja, testar novamente
		BCF		PORTB,RB3	; RB3 = 0 (sem�foro 1 VERMELHO apaga)
		; caso seja, sem�foro 2 fica verde (na proxima execu��o da fun��o)
		RETURN

TAD:	MOVLW	d'2'		; W = 2
		BANKSEL ADRESH
		SUBWF	ADRESH,W	; W = ADRESH - W
		BTFSC 	STATUS,C	; ADRESH < 2 ? 
		GOTO	HMAII2		; ADRESH >= 2
		GOTO 	HIG1		; ADRESH = 1 
HMAII2:	MOVLW	d'3'		; W = 3
		SUBWF	ADRESH,W	; W = ADRESH - W
		BTFSS 	STATUS,Z	; ADRESH = 3 ? 
		GOTO	HIG2		; ADRESH = 2
		; aqui ADRESH = 3, portanto certamente n�o est� chovendo
		BSF		PORTC,RC0	; RC0 = 1
		BCF		PORTC,RC1	; RC1 = 0
		BCF		PORTC,RC2	; RC2 = 0
		GOTO	FIMT

HIG1:	; aqui ADRESH = 1
		MOVLW	d'200'		; W = 200
		BANKSEL ADRESL		
		SUBWF	ADRESL,W	; W = ADRESL - W
		BANKSEL	PORTC		
		BTFSC 	STATUS,C	; ADRESL < 200 ? 
		GOTO	LMI200		; ADRESL >= 200
		; aqui ADRESH = 1 e ADRESL < 200, portanto est� chovendo muito forte
		; AQUI EST� DANDO PROBLEMA
		BCF		PORTC,RC0	; RC0 = 0
		BCF		PORTC,RC1	; RC1 = 0
		BSF		PORTC,RC2	; RC2 = 1
		GOTO	FIMT

LMI200:	; aqui ADRESH = 1 e ADRESL >=200, portanto est� com chuva m�dia
		BCF		PORTC,RC0	; RC0 = 0
		BSF		PORTC,RC1	; RC1 = 1
		BCF		PORTC,RC2	; RC2 = 0
		GOTO 	FIMT		

HIG2:	; aqui ADRESH = 2, portanto est� com chuva m�dia
		BCF		PORTC,RC0	; RC0 = 0
		BSF		PORTC,RC1	; RC1 = 1
		BCF		PORTC,RC2	; RC2 = 0
	
FIMT:	RETURN

		END