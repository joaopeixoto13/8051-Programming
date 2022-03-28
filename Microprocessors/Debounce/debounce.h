#ifndef debounce_module
#define debounce_module

extern data unsigned char c;
extern volatile bit timeout; 

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
// **              COMMANDS FOR BUTTONS              **
// ****************************************************

typedef enum COMMAND
{	
	up,
	down
} cmd_t;

extern xdata cmd_t cmd;

// ****************************************************
// **               FUNCTIONS PROTOTYPE              **
// ****************************************************

void Init_Virtual_Keys(void);
void reload_timer(void);
void update_buttons(void);
void test_buttons(char, char);


#endif