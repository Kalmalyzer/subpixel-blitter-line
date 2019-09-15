
		include	"BlitterLine.i"

		include	"hardware/custom.i"
		include	"additionalincludes/hardware/blitbits.i"

		section	code,code
		
;LINE_MINTERM	=	$4a		; xor
LINE_MINTERM	=	$ca		; or

;----------------------------------------------------------------------------------
; Draw regular blitter line
;
; The routine assumes that the blitter is idle when called
; The routine will exit with the blitter active
;
; in	d0.w	x0
;	d1.w	y0
;	d2.w	x1
;	d3.w	y1
;	d4.w	bytes per row in bitplane
;	a0	bitplane
;	a6	$dff000

BlitterLine
		movem.l	d2-d7/a2,-(sp)

		move.w	d4,a1
		
		cmp.w	d1,d3
		bge.s	.downward
		exg	d0,d2
		exg	d1,d3
.downward

		sub.w	d0,d2
		sub.w	d1,d3
		
		move.w	d2,d4
		bpl.s	.positiveDX
		neg.w	d4
.positiveDX
		move.w	d3,d5
		bpl.s	.positiveDY
		neg.w	d5
.positiveDY
		move.w	d4,d6
		sub.w	d5,d6
		add.l	d6,d6
		move.w	d3,d6
		add.l	d6,d6
		move.w	d2,d6
		add.l	d6,d6
		swap	d6
		and.w	#7,d6
		lea	.octant_lookup,a2
		move.b	(a2,d6.w),d6
		or.w	#BLTCON1F_LINE,d6

		cmp.w	d4,d5
		bls.s	.absDyLessThanAbsDx
		exg	d4,d5
.absDyLessThanAbsDx

		move.w	d5,d7
		add.w	d7,d7
		sub.w	d4,d7
		add.w	d7,d7
		ext.l	d7
		move.l	d7,bltapt(a6)
		bpl.s	.positiveGradient
		or.w	#BLTCON1F_SIGN,d6
.positiveGradient

		add.w	d4,d4
		add.w	d4,d4
		add.w	d5,d5
		add.w	d5,d5
		move.w	d5,bltbmod(a6)
		sub.w	d4,d5
		move.w	d5,bltamod(a6)
		lsr.w	#2,d4

		move.w	#$8000,bltadat(a6)
		move.l	#$ffffffff,bltafwm(a6)

		move.w	d0,d2
		and.w	#$f,d2
		ror.w	#4,d2
		
		move.w	#$ffff,bltbdat(a6)

		move.w	a1,d7
		mulu.w	d1,d7
		add.l	d7,a0
		move.w	d0,d7
		lsr.w	#4,d7
		add.w	d7,d7
		add.w	d7,a0
		move.l	a0,bltcpt(a6)
		move.l	#blitter_temp_output_word,bltdpt(a6)
		
		move.w	a1,bltcmod(a6)
		move.w	a1,bltdmod(a6)

		or.w	#BLTCON0F_USEA|BLTCON0F_USEC|BLTCON0F_USED|LINE_MINTERM,d2
		move.w	d2,bltcon0(a6)
		move.w	d6,bltcon1(a6)

		addq.w	#1,d4
		lsl.w	#6,d4
		addq.w	#2,d4
		move.w	d4,bltsize(a6)

		movem.l	(sp)+,d2-d7/a2
		
		rts

		section	data,data
		
.octant_lookup
		dc.b	BLTCON1F_SUD				; octant 7
		dc.b	BLTCON1F_SUD|BLTCON1F_AUL		; octant 4
		dc.b	BLTCON1F_SUD|BLTCON1F_SUL		; octant 0
		dc.b	BLTCON1F_SUD|BLTCON1F_SUL|BLTCON1F_AUL	; octant 3
		dc.b	0					; octant 6
		dc.b	BLTCON1F_SUL				; octant 5
		dc.b	BLTCON1F_AUL				; octant 1
		dc.b	BLTCON1F_SUL|BLTCON1F_AUL		; octant 2

		section	bss_c,bss_c

blitter_temp_output_word
		ds.w	1
