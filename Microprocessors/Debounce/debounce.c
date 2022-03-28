#include "debounce.h"
#include "device_driver.h"
#include <REG51F380.H>

// ****************************************************
// **            VARIABLES INITIALIZE                **
// ****************************************************

unsigned char data c;
xdata cmd_t cmd;
bit timeout;
bit update_set = 0;
bit update_load = 0;

byte_int_t xdata vtime;
virt_key_t xdata p_set;
virt_key_t xdata p_load;


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
	vtime.byte[1] = 0x10;									// 15ms . 240 contagens - 15ms / 62.5uS
}


void update_buttons() interrupt 3 using 2
{
	vtime.integer16 += 1;									// Timer Virtual
	timeout = ~((bit)vtime.byte[0]);
	TF1 = 0;		
}


void test_buttons(char pin_set, char pin_load)
{
	// ********** TEST P0_7 **********
	
	char result;
	static bit old_set = 1;		
	static bit old_load = 1;	
	
	p_set.key_window.integer16 <<= 1;									
	p_set.key_window.byte[1] |= pin_set;							
	p_set.count_ones += pin_set;											
	
	result = 4 - p_set.count_ones;										
	
	p_set.count_ones -= p_set.key_window.byte[0];					
	
	p_set.key_window.byte[0] = 0;					          			
	pin_set = result & (1<<7);									    																																																									
		
	update_set = ~((bit)pin_set);													
	
	if (update_set && old_set)
	{
		old_set = 0;
		update = 1;
		cmd = up;									//incrementar
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
		cmd = down;		// decrementar
	}
	else if (!update_load)
		old_load = 1;
}