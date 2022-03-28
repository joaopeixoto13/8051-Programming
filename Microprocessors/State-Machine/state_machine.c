#include "state_machine.h"
#include "serialIO.h"
#include <stdio.h>
#include <REG51F380.H>

states_t xdata state, next_state;
modes_t xdata mode, next_mode;


char code array_display[] = {0xC0, 0xF9, 0xA4, 0xB0};

void update_display(void)
{
	P2 = array_display[mode];
}

void idle(void)
{
	TR0 = 0;										
	update_display();
	printf("Idle State!\r\n");
}

void config_manual(void)
{
	TR0 = 1;
	next_mode = GREEN;
	printf("Manual Mode active!\r\n");
}

void config_automatic(void)
{		
	TR0 = 1;
	next_mode = GREEN;	
	printf("Automatic Mode active!\r\n");
}

void green(void)
{
	next_mode = YELLOW;
	update_display();
}

void yellow(void)
{
	next_mode = RED;
	update_display();
}

void red(void)
{
	next_mode = GREEN;
	update_display();
}

void dummy(void)
{
	next_state = IDLE;
	next_mode = CONFIG;
	printf("Invalid Option!\r\n");
}

void (*state_process[4][4])(void) = {
	{idle ,            idle,  idle,   idle},
	{config_manual,    green, yellow, red},
	{config_automatic, green, yellow, red},
	{dummy,            dummy, dummy,  dummy}
};

void encode_FSM(void)
{
	state_process[state][mode]();
}

