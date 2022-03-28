#include <REG51F380.H>
#include "timer.h"
code int reload[] = { RELOAD_0, RELOAD_1};
int vtimer[2];
bit pwm;
void idle(void){
}

my_callback call_back[2];

void set_timer_call_back(my_callback p_this, char index, char offset){
	call_back[index & 1] = p_this;
	vtimer[index & 1]  = reload[index & 1] - offset;
}

void timer0_init(void)
{
		call_back[0]= idle;
		call_back[1]= idle;
		TMOD  |= 0x02;
		CKCON |= 0x02;
		TH0 = -250;
		TL0 = -250;
		IE        |= 0x02;
		vtimer[0] = reload[0];
		vtimer[1] = reload[1];
}

void isr_timer(void) interrupt 1
{
	pwm = P0 & 1;
	vtimer[0]++;
	if(vtimer[0] == 0){
		vtimer[0] = reload[0];
		call_back[0]();
	}
	
	vtimer[1]++;
	if(vtimer[1]== 0){
		vtimer[1] = reload[1];
		call_back[1]();
	}
}