
		include	"BlitterLine_ToCopperList.i"

		include	"hardware/custom.i"
		include	"additionalincludes/hardware/blitbits.i"
		include	<Engine/A500/System/Copper.i>

		section	code,code

;LINE_MINTERM	=	$4a		; xor
LINE_MINTERM	=	$ca		; or

;----------------------------------------------------------------------------------
; Setup for blitter edge line drawing
;
; The routine sets up initial registers needed for blitter edge line drawing

; in	d0.w	bytes per row in bitplane
;	a0	copperlist

BlitterLine_ToCopperList_init
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
; Draw blitter edge line for blitter area fill
;
; The routine assumes that the blitter is idle when called
; The routine will exit with the blitter active
;
; in	d0.w	x0
;	d1.w	y0
;	d2.w	x1
;	d3.w	y1
;	d4.w	width
;	a0	bitplane
;	a1	copperlist

BlitterLine_ToCopperList_line

		movem.l	d2-d7/a2-a3,-(sp)

		move.w	d4,a3

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

		cmp.w	d4,d5
		blo.s	.absDyLessThanAbsDx
		exg	d4,d5

		tst.w	d2
		bmi.s	.absDyNotLessThanAbsDx_DxNegative
.absDyNotLessThanAbsDx_DxPositive
		moveq	#0|BLTCON1F_LINE,d6
		bra.s	.octantDone
.absDyNotLessThanAbsDx_DxNegative
		moveq	#BLTCON1F_SUL|BLTCON1F_LINE,d6
		bra.s	.octantDone

.absDyLessThanAbsDx
		tst.w	d2
		bmi.s	.absDyLessThanAbsDx_DxNegative
.absDyLessThanAbsDx_DxPositive
		moveq	#BLTCON1F_SUD|BLTCON1F_LINE,d6
		bra.s	.octantDone
.absDyLessThanAbsDx_DxNegative
		moveq	#BLTCON1F_SUD|BLTCON1F_AUL|BLTCON1F_LINE,d6

.octantDone

		add.w	d5,d5
		add.w	d5,d5
		move.w	d5,d7
		add.w	d4,d4
		sub.w	d4,d7
		add.w	d4,d4
		ext.l	d7

		move.w	#bltapt+2,(a1)+
		move.w	d7,(a1)+
		swap	d7
		move.w	#bltapt,(a1)+
		move.w	d7,(a1)+

		bpl.s	.positiveGradient
		or.w	#BLTCON1F_SIGN,d6
.positiveGradient

		move.w	#bltbmod,(a1)+
		move.w	d5,(a1)+
		sub.w	d4,d5
		move.w	#bltamod,(a1)+
		move.w	d5,(a1)+

		ror.w	#4,d0
		move.w	d0,d2
		and.w	#$f000,d2
		eor.w	d2,d0

		move.w	a3,d7
		mulu.w	d1,d7
		add.w	d0,d0
		add.w	d0,d7
		add.l	a0,d7

		move.w	#bltcpt+2,(a1)+
		move.w	d7,(a1)+
		move.w	#bltcpt,(a1)+
		swap	d7
		move.w	d7,(a1)+

		move.l	#blitter_temp_output_word,d7
		move.w	#bltdpt+2,(a1)+
		move.w	d7,(a1)+
		move.w	#bltdpt,(a1)+
		swap	d7
		move.w	d7,(a1)+

		or.w	#BLTCON0F_USEA|BLTCON0F_USEC|BLTCON0F_USED|LINE_MINTERM,d2
		move.w	#bltcon0,(a1)+
		move.w	d2,(a1)+
		move.w	#bltcon1,(a1)+
		move.w	d6,(a1)+

		; d4 is already left-shifted by 2
		addq.w	#1<<2,d4
		lsl.w	#(6-2),d4
		addq.w	#2,d4
		move.w	#bltsize,(a1)+
		move.w	d4,(a1)+

		movem.l	(sp)+,d2-d7/a2-a3

		rts

		section	bss_c,bss_c

blitter_temp_output_word
		ds.w	1

