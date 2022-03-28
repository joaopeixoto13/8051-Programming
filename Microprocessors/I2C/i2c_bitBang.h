#ifndef _I2C_BITBANG_
#define _I2C_BITBANG_

#include <REG51F380.H>

void i2c_start(void);							 // generates start condition
void i2c_stop(void);							 // generates stop condition
unsigned char i2c_write(unsigned char i2c_data); // writes a byte to the I2C bus
unsigned char i2c_read(unsigned char ack);		 // read a byte from the I2C bus
void read_ack(unsigned char *ack);										
void ack_poll(unsigned char control);

sbit SCLK = P1^0;
sbit SDA  = P1^1;

#define ACK   0x00
#define NACK  0x80
#define DELAY 10

#endif