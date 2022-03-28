#ifndef _EEPROM_I2C_
#define _EEPROM_I2C_

unsigned char eeprom_write_byte(unsigned char addr, unsigned char wdata);
unsigned char eeprom_read_byte(unsigned int addr);

#define EEPROM_WRITE 0xA0				// slave ADDRESS + WRITE instruction
#define EEPROM_READ  0xA1				// slave ADDRESS + READ  instruction

#endif