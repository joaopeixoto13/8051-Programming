#ifndef _CONFIG_PLATFORM_
#define _CONFIG_PLATFORM_

#include <REG51F380.H>


void Oscilator_init(void)
{
	FLSCL     = 0x90;					// SYSCLK = 48MHz
    CLKSEL    = 0x03;
	PCA0MD    = 0x00;					// Disable WD Timer
}


void UART_init(void)
{
	SBRLL1    = 0x30;					// Baudrate a 115200 bps
    SBRLH1    = 0xFF;
    SCON1     = 0x10;					// Enable UART1 reception -> REN1
    SBCON1    = 0x43;
}


void Port_IO_init(void)
{
	P0SKIP    = 0x0F;					// TxD e RxD a P0_4 e P0_5
    XBR1      = 0x40;					// Crossbar enable
    XBR2      = 0x01;					
}

void Timer_init(void)
{
	TMOD = 0x02;						// Timer 0 no modo 8 bits auto-reaload
	
	TH0 = (-250);
	TL0 = (-250);						// T overflow = 62.5uS
}

void Device_init(void)
{
	Oscilator_init();
	Port_IO_init();
	UART_init();
	Timer_init();
}

#endif