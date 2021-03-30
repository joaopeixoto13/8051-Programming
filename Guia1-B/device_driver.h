#ifndef device_driver_module
#define device_driver_module

#define LEN 32

extern bit update;
extern bit uart_update;


// ****************************************************
// **        FIFO STRUCT FOR COMMUNICATION           **
// ****************************************************

typedef struct Fifo
{
    unsigned char buffer[LEN];
    unsigned char start;
    unsigned char end;
    unsigned char len;
} fifo_t;


// ****************************************************
// **            PROTOYPE OF FUNCTIONS               **
// ****************************************************

void device_driver_init(void);
char _getkey(void);


#endif
