#ifndef __TIMER_MOD__
#define __TIMER_MOD__

#define RELOAD_1 (-2)
#define RELOAD_0 (-4)

typedef void (*my_callback)(void);

extern void timer0_init(void);

extern void set_timer_call_back(my_callback p_this, char index, char offset);

#endif 