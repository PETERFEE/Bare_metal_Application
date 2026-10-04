;
; Prep_L1.asm
;
; Created: 9/14/2025 11:36:26 PM
; Author : fengh
;
.equ NULL = 0

.include "ATxmega128a1udef.inc"
; Replace with your application code
.cseg // start of memory
.org 0xDADD

in_ta:
	.db 0x21, 0xB4, 0x34,0x38, 0xDA, 0xE4, 0xB8, 0x47, 0x6E, 0x76, 0x2E, 0xD0, 0xCC, 0x32, 0x7D
	.db NULL
	
in_ta_end: 


.dseg 
.org 0x3744

out_ta: 
	 .byte (in_ta_end - in_ta)
out_ta_end:


.cseg 
.org 0x0
	rjmp main

.org 0x100
main: 
	
	ldi r16, byte3(in_ta*2)
	out CPU_RAMPZ, r16
	ldi ZH, byte2(in_ta*2) 
	ldi ZL, low(in_ta*2)
	
	ldi YH, high(out_ta)
	ldi YL, low(out_ta)
	
	
Loop: 
	ELPM r17, Z+
	
	cpi r17, NULL
	breq exit
	; if bit 7 in r16 is not set i'll skip the next insturction
	sbrc r17, 7
	rjmp BIT7_set
	rjmp BIT7_not_set

	

BIT7_not_set: 
	; multiply by 2
	lsl r17
	cpi r17, 111
	BRLO Less_than111
	rjmp Loop 

Less_than111: 
	subi r17, -12
	st Y+, r17
	rjmp Loop

BIT7_set:
	lsr r17
	cpi r17, 70 
	brge greater_70
	rjmp Loop


greater_70:
	subi r17, -7
	st Y+, r17 
	rjmp Loop

	   
rjmp Loop




exit:
rjmp exit
	

	
	
