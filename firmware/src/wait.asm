;------------------------------------------------------------------------------
; Busy-wait loops utilities module
; For F_CPU >= 4MHz
; http://avr-mcu.dxp.pl
; (c) Radoslaw Kwiecien, 2008
;------------------------------------------------------------------------------

#define CYCLES_PER_US (FCLK/1000000)
#define C4PUS (CYCLES_PER_US/4)
#define DVUS(x) (C4PUS*x)

;------------------------------------------------------------------------------
; Input : XH:XL - number of CPU cycles to wait (divided by four)
;------------------------------------------------------------------------------
Wait4xCycles:
  sbiw	  XH:XL, 1
  brne	  Wait4xCycles
  ret
;------------------------------------------------------------------------------
; Input : temp - number of miliseconds to wait
;------------------------------------------------------------------------------
WaitMiliseconds:
  push	temp
WaitMsLoop: 
  ldi	   XH,HIGH(DVUS(500))
  ldi	   XL,LOW(DVUS(500))
  rcall	 Wait4xCycles
  ldi	   XH,HIGH(DVUS(500))
  ldi	   XL,LOW(DVUS(500))
  rcall	 Wait4xCycles
  dec	   temp
  brne	  WaitMsLoop
  pop	   temp
  ret
;------------------------------------------------------------------------------
; End of file
;------------------------------------------------------------------------------