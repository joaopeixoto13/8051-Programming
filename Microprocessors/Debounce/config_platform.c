#include <REG51F380.H>
#include "config_platform.h"

// ****************************************************
// **              INIT OSCILATOR                    **
// ****************************************************

void Oscilator_Init()
{
	FLSCL = 0x90;											
	CLKSEL = 0x03;							// Oscilador a 48MHz
}

// ****************************************************
// **               	PCA INIT                       **
// ****************************************************


void PCA_init()
{
  PCA0MD    = 0x04;     			// Timer 0 base Time 		
  PCA0CPM0  = 0x42;       		// Module 0 a 8bit PWM
	PCA0CPM1  = 0x49; 					// Module 1 Software Timer + enable CCF flag
}


// ****************************************************
// **               INIT TIMER                       **
// ****************************************************

void Timer_Init()
{
	TMOD = 0x22;				  			// Timer 0 e 1 no modo 2 8bit auto reaload
	
	// Para o controlo do PCA
	TH0 = (-12);					
	TL0 = (-12);				  			// f=50Hz -> -12
	
	// Para o Debounce dos botões
	TH1 = (-250);													
	TL1 = (-250);								// T overflow = 62.5uS
}


// ****************************************************
// **                INIT UART                       **
// ****************************************************

void UART_Init()
{
	SBRLL1 = 0x30;
	SBRLH1 = 0xff;							// BaudRate a 115200 bps
	SCON1 = 0x10;								// Enable UART1 reception -> REN1
	SBCON1 = 0x43;
	EIE2 |= 0x02;								// Enable UART1 Interrupt	
}

// ****************************************************
// **                PORT_IO INIT                    **
// ****************************************************

void Port_IO_init()
{
	P0SKIP = 0x0E;       				// TxD e RxD a P0_4 e P0_5 e PCA a P0_0
  XBR1   = 0x41;				
	XBR2   = 0x01;
	P0_6 = 1;										// Defenir P0_6 como entrada
	P0_7 = 1;										// Definir P0_7 como entrada
	//P0MDOUT   = 0x01;   ->PushPull
}


// ****************************************************
// **              INIT ALL DEVICE                   **
// ****************************************************

void Init_Device()
{
	Oscilator_Init();
	PCA_init();
	Port_IO_init();
	Timer_Init();
	UART_Init();
}
