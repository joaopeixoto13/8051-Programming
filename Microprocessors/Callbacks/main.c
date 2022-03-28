#include <REG51F380.H>
#include "timer.h"

extern void Device_init(void);

void blink_bcd(void)
{
	P2 ^= (1<<3);
}

void update_bcd(void)
{
	P2 ^= (1<<0);
}

void main(void)
{
	char a;
	char b;
	Device_init();
	timer0_init();
	set_timer_call_back(update_bcd, 0, 0);
	set_timer_call_back(blink_bcd, 1, 0);
	
	TR0 = 1;
	EA = 1;
	
	while (1)
	{ }	
}
