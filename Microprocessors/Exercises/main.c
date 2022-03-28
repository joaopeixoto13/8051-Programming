#include <REG51F380.H>
#include "serialIO.h"
#define CR 6
#define CCF2 2

unsigned char code init_value = 0xA0;
unsigned char code finish_value = 0xB0;

//                            0      1    2      3
char code display_array[] = {0xC0, 0xF9, 0xA4, 0xB0};

//                          -     500ms    100ms    100ms
int code timer_array[] = {  0   , 57536,   63936,  63936 };


long int code timeout_time = 4292087296;				// 3 minutos

typedef enum STATES
{
	READY = 0,
	WARMUP,
	ON,
	COOL
} states_t;

states_t data state, next_state;
int data vtimer;
long int data vtimer_timeout;

volatile bit update = 0;
volatile bit timeout_3min = 0;

void update_display(void)
{
	P2 = display_array[state & 3];
}

void state_ready(void)
{
	TR0 = 0;
	PCA0CN &= ~(1<<CR);				// Disable PCA Counter
	vtimer_timeout = timeout_time;
	next_state = WARMUP;
	update_display();
}

void state_warmup(void)
{
	TR0 = 1;
	next_state = ON;	
	PCA0CPH0 = 180;					// Duty Cycle de 30%
	PCA0CN |= (1<<CR);				// Enable PCA Counter
	update_display();
}

void state_on(void)
{
	TR0 = 1;
	next_state = COOL;
	PCA0CPL0 = 51;					// Duty Cycle de 80%
	PCA0CN |= (1<<CR);				// Enable PCA Counter
	update_display();
}

void read_temperature_sensor(void)
{
	static bit read_once = 0;
	if (P1 >= 80) {				 			//Temperature no porto P1
		read_once = 1;
		PCA0CPH1 = 77;						// Duty Cycle de 70%
	}
	else if (P1 <= 45 && read_once) {
		read_once = 0;
		PCA0CPH1 = 180;						// Duty Cycle de 30%
		next_state = ON;
		update = 1;
	}
}

void state_cool(void)
{
	read_temperature_sensor();
	update_display();
}

void (*state_process[])(void) = {
	state_ready, state_warmup, state_on, state_cool
};
void encode_FSM(void)
{
	state_process[state]();
}

void Device_config(void)
{
	FLSCL     = 0x90;					// SYSCLK = 48MHz
    CLKSEL    = 0x03;				
	
	PCA0MD    = 0x04;					// Timebase Timer 0 overflow -> necessário para frequency output mode
	PCA0CPM0  = 0x42;					// Module 0 8bit PWM -> Laser
	PCA0CPM1  = 0x42;					// Module 1 8bit PWM -> Ventoinha
	
	P0SKIP    = 0xFF;					
    P1SKIP    = 0xFF;
	P2SKIP    = 0xFE;					// PCA in P2_7
	
    XBR1      = 0x41;					// Crossbar enable
}

void encode_timer(void)
{
	vtimer = timer_array[state];
}

void timer0_isr(void) interrupt 1 using 2
{
	vtimer++;
	update = ~((bit)vtimer);
	
	vtimer_timeout++;
	timeout_3min = ~((bit)vtimer_timeout);
}

void pca_isr(void) interrupt 11 using 3
{
	PCA0L = 0;								// for new iterations
	PCA0CN &= ~(1<<CCF2);					// clear CCF2 flag
}

void main(void)
{
	int cmd;
	char a = 0x08;
	a = a >> 8;
	Device_config();
	SerialIO_init();
	state = next_state = READY;
	update = 1;
	EIE2 = 0x02;					// Enable UART1 Interrupt
	ET0 = 1;						// Enable Timer 0 Interrupt
	EA = 1;							// Enable All Interrupts
	
	while(1)
	{
		if (try_receive_char(&cmd))
		{
			if ((char)cmd == 0xA0 && state == READY)
				update = 1;
			else if ((char)cmd == 0xB0) {
				next_state = READY;
				update = 1;
			}
		}
		if (timeout_3min)
			// Gerar onda Quadrada com Módulo PCA Frequency Output
		
		if (update)
		{
			EA = 0;
			state = next_state & 3;
			encode_timer();
			encode_FSM();
			update = 0;
			EA = 1;
		}
	}
}
