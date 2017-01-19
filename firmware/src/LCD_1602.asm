;----------------------------------------------------------------------------

;LCD support module
;Used LCD - WH1602S + 74HC164

;Connections:
;LOAD -> E LCD
;DATA -> pin 2 74HC164
;CLK  -> pin 8 74HC164

;----------------------------------------------------------------------------

.include "wait.asm"

;----------------------------------------------------------------------------

;Constantes:

.equ	Pt	= 0x80		;point in Dig
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
			ldi		temp, 15
			rcall	WaitMiliseconds
			ldi		temp,0x30		; FUNCTION SET (8 bit)
			rcall	LCD_WA
			ldi		temp, 15 		;delay >4.1 ms 	
			rcall	WaitMiliseconds 
			ldi		temp,0x30		; FUNCTION SET (8 bit)
			rcall	LCD_WA
			ldi		temp, 15
			rcall	WaitMiliseconds	;delay >100 us
			ldi		temp,0x30		; FUNCTION SET (8 bit)
			rcall	LCD_WA
			ldi		temp, 15 		;delay >4.1 ms 	
			rcall	WaitMiliseconds 
			ldi		temp,0x20		; FUNCTION SET (4 bit)
			rcall	LCD_WA
			ldi		temp, 15 		;delay >4.1 ms 	
			rcall	WaitMiliseconds 
			ldi		temp,0x28		;FUNCTION SET (4 bit)
			rcall	LCD_CMD
			ldi		temp, 20
			rcall	WaitMiliseconds
			ldi		temp,0x06		; entry mode
			rcall	LCD_CMD
			ldi		temp, 25
			rcall	WaitMiliseconds
			ldi		temp,0x01		; clear display
			rcall	LCD_CMD
			ldi		temp, 25
			rcall	WaitMiliseconds
			ldi		temp,0x0C		; display on
			rcall	LCD_CMD
			ldi		temp, 25 
			rcall	WaitMiliseconds
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

;tempH:tempM:tempL convert to BCD Dig[3..9]
	
DisBCD:	ldy	Dig+Lcd_cols
	clr	temp
	ldi	Cnt,7
clrout: st	Y+,temp		;output array clear
	dec	Cnt
	brne	clrout		

	ldi	Cnt,24		;input bits count
	ldz	Dig+Lcd_cols
hloop:	lsl	tempL		;input array shift left
	rol	tempM
	rol	tempH		
	ldy	Dig+Lcd_cols+7
sloop:	ld	temp,-Y
	rol	temp
	subi	temp,-0x06	;temp+6, C=1
	sbrs	temp,4
	subi	temp,0x06	;temp-6, C=0
	andi	temp,0x0f
	st	Y,temp
	cpse	YL,ZL		;ZH:ZL = Dig+3
	rjmp	sloop
	cpse	YH,ZH
	rjmp	sloop
	dec	Cnt		;YH:YL = Dig+3
	brne	hloop

;Supress zeros:

	ldz	Dig+Lcd_cols+4
	ldi	tempL,BLANK
zsp:	ld	temp,Y
	tst	temp
	brne	notz
	st	Y+,tempL	;suppress zero
	cp	YL,ZL
	brne	zsp
	cp	YH,ZH
	brne	zsp
notz:	movw	ZH:ZL,YH:YL	;ZH:ZL points to first non-zero digit
	
;Setup point:

	ldy	Dig+Lcd_cols+2
	cp	ZL,YL
	cpc	ZH,YH
	ldy	Dig+Lcd_cols+1
	brlo	setpo
	ldy	Dig+Lcd_cols+4
setpo:	
	ld	temp,Y+
	ldi	temp,DOT
	st	Y,temp		;setup point at Dig+4 or Dig+7
	ret	

;----------------------------------------------------------------------------

;Indicate Dig[0..9] on LCD:
	
Disp:	
		ldi		temp,0x80		;temp home  address
		rcall	LCD_CMD			;write address
		ldy		Dig				;pointer to Dig
		ldi		Cnt,Lcd_bytes
disp_loop:	
		ld		temp,Y+			;temp <- digit
		table	FONT			;pointer to FONT
		add		ZL,temp			;ZH:ZL = ZH:ZL + temp
		adc		ZH,temp
		sub		ZH,temp
		lpm		temp,Z			;read font table
		push	temp			;save byte
		swap	temp
		rcall	LCD_WN			;write nibble from temp to LCD
		pop		temp			;restore byte
		rcall	LCD_WN			;write nibble from temp to LCD
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
  		nop
      nop
      nop
      nop
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
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
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
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
      nop
			Port_LOAD_0			;E <- 0
			pop    Cnt
			ret

;----------------------------------------------------------------------------

; Strings table

StrFreq:
    .db _iF, _iiR, _iiE, _iiQ, _iiU, _iiE, _iiN, _iiC, _iiY, '\0'
StrkHz:
    .db _iiK, _iH, _iiZ, '\0'
StrStep:
    .db _iiS, _iiT, _iiE, _iiP
StrMode:
	.db _iM, _iiO, _iiD, _iiE

;----------------------------------------------------------------------------

;Font table:

FONT:
	.DB '0', '1'
	.DB '2', '3'
	.DB '4', '5'
	.DB '6', '7'
	.DB '8', '9'
	.DB 'A', 'a'	; 0x0A, 0x0B
	.DB 'B', 'b'	; 0x0C, 0x0D
	.DB 'C', 'c'	; 0x0E, 0x0F
	.DB 'D', 'd'	; 0x10, 0x11
	.DB 'E', 'e'	; 0x12, 0x13
	.DB 'F', 'f'	; 0x14, 0x15
	.DB 'G', 'g'	; 0x16, 0x17
	.DB 'H', 'h'	; 0x18, 0x19
	.DB 'I', 'i'	; 0x1A, 0x1B
	.DB 'J', 'j'	; 0x1C, 0x1D
	.DB 'K', 'k'	; 0x1E, 0x1F
	.DB 'L', 'l'	; 0x20, 0x21
	.DB 'M', 'm'	; 0x22, 0x23
	.DB 'N', 'n'	; 0x24, 0x25
	.DB 'O', 'o'	; 0x26, 0x27
	.DB 'P', 'p'	; 0x28, 0x29
	.DB 'Q', 'q'	; 0x2A, 0x2B
	.DB 'R', 'r'	; 0x2C, 0x2D
	.DB 'S', 's'	; 0x2E, 0x2F
	.DB 'T', 't'	; 0x30, 0x31
	.DB 'U', 'u'	; 0x32, 0x33
	.DB 'V', 'v'	; 0x34, 0x35
	.DB 'W', 'w'	; 0x36, 0x37
	.DB 'X', 'x'	; 0x38, 0x39
	.DB 'Y', 'y'	; 0x3A, 0x3B
	.DB 'Z', 'z'	; 0x3C, 0x3D
	.DB '.', ' '	; 0x3E, 0x3F

.equ	H	= 4			;point

;----------------------------------------------------------------------------

;Characters codes table:

.equ	_iA 	  = 0x0A	;character "A" code
.equ	_iiA	  = 0x0B	;character "a" code
.equ	_iB 	  = 0x0C	;character "B" code
.equ	_iiB	  = 0x0D	;character "b" code
.equ	_iC 	  = 0x0E	;character "C" code
.equ	_iiC	  = 0x0F	;character "c" code
.equ	_iD 	  = 0x10	;character "D" code
.equ	_iiD	  = 0x11	;character "d" code
.equ	_iE 	  = 0x12	;character "E" code
.equ	_iiE	  = 0x13	;character "e" code
.equ	_iF 	  = 0x14	;character "F" code
.equ	_iiF	  = 0x15	;character "f" code
.equ	_iG 	  = 0x16	;character "G" code
.equ	_iiG	  = 0x17	;character "g" code
.equ	_iH 	  = 0x18	;character "H" code
.equ	_iiH	  = 0x19	;character "h" code
.equ	_iI 	  = 0x1A	;character "I" code
.equ	_iiI	  = 0x1B	;character "i" code
.equ	_iJ 	  = 0x1C	;character "J" code
.equ	_iiJ	  = 0x1D	;character "j" code
.equ	_iK 	  = 0x1E	;character "K" code
.equ	_iiK	  = 0x1F	;character "k" code
.equ	_iL 	  = 0x20	;character "L" code
.equ	_iiL	  = 0x21	;character "l" code
.equ	_iM 	  = 0x22	;character "M" code
.equ	_iiM	  = 0x23	;character "m" code
.equ	_iN 	  = 0x24	;character "N" code
.equ	_iiN	  = 0x25	;character "n" code
.equ	_iO 	  = 0x26	;character "O" code
.equ	_iiO	  = 0x27	;character "o" code
.equ	_iP 	  = 0x28	;character "P" code
.equ	_iiP	  = 0x29	;character "p" code
.equ	_iQ 	  = 0x2A	;character "Q" code
.equ	_iiQ	  = 0x2B	;character "q" code
.equ	_iR 	  = 0x2C	;character "R" code
.equ	_iiR	  = 0x2D	;character "r" code
.equ	_iS 	  = 0x2E	;character "S" code
.equ	_iiS	  = 0x2F	;character "s" code
.equ	_iT 	  = 0x30	;character "T" code
.equ	_iiT	  = 0x31	;character "t" code
.equ	_iU 	  = 0x32	;character "U" code
.equ	_iiU	  = 0x33	;character "u" code
.equ	_iV 	  = 0x34	;character "V" code
.equ	_iiV	  = 0x35	;character "v" code
.equ	_iW 	  = 0x36	;character "W" code
.equ	_iiW	  = 0x37	;character "w" code
.equ	_iX 	  = 0x38	;character "X" code
.equ	_iiX	  = 0x39	;character "x" code
.equ	_iY 	  = 0x3A	;character "Y" code
.equ	_iiY	  = 0x3B	;character "y" code
.equ	_iZ 	  = 0x3C	;character "Z" code
.equ	_iiZ	  = 0x3D	;character "z" code
.equ	DOT	  	  = 0x3E	;character "." code
.equ	BLANK 	  = 0x3F	;character "blank" code

;----------------------------------------------------------------------------
