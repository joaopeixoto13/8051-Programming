#ifndef _SERIALIO_
#define _SERIALIO_

#define LEN 32

typedef struct Fifo
{
	unsigned char buffer[LEN];
	unsigned char start;
	unsigned char end;
} fifo_t;

void SerialIO_init(void);
bit try_receive_char(int* cmd);

#endif
