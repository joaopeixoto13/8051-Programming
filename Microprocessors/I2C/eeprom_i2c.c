#include "eeprom_i2c.h"
#include "i2c_bitBang.h"

unsigned char eeprom_write_byte(unsigned char addr, unsigned char wdata)
{
	i2c_start();						// generates a start condition		
	if (!i2c_write(EEPROM_WRITE))		// send ADDR + WRITE command
	{
		if (!i2c_write(addr & 0xff))	// specify the memory address that we gonna write  ! MEMORY SPECIF!
		{
			if (!i2c_write(wdata))		// write the byte 
			{
				i2c_stop();				// generate the stop condition
				return 1;				// successuful
			}
		}
	}
	i2c_stop();							// generate the stop condition
	return 0;							// failed
}


unsigned char eeprom_read_byte(unsigned char addr)
{
	unsigned char rdata;				// read data 
	
	i2c_start();						// generate start condition
	
	if (!i2c_write(EEPROM_WRITE))		// send ADDR + WRITE command 
	{
		if (!i2c_write(addr & 0xFF))	// specify the memory address that we gonna read ! MEMORY SPECIF!
		{
			i2c_start();				// generate restart/other start condition - now, we gonna read
			if (!i2c_write(EEPROM_READ)) // send READ command
			{	
				rdata = i2c_read(NACK);	// read data from buffer !!! AVISAR O SLAVE PARA PARAR DE TRANMITIR DADOS - NACK !!!
				i2c_stop();				// stop condition        !!! DEPOIS DO AVISO PARA NÃO HAVER CONFLITOS DE TRANSMISSOES !!!
				return rdata;			// return data form I2C buffer
			}
		}
	}
	i2c_stop();							// stop condition
	return 0;							// failed
}