#ifndef _DEBOUNCE_
#define _DEBOUNCE_

typedef union break_integer
{
	int integer16;
	char byte[2];
} byte_int_t;

typedef struct virt_key
{
	byte_int_t key_window;
	unsigned char count_ones;
	char key_now;
} virt_key_t;

void Virtual_Keys_init(void);
bit test_buttons(char);

#endif