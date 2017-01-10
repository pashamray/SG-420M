;----------------------------------------------------------------------------

;Keyboard support module
;Used 74HC164

;Connections:
;DATA -> pin 2 74HC164
;CLK -> pin 8 74HC164
;RETL -> keyboard return line

;----------------------------------------------------------------------------

;Constantes:

.equ	ARCnV	= 16		;slow autorepeat count
.equ	ARDel	= 800		;initial autorepeat delay, mS
.equ	ARSlw	= 180		;slow autorepeat rate, mS
.equ	ARFst	= 60		;fast autorepeat rate, mS
.equ	Debnc	= 30		;debounce delay, mS

;----------------------------------------------------------------------------

;Derivated constantes:

.equ ARDelV = ARDel/TSYS
.equ ARSlwV = ARSlw/TSYS
.equ ARFstV = ARFst/TSYS
.equ DebncV = Debnc/TSYS

;----------------------------------------------------------------------------

;Keyboard scancodes:

.equ	K_NO	= 0x00		;no press
.equ	K_EX	= 0x01		;key EXIT code
.equ	K_DN	= 0x02		;key DOWN code
.equ	K_UP	= 0x04		;key UP code
.equ	K_EN	= 0x08		;key ENTER code

;----------------------------------------------------------------------------

.DSEG	;data segment

;----------------------------------------------------------------------------

KBD:	.byte 5			;keyboard data structure
.equ	Lc	= 0		;LastCode offset
.equ	Tc	= 1		;TempCode offset
.equ	ARCnt	= 2		;autorepeat counter offset
.equ	DebTM	= 3		;debounce timer offset
.equ	KeyTM	= 4		;key timer offset

;----------------------------------------------------------------------------

.CSEG	;Code segment

;----------------------------------------------------------------------------

;Scan keyboard and validate code:
;KBD+Lc	= true scancode,
;NEWPR	= 1 if new press

mKey:	rcall	Scan		;scan keyboard
	ldy	KBD		;keyboard data structure base
	ldd	tempL,Y+Lc	
	cp	tempL,temp	;scancode = LastCode ?
	breq	Hold		;branch if same key
	
	ldd	tempL,Y+Tc
	cp	tempL,temp	;scancode = TempCode ?
	brne	NewP		;branch if new key
	
	ldd	tempL,Y+DebTM
	tst	tempL		;check debounce timer
	brne	Hold
	
	ldd	tempL,Y+Lc
	cpi	tempL,K_NO	;check LastCode
	std	Y+Lc,temp	;LastCode <- scancode
	brne	Proc		;if LastCode == K_NO, then
	stbr	Flags,NEWPR	;set new press flag
	ldi	tempH,ARDelV	;autorepeat delay value
	ldi	tempL,ARCnV
	rjmp	Stac		;go to store ARCnt
	
NewP:	std	Y+Tc,temp	;TempCode <- scancode
	ldi	tempL,DebncV
	std	Y+DebTM,tempL	;debounce timer load
	
Hold:	clbr	Flags,NEWPR	;clear new press flag
	ldd	tempL,Y+KeyTM
	tst	tempL		;check key timer
	brne	Proc
	ldd	tempL,Y+Lc
	cpi	tempL,K_UP	;K_UP, autorepeat enable
	breq	Ar
	cpi	tempL,K_DN	;K_DN, autorepeat enable
	breq	Ar
	rjmp	Proc
Ar:	stbr	Flags,NEWPR	;set new press flag
	ldd	tempL,Y+ARCnt
	tst	tempL
	breq	Fast		;fast autorepeat if count is over
	dec	tempL		;dec autorepeat counter
	ldi	tempH,ARSlwV	;slow autorepeat rate
	
Stac:	std	Y+ARCnt,tempL	;store autorepeat counter ARCnt
	rjmp	Stkt		;go to store KeyTM
	
Fast:	ldi	tempH,ARFstV	;fast autorepeat rate
Stkt:	std	Y+KeyTM,tempH	;store key timer KeyTM
Proc:

;Process timers:

	bbrc	Flags,UPD,Tmr2
	
	ldd	temp,Y+DebTM
	tst	temp		;check debounce timer		 
	breq	Tmr1
	dec	temp		;advance debounce timer
	std	Y+DebTM,temp

Tmr1:	ldd	temp,Y+KeyTM
	tst	temp		;check key timer		 
	breq	Tmr2
	dec	temp		;advance key timer
	std	Y+KeyTM,temp
Tmr2:	ret

;----------------------------------------------------------------------------

;Scan keyboard:
;Out: temp - scancode

Scan:	rcall	scyc		;dummy scan (load 0bXXXX1111 in HC164)
	Port_DATA_0		;DATA <- 0 at first
scyc:	ldi	temp,0b00001000	;scan 4 buttons by 5 impulses
sclk:	Port_CLK_0		;CLK <- 0
	clc			;clc inside the loop for longer delay only
	Skip_if_RETL_1		;C <- ~RETL
	sec
	Port_CLK_1		;CLK <- 1
	Port_DATA_1		;DATA <- 1 forever
	rol	temp		;C <- temp.7..temp.0 <- C
	brcc	sclk
	ret			;temp = scancode

;----------------------------------------------------------------------------
