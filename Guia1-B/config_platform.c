#include <REG51F380.H>

// ****************************************************
// **              INIT OSCILATOR                    **
// ****************************************************

void Oscilator_Init()
{
	PCA0MD = 0;
	FLSCL = 0x90;
	CLKSEL = 0x03;	
}


// ****************************************************
// **               INIT TIMER                       **
// ****************************************************

void Timer_Init()
{
	TMOD = 0x02;				  	// Timer 0 no modo 2
	TH0 = (-250);				
	TL0 = (-250);				  	// T overflow = 62.5uS
}


// ****************************************************
// **                INIT UART                       **
// ****************************************************

void UART_Init()
{
	P0SKIP = 0x0f;					// skip dos pinos UART1 para TxD P0.4 e RxD P0.5
	XBR1 = 0x40;					// enable Crossbar
	XBR2 = 0x01;
	SBRLL1 = 0x30;
	SBRLH1 = 0xff;
	SCON1 = 0x10;					// Enable UART1 reception -> REN1
	SBCON1 = 0x43;
}


// ****************************************************
// **              INIT ALL DEVICE                   **
// ****************************************************

void Init_Device()
{
	Oscilator_Init();
	Timer_Init();
	UART_Init();
}

