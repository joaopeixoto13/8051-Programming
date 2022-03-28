#include <REG51F380.H>

//EX 1
;Implemente um programa que recebe dois parâmetros da memoria de código na posição 1000H, 
;período de uma onda quadrada e o tempo a ON(1001H), -> 0ms<periodo<10ms / 1s<tempo<30s  
;e configura o timer 2 com interrupção para gerar a onda respetiva
;no pino de um porto, P2.7 por exemplo


/*
CSEG AT 0H
	LJMP MAIN
	
CSEG AT 002BH
	LJMP ISR_TIMER2
	
	
MAIN:
	ACALL CONFIGS
	ACALL OSCILATOR_INIT
	MOV DPTR, #1000H
	MOV A, #0
	MOVC A, @A + DPTR
	ACALL DESCOBRE_PERIODO
	MOV A, #1
	MOVC A, @A + DPTR
	ACALL DESCOBRE_TEMPO
	



DESCOBRE_PERIODO:
	RR A 		;por causa do complemento -> t/2 liagado e t/2 desligado -> T = t
	RL A		;multiplicar por 2
	RL A		;multiplicar por 2 -> multiplicar por 4 é o mesmo que dividir por 0.25 -> 


	
TIMER_INIT:
	MOV TMR2CN, #4H									//Timer 2: 16 bit c/auto-reload
	MOV TMR2L, #LOW(-1)
    MOV TMR2H, #HIGH(-1)
	MOV TMR2RLL, #LOW(-40000)
    MOV TMR2RLH, #HIGH(-40000)
    RET


OSCILATOR_INIT:
    MOV FLSCL, #090h
    MOV CLKSEL, #003h
    RET


CONFIGS:
	MOV PCA0MD, #0H																						//Desabilitar o WatchDod Timer
	MOV XBR1, #40H																						//Ativar a Crossbar -> para o Display de 7 segmentos e P0.6 e P0.7 funcionar -> 'ligar pinos físicos/metálicos
	RET
*/


//EX 2
;Implemente um programa que gere uma onda quadrada com um periodo de 0,25s usando o Timer 2 16 bit auto-reload
;Implemente uma interrupção que quando acionado o botão P0.7, coloque na Porta 2 o número 0

/*
MAX_0125 DATA 30H
LOAD EQU 20H.0

CSEG AT 0H
	LJMP MAIN
	
CSEG AT 0003H
	LJMP ISR_EXT0
	
CSEG AT 002BH
	LJMP ISR_TIMER2


ISR_EXT0:
	SETB LOAD
	RETI


ISR_TIMER2:
	PUSH ACC
	PUSH PSW
	CLR  TF2H
	DJNZ MAX_0125, FIM_ISR_TIMER2
			CPL P2.7
			MOV MAX_0125, #12
			
FIM_ISR_TIMER2:
	POP PSW
	POP ACC
	RETI
	
	

CSEG AT 200H
	
MAIN:
	ACALL CONFIGS
	ACALL OSCILATOR_INIT
	ACALL TIMER_INIT
	CLR LOAD
	MOV MAX_0125, #12
	MOV P2, #0x7F
	MOV IE, #001H		//Enable \INT0 Interrupt
	MOV IT01CF, #007H	//Enable P0.7 to Interrupt
	SETB IT0			//Enable
	SETB ET2 			//Ligar Interrupt para o Timer 2
	SETB EA				//Ligar Interrupt para o Timer 2
	JMP LOOP
	
LOOP:
	JBC LOAD, STOP
	JMP LOOP

STOP:
	MOV IE, #0h		//Desligar \INT0 Interrupt
	CLR IT0			//Disable
	CLR ET2 		//Desligar Interrupt para o Timer 2
	CLR EA			//Desligar Interrupt para o Timer 2
	MOV P2, #0xC0
	SJMP $
	
	
TIMER_INIT:
	MOV TMR2CN, #4H									//Timer 2: 16 bit c/auto-reload
	MOV TMR2L, #LOW(-1)
    MOV TMR2H, #HIGH(-1)
	MOV TMR2RLL, #LOW(-40000)		//40000 contagens * 0.25uS = 10ms -> 0.125s ~ 12 * 10ms
    MOV TMR2RLH, #HIGH(-40000)
    RET


OSCILATOR_INIT:
    MOV FLSCL, #090h
    MOV CLKSEL, #003h
    RET



CONFIGS:
	MOV PCA0MD, #0H																						//Desabilitar o WatchDod Timer
	MOV XBR1, #40H																						//Ativar a Crossbar -> para o Display de 7 segmentos e P0.6 e P0.7 funcionar -> 'ligar pinos físicos/metálicos
	RET

END																										//Fim do Programa
*/



//EX 3
;O microcontrolador controla um semáforo com duas lâmpadas, uma vermelha (comandada
;através de P1.0) e outra amarela (comandada através de P1.1). A lâmpada amarela deve piscar de
;1,5 em 1,5 segundos. No entanto, se o bit EXCESSO (que deve declarar para a posição 9 do
;espaço endereçável ao bit) estiver a 1, a lâmpada vermelha deve ficar ligada durante 15 segundos
;e a lâmpada amarela deve ser apagada. Após os 15 segundos, o bit EXCESSO deve ser colocado
;a zero e a lâmpada amarela deve piscar de 1,5 em 1,5 segundos. Escreva a rotina de configuração
;e a rotina de serviço à interrupção da unidade temporizadora 0 que permitem implementar o
;funcionamento descrito


/*
MAX_075 DATA 30H
MAX_15 DATA 31H
	
EXCESSO EQU 21H.0	
AMARELO EQU 20H.0
TIMEOUT EQU 20H.1

CSEG AT 0H
	LJMP MAIN
	
CSEG AT 0003H
	LJMP ISR_EXT0
	
CSEG AT 002BH
	LJMP ISR_TIMER2


ISR_EXT0:
	SETB EXCESSO
	RETI


ISR_TIMER2:
	PUSH ACC
	PUSH PSW
	
	JB AMARELO, ISR_TIMER2_AMARELO
	JB EXCESSO, ISR_TIMER2_VERMELHO
	
	ISR_TIMER2_AMARELO:
		CLR  TF2H
		DJNZ MAX_075, FIM_ISR_TIMER2_AMARELO
			CPL P1.1
			MOV MAX_075, #75
			
	FIM_ISR_TIMER2_AMARELO:
		POP PSW
		POP ACC
		RETI
		
		
		
	ISR_TIMER2_VERMELHO:
		CLR  TF2H
		DJNZ MAX_075, FIM_ISR_TIMER2_VERMELHO
			MOV MAX_075, #75
			DJNZ MAX_15, FIM_ISR_TIMER2_VERMELHO
				SETB TIMEOUT
				MOV MAX_15, #20
				
	FIM_ISR_TIMER2_VERMELHO:
		POP PSW
		POP ACC
		RETI
				
	
MAIN:
	ACALL CONFIGS
	ACALL OSCILATOR_INIT
	ACALL TIMER_INIT
	CLR EXCESSO
	SETB AMARELO
	CLR TIMEOUT
	SETB P0.7
	MOV MAX_075, #75
	MOV MAX_15, #20
	MOV IE, #001H		//Enable \INT0 Interrupt
	MOV IT01CF, #007H	//Enable P0.7 to Interrupt
	SETB IT0			//Enable
	SETB ET2 			//Ligar Interrupt para o Timer 2
	SETB EA				//Ligar Interrupt para o Timer 2
	JMP LOOP

LOOP:
	JNB P0.7, STATE_VERMELHO
	JMP LOOP
	
STATE_VERMELHO:
	JNB P0.7, $
	CLR P1.0		//Ativar luz vermelha
	CLR AMARELO
	SETB EXCESSO
	JMP VERMELHO_LOOP


VERMELHO_LOOP:
	JBC TIMEOUT, LABEL_VERMELHO
	JMP VERMELHO_LOOP


LABEL_VERMELHO:
	SETB P1.0		//Desligar a luz vermelha
	SETB AMARELO
	CLR EXCESSO
	JMP LOOP


TIMER_INIT:
	MOV TMR2CN, #4H									//Timer 2: 16 bit c/auto-reload
	MOV TMR2L, #LOW(-1)
    MOV TMR2H, #HIGH(-1)
	MOV TMR2RLL, #LOW(-40000)						//40000 contagens * 0.25uS = 10ms -> 0.75s = 75 * 10ms
    MOV TMR2RLH, #HIGH(-40000)						//15s -> 20 * 0.75s
    RET


OSCILATOR_INIT:
    MOV FLSCL, #090h
    MOV CLKSEL, #003h
    RET



CONFIGS:
	MOV PCA0MD, #0H																						//Desabilitar o WatchDod Timer
	MOV XBR1, #40H																						//Ativar a Crossbar -> para o Display de 7 segmentos e P0.6 e P0.7 funcionar -> 'ligar pinos físicos/metálicos
	RET

END
*/


//EX 4

/*
;Implemente um programa que gere uma onda quadrada com uma frequencia de 1kHz -> 1ms, usando o Timer 0 16 bit

CSEG AT 0H
	LJMP MAIN


MAIN:
	SETB TR0	//Inicio da contagem
	JMP LOOP
	
LOOP:
	MOV TH0, #HIGH(-500)
	MOV TL0, #LOW(-500)
	JNB TF0, $				//Equanto não houver Overflow
	CLR TF0
	CPL P2.7
	JMP LOOP
	

TIMER_INIT:
    MOV TMOD, #001H			//Modo 2 -> 16 bit
    MOV CKCON, #002H		//SYSCLK/48 -> F = 1MHz  -> T=1uS -> 1ms/1us = 1000 contagens -> 500 contagens -> CPL
    RET



OSCILATOR_INIT:
    MOV FLSCL, #090h
    MOV CLKSEL, #003h
    RET



CONFIGS:
	MOV PCA0MD, #0H																						//Desabilitar o WatchDod Timer
	MOV XBR1, #40H																						//Ativar a Crossbar -> para o Display de 7 segmentos e P0.6 e P0.7 funcionar -> 'ligar pinos físicos/metálicos
	RET

END
*/


//EX 5
;Pretende-se desenvolver um programa que gere uma onda quadrada no pino P2.0, cujo período é
;dado pelo valor à entrada do porto P0 (ex: se P0==10, período de 0x10 - 16ms - micro segundos). Implemente
;o programa utilizando o Timer 2, recorrendo à sua interrupção e recorrendo a polling (na função
;principal) para ler o valor de P0.

/*
CSEG AT 0H
	JMP MAIN
	
	
MAIN:
	ACALL CONFIGS
	ACALL OSCILATOR_INIT
	//T = 0.25us
	MOV A, P0
	RR A			//Por causa do Complemento
	RL A			//Dividir por 0.25 = multiplicar por 4
	RL A
	MOV P0, A

	MOV TMR2CN, #4H									//Timer 2: 16 bit c/auto-reload
	MOV TMR2L, #LOW(-1)
    MOV TMR2H, #HIGH(-1)
	MOV TMR2RLL, #LOW(-P0)
    MOV TMR2RLH, #HIGH(-P0)
	
	JMP LOOP
	
LOOP:
	JNB TF2H, LOOP
	CLR TF2H
	CPL P2.0
	JMP LOOP
	

OSCILATOR_INIT:
    MOV FLSCL, #090h		
    MOV CLKSEL, #003h
    RET	

CONFIGS:
	MOV PCA0MD, #0H																						//Desabilitar o WatchDod Timer
	MOV XBR1, #40H																						//Ativar a Crossbar -> para o Display de 7 segmentos e P0.6 e P0.7 funcionar -> 'ligar pinos físicos/metálicos
	RET
	
END
*/


;Implemente um programa que, após uma interrupção externa provocada por P0.6, faça gerar uma onda quandrada de t=500ms
;Antes de ser premido o botão, a onda teria um periodo de 1s


/*
CSEG AT 0H
	LJMP MAIN
	
		
CSEG AT 03H
	LJMP ISR_EXT0
	

CSEG AT 002BH
	LJMP ISR_TIMER2


ISR_EXT0:
	SETB TIMEOUT
	RETI


ISR_TIMER2:
	PUSH ACC
	PUSH PSW
	
	JB ONDA0, ONDA_05
	JB ONDA1, ONDA_1
		
		ONDA_05:
			CLR  TF2H
			DJNZ MAX_05, FIM_ONDA_05
					CPL P2.7
					MOV MAX_05, #50
					
		FIM_ONDA_05:
			POP PSW
			POP ACC
			RETI
	
	
		ONDA_1:
			CLR  TF2H
			DJNZ MAX_025, FIM_ONDA_1
					CPL P2.7
					MOV MAX_025, #25
					
		FIM_ONDA_1:
			POP PSW
			POP ACC
			RETI

	
MAX_05 DATA 30H
MAX_025 DATA 31H
	
ONDA0 EQU 20H.0
ONDA1 EQU 20H.1
TIMEOUT EQU 20H.2
	
	
MAIN:
	ACALL CONFIGS
	ACALL OSCILATOR_INIT
	ACALL TIMER_INIT
	MOV MAX_025, #25
	MOV MAX_05, #50
	CLR TIMEOUT
	CLR ONDA0
	CLR ONDA1
	JMP STATE_ONDA0
	
STATE_ONDA0:
	SETB ET2 		//Ligar Interrupt para o Timer 2
	SETB EA			//Ligar Interrupt para o Timer 2
	SETB ONDA0
	MOV IT01CF, #06H
	SETB IT0
	SETB EX0
	JMP LOOP_ONDA0
	
LOOP_ONDA0:
	JBC TIMEOUT, STOP
	JMP LOOP_ONDA0

STOP:
	CLR IT0
	CLR EX0
	CLR EA
	CLR ET2
	CLR ONDA0
	JMP STATE_ONDA1
	
STATE_ONDA1:
	SETB ET2 		//Ligar Interrupt para o Timer 2
	SETB EA			//Ligar Interrupt para o Timer 2
	SETB ONDA1
	SETB IT0
	SETB EX0
	JMP LOOP_ONDA1
	
LOOP_ONDA1:
	JMP LOOP_ONDA1
	
		
	
TIMER_INIT:
	MOV TMR2CN, #4H									//Timer 2: 16 bit c/auto-reload
	MOV TMR2L, #LOW(-1)
    MOV TMR2H, #HIGH(-1)
	MOV TMR2RLL, #LOW(-40000)
    MOV TMR2RLH, #HIGH(-40000)
    RET


OSCILATOR_INIT:
    MOV FLSCL, #090h
    MOV CLKSEL, #003h
    RET



CONFIGS:
	MOV PCA0MD, #0H																						//Desabilitar o WatchDod Timer
	MOV XBR1, #40H																						//Ativar a Crossbar -> para o Display de 7 segmentos e P0.6 e P0.7 funcionar -> 'ligar pinos físicos/metálicos
	RET

END			


*/

/*

;O microcontrolador controla um semáforo com duas lâmpadas, uma vermelha (comandada
;através de P1.0) e outra amarela (comandada através de P1.1). A lâmpada amarela deve piscar de
;1,5 em 1,5 segundos. No entanto, se o bit EXCESSO (que deve declarar para a posição 9 do
;espaço endereçável ao bit) estiver a 1, a lâmpada vermelha deve ficar ligada durante 15 segundos
;e a lâmpada amarela deve ser apagada. Após os 15 segundos, o bit EXCESSO deve ser colocado
;a zero e a lâmpada amarela deve piscar de 1,5 em 1,5 segundos. Escreva a rotina de configuração
;e a rotina de serviço à interrupção da unidade temporizadora 0 que permitem implementar o
;funcionamento descrito


MAX_075 DATA 30H
MAX_15 DATA 31H
MAX_200 DATA 32H
	
EXCESSO EQU 21H.0	
AMARELO EQU 20H.0
TIMEOUT EQU 20H.1
INT0 EQU 20H.2
INT1 EQU 20H.3
	

CSEG AT 0H
	LJMP MAIN
	
CSEG AT 0003H
	LJMP ISR_EXT0
	
	
CSEG AT 0013H
	LJMP ISR_EXT1


CSEG AT 002BH
	LJMP ISR_TIMER2


ISR_EXT0:
	SETB INT0
	RETI


ISR_EXT1:
	SETB INT1
	RETI


ISR_TIMER2:
	PUSH ACC
	PUSH PSW
	
	JB AMARELO, ISR_TIMER2_AMARELO
	JB EXCESSO, ISR_TIMER2_VERMELHO
	
	ISR_TIMER2_AMARELO:
		CLR  TF2H
		DJNZ MAX_075, FIM_ISR_TIMER2_AMARELO
			CPL P1.1
			MOV MAX_075, #75
			
	FIM_ISR_TIMER2_AMARELO:
		POP PSW
		POP ACC
		RETI
		
		
		
	ISR_TIMER2_VERMELHO:
		CLR  TF2H
		DJNZ MAX_075, FIM_ISR_TIMER2_VERMELHO
			MOV MAX_075, #75
			DJNZ MAX_15, FIM_ISR_TIMER2_VERMELHO
				SETB TIMEOUT
				MOV MAX_15, #20
				
	FIM_ISR_TIMER2_VERMELHO:
		POP PSW
		POP ACC
		RETI
				
	
MAIN:
	ACALL CONFIGS
	ACALL OSCILATOR_INIT
	ACALL TIMER_INIT
	CLR TIMEOUT
	SETB P0.7
	MOV MAX_075, #75
	MOV MAX_15, #20
	MOV MAX_200, #20
	MOV IE, #001H		//Enable \INT0 Interrupt
	MOV IT01CF, #007H	//Enable P0.7 to Interrupt
	SETB IT0			//Enable
	JMP STATE_AMARELO

STATE_AMARELO:
	SETB AMARELO
	CLR EXCESSO
	SETB ET2 			//Ligar Interrupt para o Timer 2
	SETB EA				//Ligar Interrupt para o Timer 2
	JMP AMARELO_LOOP
	
	
AMARELO_LOOP:
	JBC EXCESSO, STATE_VERMELHO
	ACALL TEST_VEL
	JMP AMARELO_LOOP
	
	TESTE_VEL:
		
	
	
STATE_VERMELHO:
	CLR ET2
	CLR EA
	CLR P1.0		//Ativar luz vermelha
	CLR AMARELO
	SETB EXCESSO
	JMP VERMELHO_LOOP


VERMELHO_LOOP:
	JBC TIMEOUT, VERMELHO_FIM
	JMP VERMELHO_LOOP


VERMELHO_FIM:
	CLR ET2
	CLR EA
	SETB P1.0		//Desligar a luz vermelha
	SETB AMARELO
	CLR EXCESSO
	JMP STATE_AMARELO


TIMER_INIT:
	MOV TMR2CN, #4H									//Timer 2: 16 bit c/auto-reload
	MOV TMR2L, #LOW(-1)
    MOV TMR2H, #HIGH(-1)
	MOV TMR2RLL, #LOW(-40000)						//40000 contagens * 0.25uS = 10ms -> 0.75s = 75 * 10ms
    MOV TMR2RLH, #HIGH(-40000)						//15s -> 20 * 0.75s
    RET


OSCILATOR_INIT:
    MOV FLSCL, #090h
    MOV CLKSEL, #003h
    RET



CONFIGS:
	MOV PCA0MD, #0H																						//Desabilitar o WatchDod Timer
	MOV XBR1, #40H																						//Ativar a Crossbar -> para o Display de 7 segmentos e P0.6 e P0.7 funcionar -> 'ligar pinos físicos/metálicos
	RET

END
*/


;Pretende-se desenvolver um programa em assembly que permita controlar um semáforo limitador de  
;velocidade  (duas  lâmpadas  apenas,  uma  encarnada  –  P1.1  -  a  outra  laranja  –  P1.0)
;Se  for  detectado  um  veículo  a  circular  a  mais  de  55Km/h,  o  programa  deve  acender  
;a  luz  encarnada  do  semáforo  durante  15  segundos,  comutando  depois  para  o  estado  
;por  defeito  (reset)  em  que  a  luz  amarela está em intermitente 
;(650 milisegundos ligada e 650 milisegundos desligada). 
;A  detecção  da  velocidade  do  veículo  é  realizada  recorrendo  a  dois  sensores  separados  
;de  5,5  metros.  Os  sinais  dos  sensores  estão  ligados  às  duas  interrupções  externas  
;do  microcontrolador.  Quando  o  veículo  é  detectado  num  sensor  o  sinal  no  pino  da  
;respectiva  interrupção  transita  de  nível lógico 1 para nível lógico 0


//a) Configure o temporizador 0 no modo 16-bit, utilize as interrupções do temporizador 
//   para gerar o sinal que permite colocar a luz laranja a piscar de 650 em 650 milisegundos.



//b) Escreva  uma  rotina  que  configure  as  interrupções  externas  e  o  temporizador  2  
//   para  16-bit  (auto-reload)  com  interrupção.  A  interrupção  externa  0  deve  estar  activada  
//   e  a  externa  1  desactivada até ser detectado um veículo. Escreva a rotina de serviço à interrupção 
//   externa 0 que deve iniciar a contagem do temporizador 2 e permitir a interrupção externa 1.


/*
MAX_0325 DATA 30H	//325ms
MAX_1 DATA 31H 		//1s
MAX_15 DATA 32H		//15s
MAX_2 DATA 33H		//2s

AMARELO EQU 20H.0
VERMELHO EQU 20H.1
TIMEOUT EQU 20H.2
TIMEOUT_2 EQU 20H.5
INT_0 EQU 20H.3
INT_1 EQU 20H.4


CSEG AT 0H
	LJMP MAIN
	
CSEG AT 03H
	LJMP ISR_EX0
	
CSEG AT 13H
	LJMP ISR_EX1
	
CSEG AT 0BH
	LJMP ISR_TIMER0
	
CSEG AT 0x002B
	LJMP ISR_TIMER2

ISR_EX0:
	SETB INT_0
	SETB TR2
	SETB ET2
	RETI
		
		
ISR_EX1:
	SETB INT_1
	CLR TR2
	CLR ET2
	RETI
	

ISR_TIMER0:
	PUSH ACC
	PUSH PSW
	
	
	JB AMARELO, ISR_TIMER0_AMARELO
	JB VERMELHO, ISR_TIMER_VERMELHO
	
	ISR_TIMER0_AMARELO:
		CLR TF0
		DJNZ MAX_0325, FIM_ISR_TIMER0_AMARELO
			CPL P2.7
			MOV MAX_0325, #13		

		FIM_ISR_TIMER0_AMARELO:
			MOV TH0, #HIGH(-25000)
			MOV TL0, #LOW(-25000)
			POP PSW
			POP ACC
			RETI


	ISR_TIMER_VERMELHO:
		CLR TF0
		DJNZ MAX_1, FIM_ISR_TIMER0_VERMELHO
			MOV MAX_1, #40
			DJNZ MAX_15, FIM_ISR_TIMER0_VERMELHO
			SETB TIMEOUT_2
			MOV MAX_15, #15

		FIM_ISR_TIMER0_VERMELHO:
			MOV TH0, #HIGH(-25000)
			MOV TL0, #LOW(-25000)
			POP PSW
			POP ACC
			RETI

ISR_TIMER2:
	PUSH ACC
	PUSH PSW
	CLR  TF2H
	DJNZ MAX_2, FIM_ISR_TIMER2
		SETB TIMEOUT
		MOV MAX_2, #200
		
		FIM_ISR_TIMER2:
			POP PSW
			POP ACC
			RETI


MAIN:
	ACALL CONFIGS
	ACALL OSCILATOR_INIT
	ACALL TIMER0_INIT
	ACALL TIMER2_INIT
	MOV MAX_0325, #13
	MOV MAX_1, #40
	MOV MAX_15, #15
	MOV MAX_2, #200
	CLR AMARELO
	CLR VERMELHO
	CLR TIMEOUT
	CLR TIMEOUT_2
	
	SETB P0.6
	SETB P0.7
	;P0.6 atribuido a INT0
	;P0.7 atribuido a INT1
	;INT0 e INT1 active a LOW
	MOV IT01CF, #76H
	;INT0 e INT1 à transição -> ORL TCON, #5
	SETB IT1
	SETB IT0
	SETB EX0
	SETB EX1
	JMP STATE_AMARELO
	
STATE_AMARELO:
	CLR INT_0
	CLR TIMEOUT
	CLR TIMEOUT_2
	SETB P2.0
	SETB AMARELO
	CLR VERMELHO
	SETB TR0				//Run Timer 0
	SETB EA
	SETB ET0				//Enable Interrupt para Timer 0
	JMP LOOP_STATE_AMARELO
	
LOOP_STATE_AMARELO:
	JBC INT_1, FIM_AMARELO
	JMP LOOP_STATE_AMARELO
	
FIM_AMARELO:
	JNB TIMEOUT, EXCESSO_VELOCIDADE
	JMP STATE_AMARELO
	
	
EXCESSO_VELOCIDADE:
	SETB P2.7
	CLR TIMEOUT
	CLR P2.0
	SETB VERMELHO	
	CLR AMARELO
	JMP LOOP_STATE_VERMELHO
	
LOOP_STATE_VERMELHO:
	JBC TIMEOUT_2, 	STATE_AMARELO
	JMP LOOP_STATE_VERMELHO


OSCILATOR_INIT:
    MOV FLSCL, #090h		//48MHz
    MOV CLKSEL, #003h
    RET


TIMER0_INIT:
    MOV TMOD, #01H			//Modo 16 bit Timer 0
    MOV CKCON, #002H		//SYSCLK/48 -> F = 1MHz -> T = 1uS -> 625ms/2 = 325ms 		25ms-> 25000 contagens -> 25ms * 13 = 325ms
	MOV TH0, #HIGH(-25000)
	MOV TL0, #LOW(-25000)
    RET

TIMER2_INIT:
	//MOV TMR2CN, #4H										//Timer 2: 16 bit c/auto-reload
	MOV TMR2L, #LOW(-40000)
    MOV TMR2H, #HIGH(-40000)
	MOV TMR2RLL, #LOW(-40000)							//4000 contagens * 0.25uS = 0.1ms -> Máximo tempo para excesso de velocidade
    MOV TMR2RLH, #HIGH(-40000)						
    RET


CONFIGS:
	MOV PCA0MD, #0H																						//Desabilitar o WatchDod Timer
	MOV XBR1, #40H																						//Ativar a Crossbar -> para o Display de 7 segmentos e P0.6 e P0.7 funcionar -> 'ligar pinos físicos/metálicos
	RET

END

*/


/*
//80H IDATA -> Tempo do nivel alto em Us 
//81H IDATA -> Tempo do nivel baixo em Us     ;onda quadrada

CSEG AT 0H
	LJMP MAIN

CSEG AT 002BH
	LJMP ISR_TIMER2


ISR_TIMER2:
	PUSH ACC
	PUSH PSW
	CLR  TF2H
	SETB TIMEOUT
			
FIM_ISR_TIMER2:
	POP PSW
	POP ACC
	RETI


STORAGE IDATA 80H
TIMEOUT EQU 20H.0

MAIN:
	ACALL CONFIGS
	ACALL OSCILATOR_INIT
	CLR TIMEOUT
	JMP STATE_SUBIDA
	
STATE_SUBIDA:
	MOV R0, #STORAGE
	
	MOV A, @R0
	RL A			//Dividir por 0.25 = multiplicar por 4
	RL A
	MOV P0, A

	MOV TMR2L, #LOW(-P0)
    MOV TMR2H, #HIGH(-P0)
	MOV TMR2RLL, #LOW(-P0)
    MOV TMR2RLH, #HIGH(-P0)
	
	SETB TR2
	SETB EA
	SETB ET2
	CLR P2.0		//Ligar ponto decimal
	JMP LOOP_SUBIDA

LOOP_SUBIDA:	
	JBC TIMEOUT, STATE_DESCIDA
	JMP LOOP_SUBIDA


STATE_DESCIDA:
	CLR ET2
	
	INC R0
	
	MOV A, @R0
	RL A			//Dividir por 0.25 = multiplicar por 4
	RL A
	MOV P0, A

	MOV TMR2L, #LOW(-P0)
    MOV TMR2H, #HIGH(-P0)
	MOV TMR2RLL, #LOW(-P0)
    MOV TMR2RLH, #HIGH(-P0)
	
	SETB ET2
	SETB P2.0		//Desligar ponto decimal
	JMP LOOP_DESCIDA
	
LOOP_DESCIDA:
	JBC TIMEOUT, STATE_SUBIDA
	JMP LOOP_DESCIDA


OSCILATOR_INIT:
    MOV FLSCL, #090h
    MOV CLKSEL, #003h
    RET



CONFIGS:
	MOV PCA0MD, #0H																						//Desabilitar o WatchDod Timer
	MOV XBR1, #40H																						//Ativar a Crossbar -> para o Display de 7 segmentos e P0.6 e P0.7 funcionar -> 'ligar pinos físicos/metálicos
	RET
END

*/


; GERAR ONDA QUADRADA, PERIODO = 1 SEG,  USANDO TIMER 0 COM 8 BITS AUTO RELOAD

/*
CSEG AT 0H
	LJMP MAIN
	
CSEG AT 0BH
	LJMP ISR_TIMER0
	
	
ISR_TIMER0:
	CLR TF0
	DJNZ MAX_001, FIM_ISR_TIMER0
		MOV MAX_001, #100
		DJNZ MAX_05, FIM_ISR_TIMER0
		CPL P2.7
		MOV MAX_05, #50
		
		FIM_ISR_TIMER0:
			RETI



	
	
MAX_001 DATA 30H	;0.01s
MAX_05 DATA 31H		;0.5s


MAIN:
	ACALL CONFIGS
	ACALL OSCILATOR_INIT
	ACALL TIMER0_INIT
	MOV MAX_001, #100
	MOV MAX_05, #50
	
	SETB TR0				//Run Timer 0
	SETB EA
	SETB ET0				//Enable Interrupt para Timer 0
	
	SJMP $
	



TIMER0_INIT:
    MOV TMOD, #002H			//8 bit auto reload
    MOV CKCON, #002H		//T=1uS 
	MOV TH0, #-100			//Valor de recarga
	MOV TL0, #0FFH
    RET



OSCILATOR_INIT:
    MOV FLSCL, #090h
    MOV CLKSEL, #003h
    RET



CONFIGS:
	MOV PCA0MD, #0H																						//Desabilitar o WatchDod Timer
	MOV XBR1, #40H																						//Ativar a Crossbar -> para o Display de 7 segmentos e P0.6 e P0.7 funcionar -> 'ligar pinos físicos/metálicos
	RET
	
END

*/



;Implemente um programa que gere uma onda quadrada com T=500ms
;Quando a interrupção externa gerada por P0.6 estiver ativa, passa a gerar uma omda com T=1s
;Quando premido novamente, passa a gerar a onda de T=500ms

/*

CSEG AT 0H
	LJMP MAIN
	
		
CSEG AT 03H
	LJMP ISR_EXT0
	

CSEG AT 002BH
	LJMP ISR_TIMER2


ISR_EXT0:
	SETB TIMEOUT	
	RETI
	


ISR_TIMER2:
	PUSH ACC
	PUSH PSW
	
	JB ONDA0, ONDA_05
	JB ONDA1, ONDA_1
		
		ONDA_05:						//Onda com T=500ms
			CLR  TF2H
			DJNZ MAX_025, FIM_ONDA_05
					CPL P2.7
					MOV MAX_025, #25
					
		FIM_ONDA_05:
			POP PSW
			POP ACC
			RETI
	
	
		ONDA_1:							//Onda com T=1s
			CLR  TF2H
			DJNZ MAX_05, FIM_ONDA_1
					CPL P2.7
					MOV MAX_05, #50
					
		FIM_ONDA_1:
			POP PSW
			POP ACC
			RETI
			
MAX_05 DATA 30H
MAX_025 DATA 31H
	
ONDA0 EQU 20H.0
ONDA1 EQU 20H.1
TIMEOUT EQU 20H.2
	
MAIN:
	ACALL CONFIGS
	ACALL OSCILATOR_INIT
	ACALL TIMER_INIT
	MOV MAX_025, #25
	MOV MAX_05, #50
	CLR TIMEOUT
	CLR ONDA0
	CLR ONDA1
	MOV IT01CF, #06H	//Interrupção externa para P0.6
	SETB ET2 		//Ligar Interrupt para o Timer 2
	SETB EA			//Ligar Interrupt para o Timer 2
	SETB IT0		//Enable
	SETB EX0		//Enable External Interrupt 0
	SETB TR2		//Timer 2 a contar
	JMP STATE_ONDA0
	
STATE_ONDA0:
	SETB ONDA0
	JMP LOOP_ONDA0
	
LOOP_ONDA0:
	JBC TIMEOUT, FIM_LOOP_ONDA0
	JMP LOOP_ONDA0

FIM_LOOP_ONDA0:
	CLR ONDA0
	JMP STATE_ONDA1
	
STATE_ONDA1:
	SETB ONDA1
	JMP LOOP_ONDA1
	
LOOP_ONDA1:
	JBC TIMEOUT, FIM_LOOP_ONDA1
	JMP LOOP_ONDA1
	
	
FIM_LOOP_ONDA1:
	CLR ONDA1
	JMP STATE_ONDA0
	
	
	
TIMER_INIT:
	//MOV TMR2CN, #4H									//Timer 2: 16 bit c/auto-reload
	MOV TMR2L, #LOW(-1)
    MOV TMR2H, #HIGH(-1)
	MOV TMR2RLL, #LOW(-40000)
    MOV TMR2RLH, #HIGH(-40000)
    RET


OSCILATOR_INIT:
    MOV FLSCL, #090h
    MOV CLKSEL, #003h
    RET



CONFIGS:
	MOV PCA0MD, #0H																						//Desabilitar o WatchDod Timer
	MOV XBR1, #40H																						//Ativar a Crossbar -> para o Display de 7 segmentos e P0.6 e P0.7 funcionar -> 'ligar pinos físicos/metálicos
	RET

END			

*/


/*
CSEG AT 0H
	LJMP MAIN
	
CSEG AT 03H
	LJMP ISR_EX0
	
	
CSEG AT 02BH
	LJMP ISR_TIMER2
	
ISR_EX0:
	CLR IE0
	
	JB FLAG, TROCA
	MOV S_0, #0
	MOV S_1, #1
	MOV S_2, #2
	MOV S_3, #3
	CPL FLAG
	
	RETI
	
	TROCA:
		MOV S_0, #2
		MOV S_1, #3
		MOV S_2, #0
		MOV S_3, #1
		CPL FLAG
		
		RETI
	
	
ISR_TIMER2:
	PUSH ACC
	PUSH PSW
	CLR TF2H
	
	JB TIM_0, ISR_TIMER2_0	;500ms
	JB TIM_1, ISR_TIMER2_1	;1s
	JB TIM_2, ISR_TIMER2_2	;5s
	JB TIM_3, ISR_TIMER2_3	;10s

	ISR_TIMER2_0:
		DJNZ MAX_05, FIM_ISR_TIMER2_0
		SETB TIMEOUT
		MOV MAX_05, #50
		
		FIM_ISR_TIMER2_0:
			POP PSW
			POP ACC
			RETI
			
	ISR_TIMER2_1:
		DJNZ MAX_05, FIM_ISR_TIMER2_1
		MOV MAX_05, #50
			DJNZ MAX_1, FIM_ISR_TIMER2_1
			SETB TIMEOUT
			MOV MAX_1, #2
		
		FIM_ISR_TIMER2_1:
			POP PSW
			POP ACC
			RETI	
		
	
	ISR_TIMER2_2:
		DJNZ MAX_05, FIM_ISR_TIMER2_2
		MOV MAX_05, #50
			DJNZ MAX_5, FIM_ISR_TIMER2_2
			SETB TIMEOUT
			MOV MAX_5, #10
		
		FIM_ISR_TIMER2_2:
			POP PSW
			POP ACC
			RETI	
	
	ISR_TIMER2_3:
		DJNZ MAX_05, FIM_ISR_TIMER2_3
		MOV MAX_05, #50
			DJNZ MAX_10, FIM_ISR_TIMER2_3
			SETB TIMEOUT
			MOV MAX_10, #20
		
		FIM_ISR_TIMER2_3:
			POP PSW
			POP ACC
			RETI	


	
S_0 DATA 30H
S_1 DATA 31H
S_2 DATA 32H
S_3 DATA 33H
	
STATE DATA 34H
N_STATE DATA 35H
	
MAX_05 DATA 36H
MAX_1 DATA 37H
MAX_5 DATA 38H	
MAX_10 DATA 39H
	
FLAG EQU 20H.0
TIM_0 EQU 20H.1	
TIM_1 EQU 20H.2
TIM_2 EQU 20H.3
TIM_3 EQU 20H.4
	
TIMEOUT EQU 20H.5
	

MAIN:
	ACALL CONFIGS
	ACALL OSCILATOR_INIT
	ACALL TIMER2_INIT
	MOV S_0, #0
	MOV S_1, #1
	MOV S_2, #2
	MOV S_3, #3
	
	MOV MAX_05, #50
	MOV MAX_1, #2
	MOV MAX_5, #10
	MOV MAX_10, #20
	
	SETB FLAG
	
	CLR TIM_0
	CLR TIM_1
	CLR TIM_2
	CLR TIM_3
	
	CLR TIMEOUT
	
	MOV IT01CF, #06H		;P0.6 Interrupt
	SETB IT0				;Edge -> high-low
	
	MOV N_STATE, S_0
	
	
	JMP ENCODE_FSM
	
	
ENCODE_FSM:
	MOV DPTR, #SWITCH_STATE
	MOV STATE, N_STATE 
	MOV A, STATE
	RL A
	JMP @A + DPTR
	
	
SWITCH_STATE:
	AJMP STATE_0
	AJMP STATE_1
	AJMP STATE_2
	AJMP STATE_3
		
STATE_0:
	MOV TMR2L, #LOW(-20000)
    MOV TMR2H, #HIGH(-20000)	
	MOV P2, #0C0H
	SETB TIM_0
	SETB EA
	SETB EX0	
	SETB ET2
	SETB TR2
	JMP LOOP_STATE_0
	
	LOOP_STATE_0:
		JBC TIMEOUT, FIM_LOOP_STATE_0
		JMP LOOP_STATE_0
	
	FIM_LOOP_STATE_0:
		CLR EA
		CLR EX0	
		CLR ET2
		CLR TR2
		MOV P2, #0FFH
		MOV N_STATE, S_1
		CLR TIM_0
		JMP ENCODE_FSM

STATE_1:
	MOV TMR2L, #LOW(-20000)
    MOV TMR2H, #HIGH(-20000)	
	MOV P2, #0F9H
	SETB TIM_1
	SETB EA
	SETB EX0	
	SETB ET2
	SETB TR2
	JMP LOOP_STATE_1
	
	LOOP_STATE_1:
		JBC TIMEOUT, FIM_LOOP_STATE_1
		JMP LOOP_STATE_1
	
	FIM_LOOP_STATE_1:
		CLR EA
		CLR EX0	
		CLR ET2
		CLR TR2
		MOV P2, #0FFH
		MOV N_STATE, S_2
		CLR TIM_1
		JMP ENCODE_FSM
	
	
STATE_2:
	MOV TMR2L, #LOW(-20000)
    MOV TMR2H, #HIGH(-20000)	
	MOV P2, #0A4H
	SETB TIM_2
	SETB EA
	SETB EX0	
	SETB ET2
	SETB TR2
	JMP LOOP_STATE_2
	
	LOOP_STATE_2:
		JBC TIMEOUT, FIM_LOOP_STATE_2
		JMP LOOP_STATE_2
	
	FIM_LOOP_STATE_2:
		CLR EA
		CLR EX0	
		CLR ET2
		CLR TR2
		MOV P2, #0FFH
		MOV N_STATE, S_3
		CLR TIM_2
		JMP ENCODE_FSM
	
	
	
	
STATE_3:
	MOV TMR2L, #LOW(-20000)
    MOV TMR2H, #HIGH(-20000)	
	MOV P2, #0B0H
	SETB TIM_3
	SETB EA
	SETB EX0	
	SETB ET2
	SETB TR2
	JMP LOOP_STATE_3
	
	LOOP_STATE_3:
		JBC TIMEOUT, FIM_LOOP_STATE_3
		JMP LOOP_STATE_3
	
	FIM_LOOP_STATE_3:
		CLR EA
		CLR EX0	
		CLR ET2
		CLR TR2
		MOV P2, #0FFH
		MOV N_STATE, S_0
		CLR TIM_3
		JMP ENCODE_FSM


TIMER2_INIT:
	//MOV TMR2CN, #4H									//Timer 2: 16 bit c/auto-reload -> T = 0.5uS
	MOV TMR2L, #LOW(-20000)
    MOV TMR2H, #HIGH(-20000)						
	MOV TMR2RLL, #LOW(-20000)
    MOV TMR2RLH, #HIGH(-20000)
    RET


OSCILATOR_INIT:
    MOV FLSCL, #090h
    MOV CLKSEL, #002h		//24MHz
    RET



CONFIGS:
	MOV PCA0MD, #0H																						//Desabilitar o WatchDod Timer
	MOV XBR1, #40H																						//Ativar a Crossbar -> para o Display de 7 segmentos e P0.6 e P0.7 funcionar -> 'ligar pinos físicos/metálicos
	RET

END			
		
*/	
	

//---------------------------------------------------------------------TESTE-----------------------------------------------------------------------------------------------


/*		
CSEG AT 0H
	LJMP MAIN

MAX DATA 30H
INDEX DATA 31
COUNT DATA 32H
	
STOR1 XDATA 1030H	//menor que 256		
STOR2 IDATA 80H		//maior ou igual 256	-> overflow
	
FLAG EQU 20H.0

MAIN:
	MOV INDEX, #0
	MOV COUNT, #0
	MOV MAX, #17		;64/4+1
	MOV R0, #STOR2
	MOV DPTR, #STOR1
	MOV R2, DPL
	MOV R3, DPH
	CLR FLAG
	JMP LOOP
	
	
LOOP:
	DJNZ MAX, SUM_NUMBERS
	SJMP $
	
	SUM_NUMBERS:
		MOV DPTR, #1080H
		MOV A, INDEX
		MOVC A, @A + DPTR
		MOV R4, A
		INC INDEX
		MOV A, INDEX
		MOVC A, @A + DPTR
		MOV R5, A
		INC INDEX
		MOV A, INDEX
		MOVC A, @A + DPTR
		MOV R6, A
		INC INDEX
		MOV A, INDEX
		MOVC A, @A + DPTR
		MOV R7, A
		INC INDEX
		ACALL SUM_TEST
		JMP LOOP
		
		SUM_TEST:
			//CLR C
			MOV A, R4
			//ADD A, R4
			//JC LABEL_OVERFLOW
			CLR C
			ADD A, R5
			ACALL LABEL_OVERFLOW
			CLR C
			ADD A, R6
			ACALL LABEL_OVERFLOW
			CLR C
			ADD A, R7
			ACALL LABEL_OVERFLOW
			JBC FLAG, MAIOR_256
			
			MOV DPL, R2
			MOV DPH, R3
			MOVX @DPTR, A
			INC DPTR
			MOV R2, DPL
			MOV R3, DPH
			RET


			LABEL_OVERFLOW:
				//MOV @R0, A
				//INC R0
				//RET
				JC OVERFLOW
				RET
				
				OVERFLOW:
					SETB FLAG
					RET
				
			MAIOR_256:
				MOV @R0, A
				INC R0
				RET	




END




*/







CSEG AT 0H
	LJMP MAIN
	
CSEG AT 03H
	LJMP ISR_EX0


CSEG AT 0x0013
	LJMP ISR_EX1
	

CSEG AT 02BH
	LJMP ISR_TIMER2

	
ISR_EX0:
	
	JB FLAG, TROCA
	MOV S_0, #0
	MOV S_1, #1
	MOV S_2, #2
	MOV S_3, #3
	CPL FLAG
	
	RETI
	
	TROCA:
		MOV S_0, #2
		MOV S_1, #3
		MOV S_2, #0
		MOV S_3, #1
		CPL FLAG
		
		RETI
	
ISR_EX1:
	JB FLAG2, TROCA2
		CLR PISCAR
		RETI
		
		TROCA2:
			SETB PISCAR
			RETI
	
ISR_TIMER2:
	PUSH ACC
	PUSH PSW
	CLR TF2H
	
	JB TIM_0, ISR_TIMER2_0	;2s
	JB TIM_1, ISR_TIMER2_1	;4s
	JB TIM_2, ISR_TIMER2_2	;8s
	JB TIM_3, ISR_TIMER2_3	;10s

	ISR_TIMER2_0:
		DJNZ MAX_2, FIM_ISR_TIMER2_0
		SETB TIMEOUT
		MOV MAX_2, #200
		
		FIM_ISR_TIMER2_0:
			POP PSW
			POP ACC
			RETI
			
	ISR_TIMER2_1:
		DJNZ MAX_2, FIM_ISR_TIMER2_1
		MOV MAX_2, #200
			DJNZ MAX_4, FIM_ISR_TIMER2_1
			SETB TIMEOUT
			MOV MAX_4, #2
		
		FIM_ISR_TIMER2_1:
			POP PSW
			POP ACC
			RETI	
		
	
	ISR_TIMER2_2:
		DJNZ MAX_2, FIM_ISR_TIMER2_2
		MOV MAX_2, #200
			DJNZ MAX_8, FIM_ISR_TIMER2_2
			SETB TIMEOUT
			MOV MAX_8, #4
		
		FIM_ISR_TIMER2_2:
			POP PSW
			POP ACC
			RETI	
	
	ISR_TIMER2_3:
		DJNZ MAX_2, FIM_ISR_TIMER2_3
		MOV MAX_2, #200
			DJNZ MAX_10, FIM_ISR_TIMER2_3
			SETB TIMEOUT
			MOV MAX_10, #5
		
		FIM_ISR_TIMER2_3:
			POP PSW
			POP ACC
			RETI	


	
S_0 DATA 30H
S_1 DATA 31H
S_2 DATA 32H
S_3 DATA 33H
	
STATE DATA 34H
N_STATE DATA 35H
	
MAX_2 DATA 36H
MAX_4 DATA 37H
MAX_8 DATA 38H	
MAX_10 DATA 39H
	
FLAG EQU 20H.0
TIM_0 EQU 20H.1	
TIM_1 EQU 20H.2
TIM_2 EQU 20H.3
TIM_3 EQU 20H.4
	
TIMEOUT EQU 20H.5


FLAG2 DATA 40H
PISCAR EQU 21H.0

MAIN:
	ACALL CONFIGS
	ACALL OSCILATOR_INIT
	ACALL TIMER2_INIT
	MOV S_0, #0
	MOV S_1, #1
	MOV S_2, #2
	MOV S_3, #3
	
	MOV MAX_2, #200
	MOV MAX_4, #2
	MOV MAX_8, #4
	MOV MAX_10, #5
	
	SETB FLAG
	SETB FLAG2
	
	CLR TIM_0
	CLR TIM_1
	CLR TIM_2
	CLR TIM_3
	
	CLR TIMEOUT
	
	MOV IT01CF, #06H		;P0.6 Interrupt e P0.7 Interrupt
	SETB IT0				;Edge -> high-low
	
	MOV N_STATE, S_0
	
	
	JMP ENCODE_FSM
	
	
ENCODE_FSM:
	MOV DPTR, #SWITCH_STATE
	MOV STATE, N_STATE 
	MOV A, STATE
	RL A
	JMP @A + DPTR
	
	
SWITCH_STATE:
	AJMP STATE_0
	AJMP STATE_1
	AJMP STATE_2
	AJMP STATE_3
		
STATE_0:
	MOV TMR2L, #LOW(-10000)
    MOV TMR2H, #HIGH(-10000)	
	MOV P2, #0C0H
	SETB TIM_0
	SETB EA
	SETB EX0	
	SETB ET2
	SETB TR2
	JMP LOOP_STATE_0
	
	LOOP_STATE_0:
		JBC TIMEOUT, FIM_LOOP_STATE_0
		JMP LOOP_STATE_0
	
	FIM_LOOP_STATE_0:
		CLR EA
		CLR EX0	
		CLR ET2
		CLR TR2
		MOV P2, #0FFH
		MOV N_STATE, S_1
		CLR TIM_0
		JMP ENCODE_FSM

STATE_1:
	MOV TMR2L, #LOW(-10000)
    MOV TMR2H, #HIGH(-10000)	
	MOV P2, #0F9H
	SETB TIM_1
	SETB EA
	SETB EX0	
	SETB ET2
	SETB TR2
	JMP LOOP_STATE_1
	
	LOOP_STATE_1:
		JBC TIMEOUT, FIM_LOOP_STATE_1
		JMP LOOP_STATE_1
	
	FIM_LOOP_STATE_1:
		CLR EA
		CLR EX0	
		CLR ET2
		CLR TR2
		MOV P2, #0FFH
		MOV N_STATE, S_2
		CLR TIM_1
		JMP ENCODE_FSM
	
	
STATE_2:
	MOV TMR2L, #LOW(-10000)
    MOV TMR2H, #HIGH(-10000)	
	MOV P2, #0A4H
	SETB TIM_2
	SETB EA
	SETB EX0	
	SETB ET2
	SETB TR2
	JMP LOOP_STATE_2
	
	LOOP_STATE_2:
		JBC TIMEOUT, FIM_LOOP_STATE_2
		JMP LOOP_STATE_2
	
	FIM_LOOP_STATE_2:
		CLR EA
		CLR EX0	
		CLR ET2
		CLR TR2
		MOV P2, #0FFH
		MOV N_STATE, S_3
		CLR TIM_2
		JMP ENCODE_FSM
	
	
	
	
STATE_3:
	MOV TMR2L, #LOW(-10000)
    MOV TMR2H, #HIGH(-10000)
	MOV P2, #0B0H
	SETB TIM_3
	SETB EA
	SETB EX0	
	SETB ET2
	SETB TR2
	JMP LOOP_STATE_3
	
	LOOP_STATE_3:
		JBC TIMEOUT, FIM_LOOP_STATE_3
		JMP LOOP_STATE_3
	
	FIM_LOOP_STATE_3:
		CLR EA
		CLR EX0	
		CLR ET2
		CLR TR2
		MOV P2, #0FFH
		MOV N_STATE, S_0
		CLR TIM_3
		JMP ENCODE_FSM


TIMER2_INIT:
	//MOV TMR2CN, #4H									//Timer 2: 16 bit c/auto-reload -> T = 1uS
	MOV TMR2L, #LOW(-10000)
    MOV TMR2H, #HIGH(-10000)						
	MOV TMR2RLL, #LOW(-10000)
    MOV TMR2RLH, #HIGH(-10000)
    RET


OSCILATOR_INIT:
    mov  OSCICN,    #0C3h	//12MHz
    RET



CONFIGS:
	MOV PCA0MD, #0H																						//Desabilitar o WatchDod Timer
	MOV XBR1, #40H																						//Ativar a Crossbar -> para o Display de 7 segmentos e P0.6 e P0.7 funcionar -> 'ligar pinos físicos/metálicos
	RET

END			













//---------------------------------------------------------------------TESTE-----------------------------------------------------------------------------------------------



