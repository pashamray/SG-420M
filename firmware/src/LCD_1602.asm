;----------------------------------------------------------------------------

;LCD support module
;Used LCD - WH1602S + 74HC164

;Connections:
;LOAD -> E LCD
;DATA -> pin 2 74HC164
;CLK  -> pin 8 74HC164

;----------------------------------------------------------------------------

;Constantes:

.equ	Pt	= 0x80		;point in Dig
.equ	LCD_COLS = 16	;
.equ	LCD_ROWS = 2	;
.equ	LCD_BYTES = LCD_COLS * LCD_ROWS
;----------------------------------------------------------------------------

.DSEG	;data segment (internal SRAM)

Dig:	.byte LCD_BYTES	;display data (string copy)

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

iDisp:		Port_LOAD_0;        ;E <- 0
			ldi		temp, 15
  			rcall	WaitMiliseconds
			ldi		temp,0x30		; FUNCTION SET (8 bit)
			rcall	LCD_CMD
			ldi		temp, 5 		;delay >4.1 ms 	
  			rcall	WaitMiliseconds 
			ldi		temp,0x30		; FUNCTION SET (8 bit)
			rcall	LCD_CMD
			ldi		temp, 1
  			rcall	WaitMiliseconds	;delay >100 us
			ldi		temp,0x30		; FUNCTION SET (8 bit)
			rcall	LCD_CMD
			ldi		temp, 5 		;delay >4.1 ms 	
  			rcall	WaitMiliseconds 
			ldi		temp,0x20		; FUNCTION SET (4 bit)
			rcall	LCD_CMD
			ldi		temp, 5 		;delay >4.1 ms 	
  			rcall	WaitMiliseconds 
			ldi		temp,0x20		;FUNCTION SET (4 bit)
			rcall	LCD_CMD
			ldi		temp, 5 		;delay >4.1 ms 	
  			rcall	WaitMiliseconds 
			ldi		temp,0x80		;FUNCTION SET (4 bit)
			rcall	LCD_CMD
			ldi		temp, 1
  			rcall	WaitMiliseconds
			ldi		temp,0x00		; display on
			rcall	LCD_CMD
			ldi		temp, 1
  			rcall	WaitMiliseconds
			ldi		temp,0xC0		; display on
			rcall	LCD_CMD
			ldi		temp, 1
  			rcall	WaitMiliseconds
			ldi		temp,0x00		; entry mode
			rcall	LCD_CMD
			ldi		temp, 1
  			rcall	WaitMiliseconds
			ldi		temp,0x60		; entry mode
			rcall	LCD_CMD
			ldi		temp, 1
  			rcall	WaitMiliseconds
			ldi		temp,0x00		; entry mode
			rcall	LCD_CMD
			ldi		temp, 1
  			rcall	WaitMiliseconds
			ldi		temp,0x01		; clear display
			rcall	LCD_CMD
			ldi		temp, 1 
  			rcall	WaitMiliseconds
			ldi		temp,BLANK		;load char
			rcall	Fill			;fill Dig
			rcall	Disp			;
			ldi		temp, 1
  			rcall	WaitMiliseconds
			ret

;----------------------------------------------------------------------------

;Update display:

mDisp:		bbrc	Flags,UPDD,NoUpd ;check up update flag
			clbr	Flags,UPDD	 ;clear update flag
			rcall	Disp		 ;update display
NoUpd:		ret

;----------------------------------------------------------------------------

;Fill display with char from temp:

Fill:		ldy		Dig
			ldi		Cnt,LCD_BYTES
fill1:		st		Y+,temp
			dec		Cnt
			brne	fill1
			ret

;----------------------------------------------------------------------------

;tempH:tempM:tempL convert to BCD Dig[3..9]
	
DisBCD:		ldy		Dig+3
			clr		temp
			ldi		Cnt,7
clrout: 	st		Y+,temp		;output array clear
			dec		Cnt
			brne	clrout		

			ldi		Cnt,24		;input bits count
			ldz		Dig+3
hloop:		lsl		tempL		;input array shift left
			rol		tempM
			rol		tempH		
			ldy		Dig+10
sloop:		ld		temp,-Y
			rol		temp
			subi	temp,-0x06	;temp+6, C=1
			sbrs	temp,4
			subi	temp,0x06	;temp-6, C=0
			andi	temp,0x0f
			st		Y,temp
			cpse	YL,ZL		;ZH:ZL = Dig+3
			rjmp	sloop
			cpse	YH,ZH
			rjmp	sloop
			dec		Cnt		;YH:YL = Dig+3
			brne	hloop

;Supress zeros:

			ldz		Dig+7
			ldi		tempL,BLANK
zsp:		ld		temp,Y
			tst		temp
			brne	notz
			st		Y+,tempL	;suppress zero
			cp		YL,ZL
			brne	zsp
			cp		YH,ZH
			brne	zsp
notz:		movw	ZH:ZL,YH:YL	;ZH:ZL points to first non-zero digit
	
;Setup point:

			ldy		Dig+5
			cp		ZL,YL
			cpc		ZH,YH
			ldy		Dig+4
			brlo	setpo
			ldy		Dig+7
setpo:		ld		temp,Y
			ori		temp,Pt
			st		Y,temp		;setup point at Dig+4 or Dig+7
			ret	

;----------------------------------------------------------------------------

;Indicate Dig[0..9] on LCD:
	
Disp:		ldy		Dig			;pointer to Dig
			ldi		Cnt,16
disp1:		ld		temp,Y+		;temp <- digit
			rcall	LCD_DATA
			dec		Cnt
			brne	disp1		;repeat for all digits
			ret	
;disp1:		ld		temp,Y+		;temp <- digit
;			;bst		temp,7		;T <- temp.7 (point)
;			andi	temp,0x7F	;temp.7 <- 0
;			;table	FONT		;pointer to FONT
;			add		ZL,temp		;ZH:ZL = ZH:ZL + temp
;			adc		ZH,temp
;			sub		ZH,temp
;			;lpm		temp,Z		;read font table
;			push	temp		;save byte
;			swap	temp
;			rcall	LCD_WN		;write nibble from temp to LCD
;			pop		temp		;restore byte
;			;bld		temp,H	;H - point
;			rcall	LCD_WN		;write nibble from temp to LCD
;			dec		Cnt
;			brne	disp1		;repeat for all digits
;			ret	

;----------------------------------------------------------------------------
LCD_CMD:	push	temp
			swap	temp
			rcall	LCD_WA		; first HIGH bits
			pop		temp
			;rcall	LCD_WA		; second LOW bits
			ret

LCD_DATA:	push	temp
			swap	temp
			rcall	LCD_WN		; first HIGH bits
			pop		temp
			rcall	LCD_WN		; second LOW bits
			ret

;Write nibble from temp to LCD:

LCD_WN:		andi	temp,0x0F	;mask unused bits
			ori		temp,0x10	;address = 1
			rjmp	w5

;Write address from temp to LCD:

LCD_WA:		andi	temp,0x0F	;mask unused bits

w5:			push	Cnt
			ldi		Cnt,5		;write 5 bits to LCD
w5_cyc:		Port_CLK_0			;CLK <- 0
			Port_DATA_0			;DATA <- 0 or..
			bbrc	temp,4,w5_0
			Port_DATA_1			;DATA <- 1
w5_0:		rol		temp
			dec		Cnt
			Port_CLK_1			;CLK <- 1
			brne	w5_cyc
			Port_LOAD_1			;E <- 1
			Port_DATA_1
			push 	temp
			ldi	   	temp, 1
  			rcall	WaitMiliseconds
  			pop 	temp
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

.equ	BLANK=' '		;character "blank" code
.equ	i_	=' '		;character "blank" code
.equ	iMIN='-'		;character "-" code
.equ	iLL	='_'		;character "lower -" code
.equ	iHH	='-'		;character "upper -" code
.equ	iHL	='_'		;character "|_" code
.equ	iLH	='~'		;character "|~" code
.equ	iDEG='='		;character "degree" code
.equ	iA	='A'		;character "A" code
.equ	iB	='b'		;character "b" code
.equ	iC	='C'		;character "C" code
.equ	iiC	='c'		;character "c" code
.equ	iD	='d'		;character "d" code
.equ	iE	='E'		;character "E" code
.equ	iF	='F'		;character "F" code
.equ	iG	='G'		;character "G" code
.equ	iH	='H'		;character "H" code
.equ	iI	='I'		;character "I" code
.equ	iL	='L'		;character "L" code
.equ	iii	='i'		;character "i" code
.equ	iiN	='n'		;character "n" code
.equ	iO	='O'		;character "O" code
.equ	iiO	='o'		;character "o" code
.equ	iP	='P'		;character "P" code
.equ	iR	='R'		;character "R" code
.equ	iiR	='r'		;character "r" code
.equ	iS	='S'		;character "S" code
.equ	iT	='t'		;character "t" code
.equ	iU	='U'		;character "U" code
.equ	iiU	='u'		;character "u" code
.equ	iY	='Y'		;character "Y" code

;----------------------------------------------------------------------------
