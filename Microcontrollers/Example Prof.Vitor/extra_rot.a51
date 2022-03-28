#include <REG51F380.H>

EXTRN DATA (DIGIT_ARRAY, CYPHER_KEY, K_INDEX, INDEX, SEC_KEY, DR_LEN, USER_KEY, P_DISP, RELOAD	)
PUBLIC INIT_XRAM, UPDATE_DISP, UPDATE_ARRAY, CYPHER, INCREMENT_ROUTINE, RELOAD_ROUTINE


CSEG AT 1500H
		
		
	INIT_XRAM:
		MOV A, R0
		MOVC A, @A + DPTR
		MOVX @R0, A
		
		INC R0
		
		DJNZ R7, INIT_XRAM
		
		RET
	
;----------------------------	
	UPDATE_DISP:
		MOV DPTR, #DIGIT_ARRAY		
		MOV A, INDEX
		ANL A, #DR_LEN
		MOV INDEX, A
		
		MOVC A, @A+DPTR
		MOV P_DISP, A
		RET
;----------------------------
	UPDATE_ARRAY:
	
		MOV A, #USER_KEY
		ADD A, K_INDEX
		MOV R0, A
		MOV @R0, INDEX
		
		RET		
;----------------------------	
	
	CYPHER:
		
		MOV DPTR, #CYPHER_KEY
		MOV A, K_INDEX
		MOVC A, @A+DPTR
		
		XRL A, R0
		
		MOV R0, A
		
		RET
		
;--------------------------------		
;		INTERRUPT ROUTINES
;--------------------------------	

	INCREMENT_ROUTINE:
		
		MOVX A, @R0
		ADD A, #1
		MOVX @R0, A
		
		INC R0
		
		MOVX A, @R0
		ADDC A, #0
		MOVX @R0, A
		
		INC R0
		
		MOVX A, @R0
		ADDC A, #0
		MOVX @R0, A
		
		RET		
;----------------------------		
		
	RELOAD_ROUTINE:
		
		MOVX A, @R0
		JNZ BYTE2
		MOV A, R0
		MOVC A, @A+DPTR 
		MOVX @R0, A
		
		BYTE2:
		INC R0
		MOVX A, @R0
		JNZ BYTE3
		MOV A, R0
		MOVC A, @A+DPTR  
		MOVX @R0, A
		
		BYTE3:
		INC R0
		MOVX A, @R0
		JNZ END_RELOAD
		MOV A, R0
		MOVC A, @A+DPTR 
		MOVX @R0, A
		
	END_RELOAD:
		RET
		

	END	