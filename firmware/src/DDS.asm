;----------------------------------------------------------------------------

;Software DDS implementation module
;using I2S audio DAC TDA1543
;I2S is imulated with hardware SPI
;plus OC signal

;Used ports:

;I2SWS - any port pin
;I2SBCK0 - OC1A
;I2SDATA - SPI MOSI
;I2SBCK - SPI SCK

;Connections:

;I2SWS -> NOT gate
;NOT gate out -> DAC WS (pin2)

;I2SBCK0 -> NOR gate input 1
;I2SBCK -> NOR gate input 2
;NOR gate out -> DAC BCK (pin 1)

;I2SDATA -> NOT gate
;NOT gate out -> DAC DATA (pin 3)

;----------------------------------------------------------------------------

;Constantes:

.equ	FUPD	= 216000	;update frequency, Hz

;Nominal frequency calibration value:

.equ CAL_0 = 0 ;(1125899906842624 / FCLK * (FCLK/FUPD) + 50) / 100

;----------------------------------------------------------------------------

.DSEG	;data segment (internal SRAM)

CalB:	.byte 4			;calibration value buffer
MulB:	.byte 7			;multiply buffer

FreeMem:

.org	(FreeMem + 0x100) & 0xFF00 ;align table to page

LUT:	.byte 514		;LUT

;----------------------------------------------------------------------------

.CSEG	;Code segment

;----------------------------------------------------------------------------

;Timer1 output compare A interrupt (DDS implementation)
;To minimize execution time handle must be located
;direct at vector address. It eliminates RJMP command.

;Input:
;FreqK,L,M,N - current frequency (register variables)

;Internal variables:
;PhaseK,L,M,N,P - current phase (register variables)
;SinL,H - instantaneous sin amplitude (register variables)
;XL,XH - data pointer
;tsreg - SREG store
;r0,r1 - used with mul instruction

DDS:	ldi	XL,(1<<COM1A0)
	out	TCCR1A,XL	;OC1A toggle
	ldi	XL,(1<<COM1A0) | (1<<FOC1A)
	out	TCCR1A,XL	;set SCK (OC1A force toggle)
	Port_I2SWS_0		;clear WS
	out	TCCR1A,XL	;clear SCK (OC1A force toggle)

	out	SPDR,SinH	;---> load DAC high byte

	in	tsreg,SREG	;save status register
	clr	r1
	add	PhaseK,FreqK	;Phase(0..33) = Phase(0..33) + Freq(0..31)
	adc	PhaseL,FreqL
	adc	PhaseM,FreqM
	adc	PhaseN,FreqN
	adc	PhaseP,r1	;r1 = 0

	mov	XL,PhaseN	;XL = wa (word address)
	mov	r0,PhaseM	;r0 = dx
	sbrc	PhaseP,0	;if(Phase.32 == 0)
	com	XL		;wa = !wa
	sbrc	PhaseP,0	;if(Phase.32 == 0)
	com	r0		;dx = !dx

	ldi	XH,high(LUT)	;XH = table base (low(LUT) = 0)
	add	XL,XL		;offset * 2 (word offset)
	adc	XH,r1		;r1 = 0
	nop

	out	SPDR,SinL	;---> load DAC low byte

	ld	SinL,X+		;SinL = lo sin[x]
	ld	SinH,X+		;SinH = hi sin[x]
	ld	r1,X		;r1 = lo sin[x + 1]
	sub	r1,SinL		;r1 = dA
	mul	r1,r0		;r1,r0 = dA * dx
	rol	r0		;C = 1 if r0.7 == 1
	clr	r0
	adc	SinL,r1		;SinH:SinL = sin[x] + round(r1:r0 / 256)
	adc	SinH,r0		;SinH:SinL = A

	sbrs	PhaseP,1
	rjmp	ph_cd		;jump if Phase.33 == 0

ph_ab:	com	SinL		;SIN > 0, data line has NOT gate,
	com	SinH		;SinH:SinL = !SinH:SinL
	rjmp	ph_all

ph_cd:	sec
	sbc	SinL,r0		;SIN < 0, data line has NOT gate,
	sbc	SinH,r0		;SinH:SinL = SinH:SinL - 1

ph_all:	ldi	XL,(1<<COM1A0) | (1<<FOC1A)
	out	TCCR1A,XL	;OC1A force toggle
	out	SPDR,r0		;zero data for another DAC channel
	Port_I2SWS_1		;set WS
	ldi	XL,(1<<COM1A1)
	out	TCCR1A,XL	;OC1A clear on compare

	out	SREG,tsreg	;restore status register
	reti

;----------------------------------------------------------------------------

;Init DDS subsystem:

iDDS:

;Periphery setup:

	ldi	temp,(1<<WGM12) | (1<<CS10)
	out	TCCR1B,temp	;clear on compare match, CK/1

	ldi	temp,(1<<COM1A1)
	out	TCCR1A,temp	;OC1A clear on compare

	ldi	temp,high(FCLK/FUPD-1)
	out	OCR1AH,temp
	ldi	temp, low(FCLK/FUPD-1)
	out	OCR1AL,temp

	ldi	temp,(1<<OCF1A)
	out	TIFR,temp	;clear pending timer interrupt
	out	TIMSK,temp	;enable output compare interrupt

	ldi	temp,(1<<SPE) | (1<<MSTR) | (1<<CPHA)
	out	SPCR,temp	;SPI enable, MSB first, master

	ldi	temp,(1<<SPI2X)
	out	SPSR,temp	;double SPI speed

;Build sin LUT in RAM:

	table	SinTab
	ldy	LUT
TCopy:	lpm	temp,Z+
	st	Y+,temp
	cpi	YH,high(LUT+514)
	brne	TCopy
	cpi	YL, low(LUT+514)
	brne	TCopy

;Build triangle LUT in RAM:

;	ldz	0
;	ldy	LUT
;RCopy:	st	Y+,ZL
;	st	Y+,ZH
;	subi	ZL, low(-127)
;	sbci	ZH,high(-127)
;	cpi	YH,high(LUT+514)
;	brne	RCopy
;	cpi	YL, low(LUT+514)
;	brne	RCopy

;Build  trapeze LUT in RAM:

;	ldz	0
;	ldy	LUT
;PCopy:	st	Y+,ZL
;	st	Y+,ZH
;	subi	ZL, low(-255)
;	sbci	ZH,high(-255)
;	cpi	YH,high(LUT+256)
;	brne	PCopy
;	cpi	YL, low(LUT+256)
;	brne	PCopy
;ZCopy:	st	Y+,ZL
;	st	Y+,ZH
;	cpi	YH,high(LUT+514)
;	brne	ZCopy
;	cpi	YL, low(LUT+514)
;	brne	ZCopy

;Variables init

	clr	SinL		;clear instantaneous sin amplitude
	clr	SinH

	clr	PhaseK		;clear phase
	clr	PhaseL
	clr	PhaseM
	clr	PhaseN
	clr	PhaseP

	clr	FreqK		;clear frequency
	clr	FreqL
	clr	FreqM
	clr	FreqN

;	ldi	temp,0xf5
;	mov	FreqK,temp
;	ldi	temp,0x28
;	mov	FreqL,temp
;	ldi	temp,0x5c
;	mov	FreqM,temp
;	ldi	temp,0x2f	;10 KHz
;	mov	FreqN,temp

	ret

;----------------------------------------------------------------------------

;Process ON bit:

mOn:
	mov		temp,Flags
	andi	temp,(1<<ON) | (1<<ONR)
	breq	No_op
	cpi		temp,(1<<ON) | (1<<ONR)
	breq	No_op
	cpi		temp,(1<<ON)
	brne	do_off

do_on:
	cbr		Flags,(1<<MF)
	sbr		Flags,(1<<ONR)
	rcall	MakeF		;restore ValF
	rjmp	No_op

do_off:
	mov		temp,SinH
	bbrs	temp,7,dd_off	;jump if minus
	sbr		Flags,(1<<MF)	;set minus flag
	tst		FreqM
	brne	do_off		;wait for plus if FreqM > 0
	rjmp	No_op

dd_off:
	bbrc	Flags,MF,No_op	;wait for minus flag
	cbr		Flags,(1<<ONR)
	rcall	MakeF		;ValF <- 0
	clr		PhaseK		;Phase <- 0
	clr		PhaseL
	clr		PhaseM
	clr		PhaseN
	clr		PhaseP
No_op:
	ret

;----------------------------------------------------------------------------

;Calculate Freq
;Input:	ValF, Calib
;Out: FreqN:FreqM:FreqL:FreqK

;Freq = ValF x C / 65536

;C = Calib + (CAL_0 - C_0)

;m = mc x mp
;mc - C -> [CalB+0]..[CalB+3]
;mp - ValF -> [MulB+0]..[MulB+2]
;m  - [MulB+0]..[MulB+6]

MakeF:
	ldi		Cnt,7
	ldy		MulB+7
	clr		temp
clrm:
	st	    -Y,temp		;clear m
	dec		Cnt
	brne	clrm

	bbrc	Flags,ONR,m0	;if(ONR == 0) Freq = 0
	ldy		Calib		;init mc
	rcall	LdLMH
	clr		tempD
	subi	tempL,byte1(C_0 - CAL_0)
	sbci	tempM,byte2(C_0 - CAL_0)
	sbci	tempH,byte3(C_0 - CAL_0)
	sbci	tempD,byte4(C_0 - CAL_0)
	sts		CalB+3,tempD
	ldy		CalB
	rcall	StLMH

	ldy		MulB
	ldz		ValF+3		;init mp
	ld		temp,-Z
	lsr		temp
	std		Y+2,temp
	ld		temp,-Z
	ror		temp
	std		Y+1,temp
	ld		temp,-Z
	ror		temp
	std		Y+0,temp

	ldi		Cnt,24		;load cycle counter
m24_32:
	brcc	noadd
	ldz		CalB
	ldd		temp,Y+3
	ld		tempD,Z+
	add		temp,tempD
	std		Y+3,temp
	ldd		temp,Y+4
	ld		tempD,Z+
	adc		temp,tempD
	std		Y+4,temp
	ldd		temp,Y+5
	ld		tempD,Z+
	adc		temp,tempD
	std		Y+5,temp
	ldd		temp,Y+6
	ld		tempD,Z+
	adc		temp,tempD
	std		Y+6,temp

noadd:
	ldz		MulB+7
rry:
	ld		temp,-Z
	ror		temp
	st		Z,temp
	cpse	ZL,YL
	rjmp	rry
	cpse	ZH,YH
	rjmp	rry

	dec		Cnt
	brne	m24_32

;FreqK,L,M,N = [MulB+2]..[MulB+5] + 0.5

m0:
	ld		temp,Y+		;skip [MulB+0]
	ldi		tempD,0x80
	ld		temp,Y+		;load [MulB+1]
	add		temp,tempD
	in		tempL,SREG
	cli					;interrupts disable
	ld		FreqK,Y+
	adc		FreqK,Cnt	;Cnt = 0
	ld		FreqL,Y+
	adc		FreqL,Cnt
	ld		FreqM,Y+
	adc		FreqM,Cnt
	ld		FreqN,Y+
	adc		FreqN,Cnt
	out		SREG,tempL	;interrupts enable
	ret

;----------------------------------------------------------------------------

SinTab:

.include "sin256.asm"		;sine wave table

;----------------------------------------------------------------------------
