#ifndef _STATE_MACHINE_
#define _STATE_MACHINE_

typedef enum STATES
{
	IDLE = 0,
	MANUAL,
	AUTOMATIC,
	DUMMY_STATE
} states_t;

typedef enum MODES
{
	CONFIG = 0,
	GREEN,
	YELLOW,
	RED
} modes_t;

void encode_FSM(void);

extern states_t xdata state, next_state;
extern modes_t xdata mode, next_mode;

#endif