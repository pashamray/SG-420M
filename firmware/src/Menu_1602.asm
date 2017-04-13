;----------------------------------------------------------------------------

;Menu implementation module

;----------------------------------------------------------------------------

;Constantes:

.equ	MIN_F	= 100		;F min,  x0.01 Hz
.equ	MAX_F	= 5000000	;F max,  x0.01 Hz
.equ	MIN_FS	= 1			;FS min, x0.01 Hz
.equ	MAX_FS	= 1000000	;FS max, x0.01 Hz
.equ	MIN_SH	= 0			;min SH menu index
.equ	MAX_SH	= 1			;max SH menu index
.equ	MIN_PE	= 0			;min P and E menus index
.equ	MAX_PE	= 9			;max P and E menus index
.equ	MIN_C	= 0			;min calibration value
.equ	MAX_C	= 99999		;max calibration value
.equ	STEP_C	= 10		;calibration value edit step
.equ	C_0		= 50000		;nominal calibration value C

;Menu structure and codes:

;[F  0]	<-> [FS 4]
;  |
;[P  1]
;  |
;[E  2]
;  |
;[SH 3]
;
;[C  5]

.equ	MnuF	=0		;edit Frequency
.equ	MnuP	=1		;read Preset
.equ	MnuE	=2		;preset save in Eeprom
.equ	MnuSH	=3		;set Shape
.equ	MnuFS	=4		;edit Frequency Step
.equ	MnuC	=5		;calibration

;----------------------------------------------------------------------------

;Variables:

.DSEG	;data segment (internal RAM)

Menu:	.byte 1			;menu code

Calib:	.byte 3			;calibration
ValFS:	.byte 3			;frequency step
ValF:	.byte 3			;frequency
ValP:	.byte 3			;preset

Buff:	.byte 3			;edit buffer
Step:	.byte 3			;plus/minus step
Max:	.byte 3			;max limit
Min:	.byte 3			;min limit

;----------------------------------------------------------------------------

;Macros:

.macro	ldmi			;load tempH,M,L with 24-bit data
	ldi 	tempL,byte1(@0)
	ldi 	tempM,byte2(@0)
	ldi 	tempH,byte3(@0)
.endm

.macro	ldei			;load tempF,E,D with 24-bit data
	ldi 	tempD,byte1(@0)
	ldi 	tempE,byte2(@0)
	ldi 	tempF,byte3(@0)
.endm

;----------------------------------------------------------------------------

.CSEG	;Code segment

;----------------------------------------------------------------------------

;Init menu subsystem:

iMenu:
	ldi		Flags,(1<<ON) | (1<<ONR) | (1<<UPDD)
	rcall	ReadF		;read from EEPROM Calib, ValFS, ValF
	ldi		temp,MnuF	;menu "Frequency"
	sts		Menu,temp
	rcall	SetMd		;set mode, calculate Freq and enable interrupts
	rcall	Update		;update display data

	rcall	Scan
	cpi		temp,K_EX	;EX pressed ?
	brne	norm
	ldi		temp,MnuC	;menu "Calibration"
	sts		Menu,temp
	rcall	SetMd		;set calibration mode
	rcall	Update		;update display data
	rcall	Disp		;display

norm:
	ldi		tempE,35
	rcall	Tone		;initial beep

rels:
	rcall	Scan
	wdr
	cpi		temp,K_NO
	brne	rels		;wait for keyboard release
	ret

;----------------------------------------------------------------------------

;Process key functions:

mMenu:	bbrc	Flags,NEWPR,NoPr
	ldy	KBD
	ldd	temp,Y+Lc	;temp <- LastCode
	cpi	temp,K_NO
	breq	NoPr		;skip if no press
	rcall	Sound		;key beep
	cpi	temp,K_UP
	brne	Pro1
	rcall	Do_UP		;key UP processing
	rjmp	NoPr
Pro1:	cpi	temp,K_DN
	brne	Pro2
	rcall	Do_DN		;key DN processing
	rjmp	NoPr
Pro2:	cpi	temp,K_EX
	brne	Pro3
	rcall	Do_EX		;key EX processing
	rjmp	NoPr
Pro3:	cpi	temp,K_EN
	brne	NoPr
	rcall	Do_EN		;key EN procesing
NoPr:	ret

;----------------------------------------------------------------------------

;Key "UP" processing:

Do_UP:	lds	temp,Menu
	cpi	temp,MnuFS	;---> menu "Frequency Step"?
	breq	upst

;Buff + Step, align value to step

	ldy		Buff
	rcall	LdLMH		;tempH:tempM:tempL = Buff
	ldy	Step
	rcall	LdDEF		;tempF:tempE:tempD = Step
	rcall	div24		;tempC:tempB:tempA = Rem(Buff / Step)
	ldy	Buff
	rcall	LdLMH		;tempH:tempM:tempL = Buff
	sub	tempL,tempA	;tempH:tempM:tempL - Rem(Buff / Step)
	sbc	tempM,tempB
	sbc	tempH,tempC
	add	tempL,tempD	;tempH:tempM:tempL + Step
	adc	tempM,tempE
	adc	tempH,tempF
	rjmp	upv		;validate buffer

;Step change (1 -> 2 -> 5 -> 10 -> 20..)

upst:	ldy	Buff
	rcall	LdLMH		;tempH:tempM:tempL = Buff
	lsl	tempL
	rol	tempM
	rol	tempH		;Buff * 2
	rcall	Search
	cpi	temp,2
	brne	upv		;validate buffer
	ldy	Buff
	rcall	LdABC		;tempC:tempB:tempA = Buff
	lsr	tempC
	ror	tempB
	ror	tempA		;Buff / 2
	add	tempL,tempA
	adc	tempM,tempB
	adc	tempH,tempC	;Buff * 2.5

upv:	rcall	Valid		;validate tempH:tempM:tempL
	rcall	Assume		;assume new parameters
	stbr	Flags,EDT	;set edited flag
	rcall	Update		;update display data
	ret

;----------------------------------------------------------------------------

;Key "DN" processing:

Do_DN:	lds	temp,Menu
	cpi	temp,MnuFS	;---> menu "Frequency Step"?
	breq	dnst


;Buff - Step, align value to step

	ldy	Buff
	rcall	LdLMH		;tempH:tempM:tempL = Buff
	ldy	Step
	rcall	LdDEF		;tempF:tempE:tempD = Step
	rcall	div24		;tempC:tempB:tempA = Rem(Buff / Step)
	ldy	Buff
	rcall	LdLMH		;tempH:tempM:tempL = Buff
	mov	temp,tempA
	or	temp,tempB
	or	temp,tempC
	breq	dn0
	sub	tempL,tempA	;Buff - Rem(Buff/Step)
	sbc	tempM,tempB
	sbc	tempH,tempC
	rjmp	dnv		;validate buffer
dn0:	sub	tempL,tempD	;Buff - Step
	sbc	tempM,tempE
	sbc	tempH,tempF
dn1:	rjmp	dnv		;validate buffer

;Step change (..20 -> 10 -> 5 -> 2 -> 1)

dnst:	ldy	Buff
	rcall	LdLMH		;tempH:tempM:tempL = Buff
	lsr	tempH
	ror	tempM
	ror	tempL		;Buff / 2
	rcall	Search
	cpi	temp,5
	brne	dnv		;validate buffer
	ldy	Buff
	rcall	LdLMH		;tempH:tempM:tempL = Buff
	lsl	tempL
	rol	tempM
	rol	tempH		;Buff * 2
	ldi	tempD,5
	clr	tempE
	clr	tempF
	rcall	Div24		;Buff / 2.5

dnv:	rcall	Valid		;validate tempH:tempM:tempL
	rcall	Assume		;assume new parameters
	stbr	Flags,EDT	;set edited flag
	rcall	Update		;update display data
	ret

;----------------------------------------------------------------------------

;Key "EX" processing (change menu item):

Do_EX:	lds	temp,Menu
	cpi	temp,MnuFS	;---> menu "Frequency Step":
	breq	Do_EN		;process enter key

	cpi	temp,MnuC	;---> menu "Calibration":
	brne	ex1
	rcall	ReadF		;skip calibration, read Calib from EEPROM
	rjmp	exf		;return to the frequency menu

ex1:	cpi	temp,MnuF	;---> menu "Frequency":
	breq	exn

	bbrc	Flags,EDT,ex2	;if (EDT == 1) return to the frequency menu
	rjmp	exf		;else next menu item

ex2:	cpi	temp,MnuSH	;---> menu "Shape":
	breq	exf		;return to the frequency menu

exn:	inc	temp		;next menu item
	rjmp	ex0
exf:	ldi	temp,MnuF
ex0:	sts	Menu,temp
	rcall	SetMd		;set mode
	rcall	Update		;update display data
	ret

;----------------------------------------------------------------------------

;Key "EN" processing (change menu item):

Do_EN:
	lds		temp,Menu
	cpi		temp,MnuC	;---> menu "Calibration":
	brne	en1
	rcall	SaveC		;save Calib in EEPROM
	rjmp	enf			;return to the frequency menu

en1:
	cpi		temp,MnuF	;---> menu "Frequency":
	brne	en2
	ldi		temp,MnuFS	;jump to the frequency step menu
	rjmp	en0

en2:
	cpi		temp,MnuP	;---> menu "Read Preset":
	brne	en3
	ldy		ValP
	rcall	LdLMH		;tempH:tempM:tempL = ValP
	ldy		ValF
	rcall	StLMH		;ValF = tempH:tempM:tempL
	rjmp	ens			;beep and return to the frequency menu

en3:
	cpi		temp,MnuE	;---> menu "Save Preset":
	brne	en4
	rcall	SaveP		;save preset
	rjmp	enf			;return to the frequency menu

en4:
	cpi		temp,MnuSH	;---> menu "Shape":
	brne	ens			;beep and return to the frequency menu
	rcall	ErrB		;error beep
	rjmp	enx

ens:
	ldi		temp,0
	rcall	Sound		;return beep
enf:
	ldi		temp,MnuF	;menu "Frequency"
en0:
	sts		Menu,temp
	rcall	SetMd		;set mode
enx:
	rcall	Update		;update display data
	ret

;----------------------------------------------------------------------------

;Set current edit mode:
;Input: Menu
;Out:   Buff, Step, Min, Max

SetMd:
	lds		temp,Menu
	cpi		temp,MnuC	;---> menu "Calibration":
	brne	smd1
	ldy		Calib
	rcall	LdLMH
	ldy		Buff
	rcall	StLMH		;Buff = Calib
	ldmi	STEP_C
	ldy		Step
	rcall	StLMH		;Step = StepC
	ldmi	MIN_C		;Min  = MIN_C
	ldei	MAX_C		;Max  = MAX_C
	rjmp	smm

smd1:
	cpi		temp,MnuF	;---> menu "Frequency":
	brne	smd2
	ldy		ValF
	rcall	LdLMH
	ldy		Buff
	rcall	StLMH		;Buff = ValF
	ldy		ValFS
	rcall	LdLMH
	ldy		Step
	rcall	StLMH		;Step = ValFS
	ldmi	MIN_F		;Min  = MIN_F
	ldei	MAX_F		;Max  = MAX_F
	rjmp	smm

smd2:
	cpi		temp,MnuFS	;---> menu "Frequency Step":
	brne	smd3
	ldy		ValFS
	rcall	LdLMH
	ldy		Buff
	rcall	StLMH		;Buff = ValFS
	ldmi	MIN_FS		;Min  = MIN_FS
	ldei	MAX_FS		;Max  = MAX_FS
	rjmp	smm

smd3:
	cpi		temp,MnuSH	;---> menu "Shape":
	brne	smd4
	sbrc	Flags,ON
	ldmi	1
	ldy		Buff
	rcall	StLMH		;Buff = ON
	ldmi	1
	ldy		Step
	rcall	StLMH		;Step = 1
	ldmi	MIN_SH		;Min = MIN_SH
	ldei	MAX_SH		;Max = MAX_SH
	rjmp	smm

smd4:
	ldmi	0		;---> menu "Read/Save Preset":
	ldy		Buff
	rcall	StLMH		;Buff = 0
	ldmi	1
	ldy		Step
	rcall	StLMH		;Step = 1
	ldmi	MIN_PE		;Min = MIN_PE
	ldei	MAX_PE		;Max = MAX_PE

smm:
	ldy		Max
	rcall	StDEF		;save Max
	ldy		Min
	rcall	StLMH		;save Min
	ldy		Buff
	rcall	LdLMH		;tempH:tempM:tempL = Buff
	rcall	Valid		;validate buffer
	rcall	Assume		;assume new values
	clbr	Flags,EDT	;set edited flag
	ret

;----------------------------------------------------------------------------

;Search for first non-zero digit:

Search:
	ldy		Dig+5
srch:
	ld		temp,Y+
	andi	temp,~Pt
	breq	srch
	cpi		temp,BLANK
	breq	srch
	ret

;----------------------------------------------------------------------------

;Validate value:
;Input: [Buff] - old value
;       tempH:tempM:tempL - new value
;       [Max], [Min] - limits
;Out:   tempH:tempM:tempL, [Buff] - validated value

Valid:
	rcall	ChkMin		;check for Min
	brcs	RstBf
	rcall	ChkMax		;check for Max
	brcc	ValOk

RstBf:
	ldy		Buff
	rcall	LdLMH		;error, restore buffer
	rcall	ErrB		;error bell
	rcall	ChkMin		;check for Min
	brcs	LimBf
	rcall	ChkMax		;check for Max
	brcc	ValOk

LimBf:
	mov		tempL,tempA	;limit buffer
	mov		tempM,tempB
	mov		tempH,tempC
	rcall	ErrB		;error bell

ValOk:
	ldy		Buff
	rcall	StLMH		;save value to buffer
	ret

;----------------------------------------------------------------------------

;Compare tempH:tempM:tempL and [Min]:
;Out: C = 1 if limit exceeded

ChkMin:
	ldy		Min
	rcall	LdABC		;tempC:tempB:tempA = Min
	ldi		temp,0xC0	;0xC00000 is max negative
	cp		temp,tempH
	brcs	chmr
	cp		tempL,tempA
	cpc		tempM,tempB
	cpc		tempH,tempC
chmr:
	ret

;----------------------------------------------------------------------------

;Compare tempH:tempM:tempL and [Max]:
;Out: C = 1 if limit exceeded

ChkMax:
	ldy		Max
	rcall	LdABC		;tempC:tempB:tempA = Max
	cp		tempA,tempL
	cpc		tempB,tempM
	cpc		tempC,tempH
	ret

;----------------------------------------------------------------------------

;Assume new parameters:
;Input:	tempH:tempM:tempL - new value
;[Menu] - index
Assume:
	lds		temp,Menu
	cpi		temp,MnuF	;---> menu "Frequency":
	brne	assm1
	ldy		ValF
	rcall	StLMH		;save new ValF
	rcall	MakeF		;change frequency
	rjmp	assmr

assm1:
	cpi		temp,MnuFS	;---> menu "Frequency Step":
	brne	assm2
	ldy		ValFS
	rcall	StLMH		;save new ValFS
	rjmp	assmr

assm2:
	cpi		temp,MnuSH	;---> menu "Shape":
	brne	assm3
	bst		tempL,0
	bld		Flags,ON	;change shape
	rjmp	assmr

assm3:
	cpi		temp,MnuP	;---> menu "Preset":
	brne	assm4
	rcall	ReadP		;read preset fom EEPROM
	rjmp	assmr

assm4:
	cpi		temp,MnuC	;---> menu "Calibration":
	brne	assmr
	ldy		Calib
	rcall	StLMH		;save new Calib
	rcall	MakeF		;change frequency
assmr:
	ret

;----------------------------------------------------------------------------

;Update display data:
;Input:	Menu, Buff/ValF/ValP
;Out:	Dig[0..9]
;	UPDD = 1

Update:
	ldi		temp,BLANK	;load char
	rcall	Fill		;clear display data
	ldy		Buff
	rcall	LdLMH		;tempH:tempM:tempL = Buff

	lds		temp,Menu
	cpi		temp,MnuSH	;---> menu "Shape":
	brne	upd1

	table	StrMode		;string table base
	ldy		Dig 		;display data base
	lpm		temp,Z+
	st		Y+,temp		;O
	lpm		temp,Z+
	st		Y+,temp		;u
	lpm		temp,Z+
	st		Y+,temp		;t
	lpm		temp,Z+
	st		Y+,temp		;p
	lpm		temp,Z+
	st		Y+,temp		;u
	lpm		temp,Z+
	st		Y+,temp		;t
	table	ShpT
	ldy		Dig+Lcd_cols 		;display data base
	mov		temp,tempL
	add		temp,tempL
	add		temp,tempL	;temp = Buff[0] * 3
	add		ZL,temp
	adc		ZH,temp
	sub		ZH,temp		;ZH:ZL = ShpT + Buff[0] * 3
	lpm		temp,Z+
	st		Y+,temp		;menu char 1
	lpm		temp,Z+
	st		Y+,temp		;menu char 2
	lpm		temp,Z+
	st		Y+,temp		;menu char 3
	rjmp	upd31

upd1:
	table	StrFreq		;string table base
	ldy		Dig			;display data base
	lpm		temp,Z+
	st		Y+,temp		;F
	lpm		temp,Z+
	st		Y+,temp		;r
	lpm		temp,Z+
	st		Y+,temp		;e
	lpm		temp,Z+
	st		Y+,temp		;q
	lpm		temp,Z+
	st		Y+,temp		;u
	lpm		temp,Z+
	st		Y+,temp		;e
	lpm		temp,Z+
	st		Y+,temp		;n
	lpm		temp,Z+
	st		Y+,temp		;c
	lpm		temp,Z+
	st		Y+,temp		;y

	lds		temp,Menu
	cpi		temp,MnuFS	;---> menu "Freq step":
	brne	skip
	ldi 	temp,BLANK
	st		Y+,temp		;blank
	table	StrStep		;string table base
	lpm		temp,Z+
	st		Y+,temp		;s
	lpm		temp,Z+
	st		Y+,temp		;t
	lpm		temp,Z+
	st		Y+,temp		;e
	lpm		temp,Z+
	st		Y+,temp		;p

skip:
	table	StrkHz		;string table base
	ldy		Dig+Lcd_bytes-3		;display data base
	lpm		temp,Z+
	st		Y+,temp		;k
	lpm		temp,Z+
	st		Y+,temp		;H
	lpm		temp,Z+
	st		Y+,temp		;z

	lds		temp,Menu
	cpi		temp,MnuE	;---> menu "Save Preset":
	brne	upd2
	ldy		Dig
	table	StrSave		;save string
	lpm		temp,Z+
	st		Y+,temp		;S
	lpm		temp,Z+
	st		Y+,temp		;a
	lpm		temp,Z+
	st		Y+,temp		;v
	lpm		temp,Z+
	st		Y+,temp		;e
	ldi		temp,BLANK
	st		Y+,temp		;blank
	table	StrPre		;preset string
	lpm		temp,Z+
	st		Y+,temp		;p
	lpm		temp,Z+
	st		Y+,temp		;r
	lpm		temp,Z+
	st		Y+,temp		;e
	lpm		temp,Z+
	st		Y+,temp		;s
	lpm		temp,Z+
	st		Y+,temp		;e
	lpm		temp,Z+
	st		Y+,temp		;t
	ldi		temp,BLANK
	st		Y+,temp		;blank
	mov		temp,tempL
	st		Y+,temp		;number
	ldy		ValF
	rjmp	upd21

upd2:
	cpi		temp,MnuP	;---> menu "Read Preset":
	brne	upd3
	ldy		Dig
	table	StrRead		;read string
	lpm		temp,Z+
	st		Y+,temp		;R
	lpm		temp,Z+
	st		Y+,temp		;e
	lpm		temp,Z+
	st		Y+,temp		;a
	lpm		temp,Z+
	st		Y+,temp		;d
	ldi		temp,BLANK
	st		Y+,temp		;blank
	table	StrPre		;preset string
	lpm		temp,Z+
	st		Y+,temp		;p
	lpm		temp,Z+
	st		Y+,temp		;r
	lpm		temp,Z+
	st		Y+,temp		;e
	lpm		temp,Z+
	st		Y+,temp		;s
	lpm		temp,Z+
	st		Y+,temp		;e
	lpm		temp,Z+
	st		Y+,temp		;t
	ldi		temp,BLANK
	st		Y+,temp		;blank
	mov		temp,tempL
	st		Y+,temp		;number
	ldy		ValP
upd21:
	rcall	LdLMH		;tempH:tempM:tempL = ValF or ValP
upd3:
	rcall	DisBCD		;tempH:tempM:tempL convert to BCD Dig[3..9]
upd31:
	stbr	Flags,UPDD	;display update request
	ret

;----------------------------------------------------------------------------

;Divide tempH:tempM:tempL / tempF:tempE:tempD =
; tempH:tempM:tempL.tempC:tempB:tempA

div24:
	clr		tempA		;clear remainder Low byte
	clr		tempB
	sub		tempC,tempC	;clear remainder High byte and carry

	ldi		Cnt,25		;init loop counter

div1:
	rol		tempL		;shift left dividend
	rol		tempM
	rol		tempH
	dec		Cnt		;decrement counter
	breq	divret
	rol		tempA		;shift dividend into remainder
	rol		tempB
	rol		tempC
	sub		tempA,tempD	;remainder = remainder - divisor
	sbc		tempB,tempE
	sbc		tempC,tempF
	brcc	div1		;if result negative
	add		tempA,tempD	; restore remainder
	adc		tempB,tempE
	adc		tempC,tempF
	rjmp	div1
divret:
	com		tempL
	com		tempM
	com		tempH
	ret

;----------------------------------------------------------------------------

;Load tempH,M,L from [Y+2],[Y+1],[Y+0]

LdLMH:
	ld		tempL,Y+
	ld		tempM,Y+
	ld		tempH,Y+
	ret

;----------------------------------------------------------------------------

;Load tempC,B,A from [Y+2],[Y+1],[Y+0]

LdABC:	ld	tempA,Y+
	ld	tempB,Y+
	ld	tempC,Y+
	ret

;----------------------------------------------------------------------------

;Load tempF,E,D from [Y+2],[Y+1],[Y+0]

LdDEF:	ld	tempD,Y+
	ld	tempE,Y+
	ld	tempF,Y+
	ret

;----------------------------------------------------------------------------

;Store tempH,M,L  to [Y+2],[Y+1],[Y+0]

StLMH:
	st	Y+,tempL
	st	Y+,tempM
	st	Y+,tempH
	ret

;----------------------------------------------------------------------------

;Store tempF,E,D  to [Y+2],[Y+1],[Y+0]

StDEF:	st	Y+,tempD
	st	Y+,tempE
	st	Y+,tempF
	ret

;----------------------------------------------------------------------------

;Shape string table:

ShpT:	.DB _iO, _iiF, _iiF, _iO, _iiN, BLANK

;----------------------------------------------------------------------------
