#include <REG51F380.H>
#include "device_driver.h"
#define RI1 0
#define TI1 1
#define ES1 1

bit update;
bit sendactive;

// ****************************************************
// **            VARIABLES INITIALIZE                **
// ****************************************************

fifo_t xdata Rx;
fifo_t xdata Tx;


// ****************************************************
// **          DEVICE DRIVER INITIALIZATION          **
// ****************************************************

void device_driver_init()
{																	// inicializar todas as vari�veis do device driver
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
	EIE2 &= ~(1<<ES1);											// disable UART1 interrupt -> c�digo cr�tico
	c = (Rx.buffer[Rx.start++ & (LEN-1)]);	// colocar em c o caracter do buffer
	Rx.len--;																// diminuir tamanho do buffer
	EIE2 |= (1<<ES1);												// rep�r UART1 interrupt
	return c;
}



// ****************************************************
// **        DEVICE DRIVER ISR FUNCTION              **
// ****************************************************

void device_driver_isr() interrupt 16
{
	if (SCON1 & (1<<RI1)) 												// RI1 = 1 ?
	{
		if (Rx.len < LEN)														// se n�o estiver cheio
		{
			Rx.buffer[Rx.end++ & (LEN-1)] = SBUF1;		// colocar no buffer de rece��o o conte�do de SBUF1
			Rx.len++;																	// aumentar tamanho do buffer
		}
		SCON1 &= ~(1<<RI1);													// limpar flag RI1
	}
	if (SCON1 & (1<<TI1))													// TI1 = 1 ?
	{	
		SCON1 &= ~(1<<TI1);													// limpar flag TI1
		if (Tx.len)																	// se n�o estiver vazio  
		{
			SBUF1 = Tx.buffer[Tx.start++ & (LEN-1)];	// colocar em SBUF1 elemento do buffer de transmiss�o
			Tx.len--;																	// diminuir tamanho do buffer
		}
		else
		{
			sendactive = 0;														// sendactive = 0 -> n�o tem nada no buffer para transmitir									
		}
	}
}


// ****************************************************
// **             PUTCHAR() FUNCTION                 **
// ****************************************************

char putchar (char c)
{
	while(Tx.len >= LEN);													// enquanto estiver cheio -> espera at� esvaziar 
	if (!sendactive)															// se n�o tiver nada para transmitir 
	{
		SBUF1 = c;																	// coloca em SBUF1 o caractere 
		sendactive = 1;															// flag sendactive = 1
	}
	else
	{
		EIE2 &= ~(1<<ES1);													// disable UART1 interrupt -> c�digo cr�tico
		Tx.buffer[Tx.end++ & (LEN-1)] = c;							// coloca o caractere no buffer de transmiss�o
		Tx.len++;																		// aumenta o tamanho do buffer de transmiss�o
		EIE2 |= (1<<ES1);														// rep�r UART1 interrupt
	}
	return (c);
}


bit try_receive_message()
{																								//Verifica a existencia de \r e consequentemente uma keyword valida
	bit uart_update = 0;
	char i;
	if(Rx.len >= LEN)															//Se esta cheio de lixo
		device_driver_init();
	for(i = 0; i < Rx.len && uart_update == 0 ; i++)
		uart_update = ~((bit)(Rx.buffer[(Rx.start + i)  & (LEN-1)] ^ 0x0D));    
	return uart_update;
}


void get_keyword(char* keyword)
{
	char i;
	for (i = 0; Rx.buffer[(Rx.start) & (LEN-1)] != '\r'; i++)
		keyword[i] = _getkey();
	_getkey();																		// retirar '\r'					
}
