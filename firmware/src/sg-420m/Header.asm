;----------------------------------------------------------------------------

;SG-420M header file

;----------------------------------------------------------------------------

;Constantes:

.equ	FCLK	= 16000000	;Fclk, Hz
.equ	TSYS	= 10		;system timer, mS

;----------------------------------------------------------------------------

;Derivated constantes:

.equ MAXBYTE = 0xFF
.equ MAXWORD = 0xFFFF

.equ T0Val = (256 - ((FCLK/1024)*TSYS/1000))

;----------------------------------------------------------------------------

;Port Definitions:

;Port B:

.equ	DIRB	= 0b11111111	;Port B direction
.equ	PUPB	= 0b00000000	;Port B pull-ups
.equ	I2SWS	= PB0		;I2S word select
.equ	I2SBCK0	= PB1		;I2S frame clock (OC1A)
;.equ		= PB2		;
.equ	I2SDATA	= PB3		;I2S data (MOSI)
;.equ		= PB4		;
.equ	I2SBCK	= PB5		;I2S clock (SCK)

.macro	Port_I2SWS_0		;WS = 0
	cbi	PORTB,I2SWS
.endm

.macro	Port_I2SWS_1		;WS = 1
	sbi	PORTB,I2SWS
.endm

;Port C:

.equ	DIRC	= 0b11111111	;Port C direction
.equ	PUPC	= 0b00000000	;Port C pull-ups
;.equ		= PC0		;
;.equ		= PC1		;
;.equ		= PC2		;
;.equ		= PC3		;
;.equ		= PC4		;
;.equ		= PC5		;

;Port D:

.equ	DIRD	= 0b11101111	;Port D direction
.equ	PUPD	= 0b11110100	;Port D pull-ups
;.equ		= PD0		;
;.equ		= PD1		;
.equ	SND	= PD2		;sound generation
;.equ		= PD3		;
.equ	RETL	= PD4		;keyboard return line
.equ	LOAD	= PD5		;display load
.equ	DATA	= PD6		;display data
.equ	CLK	= PD7		;display clock

.macro	Port_SND_0		;SND = 0
	cbi	PORTD,SND
.endm

.macro	Port_SND_1		;SND = 1
	sbi	PORTD,SND
.endm

.macro	Skip_if_RETL_1		;skip if RETL = 1
	sbis	PIND,RETL
.endm

.macro	Port_LOAD_0		;LOAD = 0
	cbi	PORTD,LOAD
.endm

.macro	Port_LOAD_1		;LOAD = 1
	sbi	PORTD,LOAD
.endm

.macro	Port_DATA_0		;DATA = 0
	cbi	PORTD,DATA
.endm

.macro	Port_DATA_1		;DATA = 1
	sbi	PORTD,DATA
.endm

.macro	Port_CLK_0		;CLK = 0
	cbi	PORTD,CLK
.endm

.macro	Port_CLK_1		;CLK = 1
	sbi	PORTD,CLK
.endm

;----------------------------------------------------------------------------

;Global Register Variables:

;* - used in OC1A interrupt
;r0, r1 * used with mul instruction

.def	tsreg	= r2		;* SREG store

.def	PhaseK	= r3		;* phase code
.def	PhaseL	= r4		;*
.def	PhaseM	= r5		;*
.def	PhaseN	= r6		;*
.def	PhaseP	= r7		;*

.def	FreqK	= r8		;* frequency code (delta phase)
.def	FreqL	= r9		;*
.def	FreqM	= r10		;*
.def	FreqN	= r11		;*

.def	SinL	= r12		;* instantaneous amplitude code
.def	SinH	= r13		;*

.def	tempA	= r14		;temporary register tempA
.def	tempB	= r15		;temporary register tempB
.def	tempC	= r16		;temporary register tempC
.def	tempD	= r17		;temporary register tempD
.def	tempE	= r18		;temporary register tempE
.def	tempF	= r19		;temporary register tempF
.def	tempL	= r20		;temporary register tempL
.def	tempM	= r21		;temporary register tempM
.def	tempH	= r22		;temporary register tempH
.def	temp	= r23		;temporary register temp
.def	Cnt	= r24		;temporary register Cnt

.def	Flags	= r25
.equ	UPD	= 0		;timer update flag
.equ	UPDD	= 1		;display update flag
.equ	NEWPR	= 2		;keyboard new press flag
.equ	EDT	= 3		;edited flag
.equ	ON	= 4		;on flag
.equ	ONR	= 5		;real on flag
.equ	MF	= 6		;minus flag

;r26,r27 * used as X-register
;r28,r29 used as Y-register
;r30,r31 used as Z-register

;----------------------------------------------------------------------------
