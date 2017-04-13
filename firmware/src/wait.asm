;------------------------------------------------------------------------------
; Busy-wait loops utilities module
; For F_CPU >= 4MHz
; http://avr-mcu.dxp.pl
; (c) Radoslaw Kwiecien, 2008
;------------------------------------------------------------------------------

.equ CYCLES_PER_US = (FCLK/1000000)
.equ C4PUS = (CYCLES_PER_US/4)
.equ DVUS_500 = (C4PUS*500)

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
  ldi	   XH,HIGH(DVUS_500)
  ldi	   XL,LOW(DVUS_500)
  rcall	 Wait4xCycles
  ldi	   XH,HIGH(DVUS_500)
  ldi	   XL,LOW(DVUS_500)
  rcall	 Wait4xCycles
  dec	   temp
  brne	  WaitMsLoop
  pop	   temp
  ret
;------------------------------------------------------------------------------
; End of file
;------------------------------------------------------------------------------
