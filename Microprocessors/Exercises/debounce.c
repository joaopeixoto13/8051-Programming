#include "debounce.h"
#include <REG51F380.H>

virt_key_t xdata p_set;

void Virtual_Keys_init(void)
{
	p_set.key_window.integer16 = 0x00FF;		// 00000000 11111111
	p_set.count_ones = 8;
}


bit test_buttons(char pin)
{
	// ********** TEST P0_7 **********
	char result;
	static bit old_event = 1;
	char update;
	
	p_set.key_window.integer16 <<= 1;
	p_set.key_window.byte[1] |= pin;
	p_set.count_ones += (char)pin;
	
	result = 4 - p_set.count_ones;
	p_set.count_ones -= p_set.key_window.byte[0];
	p_set.key_window.byte[0] = 0;
	
	result &= (1<<7);
	
	update = !result && old_event;			// result a 0 *tecla premida* 
											// e old_event a 1 -> transição descendente
	old_event = result;
	
	return (bit)update;
}




