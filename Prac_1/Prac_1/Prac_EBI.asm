
.include "ATxmega128A1Udef.inc"

;INITIALIZATIONS
 ;.equ SRAM_START_ADDR = 0xA68000
 .equ IO_START_ADDR = 0xC000
 

 .org 0x0000
	rjmp MAIN

.org 0x0100
MAIN:
    ; Initialize the stack pointer
    ldi     r16, high(RAMEND)
    sts     CPU_SPH, r16
    ldi     r16, low(RAMEND)
    sts     CPU_SPL, r16

	clr r20

    ; Initialize the EBI I/O pins and the EBI system
	rcall GPIO_INIT
	rcall TIMER_INIT
    rcall   EBI_IO_INIT
    rcall   EBI_INIT
	

	sei
	; To access memory above 0xFFFF, we must use the
    ; Z-pointer along with the RAMPZ register.

    ; 1. Set up the Z-pointer and RAMPZ to point to our I/O address.
    ldi     ZL, Low(IO_START_ADDR)      ; Load low byte of address
    ldi     ZH, high(IO_START_ADDR)      ; Load high byte of address
    ldi     r16, byte3(IO_START_ADDR)      ; Load extended byte of address
    sts     CPU_RAMPZ, r16                  ; Store it in RAMPZ


MAIN_LOOP:
	lds r16, PORTA_IN

	sbrc r16, 7
	rjmp PA7_is_high

	PA7_is_low:
	ldi r16, 0xFF
	eor r20, r16 

	sts IO_START_ADDR, r20

	rcall DELAY_67MS
	rjmp MAIN_LOOP

	PA7_is_high:
	clr r16
	sts IO_START_ADDR, r16
	rjmp MAIN_LOOP


    ; 2. Read from the external input port (switches).
    ; The 'ld' instruction triggers an EBI read cycle. 
   ; ld    r17, Z       ; Read Z-pointer address into r17
	

    ; 3. Write to the external output port (LEDs).
    ;    The 'st' instruction triggers an EBI wriqte cycle. 
    ;st    Z, r17         ; Write from r17 to Z-pointer address

    ; 4. Repeat the process indefinitely.
;    rjmp    MAIN_LOOP


EBI_IO_INIT: 	
  ; Preserve the relevant register.
  push r16  
  
  ; Initialize the relevant EBI control signals to be 
  ; in a `false` state.
  ;	ALE1 is false (L) by default.
  ; Set active-low EBI signals to false (H) 1s, RE(L) and CS0(L)
  ldi r16, 0b01010011	
  sts PORTH_OUTSET, r16
  
  ; set ALE1 to be 0 which is false 
  ldi r16, 0b00000100
  sts PORTH_OUTCLR, r16

  ; Initialize the EBI control signals to be output from 
  ; the microcontroller.
  ; we using /cs2 , /cs0, ALE1, /RE, /WE so set them to 1
  ; /CS3 = 0, /cs2 = 1, /cs1 = 0, /cs0 = 1 , ph3 = 0 , ALE1 = 1, /RE = 1, /WE = 1
  ldi r16, 0b01010111
  sts PORTH_DIRSET , r16   

  ; Initialize the address signals to be output
  ; from the microcontroller.
  ldi r16, 0xFF        
  sts PORTK_DIRSET, r16 

  ; Recover the relevant register.
  pop r16

   ; Return from subroutine.
  ret

EBI_INIT: 
  push r16     
  ; Initialize the EBI system for SRAM 3-PORT ALE1 mode.
  ; Initialize EBI_CTRL for 3-port (H, J, K) (IFMODE), ALE1 (SRMODE)
  ; Instead of BIT0, can also use EBI_IFMODE_3PORT_gc | EBI_SRMODE_ALE1_gc 
  
  ldi r16, 0b00000001  
  sts EBI_CTRL, r16
  ; Configure chip select CS2
  ; this is just : 0b00001101 
  ; bit 6:2 , 2k is 0 0011 
  ; bit 1:0 , SRAM is 01
  ldi r16, 0b00001101
	sts EBI_CS2_CTRLA, r16  

   ldi r16, byte2(IO_START_ADDR) 
   sts EBI_CS2_BASEADDR, r16   

	ldi r16, byte3(IO_START_ADDR)     
	sts EBI_CS2_BASEADDR+1, r16 
  
	   ; Recover the relevant register.
  pop r16  

   ; Return from subroutine.
  ret

GPIO_INIT:
; set as in put 
	ldi r16, 0b10000000
	sts PORTA_DIRCLR, r16
	ret


TIMER_INIT:
	; Load Timer Period Register (PER) for 67 ms with prescaler = 4
  

    ldi r16, low(33499)       ; Load low byte of PER
    sts TCC0_PER, r16         ; Store low byte into TCC0 PER
    ldi r16, high(33499)      ; Load high byte of PER
    sts TCC0_PER+1, r16       ; Store high byte into TCC0 PER
    ; Timer counts from 0 → PER, sets overflow flag (OVF) in INTFLAGS


DELAY_67ms:
	;Start Timer C0 with prescaler 
    ; TC_CLKSEL_DIV8_gc = 0x02 → selects prescaler 4
    ldi r16, TC_CLKSEL_DIV4_gc
    sts TCC0_CTRLA, r16       ; Load prescaler into Timer C0 CTRLA

loop:
; Poll Timer Overflow Flag (OVF)
    lds r16, TCC0_INTFLAGS    ; Load Timer C0 interrupt flags into r16
                             ; Bit 0 = OVF
    sbrc r16, 0               ; Skip next instruction if OVF = 0
    rjmp overflow              ; If OVF = 1, jump to overflow handler
    rjmp loop                  ; Otherwise, continue polling

overflow:
; Handle Timer Overflow

; Clear Overflow Flag
    ldi r17, 0x01             ; Bitmask for OVF (bit 0)
    sts TCC0_INTFLAGS, r17    ; Clear OVF by writing '1'

    rjmp loop                  ; Return to main polling loop
	
	