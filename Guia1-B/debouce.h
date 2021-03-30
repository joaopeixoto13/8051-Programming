#ifndef debounce_module
#define debounce_module

// ****************************************************
// **           UNION TO BREAK INTEGERS16            **
// ****************************************************

typedef union break_integer
{
    int integer16;
    char byte[2];
} byte_int_t;


// ****************************************************
// **   STRUCT FOR VIRTUAL_KEYS (SOFTWARE DEBOUCE)   **
// ****************************************************

typedef struct virt_key
{
    byte_int_t key_window;
    char count_ones;
    char key_now;
} virt_key_t;


// ****************************************************
// **            VARIABLES INITIALIZE                **
// ****************************************************

byte_int_t idata vtime;
virt_key_t idata p_set;
virt_key_t idata p_load;

#endif