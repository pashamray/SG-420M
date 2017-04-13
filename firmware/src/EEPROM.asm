;----------------------------------------------------------------------------

;EEPROM support module

;----------------------------------------------------------------------------

;Constantes:

.equ	SIGN	= 0xDE		;signature value

.equ	STEP_0	= 10000		;initial step, x 0.01 Hz

.equ	FREQ_0	= 100000	;preset 0, x 0.01 Hz
.equ	FREQ_1	= 200000	;preset 1, x 0.01 Hz
.equ	FREQ_2	= 300000	;preset 2, x 0.01 Hz
.equ	FREQ_3	= 400000	;preset 3, x 0.01 Hz
.equ	FREQ_4	= 500000	;preset 4, x 0.01 Hz
.equ	FREQ_5	= 600000	;preset 5, x 0.01 Hz
.equ	FREQ_6	= 700000	;preset 6, x 0.01 Hz
.equ	FREQ_7	= 1000000	;preset 7, x 0.01 Hz
.equ	FREQ_8	= 2000000	;preset 8, x 0.01 Hz
.equ	FREQ_9	= 5000000	;preset 9, x 0.01 Hz

;----------------------------------------------------------------------------

.ESEG	;EEPROM initial values

.DSEG ; Start data segment
Enone:	.byte 1			;address 0 not used
ECalib:	.byte 3			;calibration value
EValFS:	.byte 3			;step
EPres:	.byte 30		;presets
ESign:	.byte 1			;signature
EEnd:				;end of EEPROM array

;----------------------------------------------------------------------------

.CSEG	;Code segment

;----------------------------------------------------------------------------

;Read Calib, ValFS, ValF from EEPROM:

ReadF:	ldy	ESign
	rcall	EE_Rd		;read signature
	cpi	temp,SIGN	;check signature
	breq	rdpar

;Signature fail, EEPROM init:

	rcall	ErrB		;error beep
	ldy	ECalib		;load EEPROM array base address
	table	FCalib		;load FLASH array base address
eeini:	rcall	EE_Rd		;wait EEPROM ready
	lpm	temp,Z+		;read byte from FLASH
	rcall	EE_Wr		;save byte to EEPROM
	adiw	ZH:ZL,1		;skip high byte of word
	adiw	YH:YL,1		;EEPROM address inc
	cpi	YL,low(EEnd)
	brne	eeini
	cpi	YH,high(EEnd)
	brne	eeini

rdpar:	ldy	ECalib
	ldz	Calib
	rcall	EE_Rd3		;read Calib
	ldy	EValFS
	ldz	ValFS
	rcall	EE_Rd3		;read ValFS
	ldy	EPres
	ldz	ValF
	rcall	EE_Rd3		;read ValF
	ret

;----------------------------------------------------------------------------

;Read preset from the EEPROM:
;Input: [Buff+0] - preset number

ReadP:	lds	temp,Buff+0	;temp = preset number
	rcall	EE_PrA		;YH:YL = EEPROM address
	ldz	ValP
	rcall	EE_Rd3		;read preset
	ret

;----------------------------------------------------------------------------

;Save calibration to the EEPROM:

SaveC:	ldy	ECalib
	ldz	Calib
	rcall	EE_Wr3		;save Calib
	rcall	Melody		;melody
	ret

;----------------------------------------------------------------------------

;Save preset to the EEPROM:

SaveP:	lds	temp,Buff+0	;temp = preset number
	tst	temp
	brne	svp

	push	temp
	ldy	EValFS
	ldz	ValFS
	rcall	EE_Wr3		;save ValFS
	pop	temp

svp:	rcall	EE_PrA		;YH:YL = EEPROM address
	ldz	ValF
	rcall	EE_Wr3		;save preset
	rcall	Melody		;melody
	ret

;----------------------------------------------------------------------------

;Make EEPROM preset address:
;Input: temp - preset number
;Out:   YH:YL - EEPROM address

EE_PrA:	ldy	EPres
	mov	tempL,temp
	add	temp,tempL
	add	temp,tempL
	clr	tempL
	add	YL,temp
	adc	YH,tempL
	ret

;----------------------------------------------------------------------------

;Read 3 bytes from the EEPROM:
;Input: YH:YL = EEPROM address
;	ZH:ZL = RAM address

EE_Rd3:	ldi	Cnt,3
rdn:	rcall	EE_Rd		;temp = EEPROM data byte
	st	Z+,temp		;save data byte
	adiw	YH:YL,1		;EEPROM address inc
	dec	Cnt
	brne	rdn
	ret

;----------------------------------------------------------------------------

;Wait for EEPROM ready and read EEPROM:
;Input: YH:YL - address
;Out:   temp - data

EE_Rd:	wdr			;watchdog restart
	sbic	EECR,EEWE
	rjmp	EE_Rd		;wait for EEPROM ready
	out	EEARL,YL	;EEPROM address low
	out	EEARH,YH	;EEPROM address high
	sbi	EECR,EERE	;strobe
	in	temp,EEDR	;read EEPROM
	clr	tempL
	out	EEARL,tempL	;EEPROM address = 0
	out	EEARH,tempL
	ret

;----------------------------------------------------------------------------

;Write 3 bytes to the EEPROM:
;Input: YH:YL = EEPROM address
;	ZH:ZL = RAM address

EE_Wr3:	ldi	Cnt,3
wrn:	rcall	EE_Rd
	mov	tempL,temp	;tempL = EEPROM data byte
	ld	temp,Z+		;temp = RAM data byte
	cp	temp,tempL
	breq	wrs		;skip write if temp == tempL
	rcall	EE_Wr		;write data byte to the EEPROM
wrs:	adiw	YH:YL,1		;EEPROM address inc
	dec	Cnt
	brne	wrn
	ret

;----------------------------------------------------------------------------

;Write EEPROM:
;Input: YH:YL - address
;	temp - data

EE_Wr:	out	EEARL,YL	;EEPROM address low
	out	EEARH,YH	;EEPROM address high
	out	EEDR,temp	;load data
	in	tempL,SREG
	cli			;interrupts disable
	sbi 	EECR,EEMWE	;master write enable
	sbi	EECR,EEWE	;strobe
	out	SREG,tempL	;interrupts enable
	clr	tempL
	out	EEARL,tempL	;EEPROM address = 0
	out	EEARH,tempL
	ret

;----------------------------------------------------------------------------

;Initial EEPROM values:

FCalib:	.dw byte1(C_0)
	.dw byte2(C_0)
	.dw byte3(C_0)

FValFS:	.dw byte1(STEP_0)
	.dw byte2(STEP_0)
	.dw byte3(STEP_0)

FPres:	.dw byte1(FREQ_0)
	.dw byte2(FREQ_0)
	.dw byte3(FREQ_0)

	.dw byte1(FREQ_1)
	.dw byte2(FREQ_1)
	.dw byte3(FREQ_1)

	.dw byte1(FREQ_2)
	.dw byte2(FREQ_2)
	.dw byte3(FREQ_2)

	.dw byte1(FREQ_3)
	.dw byte2(FREQ_3)
	.dw byte3(FREQ_3)

	.dw byte1(FREQ_4)
	.dw byte2(FREQ_4)
	.dw byte3(FREQ_4)

	.dw byte1(FREQ_5)
	.dw byte2(FREQ_5)
	.dw byte3(FREQ_5)

	.dw byte1(FREQ_6)
	.dw byte2(FREQ_6)
	.dw byte3(FREQ_6)

	.dw byte1(FREQ_7)
	.dw byte2(FREQ_7)
	.dw byte3(FREQ_7)

	.dw byte1(FREQ_8)
	.dw byte2(FREQ_8)
	.dw byte3(FREQ_8)

	.dw byte1(FREQ_9)
	.dw byte2(FREQ_9)
	.dw byte3(FREQ_9)

FSign:	.dw SIGN

;----------------------------------------------------------------------------
