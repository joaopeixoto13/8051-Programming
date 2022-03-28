#include <REG51F380.H>
#include "config_platform.h"
#include "debounce.h"
#include "device_driver.h"
#include "state_machine.h"
#define PDISP P2
#define CRF1 1
#define is_digit(i) (i >= 48 && i <= 57)

// ****************************************************
// **             VARIABLES DECLARATION              **
// ****************************************************

code char mask = 15;
char data keyword[32];

code char display[4][5] = {
	{0xAF, 0xAF, 0xAF, 0xAF, 0xAF},		// 'r'
	{0xC0, 0xF9, 0xA4, 0xB0, 0x99},		// '0' , '1' , '2' , '3', '4'
	{0x92, 0x82, 0xF8, 0x80, 0x90},		// '5',  '6' , '7' , '8', '9'
	{0xA1, 0xA1, 0xA1, 0xA1, 0xA1}		// 'd'
};
																									 

// ****************************************************
// **              FUNCTIONS PROTOYPE                **
// ****************************************************

void clear_keyword(void);
int mystrcmp(const char*, const char*);
void test_keyword(void);
void test_output_buttons(void);
void update_display(void);

// ****************************************************
// **                 MAIN FUNCTION                  **
// ****************************************************

void main()
{
	Init_Device();
	Init_Virtual_Keys();
	device_driver_init();	
	reload_timer();
	clear_keyword();
	timeout = 0;
	update = 0;
	state = next_state = IDLE;
	state_mode = next_state_mode = MODE_0;
	update_display();
	TR0 = 1;																							// Timer 0 a contar	
	EA = 1;																								// Enable geral Interrupt																																	
	
	while (1)
	{
		if (timeout)																				// 15ms para testar botoes
		{
			EA = 0;																						// Contexto Protegido
			test_buttons(P0_7 ,P0_6);													// testar botoes P0.6 e P0.7
			test_output_buttons();														// testa o output dos botões
			reload_timer();																		// reload do timer
			timeout = 0;																			// limpar flag
			EA = 1;																						// Restaurar Interrupts
		}
		if (try_receive_message())													// testa se chegou alguma mensagem															
		{
				get_keyword(keyword);														// obtem a mensagem recebida
				test_keyword();																	// testa a mensagem obtida
				clear_keyword();																// limpa a keyword
		}
		if (update)																					// se update = 1					
		{
				state = next_state;															// atualiza o estado atual
				state_mode = next_state_mode;										// atualiza o modo atual
				update_display();																// update no Display consoante o estado atual
				encode_FSM();																		// state machine
				update = 0;																			// limpar flag
		}
	}		
}

int mystrcmp(const char* s1, const char* s2)
{
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}


void test_keyword()
{
	update = 1;
	
	// ******************************  STATES MESSAGE **********************************
	
	if (!mystrcmp(keyword, "speed controller")) {																												// speed controller message																																												
		next_state = SPEED_CONTROLLER;
		next_state_mode = MODE_0;																																									
	}
	else if (!mystrcmp(keyword, "sinewave")) {																													// sinewave message
		next_state = SINEWAVE;
		next_state_mode = MODE_0;																																						
	}
	else if (!mystrcmp(keyword, "stop"))																																// stop message
		next_state = IDLE;
	
	// ************************** SPEED CONTROLLER MESSAGE *********************************
	
	else if (!mystrcmp(keyword, "status") && state == SPEED_CONTROLLER)																	// status message
		next_state_mode = MODE_1;
	else if (keyword[0]=='d' && state == SPEED_CONTROLLER) {																						// dxxx message -> change duty cycle
		if (is_digit(keyword[1]) && is_digit(keyword[2]) && is_digit(keyword[3])) {	
			index = ((keyword[1] - 48) * 100 + (keyword[2] - 48) * 10 + (keyword[3] - 48)) % 101;
			next_state_mode = MODE_2; }
		else
			next_state = DUMMY;
	}
	
	// ***************************** SINEWAVE MESSAGE **************************************
	
	else if (!mystrcmp(keyword, "sine") && state == SINEWAVE)																						// Sinewave 
		next_state_mode = MODE_2; 
	else if (!mystrcmp(keyword, "triangular") && state == SINEWAVE)																			// Triangular Wave
		next_state_mode = MODE_3;
	else if (!mystrcmp(keyword, "square") && state == SINEWAVE)																					// Square Wave
		next_state_mode = MODE_4;
	else if (keyword[0]=='w' && state == SINEWAVE) {																										// wxxx message -> input coef wave
		if (is_digit(keyword[1]) && is_digit(keyword[2]) && is_digit(keyword[3])) {
			index = ((keyword[1] - 48) * 100 + (keyword[2] - 48) * 10 + (keyword[3] - 48)) % 256;
			next_state_mode = MODE_1; }
		else
			next_state = DUMMY;
	}
	else
		next_state = DUMMY;
}


void clear_keyword()
{
	unsigned char aux = index;
	char i;
	for (i = 0; i < 32; i++)
		keyword[i] = 0;
	index = aux;
}

void test_output_buttons(void)
{
	if (cmd == up && state == SPEED_CONTROLLER) 
		next_state_mode = MODE_4;		
	else if (cmd == down && state == SPEED_CONTROLLER) 
		next_state_mode = MODE_3;
}

void update_display(void)
{
	PDISP = display[state][state_mode];
}