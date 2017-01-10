                 .macro	clbr			;clear bit in register
                 	cbr @0,exp2(@1)
                 .endm
                 
                 .macro	stbr			;set bit in register
                 	sbr @0,exp2(@1)
                 .endm
                 
                 .macro	bbrc			;branch if bit in register clear
                 	sbrs @0,@1
                 	rjmp @2
                 .endm
                 
                 .macro	bbrs			;branch if bit in register set
                 	sbrc @0,@1
                 	rjmp @2
                 .endm
                 
                 .macro	bbic			;branch if bit in I/O clear
                 	sbis @0,@1
                 	rjmp @2
                 .endm
                 
                 .macro	bbis			;branch if bit in I/O set
                 	sbic @0,@1
                 	rjmp @2
                 .endm
                 
                 .macro	addi			;add immediate 
                 	subi @0,-@1
                 .endm
                 
                 .macro	ldx			;load XL, XH with word
                 	ldi 	XL,byte1(@0)
                 	ldi 	XH,byte2(@0)
                 .endm
                 
                 .macro	ldy			;load YL, YH with word
                 	ldi	YL,byte1(@0)
                 	ldi	YH,byte2(@0)
                 .endm
                 
                 .macro	ldz			;load ZL, ZH with word
                 	ldi	ZL,byte1(@0)
                 	ldi	ZH,byte2(@0)
                 .endm
                 
                 .macro	table			;load Z pointer
                 	ldi	ZL,low (@0*2)
                 	ldi	ZH,high(@0*2)
                 .endm
                 
                 .macro	stdi			;store immediate indirect with displacement
                 	ldi	temp,@1
                 	std	@0,temp
                 .endm
                 
                 .macro	ldsx			;load XL, XH from memory
                 	lds 	XL,@0+0
                 	lds 	XH,@0+1
                 .endm
                 
                 .macro	ldsy			;load YL, YH from memory
                 	lds 	YL,@0+0
                 	lds 	YH,@0+1
                 .endm
                 
                 .macro	ldsz			;load ZL, ZH from memory
                 	lds 	ZL,@0+0
                 	lds 	ZH,@0+1
                 .endm
                 
                 .macro	stsx			;store XL, XH in memory
                 	sts 	@0+0,XL
                 	sts 	@0+1,XH
                 .endm
                 
                 .macro	stsy			;store YL, YH in memory
                 	sts 	@0+0,YL
                 	sts 	@0+1,YH
                 .endm
                 
                 .macro	stsz			;store ZL, ZH in memory
                 	sts 	@0+0,ZL
                 	sts 	@0+1,ZH
                 .endm
