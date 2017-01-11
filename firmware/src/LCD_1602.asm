;----------------------------------------------------------------------------

;LCD support module
;Used LCD - WH1602S + 74HC164

;Connections:
;LOAD -> E LCD
;DATA -> pin 2 74HC164
;CLK  -> pin 8 74HC164

.include "wait.asm"

;----------------------------------------------------------------------------

;Constantes:

.equ	Pt	= 0x80		;point in Dig

;----------------------------------------------------------------------------

.DSEG	;data segment (internal SRAM)

Dig:	.byte 16		;display data (string copy)

;Font:	.byte 18		;RAM copy of display font table
;StrT:	.byte 12		;RAM copy of string table
;ShpT:	.byte 6			;RAM copy of shape menu string table

;----------------------------------------------------------------------------

.CSEG	;Code segment

;----------------------------------------------------------------------------

;Init display:

;iDisp:	ldi	temp,0x0F	;temp <- BLK register address
;	rcall	LCD_WA		;write address
;	ldi	temp,0x0F	;temp <- 0x0F - enable bus
;	rcall	LCD_WN		;write nibble
;	ldi	temp,BLANK	;load char
;	rcall	Fill		;fill Dig
;	rcall	Disp		;blank display
;	ret

iDisp:	Port_LOAD_0;        ;E <- 0
		ldi	   r16, 15
  		rcall	 WaitMiliseconds
		ldi	temp,0x30		;LCD_WrCmd(0x30);
		rcall LCD_CMD
		ldi	   r16, 5 		;delay >4.1 ms 	
  		rcall	 WaitMiliseconds 
		ldi	temp,0x30		;LCD_WrCmd(0x30);
		rcall	LCD_CMD
		ldi	   r16, 150
  		rcall	 WaitMiliseconds	;delay >100 us
		ldi	temp,0x30		;LCD_WrCmd(0x30);
		rcall	LCD_CMD
		ldi	   r16, 5 		;delay >4.1 ms 	
  		rcall	 WaitMiliseconds 
		ldi	temp,0x20		;LCD_WrCmd(0x20);     //FUNCTION SET (8 bit)
		rcall	LCD_CMD
		ldi	   r16, 15
  		rcall	 WaitMiliseconds
		ldi	temp,0x28		;LCD_WrCmd(0x28);     //FUNCTION SET (4 bit)
		rcall	LCD_CMD
		ldi	   	r16, 15
  		rcall	 WaitMiliseconds
		ldi	temp,0x06		;LCD_WrCmd(0x06);     //ENTRY MODE SET
		rcall	LCD_CMD
		ldi	   r16, 15
  		rcall	 WaitMiliseconds
		ldi	temp,0x23		;load char
		rcall	Fill		;fill Dig
		rcall	Disp		;blank display LCD_Clear();         //CLEAR 
		ldi	   r16, 15
  		rcall	 WaitMiliseconds
		ldi	temp,0x0C		;LCD_WrCmd(0x0C);     //DISPLAY ON
		rcall	LCD_CMD
		ldi	   r16, 15
  		rcall	 WaitMiliseconds
		ret

;----------------------------------------------------------------------------

;Update display:

mDisp:	bbrc	Flags,UPDD,NoUpd ;check up update flag
	clbr	Flags,UPDD	 ;clear update flag
	rcall	Disp		 ;update display
NoUpd:	ret

;----------------------------------------------------------------------------

;Fill Dig[0..9] with char from temp:

Fill:	ldy	Dig
	ldi	Cnt,10
fill1:	st	Y+,temp
	dec	Cnt
	brne	fill1
	ret		

;----------------------------------------------------------------------------

;tempH:tempM:tempL convert to BCD Dig[3..9]
	
DisBCD:	ldy	Dig+3
	clr	temp
	ldi	Cnt,7
clrout: st	Y+,temp		;output array clear
	dec	Cnt
	brne	clrout		

	ldi	Cnt,24		;input bits count
	ldz	Dig+3
hloop:	lsl	tempL		;input array shift left
	rol	tempM
	rol	tempH		
	ldy	Dig+10
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

	ldz	Dig+7
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

	ldy	Dig+5
	cp	ZL,YL
	cpc	ZH,YH
	ldy	Dig+4
	brlo	setpo
	ldy	Dig+7
setpo:	ld	temp,Y
	ori	temp,Pt
	st	Y,temp		;setup point at Dig+4 or Dig+7
	ret	

;----------------------------------------------------------------------------

;Indicate Dig[0..9] on LCD:
	
Disp:	ldy		Dig			;pointer to Dig
		ldi		Cnt,16
disp1:	ld		temp,Y+		;temp <- digit
		rcall	LCD_DATA		;write nibble from temp to LCD
		dec		Cnt
		brne	disp1		;repeat for all digits
		ret	

;----------------------------------------------------------------------------
LCD_CMD: push temp
		 swap temp
		 rcall	LCD_WA
		 pop temp
		 rcall	LCD_WA
		 ret

LCD_DATA: push temp
		  swap temp
		  rcall	LCD_WN
		  pop temp
		  rcall	LCD_WN
		  ret

;Write nibble from temp to LCD:

LCD_WN:	andi	temp,0x0F	;mask unused bits
		ori		temp,0x10	;address = 1
		rjmp	w5

;Write address from temp to LCD:

LCD_WA:	andi	temp,0x0F	;mask unused bits

w5:		push	Cnt
		ldi		Cnt,5		;write 5 bits to LCD
w5_cyc:	Port_CLK_0			;CLK <- 0
		Port_DATA_0			;DATA <- 0 or..
		bbrc	temp,4,w5_0
		Port_DATA_1			;DATA <- 1
w5_0:	rol		temp
		dec		Cnt
		Port_CLK_1			;CLK <- 1
		brne	w5_cyc
		Port_LOAD_1			;E <- 1
		Port_DATA_1
		push temp
		ldi	   r16, 5
  		rcall	WaitMiliseconds
		pop temp
		Port_LOAD_0			;E <- 0
		pop		Cnt
		ret

;----------------------------------------------------------------------------

;Font table:

FONT:	     ;FCBHADEG    FCBHADEG
	.DB 0b11101110, 0b01100000	;0, 1
	.DB 0b00101111, 0b01101101	;2, 3
	.DB 0b11100001, 0b11001101	;4, 5
	.DB 0b11001111, 0b01101000	;6, 7
	.DB 0b11101111, 0b11101101	;8, 9
	.DB 0b11101011, 0b11000111	;A, b
	.DB 0b10001110, 0b01100111	;C, d
	.DB 0b10001111, 0b10001011	;E, F
	.DB 0b00000000, 0b00000001	;blank, -
	.DB 0b00000100, 0b00001000	;_, ~
	.DB 0b10101001, 0b00000111	;degree, c
	.DB 0b11001110, 0b11100011	;G, H
	.DB 0b01100000, 0b10000110	;I, L
	.DB 0b00000010, 0b01000011	;i, n
	.DB 0b01000111, 0b10101011	;o, P
	.DB 0b10001010, 0b00000011	;R, r
	.DB 0b10000111, 0b11100110	;t, U
	.DB 0b01000110, 0b11100101	;u, Y
	.DB 0b10000110, 0b10001010	;|_, |~

.equ	H	= 4			;point

;----------------------------------------------------------------------------

;Characters codes table:

.equ	BLANK	=0x10		;character "blank" code
.equ	i_	=0x10		;character "blank" code
.equ	iMIN	=0x11		;character "-" code
.equ	iLL	=0x12		;character "lower -" code
.equ	iHH	=0x13		;character "upper -" code
.equ	iHL	=0x24		;character "|_" code
.equ	iLH	=0x25		;character "|~" code
.equ	iDEG	=0x14		;character "degree" code
.equ	iA	=0x0A		;character "A" code
.equ	iB	=0x0B		;character "b" code
.equ	iC	=0x0C		;character "C" code
.equ	iiC	=0x15		;character "c" code
.equ	iD	=0x0D		;character "d" code
.equ	iE	=0x0E		;character "E" code
.equ	iF	=0x0F		;character "F" code
.equ	iG	=0x16		;character "G" code
.equ	iH	=0x17		;character "H" code
.equ	iI	=0x18		;character "I" code
.equ	iL	=0x19		;character "L" code
.equ	iii	=0x1A		;character "i" code
.equ	iiN	=0x1B		;character "n" code
.equ	iO	=0x00		;character "O" code
.equ	iiO	=0x1C		;character "o" code
.equ	iP	=0x1D		;character "P" code
.equ	iR	=0x1E		;character "R" code
.equ	iiR	=0x1F		;character "r" code
.equ	iS	=0x05		;character "S" code
.equ	iT	=0x20		;character "t" code
.equ	iU	=0x21		;character "U" code
.equ	iiU	=0x22		;character "u" code
.equ	iY	=0x23		;character "Y" code

;----------------------------------------------------------------------------
