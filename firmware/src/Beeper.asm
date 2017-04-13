;----------------------------------------------------------------------------

;Beeper support module
;(program generation)

;Connection:
;SND -> beeper driver (LOW active)

;----------------------------------------------------------------------------

;Constantes:

.equ	TDUR	= 150		;tone duration (in half-periods)
.equ	SDUR	= 25		;sound duration (in half-periods)
.equ	ERRBP	= 55		;error bell period
.equ	MLDP1	= 50		;melody period 1
.equ	MLDP2	= 45		;melody period 2
.equ	MLDP3	= 35		;melody period 3

;----------------------------------------------------------------------------

;Derivated constantes:

.equ	NSND	= FCLK / 1000000 ;sound generation time step

;----------------------------------------------------------------------------

.DSEG	;data segment (internal RAM)

;----------------------------------------------------------------------------

.CSEG	;Code segment

;----------------------------------------------------------------------------

;Error bell:

ErrB:	ldi	tempE,ERRBP	;period
	rcall	Tone
	ret

;----------------------------------------------------------------------------

;Data save melody:

Melody:	ldi	tempE,MLDP1	;tone 1
	rcall	Tone
	ldi	tempE,MLDP2	;tone 2
	rcall	Tone
	ldi	tempE,MLDP3	;tone 3
	rcall	Tone
	ret

;----------------------------------------------------------------------------

;Tone generation:
;Input: tempE - period

Tone:	ldi	tempD,TDUR	;tone duration
	rcall	Sgen
	ret

;----------------------------------------------------------------------------

;Sound generation:
;Input: temp - frequency

Sound:
	mov	tempE,temp	;temp - frequency
	com	tempE		;temp=~temp
	andi	tempE,0x0F	;mask unused bits
	subi	tempE,-30	;add period offset
	ldi	tempD,SDUR	;sound duration
	rcall	Sgen
	ret

;----------------------------------------------------------------------------

;Sound generation:
;Input: tempE - period
;       tempD - duration
Sgen:	mov	tempF,tempE	;3
sndb:	ldi	Cnt,NSND  	;2 outer loop
snda:	dec	Cnt		    ;1 inner loop
	brne	snda		    ;1 inner loop
	dec	tempF		  ;2 outer loop
	brne	sndb		  ;2 outer loop
	wdr			;3 watchdog restart
	sbrc	tempD,0		;3 check tempF.0
	Port_SND_1		;3 set	 SND if tempF.0 = 1
	sbrs	tempD,0		;3 check tempF.0
	Port_SND_0		;3 clear SND if tempF.0 = 0
	dec	tempD		;3
	brne	Sgen		;3
	ret			;tempF=1, SND = 1, beeper power off

;----------------------------------------------------------------------------
