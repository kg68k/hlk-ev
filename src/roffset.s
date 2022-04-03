		.title	HLK/ev (roffset.s - get roffset table size)


* Include File -------------------------------- *

		.include	hlk.mac


* Global Symbol ------------------------------- *

		.xref	get_com_no
		.xref	skip_com

		.xref	get_xref_label
		.xref	c_stack_over
		.xref	c_stack_under

		.xref	unknown_cmd

calc_size_err:	.reg	unknown_cmd
skip:		.reg	skip_com


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

*------------------------------------------------------------------------------
*
*	calc_roff_sz
*
*	in:	nothing
*
*	out:	roff_tbl_size
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a1,0
		_link_list_	link_list,a2,0

calc_roff_sz::
		link		a6,#-12
		push		d1-d6/a0-a3

		moveq.l		#0,d6			;d6.l = roff_tbl_size
		lea		(workbuf+LINK_LIST_HEAD,pc),a2
		move.l		(a2),d0			;a2.l = link_list_head
		beq		calc_size_b20
calc_size_l11:
		movea.l		d0,a2
		move.l		link_list_obj_list,a1	* a1.l = obj_list

		move.w		#1,d5			* d5.w = section no.
		movea.l		obj_list_obj_image,a0	* a0.l = obj_image
		move		(a0),d0
		beq		calc_size_b10
calc_size_l12:
		move		d0,d1
		bsr		get_com_no
		bmi		calc_size_err		* unknown command

		add		d0,d0
		lea		(jump_table,pc),a3
		move		(a3,d0.w),d0
		jsr		(a3,d0.w)		* d1.w = command code
		move		(a0),d0
		bne		calc_size_l12
calc_size_b10:
		lea		link_list_next,a2	* a2.l = next
		move.l		(a2),d0
		bne		calc_size_l11
calc_size_b20:
		lea		(workbuf+ROFF_TBL_SIZE,pc),a0
		move.l		d6,(a0)

		pop		d1-d6/a0-a3
		unlk		a6
		rts

*------------------------------------------------------------------------------

chg_sect_2001:
chg_sect_2002:
chg_sect_2003:
chg_sect_2004:
chg_sect_2005:
chg_sect_2006:
chg_sect_2007:
chg_sect_2008:
chg_sect_2009:
chg_sect_200a:
		tst.l		2(a0)
		bne		calc_size_err		* Undefined command
		addq.l		#6,a0

		and.l		#$ff,d1
		move.l		d1,d5

		rts

*------------------------------------------------------------------------------

wrt_lbl_5205:
wrt_lbl_5206:
wrt_lbl_5207:
wrt_lbl_5208:
wrt_lbl_5209:
wrt_lbl_520a:
wrt_lbl_5605:
wrt_lbl_5606:
wrt_lbl_5607:
wrt_lbl_5608:
wrt_lbl_5609:
wrt_lbl_560a:
		addq.l		#2,a0

wrt_lbl_52fc:
wrt_lbl_52fd:
wrt_lbl_56fc:
wrt_lbl_56fd:
		addq.l		#2,a0

wrt_lbl_4205:
wrt_lbl_4206:
wrt_lbl_4207:
wrt_lbl_4208:
wrt_lbl_4209:
wrt_lbl_420a:
wrt_lbl_4605:
wrt_lbl_4606:
wrt_lbl_4607:
wrt_lbl_4608:
wrt_lbl_4609:
wrt_lbl_460a:
		addq.l		#2,a0

wrt_lbl_42fc:
wrt_lbl_42fd:
wrt_lbl_46fc:
wrt_lbl_46fd:
		addq.l		#4,a0

		cmp.w		#$0005,d5		* rdata
		beq		wrt_lbl_560a_b
		cmp.w		#$0008,d5		* rldata
		bne		wrt_lbl_560a_be
wrt_lbl_560a_b	addq.l		#4,d6
wrt_lbl_560a_be	rts


wrt_lbl_52ff:
wrt_lbl_56ff:
		addq.l		#2,a0
		move.w		(a0)+,d0
		addq.l		#4,a0

		cmp.w		#$0005,d5		* rdata
		beq		wrt_lbl_56ff_b
		cmp.w		#$0008,d5		* rldata
		bne		wrt_lbl_56ff_be

wrt_lbl_56ff_b	bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		cmp.w		#$0004,d0
		bls		wrt_lbl_56ff_be
		cmp.w		#$00fe,d0
		beq		wrt_lbl_56ff_be
		addq.l		#4,d6
wrt_lbl_56ff_be	rts


wrt_lbl_42ff:
wrt_lbl_46ff:
		addq.l		#2,a0
		move.w		(a0)+,d0

		cmp.w		#$0005,d5		* rdata
		beq		wrt_lbl_46ff_b
		cmp.w		#$0008,d5		* rldata
		bne		wrt_lbl_46ff_be

wrt_lbl_46ff_b	bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		cmp.w		#$0004,d0
		bls		wrt_lbl_46ff_be
		cmp.w		#$00fe,d0
		beq		wrt_lbl_46ff_be
		addq.l		#4,d6
wrt_lbl_46ff_be	rts


psh_lbl_80fc:
psh_lbl_80fd:
psh_lbl_80fe:
psh_lbl_80ff:
		addq.l		#2,a0
		move.w		(a0)+,d0
		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		tst.w		d0
		beq		psh_lbl_80ff_b2
		cmp.w		#$0004,d0
		bls		psh_lbl_80ff_b1
		cmp.w		#$00fe,d0
		beq		psh_lbl_80ff_b1
		move.w		#2,d0
		bra		psh_lbl_80ff_b2
psh_lbl_80ff_b1	move.w		#1,d0
psh_lbl_80ff_b2	movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_TOP,pc),a3
		beq		c_stack_over		* calc stack over flow
		move.l		d1,-(a3)
		move		d0,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		subq.l		#6,(a3)
		rts


psh_lbl_8000:
		addq.l		#2,a0
		move.l		(a0)+,d1
		movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_TOP,pc),a3
		beq		c_stack_over		* calc stack over flow
		move.l		d1,-(a3)
		move		#0,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		subq.l		#6,(a3)
		rts


psh_lbl_8001:
psh_lbl_8002:
psh_lbl_8003:
psh_lbl_8004:
		addq.l		#2,a0
		move.l		(a0)+,d1
		movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_TOP,pc),a3
		beq		c_stack_over		* calc stack over flow
		move.l		d1,-(a3)
		move		#1,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		subq.l		#6,(a3)
		rts


psh_lbl_8005:
psh_lbl_8006:
psh_lbl_8007:
psh_lbl_8008:
psh_lbl_8009:
psh_lbl_800a:
		addq.l		#2,a0
		move.l		(a0)+,d1
		movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_TOP,pc),a3
		beq		c_stack_over		* calc stack over flow
		move.l		d1,-(a3)
		move		#2,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		subq.l		#6,(a3)
		rts

*------------------------------------------------------------------------------

wrt_stk_9000:
wrt_stk_9100:
wrt_stk_9300:
wrt_stk_9900:
		addq.l		#2,a0			* write stack
		movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_BOT,pc),a3
		beq		c_stack_under		* calc stack under flow
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#6,(a3)
		rts


wrt_stk_9200:
wrt_stk_9600:
		addq.l		#2,a0			* write stack (stk.l)
		movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_BOT,pc),a3
		beq		c_stack_under		* calc stack under flow
		move		(a3)+,d0		* d0.w = type
		move.l		(a3)+,d1		* d1.l = value
		cmp.w		#2,d0
		bne		wrt_stk_9600_be
		cmp.w		#$0004,d5
		bls		wrt_stk_9600_be
		addq.l		#4,d6
wrt_stk_9600_be:
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#6,(a3)
		rts

*------------------------------------------------------------------------------

*------------------------------------------------------------------------------
*
*	chk_cstk_und1
*
*	計算用スタックから値を１つ取り出す。スタックアンダーフローが
*	発生した場合はエラールーチンへジャンプする。
*
*------------------------------------------------------------------------------

chk_cstk_und1:
		addq.l		#2,a0
		movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_BOT,pc),a3
		beq		chk_cstk_err
		move.w		(a3)+,d2
		move.l		(a3)+,d0
		rts


*------------------------------------------------------------------------------
*
*	chk_cstk_und2
*
*	計算用スタックから値を２つ取り出す。スタックアンダーフローが
*	発生した場合はエラールーチンへジャンプする。
*
*------------------------------------------------------------------------------

chk_cstk_und2:
		addq.l		#2,a0
		movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_BOT,pc),a3
		beq		chk_cstk_err
		move.w		(a3)+,d2
		move.l		(a3)+,d0		* d0.l = (stk+0)
		cmp.l		(workbuf+CALC_STACK_BOT,pc),a3
		beq		chk_cstk_err
		move.w		(a3)+,d3
		move.l		(a3)+,d1		* d1.l = (stk+1)
		rts

chk_cstk_err:
		addq.l		#4,sp
		bra		c_stack_under		* calc stack under flow


*------------------------------------------------------------------------------
*
*	chk_calcexp1
*
*	取り出した値が定数なら何もしない。
*	そうでなければ、エラーを表示して無効な値の属性を設定する。
*
*------------------------------------------------------------------------------

chk_calcexp1:
		tst.w		d2
		ble		chk_calcexp1_be
*		bsr		expression_err
		moveq.l		#-1,d2
chk_calcexp1_be	rts


*------------------------------------------------------------------------------
*
*	chk_calcexp2
*
*	取り出した２つの値が２つとも定数なら何もしない。
*	そうでなければ、エラーを表示して無効な値の属性を設定する。
*
*------------------------------------------------------------------------------

chk_calcexp2:
		moveq.l		#0,d4			* d4.w = new stat
		tst.w		d2
		beq		chk_calcexp2_b2
*		bmi		chk_calcexp2_b1
*		bsr		expression_err
chk_calcexp2_b1	moveq.l		#-1,d4			* d4.w = new stat (undefined)
		bra		chk_calcexp2_be

chk_calcexp2_b2	tst.w		d3
		beq		chk_calcexp2_be
*		bmi		chk_calcexp2_b3
*		bsr		expression_err
chk_calcexp2_b3	moveq.l		#-1,d4			* d4.w = new stat (undefined)

chk_calcexp2_be	rts


cal_stk_a001:						* .neg.(stk)
cal_stk_a002:						* (stk)
cal_stk_a003:						* .not.(stk)
cal_stk_a004:						* .high.(stk)
cal_stk_a005:						* .low.(stk)
cal_stk_a006:						* .highw.(stk)
cal_stk_a007:						* .loww.(stk)
		bsr		chk_cstk_und1

		bsr		chk_calcexp1

		move.l		d0,-(a3)
		move.w		d2,-(a3)
		rts


cal_stk_a009:						* (stk+1) * (stk+0)
cal_stk_a00a:						* (stk+1) / (stk+0)
cal_stk_a00b:						* (stk+1) % (stk+0)
cal_stk_a00c:						* (stk+1) .shr. (stk+0)
cal_stk_a00d:						* (stk+1) .shl. (stk+0)
cal_stk_a00e:						* (stk+1) .asr. (stk+0)
cal_stk_a011:						* (stk+1) .eq. (stk+0)
cal_stk_a012:						* (stk+1) .ne. (stk+0)
cal_stk_a013:						* (stk+1) .lt. (stk+0)
cal_stk_a014:						* (stk+1) .le. (stk+0)
cal_stk_a015:						* (stk+1) .gt. (stk+0)
cal_stk_a016:						* (stk+1) .ge. (stk+0)
cal_stk_a017:						* (stk+1) .slt. (stk+0)
cal_stk_a018:						* (stk+1) .sle. (stk+0)
cal_stk_a019:						* (stk+1) .sgt. (stk+0)
cal_stk_a01a:						* (stk+1) .sge. (stk+0)
cal_stk_a01b:						* (stk+1) .and. (stk+0)
cal_stk_a01c:						* (stk+1) .xor. (stk+0)
cal_stk_a01d:						* (stk+1) .or. (stk+0)
		bsr		chk_cstk_und2
		bsr		chk_calcexp2

		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#6,(a3)			;+6+6-6=+6
		rts

cal_stk_a00f:
		bsr		chk_cstk_und2		* (stk+1) - (stk+0)

		tst.w		d2
		beq		cal_stk_a00f_b3
		bgt		cal_stk_a00f_b1
		moveq.l		#-1,d4
		bra		cal_stk_a00f_be

cal_stk_a00f_b1	tst.w		d3
		bge		cal_stk_a00f_b2
		moveq.l		#-1,d4
		bra		cal_stk_a00f_be

cal_stk_a00f_b2	cmp.w		d2,d3
		beq		cal_stk_a00f_b3
*		bsr		expression_err
		moveq.l		#-1,d4
		bra		cal_stk_a00f_be

cal_stk_a00f_b3	move.w		d3,d4
		eor.w		d2,d4
*		sub.l		d0,d1			* d1.l = (stk+1) - (stk+0)

cal_stk_a00f_be	move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#6,(a3)			;+6+6-6=+6
		rts


cal_stk_a010:
		bsr		chk_cstk_und2		* (stk+1) + (stk+0)

		tst.w		d2
		beq		cal_stk_a010_b3
		bgt		cal_stk_a010_b1
		moveq.l		#-1,d4
		bra		cal_stk_a010_be

cal_stk_a010_b1	tst.w		d3
		beq		cal_stk_a010_b3
*		bmi		cal_stk_a010_b2
*		bsr		expression_err
cal_stk_a010_b2	moveq.l		#-1,d4
		bra		cal_stk_a010_be

cal_stk_a010_b3	move.w		d3,d4
		eor.w		d2,d4
*		add.l		d0,d1			* d1.l = (stk+1) + (stk+0)

cal_stk_a010_be	move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#6,(a3)			;+6+6-6=+6
		rts


*------------------------------------------------------------------------------

sub_list:	.macro	call_adr
		.dc	call_adr-jump_table
		.endm

jump_table:	sub_list	calc_size_b10		* $00

		sub_list	skip			* $10

		sub_list	chg_sect_2001		* $2001
		sub_list	chg_sect_2002		* $2002
		sub_list	chg_sect_2003		* $2003
		sub_list	chg_sect_2004		* $2004
		sub_list	chg_sect_2005		* $2005		SXhas
		sub_list	chg_sect_2006		* $2006		SXhas
		sub_list	chg_sect_2007		* $2007		SXhas
		sub_list	chg_sect_2008		* $2008		SXhas
		sub_list	chg_sect_2009		* $2009		SXhas
		sub_list	chg_sect_200a		* $200a		SXhas

		sub_list	skip			* $30

		sub_list	skip			* $40fc		SXhas
		sub_list	skip			* $40fd		SXhas
		sub_list	skip			* $40fe
		sub_list	skip			* $40ff
		sub_list	skip			* $4000
		sub_list	skip			* $4001
		sub_list	skip			* $4002
		sub_list	skip			* $4003
		sub_list	skip			* $4004
		sub_list	skip			* $4005		SXhas
		sub_list	skip			* $4006		SXhas
		sub_list	skip			* $4007		SXhas
		sub_list	skip			* $4008		SXhas
		sub_list	skip			* $4009		SXhas
		sub_list	skip			* $400a		SXhas

		sub_list	skip			* $41fc		SXhas
		sub_list	skip			* $41fd		SXhas
		sub_list	skip			* $41fe
		sub_list	skip			* $41ff
		sub_list	skip			* $4100
		sub_list	skip			* $4101
		sub_list	skip			* $4102
		sub_list	skip			* $4103
		sub_list	skip			* $4104
		sub_list	skip			* $4105		SXhas
		sub_list	skip			* $4106		SXhas
		sub_list	skip			* $4107		SXhas
		sub_list	skip			* $4108		SXhas
		sub_list	skip			* $4109		SXhas
		sub_list	skip			* $410a		SXhas

		sub_list	wrt_lbl_42fc		* $42fc		SXhas
		sub_list	wrt_lbl_42fd		* $42fd		SXhas
		sub_list	skip			* $42fe
		sub_list	wrt_lbl_42ff		* $42ff
		sub_list	skip			* $4200
		sub_list	skip			* $4201
		sub_list	skip			* $4202
		sub_list	skip			* $4203
		sub_list	skip			* $4204
		sub_list	wrt_lbl_4205		* $4205		SXhas
		sub_list	wrt_lbl_4206		* $4206		SXhas
		sub_list	wrt_lbl_4207		* $4207		SXhas
		sub_list	wrt_lbl_4208		* $4208		SXhas
		sub_list	wrt_lbl_4209		* $4209		SXhas
		sub_list	wrt_lbl_420a		* $420a		SXhas

		sub_list	skip			* $43fc		SXhas
		sub_list	skip			* $43fd		SXhas
		sub_list	skip			* $43fe
		sub_list	skip			* $43ff
		sub_list	skip			* $4300
		sub_list	skip			* $4301
		sub_list	skip			* $4302
		sub_list	skip			* $4303
		sub_list	skip			* $4304
		sub_list	skip			* $4305		SXhas
		sub_list	skip			* $4306		SXhas
		sub_list	skip			* $4307		SXhas
		sub_list	skip			* $4308		SXhas
		sub_list	skip			* $4309		SXhas
		sub_list	skip			* $430a		SXhas

		sub_list	skip			* $45fe		v2.00
		sub_list	skip			* $45ff
		sub_list	calc_size_err
		sub_list	calc_size_err
		sub_list	calc_size_err
		sub_list	calc_size_err
		sub_list	calc_size_err

		sub_list	wrt_lbl_46fc		* $46fc		SXhas
		sub_list	wrt_lbl_46fd		* $46fd		SXhas
		sub_list	skip			* $46fe
		sub_list	wrt_lbl_46ff		* $46ff
		sub_list	skip			* $4600
		sub_list	skip			* $4601
		sub_list	skip			* $4602
		sub_list	skip			* $4603
		sub_list	skip			* $4604
		sub_list	wrt_lbl_4605		* $4605		SXhas
		sub_list	wrt_lbl_4606		* $4606		SXhas
		sub_list	wrt_lbl_4607		* $4607		SXhas
		sub_list	wrt_lbl_4608		* $4608		SXhas
		sub_list	wrt_lbl_4609		* $4609		SXhas
		sub_list	wrt_lbl_460a		* $460a		SXhas

		sub_list	skip			* $47fe		v2.00
		sub_list	skip			* $47ff
		sub_list	calc_size_err
		sub_list	calc_size_err
		sub_list	calc_size_err
		sub_list	calc_size_err
		sub_list	calc_size_err

		sub_list	skip			+ $4c01 .ctor adr.l
		sub_list	skip			+ $4d01 .dtor adr.l

		sub_list	skip			* $50fc		SXhas
		sub_list	skip			* $50fd		SXhas
		sub_list	skip			* $50fe
		sub_list	skip			* $50ff
		sub_list	skip			* $5000
		sub_list	skip			* $5001
		sub_list	skip			* $5002
		sub_list	skip			* $5003
		sub_list	skip			* $5004
		sub_list	skip			* $5005		SXhas
		sub_list	skip			* $5006		SXhas
		sub_list	skip			* $5007		SXhas
		sub_list	skip			* $5008		SXhas
		sub_list	skip			* $5009		SXhas
		sub_list	skip			* $500a		SXhas

		sub_list	skip			* $51fc		SXhas
		sub_list	skip			* $51fd		SXhas
		sub_list	skip			* $51fe		v2.00 ??
		sub_list	skip			* $51ff
		sub_list	skip			* $5100
		sub_list	skip			* $5101
		sub_list	skip			* $5102
		sub_list	skip			* $5103
		sub_list	skip			* $5104
		sub_list	skip			* $5105		SXhas
		sub_list	skip			* $5106		SXhas
		sub_list	skip			* $5107		SXhas
		sub_list	skip			* $5108		SXhas
		sub_list	skip			* $5109		SXhas
		sub_list	skip			* $510a		SXhas

		sub_list	wrt_lbl_52fc		* $52fc		SXhas
		sub_list	wrt_lbl_52fd		* $52fd		SXhas
		sub_list	skip			* $52fe		v2.00 ??
		sub_list	wrt_lbl_52ff		* $52ff
		sub_list	skip			* $5200
		sub_list	skip			* $5201
		sub_list	skip			* $5202
		sub_list	skip			* $5203
		sub_list	skip			* $5204
		sub_list	wrt_lbl_5205		* $5205		SXhas
		sub_list	wrt_lbl_5206		* $5206		SXhas
		sub_list	wrt_lbl_5207		* $5207		SXhas
		sub_list	wrt_lbl_5208		* $5208		SXhas
		sub_list	wrt_lbl_5209		* $5209		SXhas
		sub_list	wrt_lbl_520a		* $520a		SXhas

		sub_list	skip			* $53fc		SXhas
		sub_list	skip			* $53fd		SXhas
		sub_list	skip			* $53fe		v2.00 ??
		sub_list	skip			* $53ff
		sub_list	skip			* $5300
		sub_list	skip			* $5301
		sub_list	skip			* $5302
		sub_list	skip			* $5303
		sub_list	skip			* $5304
		sub_list	skip			* $5305		SXhas
		sub_list	skip			* $5306		SXhas
		sub_list	skip			* $5307		SXhas
		sub_list	skip			* $5308		SXhas
		sub_list	skip			* $5309		SXhas
		sub_list	skip			* $530a		SXhas

		sub_list	skip			* $55fe		v2.00 ??
		sub_list	skip			* $55ff		v2.00
		sub_list	calc_size_err
		sub_list	calc_size_err
		sub_list	calc_size_err
		sub_list	calc_size_err
		sub_list	calc_size_err

		sub_list	wrt_lbl_56fc		* $56fc		SXhas
		sub_list	wrt_lbl_56fd		* $56fd		SXhas
		sub_list	skip			* $56fe		v2.00 ??
		sub_list	wrt_lbl_56ff		* $56ff
		sub_list	skip			* $5600
		sub_list	skip			* $5601
		sub_list	skip			* $5602
		sub_list	skip			* $5603
		sub_list	skip			* $5604
		sub_list	wrt_lbl_5605		* $5605		SXhas
		sub_list	wrt_lbl_5606		* $5606		SXhas
		sub_list	wrt_lbl_5607		* $5607		SXhas
		sub_list	wrt_lbl_5608		* $5608		SXhas
		sub_list	wrt_lbl_5609		* $5609		SXhas
		sub_list	wrt_lbl_560a		* $560a		SXhas

		sub_list	skip			* $57fe		v2.00 ??
		sub_list	skip			* $57ff		v2.00
		sub_list	calc_size_err
		sub_list	calc_size_err
		sub_list	calc_size_err
		sub_list	calc_size_err
		sub_list	calc_size_err

		sub_list	skip			* $6501
		sub_list	skip			* $6502
		sub_list	skip			* $6503
		sub_list	skip			* $6504
		sub_list	skip			* $6505		SXhas
		sub_list	skip			* $6506		SXhas
		sub_list	skip			* $6507		SXhas
		sub_list	skip			* $6508		SXhas
		sub_list	skip			* $6509		SXhas
		sub_list	skip			* $650a		SXhas

		sub_list	skip			* $6901		v2.00
		sub_list	skip			* $6902		v2.00
		sub_list	skip			* $6903		v2.00
		sub_list	skip			* $6904		v2.00
		sub_list	skip			* $6905		SXhas
		sub_list	skip			* $6906		SXhas
		sub_list	skip			* $6907		SXhas
		sub_list	skip			* $6908		SXhas
		sub_list	skip			* $6909		SXhas
		sub_list	skip			* $690a		SXhas

		sub_list	skip			* $6b01		v2.00
		sub_list	skip			* $6b02		v2.00
		sub_list	skip			* $6b03		v2.00
		sub_list	skip			* $6b04		v2.00
		sub_list	skip			* $6b05		SXhas
		sub_list	skip			* $6b06		SXhas
		sub_list	skip			* $6b07		SXhas
		sub_list	skip			* $6b08		SXhas
		sub_list	skip			* $6b09		SXhas
		sub_list	skip			* $6b0a		SXhas

		sub_list	psh_lbl_80fc		* $80fc		SXhas
		sub_list	psh_lbl_80fd		* $80fd		SXhas
		sub_list	psh_lbl_80fe		* $80fe		v2.00 ??
		sub_list	psh_lbl_80ff		* $80ff
		sub_list	psh_lbl_8000		* $8000
		sub_list	psh_lbl_8001		* $8001
		sub_list	psh_lbl_8002		* $8002
		sub_list	psh_lbl_8003		* $8003
		sub_list	psh_lbl_8004		* $8004
		sub_list	psh_lbl_8005		* $8005		SXhas
		sub_list	psh_lbl_8006		* $8006		SXhas
		sub_list	psh_lbl_8007		* $8007		SXhas
		sub_list	psh_lbl_8008		* $8008		SXhas
		sub_list	psh_lbl_8009		* $8009		SXhas
		sub_list	psh_lbl_800a		* $800a		SXhas

		sub_list	wrt_stk_9000		* $9000
		sub_list	wrt_stk_9100		* $9100
		sub_list	wrt_stk_9200		* $9200
		sub_list	wrt_stk_9300		* $9300
		sub_list	wrt_stk_9600		* $9600
		sub_list	wrt_stk_9900		* $9900

		sub_list	cal_stk_a001		* $a001
		sub_list	cal_stk_a002		* $a002
		sub_list	cal_stk_a003		* $a003
		sub_list	cal_stk_a004		* $a004
		sub_list	cal_stk_a005		* $a005
		sub_list	cal_stk_a006		* $a006
		sub_list	cal_stk_a007		* $a007
		sub_list	calc_size_err
		sub_list	cal_stk_a009		* $a009
		sub_list	cal_stk_a00a		* $a00a
		sub_list	cal_stk_a00b		* $a00b
		sub_list	cal_stk_a00c		* $a00c
		sub_list	cal_stk_a00d		* $a00d
		sub_list	cal_stk_a00e		* $a00e
		sub_list	cal_stk_a00f		* $a00f
		sub_list	cal_stk_a010		* $a010
		sub_list	cal_stk_a011		* $a011
		sub_list	cal_stk_a012		* $a012
		sub_list	cal_stk_a013		* $a013
		sub_list	cal_stk_a014		* $a014
		sub_list	cal_stk_a015		* $a015
		sub_list	cal_stk_a016		* $a016
		sub_list	cal_stk_a017		* $a017
		sub_list	cal_stk_a018		* $a018
		sub_list	cal_stk_a019		* $a019
		sub_list	cal_stk_a01a		* $a01a
		sub_list	cal_stk_a01b		* $a01b
		sub_list	cal_stk_a01c		* $a01c
		sub_list	cal_stk_a01d		* $a01d
		sub_list	calc_size_err
		sub_list	calc_size_err

		sub_list	skip			* $b0ff

		sub_list	skip			* $b2fc		SXhas
		sub_list	skip			* $b2fd		SXhas
		sub_list	skip			* $b2fe
		sub_list	skip			* $b2ff
		sub_list	skip			* $b200
		sub_list	skip			* $b201
		sub_list	skip			* $b202
		sub_list	skip			* $b203
		sub_list	skip			* $b204
		sub_list	skip			* $b205		SXhas
		sub_list	skip			* $b206		SXhas
		sub_list	skip			* $b207		SXhas
		sub_list	skip			* $b208		SXhas
		sub_list	skip			* $b209		SXhas
		sub_list	skip			* $b20a		SXhas

		sub_list	skip			* $c001
		sub_list	skip			* $c002
		sub_list	skip			* $c003
		sub_list	skip			* $c004
		sub_list	skip			* $c005		SXhas
		sub_list	skip			* $c006		SXhas
		sub_list	skip			* $c007		SXhas
		sub_list	skip			* $c008		SXhas
		sub_list	skip			* $c009		SXhas
		sub_list	skip			* $c00a		SXhas

		sub_list	calc_size_err		+
		sub_list	skip			+ $c00c size.l 'ctor',0
		sub_list	skip			+ $c00d size.l 'dtor',0

		sub_list	skip			* $d000

		sub_list	skip			* $e000
		sub_list	skip			* $e001

	.rept	$e00c-($e001+1)
		sub_list	calc_size_err		+
	.endm
		sub_list	skip			+ $e00c .doctor
		sub_list	skip			+ $e00d .dodtor

		.end

* End of File --------------------------------- *
