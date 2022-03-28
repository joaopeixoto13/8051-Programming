#ifndef _CONFIG_PLATFORM_
#define _CONFIG_PLATFORM_

#include <REG51F380.H>

void Oscilator_init(void)
{
	//FLSCL     = 0x90;					// SYSCLK = 48MHz
    //CLKSEL    = 0x03;
	PCA0MD    = 0x00;					// Disable WD Timer
}

void Port_IO_init(void)
{
	P0SKIP    = 0x0F;					// TxD e RxD a P0_4 e P0_5
    XBR1      = 0x40;					// Crossbar enable	
	XBR2      = 0x01;					// UART1 on Crossbar
}

void UART_init(void)
{
	SBRLL1    = 0x30;					// Baudrate a 115200 bps
    SBRLH1    = 0xFF;
    SCON1     = 0x10;					// Enable UART1 reception -> REN1
    SBCON1    = 0x43;
}

void Device_init(void)
{
	Oscilator_init();
	Port_IO_init();
	UART_init();
}

#endif