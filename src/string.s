		.title		HLK/ev (string.s - string control module)


* Include File -------------------------------- *

		.include	hlk.mac


* Text Section -------------------------------- *

		.cpu		68000

		.text
		.even

*------------------------------------------------------------------------------
*
*	char	*strcpy(char *dst, char *sou);
*
*	ret:	d0.l = dst
*
*------------------------------------------------------------------------------

strcpy::
		PUSH		a0-a1
		movem.l		(12,sp),a0-a1		;a0.l = dst
		move.l		a0,d0			;a1.l = sou

strcpy_l:	move.b		(a1)+,(a0)+
		bne		strcpy_l

		POP		a0-a1
		rts

*------------------------------------------------------------------------------
*
*	char	*strcat(char *dst, char *sou);
*
*	ret:	d0.l = dst
*
*------------------------------------------------------------------------------

strcat::
		PUSH		a0-a1
		movem.l		(12,sp),a0-a1		;a0.l = dst
		move.l		a0,d0			;a1.l = sou

strcat_l1:	tst.b		(a0)+
		bne		strcat_l1
		subq.l		#1,a0

strcat_l2:	move.b		(a1)+,(a0)+
		bne		strcat_l2

		POP		a0-a1
		rts

*------------------------------------------------------------------------------
*
*	int	strlen(char *string);
*
*	ret:	d0.l = length of string
*
*------------------------------------------------------------------------------

strlen::
		move.l		a0,-(sp)
		movea.l		(8,sp),a0		;a0.l = string
		move.l		a0,d0

strlen_l:	tst.b		(a0)+
		bne		strlen_l
		subq.l		#1,a0
		suba.l		d0,a0
		move.l		a0,d0

		movea.l		(sp)+,a0
		rts

*------------------------------------------------------------------------------
*
*	char	*strupr(char *string);
*
*	ret:	d0.l = string
*
*------------------------------------------------------------------------------

	.if	0
strupr::
		move.l		a0,-(sp)
		movea.l		(8,sp),a0		;a0.l = string

strupr_l:	move.b		(a0)+,d0
		beq		strupr_end
		bpl		strupr_b2		;ANK
		cmpi.b		#$a0,d0
		bcs		strupr_b1		;KANJI
		cmpi.b		#$e0,d0
		bcs		strupr_l		;ANK
strupr_b1:	tst.b		(a0)+
		bne		strupr_l
		bra		strupr_end

strupr_b2:	cmpi.b		#'a',d0
		bcs		strupr_l
		cmpi.b		#'z',d0
		bhi		strupr_l
		andi.b		#$df,(-1,a0)
		bra		strupr_l

strupr_end:	move.l		(8,sp),d0		;d0.l = string
		movea.l		(sp)+,a0
		rts
	.endif

*------------------------------------------------------------------------------
*
*	char	*strlwr(char *string);
*
*	ret:	d0.l = string
*
*------------------------------------------------------------------------------

	.if	0
strlwr::
		move.l		a0,-(sp)
		movea.l		(8,sp),a0		;a0.l = string

strlwr_l:	move.b		(a0)+,d0
		beq		strlwr_end
		bpl		strlwr_b2		;ANK
		cmpi.b		#$a0,d0
		bcs		strlwr_b1		;KANJI
		cmpi.b		#$e0,d0
		bcs		strlwr_l		;ANK
strlwr_b1:	tst.b		(a0)+
		bne		strlwr_l
		bra		strlwr_end

strlwr_b2:	cmp.b		#'A',d0
		bcs		strlwr_l
		cmp.b		#'Z',d0
		bhi		strlwr_l
		ori.b		#$20,(-1,a0)
		bra		strlwr_l

strlwr_end:	move.l		(8,sp),d0		;d0.l = string
		movea.l		(sp)+,a0
		rts
	.endif

*------------------------------------------------------------------------------
*
*	int	strcmp(char *str1, char *str2);
*
*	ret:	d0.l =	0	str1 == str2
*		       -1	str1 <  str2
*			1	str1 >  str2
*
*------------------------------------------------------------------------------

strcmp::
		PUSH		d1/a0-a1
		movem.l		(16,sp),a0-a1		;a0.l = str1
							;a1.l = str2
strcmp_l:	move.b		(a1)+,d1
		beq		strcmp_b1		;str1 >  str2  or str1 == str2
		move.b		(a0)+,d0
		beq		strcmp_b3		;str1 <  str2
		cmp.b		d0,d1
		beq		strcmp_l
		bhi		strcmp_b3		;str1 <  str2

strcmp_b2:	moveq		#1,d0			;str1 >  str2
		bra		strcmp_end

strcmp_b3:	moveq		#-1,d0
		bra		strcmp_end

strcmp_b1:	cmp.b		(a0),d1
		bcs		strcmp_b2		;str1 >  str2
		moveq		#0,d0

strcmp_end:	POP		d1/a0-a1
		rts


		.end

* End of File --------------------------------- *
