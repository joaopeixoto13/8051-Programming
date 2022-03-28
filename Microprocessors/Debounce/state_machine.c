#include "state_machine.h"
#include <REG51F380.H>
#include <stdio.h>

static unsigned char count = 0;

states_t xdata state, next_state;
states_modes_t xdata state_mode, next_state_mode;

volatile unsigned char index = 50;
volatile unsigned char tmp = 127;

unsigned char xdata input_array [27];

unsigned char code waves[3][27] =  {{127,156,184,209,229,244,252,254,249,237,219,197,170,142,112,84,57,35,17,5,0,2,10,25,45,70,98},			// Sine Wave
																		{127,145,163,181,199,217,235,253,235,217,199,181,163,145,127,109,91,73,55,37,19,0,20,39,59,80,105},	// Triangular Wave
																		{0,0,0,0,0,0,0,0,0,0,0,0,0,0,255,255,255,255,255,255,255,255,255,255,255,255,255}};									// Square Wave

// ****************************************************
// **                   IDLE_STATE                   **
// ****************************************************
																			
void idle(void)
{
	PCA0CN &= ~(1<<6);       											// Disable PCA Counter
	TR1 = 0;																			// Stop Debounce
	ET1 = 0;
	P0_0 = 0;
	count = 0;
	printf("Idle!\r\n"); 
}

// ****************************************************
// **              SPEED_CONTROLLER_STATE            **
// ****************************************************

// 1. START_SPEED_MODE

void start_speed(void)
{
	index = 50;
	tmp = 127;
	PCA0CPL0 = 0;
	PCA0CPH0 = tmp;
	PCA0CPL1 = 0xFF;
	PCA0CPH1 = 0x00;
	ET1 = 1;																																														// Enable Timer 1 Interrupt
	TR1 = 1;																																														// debounce enable
	EIE1 &= ~0x10;																																											// Disable PCA Interrupt
	PCA0CN |= 1<<6;																																											// Enable PCA Count
	printf("Speed Conroller Started\r\n");
}

// 2. STATUS_MODE

void status(void)
{
	printf("Duty Cycle = %d\r\n", (int)index);
}

// 3. CHANGE_DUTY_CYCLE

void change_duty_cycle(void)
{
	tmp = index * (255/100);
	PCA0CPH0 = tmp;
}

// 4. INCREMENT 10% DUTY_CYCLE - P0.7

void inc(void)
{
	if (index <= 90)
	{
		index += 10;
		tmp += 25,5;											// Aumentar 10% do brilho 
		PCA0CPH0 = tmp;	
	}
}

// 5. DECREMENT 10% DUTY_CYCLE - P0.6

void dec(void)
{
	if (index >= 10)
	{
		index -= 10;
		tmp -= 25,5 ;											// Diminuir 10% do brilho
		PCA0CPH0 = tmp;	
	}
}

// ****************************************************
// **                   DUMMY_STATE                  **
// ****************************************************

void dummy(void)
{
	printf("Invalid Option!\r\n");
}

// ****************************************************
// **                 SINEWAVE_STATE                 **
// ****************************************************

// Carregar os valores da respetiva onda nos registos

void wave(void)
{
	if (state_mode == MODE_1) {
		PCA0CPL0 = input_array[0];
		PCA0CPH0 = input_array[1];
	} else {
		PCA0CPL0 = waves[state_mode-2][0];
		PCA0CPH0 = waves[state_mode-2][1];
	}
	index	= 2;
	PCA0CPL1  = 0xff;
	PCA0CPH1  = 0x00;
}

// Input Mode

void input(void)
{
	input_array[count++] = index;
	if (count == 27) {
		count = 0;
		wave();
	}
	else
		printf("%dº : ", (int)(count+1));
}

// Start Wave

void start_wave(void)
{
	TR1 = 0;																																								// Debounce Disable
	state_mode = MODE_2;
	wave();
	PCA0CN |= (1<<6);        																																// Enable PCA Counter
	EIE1 |= 0x10;																																						// Enable PCA Interrupt
}


void (*state_process [4][5])(void) = {
		{idle, idle, idle, idle, idle},																												// State Idle
		{start_speed, status, change_duty_cycle, dec, inc},																		// State Speed Controller
		{start_wave, input, wave, wave, wave},																								// State Sinewave 
		{dummy, dummy, dummy, dummy, dummy}																										// State Dummy
};

// ****************************************************
// **                ENCODE_FSM FUNCTION             **
// ****************************************************

void encode_FSM(void) 
{
	state_process[state][state_mode]();
}

// ****************************************************
// **                 PCA_ISR FUNCTION               **
// ****************************************************

void pca_isr(void) interrupt 11 
{
	if (state_mode == MODE_1)
		PCA0CPH0  = input_array[index++];
	else
		PCA0CPH0  = waves[state_mode-2][index++];
	index = index % 27;
	PCA0CPH1++;
	PCA0CN &= ~(1 << 1);
	TF0 = 0;
}


