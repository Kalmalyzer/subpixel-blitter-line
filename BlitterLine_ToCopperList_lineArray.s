
		include	"BlitterLine_ToCopperList.i"
		include	<Engine/A500/System/Copper.i>
		include	<Engine/A500/UAE/Printf.i>

		include	"hardware/custom.i"
		include	<Engine/A500/AdditionalIncludes/hardware/blitbits.i>

		section	code,code

;LINE_MINTERM	=	$4a		; xor
LINE_MINTERM	=	$ca		; or

;LINE_EDGE_MODE	=	BLTCON1F_SING	; 1 pixel per line mode active
LINE_EDGE_MODE	= 	0		; 1 pixel per line mode inactive

;----------------------------------------------------------------------------------
; Write a sequence of blitter line write operations into copperlist
;
; in	d0.w	num lines
;	a0	copperlist
;	a1	bitplane
;	a2	vertices
;	a3	y offset table
; out	a0	copperlist afterward

		XDEF	BlitterLine_ToCopperList_lineArray
BlitterLine_ToCopperList_lineArray

		movem.l	d2-d7/a2-a6,-(sp)

		lsl.w	#3,d0
		beq.s	.done
		lea	(a2,d0.w),a6

		move.w	#bltcon0,d4
		swap	d4

		move.l	#.blitter_temp_output_word,d0
		move.w	d0,.smc1-2
		swap	d0
		move.w	d0,.smc2-2
.line
		movem.w	(a2)+,d0-d3

		cmp.w	d1,d3
		bge.s	.downward
		exg	d0,d2
		exg	d1,d3
.downward

		sub.w	d1,d3
		sub.w	d0,d2
		bpl.s	.positiveDx
		neg.w	d2

		cmp.w	d2,d3
		blo.s	.negativeDx_absDyLessThanAbsDx
		exg	d2,d3

.negativeDx_absDyNotLessThanAbsDx
		moveq	#BLTCON1F_SUL|BLTCON1F_LINE|LINE_EDGE_MODE,d6
		bra.s	.octantDone

.negativeDx_absDyLessThanAbsDx
		moveq	#BLTCON1F_SUD|BLTCON1F_AUL|BLTCON1F_LINE|LINE_EDGE_MODE,d6
		bra.s	.octantDone

.positiveDx
		cmp.w	d2,d3
		blo.s	.positiveDx_absDyLessThanAbsDx
		exg	d2,d3

.positiveDx_absDyNotLessThanAbsDx
		moveq	#0|BLTCON1F_LINE|LINE_EDGE_MODE,d6
		bra.s	.octantDone

.positiveDx_absDyLessThanAbsDx
		moveq	#BLTCON1F_SUD|BLTCON1F_LINE|LINE_EDGE_MODE,d6

.octantDone

		add.w	d3,d3
		add.w	d3,d3
		move.w	d3,d7
		add.w	d2,d2
		sub.w	d2,d7
		add.w	d2,d2
		ext.l	d7

		bpl.s	.positiveGradient
		or.w	#BLTCON1F_SIGN,d6
.positiveGradient

		move.w	#bltapt+2,(a0)+
		move.w	d7,(a0)+
		swap	d7
		move.w	#bltapt,(a0)+
		move.w	d7,(a0)+

		move.w	#bltbmod,(a0)+
		move.w	d3,(a0)+
		sub.w	d2,d3
		move.w	#bltamod,(a0)+
		move.w	d3,(a0)+

		ror.w	#4,d0
		move.w	d0,d4
		and.w	#$f000,d4
		eor.w	d4,d0

		add.w	d1,d1
		moveq	#0,d7
		move.w	(a3,d1.w),d7
		add.w	d0,d0
		add.w	d0,d7
		add.l	a1,d7

		move.w	#bltcpt+2,(a0)+
		move.w	d7,(a0)+
		move.w	#bltcpt,(a0)+
		swap	d7
		move.w	d7,(a0)+

		move.l	#((bltdpt+2)<<16)|$1234,(a0)+
.smc1
		move.l	#((bltdpt)<<16)|$1234,(a0)+
.smc2

		or.w	#BLTCON0F_USEA|BLTCON0F_USEC|BLTCON0F_USED|LINE_MINTERM,d4
		move.l	d4,(a0)+
		move.w	#bltcon1,(a0)+
		move.w	d6,(a0)+

		; d2 is already left-shifted by 2
		addq.w	#1<<2,d2
		lsl.w	#(6-2),d2
		addq.w	#2,d2
		move.w	#bltsize,(a0)+
		move.w	d2,(a0)+

		move.l	#COP_WAITBLIT_DATA,(a0)+
		move.l	#COP_WAITBLIT_DATA,(a0)+

		cmp.l	a2,a6
		bne.s	.line

.done
		movem.l	(sp)+,d2-d7/a2-a6

		rts

		section	bss_c,bss_c

.blitter_temp_output_word
		ds.w	1

