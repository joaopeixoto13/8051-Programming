#include <REG51F380.H>
#include "i2c_bitBang.h"
#include "eeprom_i2c.h"

extern void Init_Device(void);

void main(void)
{
	unsigned char DADDR = 0x01;
	unsigned char PADDR = 0x00;
	
	char code i2cbyte_w = 0xAA;
	//char code i2cbyte_r = 0x00;
	
	Init_Device();
	
	eeprom_write_byte(DADDR, i2cbyte_w);
}

