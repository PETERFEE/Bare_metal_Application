/*--------------------------------------------------------------
 ebi_init --

 Description:
  Initialize and enable the EBI system for the relevant
  hardware expansion.
--------------------------------------------------------------*/
EBI_INIT: 
  push r16     

  ; Initialize the EBI system for SRAM 3-PORT ALE1 mode.
  ; Initialize EBI_CTRL for 3-port (H, J, K) (IFMODE), ALE1 (SRMODE)
  ; Instead of BIT0, can also use EBI_IFMODE_3PORT_gc | EBI_SRMODE_ALE1_gc 
  ldi r16, 0b00000001  
  sts EBI_CTRL, r16

  ; Initialize the relevant chip select(s).

   ;Configure chip select CS0
  ; set to 16k  space and turn on SRAM mode
   ldi r16, 0b00011101 
  sts EBI_CS0_CTRLA, r16 

 ldi r16, byte2(SRAM_START_ADDR)   
  
 sts EBI_CS0_BASEADDR, r16 

  ldi r16, byte3(SRAM_START_ADDR) 

  sts EBI_CS0_BASEADDR+1, r16 

  
  ; Configure chip select CS2
  ; this is just : 0b00001101 
  ldi r16, 0b00001101
  sts EBI_CS2_CTRLA, r16  



  ;Load the middle byte (A15:8) of the 3-byte address into a   
;  register and store it as the LOW byte of the Base Address,
;  BASEADDRL.  This will store only bits A15:A12 and ignore
;  anything in A11:8 (assumed to be 0). 
;Initialize low byte of the EBI CS2 base address (byte2 of address).
   ldi r16, byte2(IO_START_ADDR) 
   sts EBI_CS2_BASEADDR, r16   

;Load the highest byte (A23:16) of the 3-byte address into a 
;  register and store it as the HIGH byte of the Base Address.
;Initialize high byte of the EBI CS2 base address (byte3 of address).
	ldi r16, byte3(IO_START_ADDR)     
	sts EBI_CS2_BASEADDR+1, r16 
  
	   ; Recover the relevant register.
  pop r16  

   ; Return from subroutine.
  ret

  DELAY_INIT:
	; Configure Timer/Counter's Period register for the 300ms delay
	;  2MHz system clock, choose prescaler = 64
	; f_timer = f_clk / 64 = 31250Hz
	; period = T_delay * f_timer = 0.3second * 31250Hz = 9375
	
	ldi r16, low(9375)
	sts TCC0_PER, r16 
	ldi r16, high(9375)
	sts TCC0_PER+1, r16 
	ret 

  DELAY_300MS: 
	; Start Timer/Conuter C0 with 64 prescaler 
	ldi r16, TC_CLKSEL_DIV64_gc
	sts TCC0_CTRLA, r16 

; it does nothing but repeatedly checking timer status 
 WAIT:
    lds     r16, TCC0_INTFLAGS ; load Interrupt Flags of timer in to r17.
    sbrc    r16, TC0_OVFIF_bp	; if TC0_OVFIF is 0, still counting
    rjmp    WAIT_END		; otherwise timer has reach and overflow 
    rjmp    WAIT
	
 WAIT_END:
	; Stop the timer and clear the flag before returning
    ldi     r16, TC_CLKSEL_OFF_gc
    sts     TCC0_CTRLA, r16
    ldi     r16, TC0_OVFIF_bm      ; Load the bit mask for the overflow flag
    sts     TCC0_INTFLAGS, r16      ; Write 1 to the flag to clear it
    ret
