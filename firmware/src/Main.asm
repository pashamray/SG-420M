;----------------------------------------------------------------------------

;* Title	: SG-420M sine wave generator
;* Version	: 1.00
;* Target	: ATmega8
;* Author	: wubblick@yahoo.com

;----------------------------------------------------------------------------

.include "m8def.inc"
.include "macros.mac"
.include "Header.asm"

;------------------------- Interrupt Vectors: -------------------------------

.CSEG				;code segment
.org	0
	rjmp	Init		;reset vector

.org	OC1Aaddr
.include "DDS.asm"			;link DDS implementation module
;DDS implementation is located direct at the OC1A vector address
;Only one interrupt is used in this project

;--------------------------- Main program: ----------------------------------

Init:	ldy	RAMEND	
	out	SPL,YL		;locate stack
	out	SPH,YH
	;rcall	iWdog		;start internal watchdog
	rcall	iPorts		;ports init
	rcall	iVar		;variables init
	rcall	iTimer		;system timer init
	rcall	iDisp		;LCD init
	;rcall	iDDS		;DDS subsystem init
	sei			;enable interrupts
	rcall	iMenu		;menu subsystem init

;Main loop:

Main:	rcall	mTimer		;process system timer
	rcall	mKey		;scan keyboard
	rcall	mMenu		;process menu
	rcall	mDisp		;update display
	rcall	mOn		;process ON bit
	rcall	mWdog		;watchdog restart
	rjmp 	Main		;loop

;------------------------- Subroutines area: --------------------------------

;Internal watchdog init:

iWdog:	wdr
	ldi	temp,(1<<WDCE) | (1<<WDE)
	out	WDTCR,temp	
	ldi	temp,(1<<WDE) | (1<<WDP2)	
	out	WDTCR,temp	;watchdog enable, period 260 mS
	ret	

;----------------------------------------------------------------------------

;Internal watchdog restart:

mWdog:	wdr			;internal watchdog restart
	ret

;----------------------------------------------------------------------------

;System timer init:

iTimer:	ldi	temp,(1<<CS02) | (1<<CS00)
	out	TCCR0,temp	;CK/1024
	ret

;----------------------------------------------------------------------------

;Process system timer:

mTimer:	clbr	Flags,UPD
	in	temp,TIFR
	bbrc	temp,TOV0,no_tm	;check for Timer 0 overflow
	stbr	temp,TOV0	;Timer 0 overflow flag clear
	out	TIFR,temp
	ldi	temp,T0Val
	out	TCNT0,temp	;Timer 0 reload
	stbr	Flags,UPD	;set update flag
no_tm:	ret

;----------------------------------------------------------------------------

;Ports init:
	
iPorts:	ldi	temp,PUPB
	out	PORTB,temp	;init PORTB and on/off pullup
	ldi	temp,DIRB	
	out	DDRB,temp	;set PORTB direction
	
	ldi	temp,PUPC
	out	PORTC,temp	;init PORTC and on/off pullup
	ldi	temp,DIRC
	out	DDRC,temp	;set PORTC direction

	ldi	temp,PUPD
	out	PORTD,temp	;init PORTD and on/off pullup
	ldi	temp,DIRD
	out	DDRD,temp	;set PORTD direction
	ret

;----------------------------------------------------------------------------

;Variables init:

iVar:	clr	Flags		;clear flags
	ret

;----------------------------------------------------------------------------

.include "LCD_1602.asm"		;link LCD support module
.include "Keyboard.asm"		;link keyboard support module
.include "Beeper.asm"		;link beeper support module
.include "Menu_1602.asm"	;link menu implementation module
.include "EEPROM.asm"		;link EEPROM support module

;----------------------------------------------------------------------------
