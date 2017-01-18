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

;.equ	Pt	= 0x80		;point in Dig
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

;tempH:tempM:tempL convert to BCD Dig
	
DisBCD:	
		ldy		Dig+Lcd_cols
		clr		temp
		ldi		Cnt,12
clrout:
		st		Y+,temp		;output array clear
		dec		Cnt
		brne	clrout		

		ldi		Cnt,24		;input bits count
hloop:	
		lsl		tempL		;input array shift left
		rol		tempM
		rol		tempH		
		ldy		Dig+Lcd_cols+12 
sloop:	
		ld		temp,-Y
		rol		temp
		subi	temp,-0x06   ;temp+6, C=1
		sbrs	temp,4       ;skip if set
		subi	temp,0x06	   ;temp-6, C=0
		andi	temp,0x0F    ;number
    table Digits
    add   ZL,temp
    adc   ZH,temp
    sub   ZH,temp
    lpm   temp,Z
		st		Y,temp
    ldz   Dig+Lcd_cols
    
		cpse	YL,ZL		;ZH:ZL = Dig+3
		rjmp	sloop

		cpse	YH,ZH
		rjmp	sloop

		dec		Cnt			;YH:YL = Dig+3
		brne	hloop

    ret
;Supress zeros:

		ldz		Dig+Lcd_cols+4
		ldi		tempL,BLANK
zsp:	
		ld		temp,Y
		tst		temp
		brne	notz
		st		Y+,tempL	;suppress zero

		cp		YL,ZL
		brne	zsp

		cp		YH,ZH
		brne	zsp
notz:	
		movw	ZH:ZL,YH:YL	;ZH:ZL points to first non-zero digit
	
    ret

;Setup point:

		ldy		Dig+Lcd_cols+2
		cp		ZL,YL
		cpc		ZH,YH
		ldy		Dig+Lcd_cols+1
		brlo	setpo
		ldy		Dig+Lcd_cols+4
setpo:	
		ld		temp,Y
		ori		temp,'.'
		st		Y,temp		;setup point at Dig+4 or Dig+7
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
StrName:
    .db "SG-420M", '\0'
StrVer:
    .db "Version: 1.01", '\0'
StrFreq:
    .db "Frequency", '\0'
StrkHz:
    .db "kHz", '\0'
StrStep:
    .db "step ", '\0'

Digits:
    .db '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'

;----------------------------------------------------------------------------

;Characters codes table:

.equ	BLANK=' '		;character "blank" code

;----------------------------------------------------------------------------
