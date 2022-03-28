#include <REG51F380.H>
#include "debounce.h"
#include "serialIO.h"
#include "state_machine.h"

					
int code timer_array[4][4] = {{0xFFFF, 0xFFFF, 0xFFFF ,0xFFFF},		// Idle State
							  {0xFF10, 0xFF10, 0xFF10, 0xFF10},		// Manual State     -> 15ms for buttons debounce
                              {0xFFFF, 0x8300, 0x4480 ,0x0600},		// Automatic State  -> 2s / 3s / 4s
							  {0xFFFF, 0xFFFF, 0xFFFF ,0xFFFF}};	// Dummy State
							  
volatile char update[4];
							  
byte_int_t xdata vtime;

extern void Device_init(void);
void test_command(int cmd);
void encode_timer(void);

void main(void)
{
	int cmd;
	Device_init();
	Virtual_Keys_init();
	SerialIO_init();
	P0_6 = 1;
	P0_7 = 1;
	P2 = 0xC0;
	state = next_state = IDLE;
	mode = next_mode = CONFIG;
	update[AUTOMATIC] = 1;
	update[MANUAL] = 0;	
	ET0 = 1;
	EIE2 |= 0x02;
	TR0 = 0;											
	EA = 1;
	
	while (1)
	{
		if (update[MANUAL])									// 15ms for debounce
		{
			EA = 0;
			update[AUTOMATIC] = test_buttons(P0_7);			// update = 1 se tecla P0_7 foi premida
			encode_timer();									// necessário para dar reload do timer
			update[MANUAL] = 0;								// limpar flag
			EA = 1;
		}
		if (try_receive_char(&cmd))							// se recebeu um comando / char com sucesso
		{
			test_command(cmd);								
		}
		if (update[AUTOMATIC])														
		{
			state = next_state;
			mode = next_mode;
			encode_timer();
			encode_FSM();
			update[AUTOMATIC] = 0;							// limpar flag 
		}
	}
}

void test_command(int cmd)
{
	if (cmd == 'i')
		next_state = IDLE;
	else if (cmd == 'm')
		next_state = MANUAL;
	else if (cmd == 'a')
		next_state = AUTOMATIC;
	else
		next_state = DUMMY_STATE;
	next_mode = CONFIG;
	update[AUTOMATIC] = 1;
}


void timer0_isr() interrupt 1 using 2
{
	vtime.integer16++;
	update[state] = ~((bit)vtime.integer16);		
	TF0 = 0;
}

#pragma disable
void encode_timer(void)
{
	vtime.integer16 = timer_array[state][mode];
}
