#include "serialIO.h"
#include <REG51F380.H>
#define RI1 0
#define TI1 1
#define ES1 1
#define ERROR -1

fifo_t xdata Rx;
fifo_t xdata Tx;
bit TxActive = 0;

void SerialIO_init(void)
{
	Rx.start = 0;
	Rx.end = 0;
	Tx.start = 0;
	Tx.end = 0;
	TxActive = 0;
}

#pragma disable
int _getkey()
{
	if (Rx.start >= Rx.end)
		return ERROR;	
	return (Rx.buffer[Rx.start++ & (LEN-1)]);						
}


void serial_io_isr(void) interrupt 16 using 2
{
	if (SCON1 & (1<<RI1)) 													// RI1 = 1 ?
	{
		if ((Rx.end - Rx.start) < LEN)										// se não estiver cheio
			Rx.buffer[Rx.end++ & (LEN-1)] = SBUF1;							// colocar no buffer de receção o conteúdo de SBUF1
		SCON1 &= ~(1<<RI1);													// limpar flag RI1
	}
	if (SCON1 & (1<<TI1))													// TI1 = 1 ?
	{	
		SCON1 &= ~(1<<TI1);													// limpar flag TI1
		if (Tx.end - Tx.start > 0)											// se não estiver vazio  
			SBUF1 = Tx.buffer[Tx.start++ & (LEN-1)];						// colocar em SBUF1 elemento do buffer de transmissão
		else
			TxActive = 0;													// sendactive = 0 -> não tem nada no buffer para transmitir									
	}
}

char putchar(char c)
{
	while((Tx.end - Tx.start) >= LEN);										// enquanto estiver cheio -> espera até esvaziar 
	if (!TxActive)															// se não tiver nada para transmitir 
	{
		SBUF1 = c;															// coloca em SBUF1 o caractere 
		TxActive = 1;														// flag sendactive = 1
	}
	else
	{
		EA = 0;																// Contexto protegido												
		Tx.buffer[Tx.end++ & (LEN-1)] = c;									// coloca o caractere no buffer de transmissão
		EA = 1;														
	}
	return (c);
}

bit try_receive_char(int* cmd)
{
	*cmd = _getkey();														// guadar cmd por referência
	if (*cmd == ERROR)
		return 0;															// '0' caso foi mal sucedido
	return 1;																// '1' se foir bem sucessido
}
