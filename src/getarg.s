		.title	HLK/ev (getarg.s - get argument module)


* Include File -------------------------------- *

		.include	hlk.mac
		.include	doscall.mac


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

*------------------------------------------------------------------------------
*
*	void	init_arg(int max_argc, int arg_buf_size,
*				char *argv_buf, char *arg_buf);
*
*	argv_bufは末尾のNULLの分を入れて、max_argc+1だけ確保しておくこと.
*
*------------------------------------------------------------------------------

init_arg::
		link		a6,#0
		PUSH		d1-d3/a0

		movem.l		arg1,d0-d3

		lea		(workbuf,pc),a0
		move.l		d0,(ARGV_LEFT,a0)
		move.l		d1,(ARG_BUF_LEFT,a0)
		move.l		d2,(ARGV,a0)
		move.l		d3,(ARG_BUF_PTR,a0)
		move.l		d3,(ARG_BUF,a0)

		clr.l		(ARGC,a0)
		clr.l		(ARG_SIZE,a0)
		movea.l		(ARGV,a0),a0
		clr.l		(a0)

		POP		d1-d3/a0
		unlk		a6
		rts

*------------------------------------------------------------------------------
*
*	int	hup_get_arg(char *command_line);
*
*	global:
*		short	argc		argument_count
*		char	*argv[]		argument_pointer ( argv[argc] = 0 )
*
*	HUPAIR 準拠な引数取得ルーチン
*
*------------------------------------------------------------------------------

hup_get_arg::
		link		a6,#0
		PUSH		d1-d4/a0-a4

		movea.l		arg1,a0			;a0.l = command_line

		lea		(workbuf,pc),a4
		move.l		(ARGC,a4),d1		;d1.l = argc
		movea.l		(ARGV,a4),a1
		move.l		d1,d2
		lsl.l		#2,d2
		add.l		d2,a1			;a1.l = argv_pointer
		move.l		(ARG_BUF_LEFT,a4),d2	;d2.l = arg_buf_left
		move.l		(ARG_SIZE,a4),d3	;d3.l = arg_size
		moveq		#0,d4			;d4.b = quote flag
		movea.l		(ARG_BUF_PTR,a4),a2	;a2.l = arg_buf_ptr
		lea		(ARGV_LEFT,a4),a3	;a3.l = argv_left

hup_get_arg_l1	movea.l		a2,a4
		tst.l		(a3)
		bls		hup_get_arg_err		* too many arguments

hup_get_arg_l2	move.b		(a0)+,d0
		beq		hup_get_arg_end
		cmpi.b		#' ',d0
		beq		hup_get_arg_l2

hup_get_arg_l3	tst.b		d4
		beq		hup_get_arg_b2		* not in quote

		cmp.b		d4,d0
		bne		hup_get_arg_b3		* dup one

hup_get_arg_b1	eor.b		d0,d4
		bra		hup_get_arg_b4

hup_get_arg_b2	cmp.b		#'"',d0
		beq		hup_get_arg_b1

		cmp.b		#"'",d0
		beq		hup_get_arg_b1

		cmp.b		#' ',d0
		beq		hup_get_arg_b5

hup_get_arg_b3	subq.l		#1,d2
		beq		hup_get_arg_err		* too many arguments
		addq.l		#1,d3
		move.b		d0,(a2)+
		beq		hup_get_arg_b5

hup_get_arg_b4	move.b		(a0)+,d0
		bra		hup_get_arg_l3

hup_get_arg_b5	subq.l		#1,d2
		beq		hup_get_arg_err		* too many arguments
		addq.l		#1,d3
		clr.b		(a2)+

		move.l		a4,(a1)+
		addq.l		#1,d1
		subq.l		#1,(a3)
		tst.b		d0
		bne		hup_get_arg_l1

hup_get_arg_end:
		clr.l		(a1)

		lea		(workbuf,pc),a0
		move.l		d1,(ARGC,a0)		;argc
		move.l		d2,(ARG_BUF_LEFT,a0)	;arg_buf_left
		move.l		a2,(ARG_BUF_PTR,a0)	;arg_buf_ptr
		move.l		d3,(ARG_SIZE,a0)	;arg_size

		move.l		d1,d0
@@:		POP		d1-d4/a0-a4
		unlk		a6
		rts
hup_get_arg_err:
		moveq		#-1,d0
		bra		@b

*------------------------------------------------------------------------------
*
*	int	fget_arg(char *command_line);
*
*	global:
*		short	argc		argument_count
*		char	*argv[]		argument_pointer ( argv[argc] = 0 )
*
*	引数を分割し、command_lineに上書きする.
*
*------------------------------------------------------------------------------

fget_arg::
		PUSH		a0-a1/a6
		lea		(workbuf,pc),a6

		movea.l		(3*4+4,sp),a0		;a0.l = *command_line

		move.l		(ARGC,a6),d0
		movea.l		(ARGV,a6),a1
		lsl.l		#2,d0
		add.l		d0,a1			;a1.l = argv_pointer

fget_arg_loop:
		move.b		(a0)+,d0		;引数まで飛ばす
		beq		fget_arg_end
		cmpi.b		#EOF,d0
		beq		fget_arg_end
		cmpi.b		#' ',d0
		bls		fget_arg_loop

		tst.l		(ARGV_LEFT,a6)
		ble		fget_arg_err

		subq.l		#1,a0
		subq.l		#1,(ARGV_LEFT,a6)
		addq.l		#1,(ARGC,a6)
		move.l		a0,(a1)+
fget_arg_loop2:
		move.b		(a0)+,d0		;引数を飛ばす
		cmpi.b		#' ',d0
		bhi		fget_arg_loop2

		clr.b		(-1,a0)
		tst.b		d0
		beq		fget_arg_end
		cmpi.b		#EOF,d0
		bne		fget_arg_loop
fget_arg_end:
		clr.l		(a1)
		move.l		(ARGC,a6),d0
@@:		POP		a0-a1/a6
		rts
fget_arg_err:
		moveq		#-1,d0
		bra		@b


		.end

* End of File --------------------------------- *
