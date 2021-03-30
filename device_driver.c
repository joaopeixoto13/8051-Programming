#include <REG51F380.H>
#include "device_driver.h"
#define RI1 0
#define TI1 1
#define MASK 31
#define ES1 1

bit update;
bit uart_update;
bit sendactive;


// ****************************************************
// **            VARIABLES INITIALIZE                **
// ****************************************************

fifo_t idata Rx;
fifo_t idata Tx;


// ****************************************************
// **          DEVICE DRIVER INITIALIZATION          **
// ****************************************************

void device_driver_init()
{											// inicializar todas as variáveis do device driver
	Rx.start = 0;
	Rx.end = 0;
	Tx.start = 0;
	Tx.end = 0;
	Rx.len = 0;
	Tx.len = 0;
	sendactive = 0;
}


// ****************************************************
// **              GETKEY() FUNCTION                 **
// ****************************************************

char _getkey()
{
	char c;
	EIE2 &= ~(1<<ES1);						// disable UART1 interrupt -> código crítico
	c = (Rx.buffer[Rx.start++ & MASK]);		// colocar em c o caracter do buffer
	Rx.len--;								// diminuir tamanho do buffer
	EIE2 |= (1<<ES1);						// repôr UART1 interrupt
	return c;
}



// ****************************************************
// **        DEVICE DRIVER ISR FUNCTION              **
// ****************************************************

void device_driver_isr() interrupt 16
{
	if (SCON1 & (1<<RI1)) 									// RI1 = 1 ?
	{
		if (Rx.len < LEN)									// se não estiver cheio
		{
			Rx.buffer[Rx.end++ & MASK] = SBUF1;				// colocar no buffer de receção o conteúdo de SBUF1
			Rx.len++;										// aumentar tamanho do buffer
			uart_update = 1;								// flag de leitura ativa
		}
		SCON1 &= ~(1<<RI1);									// limpar flag RI1
		update = 1;
	}
	if (SCON1 & (1<<TI1))									// TI1 = 1 ?
	{	
		SCON1 &= ~(1<<TI1);									// limpar flag TI1
		if (Tx.len)											// se não estiver vazio  
		{
			SBUF1 = Tx.buffer[Tx.start++ & MASK];			// colocar em SBUF1 elemento do buffer de transmissão
			Tx.len--;										// diminuir tamanho do buffer
		}
		else
		{
			sendactive = 0;									// sendactive = 0 -> não tem nada no buffer para transmitir									
		}
	}
}


// ****************************************************
// **             PUTCHAR() FUNCTION                 **
// ****************************************************

char putchar (char c)
{
	while(Tx.len >= LEN);								// enquanto estiver cheio -> espera até esvaziar 
	if (!sendactive)									// se não tiver nada para transmitir 
	{
		SBUF1 = c;										// coloca em SBUF1 o caractere 
		sendactive = 1;									// flag sendactive = 1
	}
	else
	{
		EIE2 &= ~(1<<ES1);								// disable UART1 interrupt -> código crótico
		Tx.buffer[Tx.end++ & MASK] = c;					// coloca o caractere no buffer de transmissão
		Tx.len++;										// aumenta o tamanho do buffer de transmissão
		EIE2 |= (1<<ES1);								// repôr UART1 interrupt
	}
	return (c);
}


