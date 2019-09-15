
		include	"SubPixelBlitterEdgeLine_ToCopperList.i"

		include	"hardware/custom.i"
		include	"additionalincludes/hardware/blitbits.i"

		section	code,code
		
LINE_MINTERM	=	$4a		; xor
;LINE_MINTERM	=	$ca		; or


;----------------------------------------------------------------------------------
; Setup for subpixelled blitter edge line drawing
;
; The routine sets up initial registers needed for blitter edge line drawing
;
; in	d0.w	bytes per row in bitplane
;	a0	copperlist

SubPixelBlitterEdgeLine_ToCopperList_init

		move.l	#(bltadat<<16)|$8000,(a0)+
		move.l	#(bltbdat<<16)|$ffff,(a0)+
		move.l	#(bltafwm<<16)|$ffff,(a0)+
		move.l	#(bltalwm<<16)|$ffff,(a0)+
		move.w	#bltcmod,(a0)+
		move.w	d0,(a0)+
		move.w	#bltdmod,(a0)+
		move.w	d0,(a0)+

		rts

;----------------------------------------------------------------------------------
; Draw subpixelled blitter edge line for blitter area fill
;
; The routine builds a copperlist which, when executed, will draw the line
;
; in	d0.w	x0 in fixed point
;	d1.w	y0 in fixed point
;	d2.w	x1 in fixed point
;	d3.w	y1 in fixed point
;	d4.w	bytes per row in bitplane
;	a0	bitplane
;	a1	copperlist

SubPixelBlitterEdgeLine_ToCopperList_line

		movem.l	d2-d7/a2,-(sp)

		move.w	d4,a2
		
		cmp.w	d1,d3
		bgt.s	.downward
		beq	.done
		exg	d0,d2
		exg	d1,d3
.downward
		
		cmp.w	d0,d2
		blt	.leftWard

		move.w	d2,d6
		move.w	d3,d7
		
		sub.w	d0,d2
		sub.w	d1,d3
		
		cmp.w	d2,d3
		ble	.rightWard_xMajor

.rightWard_yMajor
		move.w	#SubPixelBlitterEdgeLine_Mask,d4
		move.w	#SubPixelBlitterEdgeLine_Mask,d5
		sub.w	d0,d4
		sub.w	d1,d5
		and.w	#SubPixelBlitterEdgeLine_Mask,d4			; prestep_x = SubPixelBlitterEdgeLine_Mask - (x0 & SubPixelBlitterEdgeLine_Mask)
		and.w	#SubPixelBlitterEdgeLine_Mask,d5			; prestep_y = SubPixelBlitterEdgeLine_Mask - (y0 & SubPixelBlitterEdgeLine_Mask)

		asr.w	#SubPixelBlitterEdgeLine_Bits,d0			; start_x = x0 >> SubPixelBlitterEdgeLine_Bits
		asr.w	#SubPixelBlitterEdgeLine_Bits,d1			; start_y = y0 >> SubPixelBlitterEdgeLine_Bits
		subq.w	#1,d1

		neg.w	d3
		
		muls.w	d2,d5
		muls.w	d3,d4

		lsl.w	#SubPixelBlitterEdgeLine_Bits,d2
		lsl.w	#SubPixelBlitterEdgeLine_Bits,d3

		add.w	d5,d4			; bltapt = dx*prestep_y-dy*prestep_x

		move.w	#bltbmod,(a1)+
		move.w	d2,(a1)+	; bltbmod = dx<<SubPixelBlitterEdgeLine_Bits

		add.w	d2,d3
		move.w	#bltamod,(a1)+
		move.w	d3,(a1)+	; bltamod = (dx-dy)<<SubPixelBlitterEdgeLine_Bits

		move.w	#bltapt+2,(a1)+
		move.w	d4,(a1)+
		
		asr.w	#SubPixelBlitterEdgeLine_Bits,d7			; end_y = (y1 >> SubPixelBlitterEdgeLine_Bits)
		sub.w	d1,d7			; line_length = end_y - start_y

		move.w	#0,d6
		or.w	#BLTCON1F_SING|BLTCON1F_LINE,d6
		tst.w	d4
		bpl.s	.rightWard_yMajor_positiveGradient
		or.w	#BLTCON1F_SIGN,d6
.rightWard_yMajor_positiveGradient
		move.w	#bltcon1,(a1)+
		move.w	d6,(a1)+

		move.w	a2,d3
		mulu.w	d1,d3
		add.l	d3,a0
		move.w	d0,d3
		asr.w	#4,d3
		add.w	d3,d3
		add.w	d3,a0
		move.l	a0,d3
		move.w	#bltcpt+2,(a1)+
		move.w	d3,(a1)+
		move.w	#bltcpt,(a1)+
		swap	d3
		move.w	d3,(a1)+
		move.l	#blitter_temp_output_word,d3
		move.w	#bltdpt+2,(a1)+
		move.w	d3,(a1)+
		move.w	#bltdpt,(a1)+
		swap	d3
		move.w	d3,(a1)+

		move.w	d0,d2
		and.w	#$f,d2
		ror.w	#4,d2

		or.w	#BLTCON0F_USEA|BLTCON0F_USEC|BLTCON0F_USED|LINE_MINTERM,d2
		move.w	#bltcon0,(a1)+
		move.w	d2,(a1)+

		lsl.w	#6,d7
		addq.w	#2,d7
		move.w	#bltsize,(a1)+
		move.w	d7,(a1)+

		bra	.done

.leftWard
		move.w	d2,d6
		move.w	d3,d7
		
		sub.w	d0,d2
		sub.w	d1,d3
		neg.w	d2
		
		cmp.w	d2,d3
		ble	.leftWard_xMajor

.leftWard_yMajor
		move.w	d0,d4
		move.w	#SubPixelBlitterEdgeLine_Mask,d5
		and.w	#SubPixelBlitterEdgeLine_Mask,d4
		sub.w	d1,d5
		subq.w	#1,d4			; prestep_x = (x0 & SubPixelBlitterEdgeLine_Mask) - 1
		and.w	#SubPixelBlitterEdgeLine_Mask,d5			; prestep_y = SubPixelBlitterEdgeLine_Mask - (y0 & SubPixelBlitterEdgeLine_Mask)

		asr.w	#SubPixelBlitterEdgeLine_Bits,d0			; start_x = x0 >> SubPixelBlitterEdgeLine_Bits
		asr.w	#SubPixelBlitterEdgeLine_Bits,d1			; start_y = y0 >> SubPixelBlitterEdgeLine_Bits
		subq.w	#1,d1

		neg.w	d3
		
		muls.w	d2,d5
		muls.w	d3,d4

		lsl.w	#SubPixelBlitterEdgeLine_Bits,d2
		lsl.w	#SubPixelBlitterEdgeLine_Bits,d3

		add.w	d5,d4			; bltapt = dx*prestep_y-dy*prestep_x

		move.w	#bltbmod,(a1)+
		move.w	d2,(a1)+	; bltbmod = dx<<SubPixelBlitterEdgeLine_Bits

		add.w	d2,d3
		move.w	#bltamod,(a1)+
		move.w	d3,(a1)+	; bltamod = (dx-dy)<<SubPixelBlitterEdgeLine_Bits

		move.w	#bltapt+2,(a1)+
		move.w	d4,(a1)+
		
		asr.w	#SubPixelBlitterEdgeLine_Bits,d7			; end_y = (y1 >> SubPixelBlitterEdgeLine_Bits)
		sub.w	d1,d7			; line_length = end_y - start_y

		move.w	#BLTCON1F_SUL,d6
		or.w	#BLTCON1F_SING|BLTCON1F_LINE,d6
		tst.w	d4
		bpl.s	.leftWard_yMajor_positiveGradient
		or.w	#BLTCON1F_SIGN,d6
.leftWard_yMajor_positiveGradient
		move.w	#bltcon1,(a1)+
		move.w	d6,(a1)+

		move.w	a2,d3
		mulu.w	d1,d3
		add.l	d3,a0
		move.w	d0,d3
		asr.w	#4,d3
		add.w	d3,d3
		add.w	d3,a0
		move.l	a0,d3
		move.w	#bltcpt+2,(a1)+
		move.w	d3,(a1)+
		move.w	#bltcpt,(a1)+
		swap	d3
		move.w	d3,(a1)+
		move.l	#blitter_temp_output_word,d3
		move.w	#bltdpt+2,(a1)+
		move.w	d3,(a1)+
		move.w	#bltdpt,(a1)+
		swap	d3
		move.w	d3,(a1)+

		move.w	d0,d2
		and.w	#$f,d2
		ror.w	#4,d2

		or.w	#BLTCON0F_USEA|BLTCON0F_USEC|BLTCON0F_USED|LINE_MINTERM,d2
		move.w	#bltcon0,(a1)+
		move.w	d2,(a1)+

		lsl.w	#6,d7
		addq.w	#2,d7
		move.w	#bltsize,(a1)+
		move.w	d7,(a1)+

		bra	.done
		nop

.rightWard_xMajor
		move.w	#SubPixelBlitterEdgeLine_Mask,d4
		move.w	#SubPixelBlitterEdgeLine_Mask,d5
		sub.w	d0,d4
		sub.w	d1,d5
		and.w	#SubPixelBlitterEdgeLine_Mask,d4			; prestep_x = SubPixelBlitterEdgeLine_Mask - (x0 & SubPixelBlitterEdgeLine_Mask)
		and.w	#SubPixelBlitterEdgeLine_Mask,d5			; prestep_y = SubPixelBlitterEdgeLine_Mask - (y0 & SubPixelBlitterEdgeLine_Mask)

		asr.w	#SubPixelBlitterEdgeLine_Bits,d0
		asr.w	#SubPixelBlitterEdgeLine_Bits,d1

		subq.w	#1,d0			; start_x = (x0 >> SubPixelBlitterEdgeLine_Bits) - 1
		subq.w	#1,d1			; start_y = (y0 >> SubPixelBlitterEdgeLine_Bits) - 1
		
		neg.w	d2

		move.w	d3,-(sp)
		move.w	d2,-(sp)
		
		muls.w	d2,d5
		muls.w	d3,d4

		lsl.w	#SubPixelBlitterEdgeLine_Bits,d2
		lsl.w	#SubPixelBlitterEdgeLine_Bits,d3

		add.w	d5,d4			; bltapt = dy*prestep_x - dx*prestep_y

		move.w	#bltbmod,(a1)+
		move.w	d3,(a1)+		; bltbmod = dy<<SubPixelBlitterEdgeLine_Bits

		add.w	d2,d3
		move.w	#bltamod,(a1)+
		move.w	d3,(a1)+		; bltamod = (dy-dx)<<SubPixelBlitterEdgeLine_Bits

		move.w	#bltapt+2,(a1)+
		move.w	d4,(a1)+

		move.w	a2,d3
		mulu.w	d1,d3
		add.l	d3,a0
		move.w	d0,d3
		asr.w	#4,d3
		add.w	d3,d3
		add.w	d3,a0
		move.l	a0,d3
		move.w	#bltcpt+2,(a1)+
		move.w	d3,(a1)+
		move.w	#bltcpt,(a1)+
		swap	d3
		move.w	d3,(a1)+
		move.l	#blitter_temp_output_word,d3
		move.w	#bltdpt+2,(a1)+
		move.w	d3,(a1)+
		move.w	#bltdpt,(a1)+
		swap	d3
		move.w	d3,(a1)+

		move.w	d0,d2
		and.w	#$f,d2
		ror.w	#4,d2

		or.w	#BLTCON0F_USEA|BLTCON0F_USEC|BLTCON0F_USED|LINE_MINTERM,d2
		move.w	#bltcon0,(a1)+
		move.w	d2,(a1)+

		move.w	d6,d2
		move.w	d7,d3
		and.w	#SubPixelBlitterEdgeLine_Mask,d2
		and.w	#SubPixelBlitterEdgeLine_Mask,d3
		subq.w	#1,d2
		subq.w	#1,d3

		muls.w	(sp)+,d3
		muls.w	(sp)+,d2
		
		move.w	d6,d7
		asr.w	#SubPixelBlitterEdgeLine_Bits,d7			; end_x = (x1 >> SubPixelBlitterEdgeLine_Bits)
		sub.w	d0,d7			; line_length = end_x - start_x

		add.l	d2,d3
		ble.s	.rightWard_xMajor_nExtraPixel
		addq.w	#1,d7
.rightWard_xMajor_nExtraPixel

		move.w	#BLTCON1F_SUD,d6
		or.w	#BLTCON1F_SING|BLTCON1F_LINE,d6
		tst.w	d4
		bpl.s	.rightWard_xMajor_positiveGradient
		or.w	#BLTCON1F_SIGN,d6
.rightWard_xMajor_positiveGradient
		move.w	#bltcon1,(a1)+
		move.w	d6,(a1)+

		lsl.w	#6,d7
		addq.w	#2,d7
		move.w	#bltsize,(a1)+
		move.w	d7,(a1)+

		bra	.done

.leftWard_xMajor
		move.w	d0,d4
		move.w	#SubPixelBlitterEdgeLine_Mask,d5
		and.w	#SubPixelBlitterEdgeLine_Mask,d4
		sub.w	d1,d5
		subq.w	#1,d4			; prestep_x = (x0 & SubPixelBlitterEdgeLine_Mask) - 1
		and.w	#SubPixelBlitterEdgeLine_Mask,d5			; prestep_y = SubPixelBlitterEdgeLine_Mask - (y0 & SubPixelBlitterEdgeLine_Mask)

		asr.w	#SubPixelBlitterEdgeLine_Bits,d0
		asr.w	#SubPixelBlitterEdgeLine_Bits,d1

		addq.w	#1,d0			; start_x = (x0 >> SubPixelBlitterEdgeLine_Bits) + 1
		subq.w	#1,d1			; start_y = (y0 >> SubPixelBlitterEdgeLine_Bits) - 1
		
		neg.w	d2
		
		move.w	d3,-(sp)
		move.w	d2,-(sp)
		
		muls.w	d2,d5
		muls.w	d3,d4

		lsl.w	#SubPixelBlitterEdgeLine_Bits,d2
		lsl.w	#SubPixelBlitterEdgeLine_Bits,d3

		add.w	d5,d4			; bltapt = dy*prestep_x - dx*prestep_y
		
		move.w	#bltbmod,(a1)+
		move.w	d3,(a1)+		; bltbmod = dy<<SubPixelBlitterEdgeLine_Bits

		add.w	d2,d3
		move.w	#bltamod,(a1)+
		move.w	d3,(a1)+		; bltamod = (dy-dx)<<SubPixelBlitterEdgeLine_Bits

		move.w	#bltapt+2,(a1)+
		move.w	d4,(a1)+
		
		move.w	a2,d3
		mulu.w	d1,d3
		add.l	d3,a0
		move.w	d0,d3
		asr.w	#4,d3
		add.w	d3,d3
		add.w	d3,a0
		move.l	a0,d3
		move.w	#bltcpt+2,(a1)+
		move.w	d3,(a1)+
		move.w	#bltcpt,(a1)+
		swap	d3
		move.w	d3,(a1)+
		move.l	#blitter_temp_output_word,d3
		move.w	#bltdpt+2,(a1)+
		move.w	d3,(a1)+
		move.w	#bltdpt,(a1)+
		swap	d3
		move.w	d3,(a1)+

		move.w	d0,d2
		and.w	#$f,d2
		ror.w	#4,d2

		or.w	#BLTCON0F_USEA|BLTCON0F_USEC|BLTCON0F_USED|LINE_MINTERM,d2
		move.w	#bltcon0,(a1)+
		move.w	d2,(a1)+

		move.w	#SubPixelBlitterEdgeLine_Mask,d2
		sub.w	d6,d2
		move.w	d7,d3
		and.w	#SubPixelBlitterEdgeLine_Mask,d2
		and.w	#SubPixelBlitterEdgeLine_Mask,d3
		subq.w	#1,d3

		muls.w	(sp)+,d3
		muls.w	(sp)+,d2
		
		move.w	d6,d7
		asr.w	#SubPixelBlitterEdgeLine_Bits,d7			; end_x = (x1 >> SubPixelBlitterEdgeLine_Bits)
		sub.w	d0,d7
		neg.w	d7			; line_length = start_x - end_x

		add.l	d2,d3
		ble.s	.leftWard_xMajor_nExtraPixel
		addq.w	#1,d7
.leftWard_xMajor_nExtraPixel

		move.w	#BLTCON1F_SUD|BLTCON1F_AUL,d6
		or.w	#BLTCON1F_SING|BLTCON1F_LINE,d6
		tst.w	d4
		bpl.s	.leftWard_xMajor_positiveGradient
		or.w	#BLTCON1F_SIGN,d6
.leftWard_xMajor_positiveGradient
		move.w	#bltcon1,(a1)+
		move.w	d6,(a1)+

		lsl.w	#6,d7
		addq.w	#2,d7
		move.w	#bltsize,(a1)+
		move.w	d7,(a1)+

		bra	.done

.done
		movem.l	(sp)+,d2-d7/a2
		rts


		section	bss_c,bss_c

blitter_temp_output_word
		ds.w	1
		