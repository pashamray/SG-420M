;----------------------------------------------------------------------------

;LCD support module
;Used LCD - WH1602S + 74HC164

;Connections:
;LOAD -> E LCD
;DATA -> pin 2 74HC164
;CLK  -> pin 8 74HC164

;----------------------------------------------------------------------------

;Constantes:

.equ	Pt	 = 0x80		;point in Dig
.equ	Coma = 0x70		;point in Dig
.equ	Lcd_cols = 16	;
.equ	Lcd_rows = 2	;
.equ	Lcd_bytes = 32
;----------------------------------------------------------------------------

.DSEG	;data segment (internal SRAM)

Dig:	.byte Lcd_bytes	;display data (string copy)

;----------------------------------------------------------------------------

.CSEG	;Code segment

;----------------------------------------------------------------------------

;Init display:

;iDisp:		ldi	temp,0x0F	;temp <- BLK register address
;			rcall	LCD_WA		;write address
;			ldi	temp,0x0F	;temp <- 0x0F - enable bus
;			rcall	LCD_WN		;write nibble
;			ldi	temp,BLANK	;load char
;			rcall	Fill		;fill Dig
;			rcall	Disp		;blank display
;			ret

iDisp:
      Port_LOAD_0;        ;E <- 0
      ldi	  Cnt,15
    	rcall	mDel
			ldi		temp,0x30		; FUNCTION SET (8 bit)
			rcall	LCD_WA
      ldi	  Cnt,15
    	rcall	mDel		;delay >4.1mS
			ldi		temp,0x30		; FUNCTION SET (8 bit)
			rcall	LCD_WA
      ldi	  Cnt,15
    	rcall	mDel
			ldi		temp,0x30		; FUNCTION SET (8 bit)
			rcall	LCD_WA
      ldi	  Cnt,15
    	rcall	mDel
			ldi		temp,0x20		; FUNCTION SET (4 bit)
			rcall	LCD_WA
      ldi	  Cnt,15
    	rcall	mDel
			ldi		temp,0x28		;FUNCTION SET (4 bit)
			rcall	LCD_CMD
      ldi	  Cnt,20
    	rcall	mDel
			ldi		temp,0x06		; entry mode
			rcall	LCD_CMD
      ldi	  Cnt,25
    	rcall	mDel
			ldi		temp,0x01		; clear display
			rcall	LCD_CMD
      ldi	  Cnt,25
    	rcall	mDel
			ldi		temp,0x0C		; display on
			rcall	LCD_CMD
      ldi	  Cnt,25
    	rcall	mDel
			ret

;----------------------------------------------------------------------------

;Update display:

mDisp:
		bbrc	Flags,UPDD,NoUpd ;check up update flag
		clbr	Flags,UPDD	 ;clear update flag
		rcall	Disp		 ;update display
NoUpd:
		ret

;----------------------------------------------------------------------------

;Fill display with char from temp:

Fill:
		ldy		Dig
		ldi		Cnt,Lcd_bytes
fill1:
		st		Y+,temp
		dec		Cnt
		brne	fill1
		ret

;----------------------------------------------------------------------------

;tempH:tempM:tempL convert to BCD Dig[5..12]

DisBCD:
  ldy	  Dig+Lcd_cols+0
	clr	  temp
	ldi	  Cnt,7
clrout:
  st	  Y+,temp		;output array clear
	dec	  Cnt
	brne	clrout

	ldi	  Cnt,24		;input bits count
	ldz	  Dig+Lcd_cols+0
hloop:
  lsl   tempL		;input array shift left
	rol	  tempM
	rol	  tempH
	ldy	  Dig+Lcd_cols+7
sloop:
  ld	  temp,-Y
	rol	  temp
	subi	temp,-0x06 ;temp+6, C=1
	sbrs	temp,4
	subi	temp,0x06	 ;temp-6, C=0
	andi	temp,0x0f
  st	  Y,temp
	cpse	YL,ZL		   ;ZH:ZL = Dig+3
	rjmp	sloop
	cpse	YH,ZH
	rjmp	sloop
	dec	  Cnt		     ;YH:YL = Dig+3
	brne	hloop
  ;ret

;Supress zeros:
	ldz	  Dig+Lcd_cols+4
	ldi	  tempL,BLANK
zsp:
  ld    temp,Y
	tst   temp
	brne  notz
	st    Y+,tempL	;suppress zero
	cp    YL,ZL
	brne  zsp
	cp    YH,ZH
	brne	zsp
notz:
  movw	ZH:ZL,YH:YL	;ZH:ZL points to first non-zero digit

;Setup point:
	ldy	Dig+Lcd_cols+2
	cp	ZL,YL
	cpc	ZH,YH
	ldy	Dig+Lcd_cols+1
	brlo	setpo
	ldy	Dig+Lcd_cols+4
setpo:
  ld	temp,Y
	ori	temp,Pt
	st	Y,temp		;setup point at Dig+4 or Dig+7
	ret

;----------------------------------------------------------------------------

;Indicate Dig[0..9] on LCD:

Disp:
		ldi		temp,0x80		;temp home  address
		rcall	LCD_CMD			;write address
		ldy		Dig				  ;pointer to Dig
		ldi		Cnt,Lcd_bytes
disp_loop:
    clt
		ld		temp,Y+			;temp <- digit
    bst	  temp,7	    ;T <- temp.7 (point)
    andi	temp,0x7F	  ;temp.7 <- 0
    cpi   temp,0x0A
    brge  skip_shift
    subi	temp,-0x30   ;shift address table for numbers hd44780
skip_shift:
		push	temp			  ;save byte
		swap	temp
		rcall	LCD_WN			;write nibble from temp to LCD
		pop		temp			;restore byte
		rcall	LCD_WN			;write nibble from temp to LCD
    brtc  skip_dot
    ldi   temp,DOT
    push	temp			  ;save byte
    swap	temp
    rcall	LCD_WN			;write nibble from temp to LCD
    pop		temp			;restore byte
    rcall	LCD_WN			;write nibble from temp to LCD
skip_dot:
		dec		Cnt
		cpi		Cnt,0			;all bytes is out
		breq	disp_ret
		cpi		Cnt,Lcd_cols	;1 line is full
		brne	disp_loop
		ldi		temp,0xC0		;temp 2 line address
		rcall	LCD_CMD			;write address
		rjmp	disp_loop
disp_ret:
		ret

;----------------------------------------------------------------------------
LCD_CMD:
      push	temp
			rcall	LCD_WA		; first HIGH bits
			pop		temp
			swap	temp 		; second LOW bits
  		nop
   		nop
      nop
      rcall	LCD_WA
			ret

LCD_DATA:
      push	temp
      swap	temp
      rcall	LCD_WN		; first HIGH bits
			pop		temp
      ldi	  Cnt,5
    	rcall	uDel
			rcall	LCD_WN		; second LOW bits
			ret

;Write nibble from temp to LCD:

LCD_WN:
      andi	temp,0x0F	;mask unused bits
			ori		temp,0x10	;address = 1
			rjmp	w5

;Write address from temp to LCD:

LCD_WA:
      swap	temp 		  ;first HIGH bits
			andi	temp,0x0F	;mask unused bits
w5:
      push   Cnt
			ldi    Cnt,5		;write 5 bits to LCD
w5_cyc:
  		Port_CLK_0			;CLK <- 0
			Port_DATA_0			;DATA <- 0 or..
			bbrc   temp,4,w5_0
			Port_DATA_1			;DATA <- 1
w5_0:
  		rol   temp
			dec  Cnt
			Port_CLK_1			;CLK <- 1
			brne   w5_cyc
			Port_LOAD_1			;E <- 1
			Port_DATA_1
      ldi	  Cnt,50
    	rcall	uDel
			Port_LOAD_0			;E <- 0
			pop    Cnt
			ret

;----------------------------------------------------------------------------
;Delay:
;Cnt - delay value, uS (2uS min)
;CAUTION! Timed code!

uDel:	dec	Cnt
	nop
;	nop
;	nop
De:	dec	Cnt
;	nop
;	nop
;	nop
;	nop
	brne	De
	ret

;----------------------------------------------------------------------------

;Delay:
;Cnt - delay value, mS

mDel:	push	YL
	push	YH
	mov	YH,Cnt
md2:	ldi	YL,5		;outer loop, 1mS
md1:	ldi	Cnt,200		;inner loop, 200uS
	rcall	uDel
	dec	YL
	brne	md1
	rcall	mWdog		;restart watchdogs
	dec	YH
	brne	md2
	pop	YH
	pop	YL
	ret

;----------------------------------------------------------------------------

; Strings table

StrFreq:
    .db "Frequency", 0
StrkHz:
    .db "Hz"
StrStep:
    .db "step"
StrMode:
	.db "Output"
StrPre:
  .db "preset"
StrRead:
  .db "Read"
StrSave:
  .db "Save"
;----------------------------------------------------------------------------

.equ	H	= 4			;point

;----------------------------------------------------------------------------

;Characters codes table:
.equ  COM       = ','
.equ	DOT	  	  = '.'	;character "." code
.equ	BLANK 	  = ' '	;character "blank" code

;----------------------------------------------------------------------------
