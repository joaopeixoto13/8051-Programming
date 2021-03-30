#include <REG51F380.H>
#include <stdio.h>
#include "debouce.h"
#include "device_driver.h"
#define PDISP P2

// ****************************************************
// **             VARIABLES DECLARATION              **
// ****************************************************

data unsigned char c;

code char mask = 15;

code char array_digit[] = {0xc0,0xf9,0xa4,0xb0,0x99,0x92,0x82,0xf8,0x80,0x90,0x88,0x83,0xc6,0xa1,0x86,0x8e};

char index = 0;
bit update_set = 0;
bit update_load = 0;
volatile bit timeout = 0;


// ****************************************************
// **             PROTOYPE OF FUNCTIONS              **
// ****************************************************

extern void Init_Device(void);
void Init_Virtual_Keys(void);
void reload_timer(void);
void update_buttons(void);
void test_buttons(char, char);
void update_display(void);


// ****************************************************
// **                 MAIN FUNCTION                  **
// ****************************************************

void main()
{
	Init_Device();
	Init_Virtual_Keys();
	device_driver_init();			
	P0_6 = 1;								// Defenir P0_6 como entrada
	P0_7 = 1;								// Definir P0_7 como entrada
	PDISP = 0xC0;							// Display com '0'
	TR0 = 1;								// Timer 0 a contar
	EIE2 |= 0x02;							// Enable UART1 Interrupt			
	ET0 = 1;								// Enable Timer 0 Interrupt
	EA = 1;									// Enable geral Interrupt
	//SCON1 |= 0x02;
	reload_timer();
	
	while (1)
	{
		if (timeout)						// 15ms para testar botões
		{
			EA = 0;							// Prevenir
			test_buttons(P0_7 ,P0_6);		// testar botões P0.6 e P0.7
			reload_timer();					// reload do timer
			timeout = 0;					// limpar flag
			EA = 1;							// Restaurar Interrupts
		}
		if (update)							// se update = 1					
		{
			if (uart_update)				// se recebeu algum caractere vir UART
			{
				c = _getkey();				// getkey() desse caractere
				uart_update = 0;			// limpar flag
			}
			switch (c)
			{
				case 'i':
				case 'I':
					index++;
					break;
				case 'd':
				case 'D':
					index--;
					break;
				case 'r':
				case 'R':
					index = 0;
				break;
				default:
					break;
			}
			update = 0;
			update_display();				// update do display
		}
	}		
}



void Init_Virtual_Keys()
{
	p_set.key_window.integer16 = 0x00ff;	// 00000000 11111111
	p_set.count_ones = 8;
	p_load.key_window.integer16 = 0x00ff;	// 00000000 11111111
	p_load.count_ones = 8;
}



void reload_timer()
{		
	vtime.byte[0] = 0xff;
	vtime.byte[1] = 0x10;					// 15ms . 240 contagens - 15ms / 62.5uS
}



void update_buttons() interrupt 1 using 2
{
	vtime.integer16 += 1;					// Timer Virtual
	timeout = ~((bit)vtime.byte[0]);
	TF0 = 0;		
}



void test_buttons(char pin_set, char pin_load)
{
	// ********** TEST P0_7 **********
	
	char result;
	static bit old_set = 1;		
	static bit old_load = 1;	
	
	p_set.key_window.integer16 <<= 1;								// shiftar janela uma vez ? esquerda
	p_set.key_window.byte[1] |= pin_set;							// se pin == 0 . entra um zero na janela *bit da direita*
	p_set.count_ones += pin_set;									// se entra um 0 . count_ones igual / se entra um 1 . count_ones++
	
	result = 4 - p_set.count_ones;									// fazer a conta com valor atual . 9 bits
	
	//   byte0    byte1
	// 00000000 11111111
	// 00000001 11111110		shift ? esquerda - entra 0
	// 00000000 11111110		limpar byte 0
	// 00000001 11111100    . sai 1 , entra 0
	
	p_set.count_ones -= p_set.key_window.byte[0];					// byte 0 armazena bit que sai da janela
	
	p_set.key_window.byte[0] = 0;					          		// limpar byte 0, para pr?xima itera??o guardar o pr?ximo valor que sai
	pin_set = result & (1<<7);									    // result = bit de sinal
																	// se pin == 1 . count_ones > 4  . TECLA N?O PREMIDA !
																	// se pin == 0 . count_ones <= 4 . TECLA PREMIDA !
		
	update_set = ~((bit)pin_set);									// update = 1 se pin = 0 *TECLA PREMIDA*
	
	if (update_set && old_set)
	{
		old_set = 0;
		update = 1;
		c = 'i';		//incrementar
	}
	else if (!update_set)
		old_set = 1;


	// ********** TEST P0_6 **********
	
	p_load.key_window.integer16 <<= 1;			
	p_load.key_window.byte[1] |= pin_load;				
	p_load.count_ones += pin_load;								
	
	result = 4 - p_load.count_ones;				
	
	p_load.count_ones -= p_load.key_window.byte[0];		
	
	p_load.key_window.byte[0] = 0;				
	pin_load = result & (1<<7);									
		
	update_load = ~((bit)pin_load);		

	if (update_load && old_load)
	{
		old_load = 0;
		update = 1;
		c = 'd';		// decrementar
	}
	else if (!update_load)
		old_load = 1;
	
}



void update_display()
{
	PDISP = array_digit[index & mask];
	printf("Index = %d\r\n", (int)(index & mask));
}