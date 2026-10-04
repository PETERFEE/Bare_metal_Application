/*
 * Lab2 part3_prescaler 256 , Section 17b
 * Name: Peter Feng 
 * Class #: 11303
  *PI Name: Grant
  Description: toggle every 50ms, perscaler 256
 *   
 */ 
.include "ATxmega128a1udef.inc"

.cseg
.org 0x0000
    rjmp main

.org 0x0100
main:
; initailze the stack pointer 
    ldi r16, low(RAMEND)
    out CPU_SPL, r16
    ldi r16, high(RAMEND)
    out CPU_SPH, r16

;set bit0 of PORTC to be output 
    ldi r16, 0x01
    sts PORTC_DIR, r16

    ; Load PER (low byte first)
	; PER controls how long before overflow occurs 
	; f_timer = f_cpu/prescaler 
	; f_timer = 2,000,000/256 = 7812.5 Hz
	; Number of timer count = f_timer * T = 7812.5 times/ seconds 
	; for 55ms, timer counts for 7812.5 * 0.055 = 429.6875

    ldi r16, low(33499)
    sts TCC0_PER, r16
    ldi r16, high(33499)
    sts TCC0_PER+1, r16
	; Timer counts from 0 → PER, sets overflow flag (OVF) in INTFLAGS


	;prescaler controls how fast the timer count 
	; Start Timer C0 with prescaler = 256
	; TC_CLKSEL_DIV256_gc is bitmask 0x06       
	; 0b110 → prescaler 25 
    ldi r16, TC_CLKSEL_DIV4_gc
	; CTRLA select prescaler
    sts TCC0_CTRLA, r16

loop:
    lds r16, TCC0_INTFLAGS        ; Load Timer C0 interrupt flags into r16
                                   ; Bit 0 = OVF (overflow flag)
                                   ; Other bits may represent other flags
    sbrc r16, 0                   ; Skip next instruction if bit 0 (OVF) is clear
                                   ; If OVF = 1, the next instruction executes
                                   ; If OVF = 0, skip next instruction and continue loop

    rjmp overflow                  ; Jump to overflow handler if OVF = 1

    rjmp loop                      ; If OVF = 0, stay in loop (poll again)

overflow:
    ldi r17, 0x01                  ; Load bitmask for PC0 (LED pin)
    sts PORTC_OUTTGL, r17          ; Toggle LED on PC0
                                    ; Writing '1' flips the pin; '0' does nothing

      ldi r17, 0x01                  ; Bitmask for OVF flag (bit 0)
    sts TCC0_INTFLAGS, r17         ; Clear overflow flag by writing '1'
                                    ; Necessary to detect next overflow

    rjmp loop                       ; Return to main polling loop

