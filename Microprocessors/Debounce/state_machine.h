#ifndef STATE_MACHINE_MODULE
#define STATE_MACHINE_MODULE

// ****************************************************
// **                   STATES                       **
// ****************************************************

typedef enum STATES
{	
	IDLE = 0,
	SPEED_CONTROLLER,
	SINEWAVE,
	DUMMY
}states_t;

// ****************************************************
// **                 STATES_MODES                   **
// ****************************************************

typedef enum STATES_MODES
{
	MODE_0 = 0,
	MODE_1,
	MODE_2,
	MODE_3,
	MODE_4
	
} states_modes_t;

extern unsigned char index;
extern unsigned char tmp;

extern states_t xdata state, next_state;
extern states_modes_t xdata state_mode, next_state_mode;    

void encode_FSM(void);


#endif