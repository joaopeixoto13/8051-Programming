#include "i2c_bitBang.h"

void write_ack(unsigned char ack);
void read_ack(unsigned char* ack);
 
void i2c_delay(void)
{
	unsigned int i;
	for (i = 0; i < DELAY; i++);
}

void i2c_start(void)
{
	SCLK = 1;			// ensure SDA e SCKL are high
	SDA  = 1;
	i2c_delay();
	i2c_delay();
	SDA = 0;			// transição descendente de SDA enquanto SCKL = 1
	i2c_delay();
	SCLK = 0;
	i2c_delay();
}

void i2c_stop(void)
{
	SCLK = 0;			// ensure SDA e SCKL are low
	SDA  = 0;
	i2c_delay();
	i2c_delay();
	SCLK = 1;
	i2c_delay();
	SDA = 1;
	i2c_delay();
}

unsigned char i2c_write(unsigned char wdata)
{	
	unsigned char i;						// loop counter
	unsigned char ack = 0;					// ACK bit
	
	SCLK = 0;
	
	for (i = 0; i < 8; i++)
	{
		SDA = (bit)((wdata << i) & 0x80);	// output MSB
		i2c_delay();
		SCLK = 1;							// validate data
		i2c_delay();
		SCLK = 0;
		i2c_delay();
	}
	// for debug purposes, SDA goes low for the ACK receive
	SDA = 0;	
	read_ack(&ack);							// read ACK 
	return ack;								// return ACK 
}


unsigned char i2c_read(unsigned char ack)
{
	unsigned char i;						// loop counter
	unsigned char ret = 0;					// return value
	
	for (i = 0; i < 8; i++)
	{
		ret <<= 1;	// shift left for next bit -> build the word with all 8 bits
		SCLK = 0;
		i2c_delay();
		SCLK = 1;
		i2c_delay();
		ret |= SDA;							// input the receive bit
		SCLK = 0;
		i2c_delay();
	}
	write_ack(ack);
	return ret;
}

void read_ack(unsigned char* ack)
{
	SCLK = 0;
	i2c_delay();
	SCLK = 1;
	i2c_delay();
	i2c_delay();
	i2c_delay();
	*ack |= SDA;					// if successuful -> SDA goes low and ack = 0
	SCLK = 0;
	i2c_delay();
}


void write_ack(unsigned char ack)
{
	SCLK = 0;
	i2c_delay();
	SCLK = 1;
	i2c_delay();
	i2c_delay();
	SDA = (bit)(ack >> 7);				// output the MSB
	i2c_delay();
	SCLK = 0	;
}



