		.title	HLK/ev (analyze.s - analize object module)


* Include File -------------------------------- *

		.include	hlk.mac


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

*------------------------------------------------------------------------------
*
*	get_com_no
*
*	in:	d0.w	コマンドコード
*
*	out:	d0.l	ステータス
*
*	ステータス:	-1	unknown command
*			other	command no
*
*------------------------------------------------------------------------------

get_com_no::
		PUSH		d1-d2/a0
		move		d0,d1
		beq		get_com_no_0		;$0000
		lsr		#8,d1
		cmpi.b		#$10,d1
		beq		get_com_no_1		;$10xx
		add		d1,d1
		lea		(index_table,pc),a0
		move		(a0,d1.w),d1
		beq		get_com_no_err		* unknown command

		lea		(command_table,pc),a0
		move.b		d0,d2
		ext		d2
		add		d2,d2
		add		d1,d2
		cmp		(a0,d2.w),d0
		bne		get_com_no_err
		lsr		#1,d2
		moveq		#0,d0
		move		d2,d0
get_com_no_end:	POP		d1-d2/a0
		tst.l		d0
		rts

get_com_no_0:	moveq		#0,d0
		bra		get_com_no_end
get_com_no_1:	moveq		#1,d0
		bra		get_com_no_end
get_com_no_err:	moveq		#-1,d0
		bra		get_com_no_end


*------------------------------------------------------------------------------
*
*	skip_com
*
*	in:	a0.l	コマンドへのポインタ
*
*	out:	d0.l	ステータス
*		a0.l	次のコマンドへのポインタ
*
*	ステータス:	-1	unknown command
*			0	ok
*
*------------------------------------------------------------------------------

skip_com::
		PUSH		d1/a1
		move.w		(a0)+,d0
		move.w		d0,d1
		bsr		get_com_no
		bmi		skip_com_err		* unknown command

		add		d0,d0
		lea		(jump_table,pc),a1
		move		(a1,d0.w),d0
		jsr		(a1,d0.w)		* d1.w = command code
		moveq		#0,d0
@@:		POP		d1/a1
		rts

skip_com_err:
		subq.l		#2,a0
		moveq		#-1,d0
		bra		@b


object_end:	subq.l		#2,a0
		rts


define_const:	andi		#$fe,d1
		addq		#2,d1
		adda		d1,a0
		rts


wrt_stk_9000:
wrt_stk_9100:
wrt_stk_9200:
wrt_stk_9300:
wrt_stk_9600:
wrt_stk_9900:
cal_stk_a001:
cal_stk_a002:
cal_stk_a003:
cal_stk_a004:
cal_stk_a005:
cal_stk_a006:
cal_stk_a007:
cal_stk_a009:
cal_stk_a00a:
cal_stk_a00b:
cal_stk_a00c:
cal_stk_a00d:
cal_stk_a00e:
cal_stk_a00f:
cal_stk_a010:
cal_stk_a011:
cal_stk_a012:
cal_stk_a013:
cal_stk_a014:
cal_stk_a015:
cal_stk_a016:
cal_stk_a017:
cal_stk_a018:
cal_stk_a019:
cal_stk_a01a:
cal_stk_a01b:
cal_stk_a01c:
cal_stk_a01d:
do_ctor_e00c:
do_dtor_e00d:
		rts

wrt_lbl_40fc:	* SXhas
wrt_lbl_40fd:	* SXhas
wrt_lbl_40fe:
wrt_lbl_40ff:
wrt_lbl_41fc:	* SXhas
wrt_lbl_41fd:	* SXhas
wrt_lbl_41fe:
wrt_lbl_41ff:
wrt_lbl_42fc:	* SXhas
wrt_lbl_42fd:	* SXhas
wrt_lbl_42fe:
wrt_lbl_42ff:
wrt_lbl_43fc:	* SXhas
wrt_lbl_43fd:	* SXhas
wrt_lbl_43fe:
wrt_lbl_43ff:
wrt_lbl_45fe:	* v2.00
wrt_lbl_45ff:	* v2.00
wrt_lbl_46fc:	* SXhas
wrt_lbl_46fd:	* SXhas
wrt_lbl_46fe:
wrt_lbl_46ff:
wrt_lbl_47fe:	* v2.00
wrt_lbl_47ff:	* v2.00
psh_lbl_80fc:	* SXhas
psh_lbl_80fd:	* SXhas
psh_lbl_80fe:	* v2.00 ??
psh_lbl_80ff:
		addq.l		#2,a0
		rts


chg_sect_2001:
chg_sect_2002:
chg_sect_2003:
chg_sect_2004:
chg_sect_2005:	* SXhas
chg_sect_2006:	* SXhas
chg_sect_2007:	* SXhas
chg_sect_2008:	* SXhas
chg_sect_2009:	* SXhas
chg_sect_200a:	* SXhas
define_space:
wrt_lbl_4000:
wrt_lbl_4001:
wrt_lbl_4002:
wrt_lbl_4003:
wrt_lbl_4004:
wrt_lbl_4005:	* SXhas
wrt_lbl_4006:	* SXhas
wrt_lbl_4007:	* SXhas
wrt_lbl_4008:	* SXhas
wrt_lbl_4009:	* SXhas
wrt_lbl_400a:	* SXhas
wrt_lbl_4100:
wrt_lbl_4101:
wrt_lbl_4102:
wrt_lbl_4103:
wrt_lbl_4104:
wrt_lbl_4105:	* SXhas
wrt_lbl_4106:	* SXhas
wrt_lbl_4107:	* SXhas
wrt_lbl_4108:	* SXhas
wrt_lbl_4109:	* SXhas
wrt_lbl_410a:	* SXhas
wrt_lbl_4200:
wrt_lbl_4201:
wrt_lbl_4202:
wrt_lbl_4203:
wrt_lbl_4204:
wrt_lbl_4205:	* SXhas
wrt_lbl_4206:	* SXhas
wrt_lbl_4207:	* SXhas
wrt_lbl_4208:	* SXhas
wrt_lbl_4209:	* SXhas
wrt_lbl_420a:	* SXhas
wrt_lbl_4300:
wrt_lbl_4301:
wrt_lbl_4302:
wrt_lbl_4303:
wrt_lbl_4304:
wrt_lbl_4305:	* SXhas
wrt_lbl_4306:	* SXhas
wrt_lbl_4307:	* SXhas
wrt_lbl_4308:	* SXhas
wrt_lbl_4309:	* SXhas
wrt_lbl_430a:	* SXhas
wrt_lbl_4600:
wrt_lbl_4601:
wrt_lbl_4602:
wrt_lbl_4603:
wrt_lbl_4604:
wrt_lbl_4605:	* SXhas
wrt_lbl_4606:	* SXhas
wrt_lbl_4607:	* SXhas
wrt_lbl_4608:	* SXhas
wrt_lbl_4609:	* SXhas
wrt_lbl_460a:	* SXhas
wrt_ctor_4c01:
wrt_dtor_4d01:
psh_lbl_8000:
psh_lbl_8001:
psh_lbl_8002:
psh_lbl_8003:
psh_lbl_8004:
psh_lbl_8005:	* SXhas
psh_lbl_8006:	* SXhas
psh_lbl_8007:	* SXhas
psh_lbl_8008:	* SXhas
psh_lbl_8009:	* SXhas
psh_lbl_800a:	* SXhas
		addq.l		#4,a0
		rts


wrt_lbl_50fc:	* SXhas
wrt_lbl_50fd:	* SXhas
wrt_lbl_50fe:
wrt_lbl_50ff:
wrt_lbl_51fc:	* SXhas
wrt_lbl_51fd:	* SXhas
wrt_lbl_51fe:	* v2.00 ??
wrt_lbl_51ff:
wrt_lbl_52fc:	* SXhas
wrt_lbl_52fd:	* SXhas
wrt_lbl_52fe:	* v2.00 ??
wrt_lbl_52ff:
wrt_lbl_53fc:	* SXhas
wrt_lbl_53fd:	* SXhas
wrt_lbl_53fe:	* v2.00 ??
wrt_lbl_53ff:
wrt_lbl_55fe:	* v2.00 ??
wrt_lbl_55ff:	* v2.00
wrt_lbl_56fc:	* SXhas
wrt_lbl_56fd:	* SXhas
wrt_lbl_56fe:	* v2.00 ??
wrt_lbl_56ff:
wrt_lbl_57fe:	* v2.00 ??
wrt_lbl_57ff:	* v2.00
wrt_lbl_6501:
wrt_lbl_6502:
wrt_lbl_6503:
wrt_lbl_6504:
wrt_lbl_6505:	* SXhas
wrt_lbl_6506:	* SXhas
wrt_lbl_6507:	* SXhas
wrt_lbl_6508:	* SXhas
wrt_lbl_6509:	* SXhas
wrt_lbl_650a:	* SXhas
wrt_lbl_6901:	* v2.00
wrt_lbl_6902:	* v2.00
wrt_lbl_6903:	* v2.00
wrt_lbl_6904:	* v2.00
wrt_lbl_6905:	* SXhas
wrt_lbl_6906:	* SXhas
wrt_lbl_6907:	* SXhas
wrt_lbl_6908:	* SXhas
wrt_lbl_6909:	* SXhas
wrt_lbl_690a:	* SXhas
wrt_lbl_6b01:	* v2.00
wrt_lbl_6b02:	* v2.00
wrt_lbl_6b03:	* v2.00
wrt_lbl_6b04:	* v2.00
wrt_lbl_6b05:	* SXhas
wrt_lbl_6b06:	* SXhas
wrt_lbl_6b07:	* SXhas
wrt_lbl_6b08:	* SXhas
wrt_lbl_6b09:	* SXhas
wrt_lbl_6b0a:	* SXhas
set_exec_adr:
		addq.l		#6,a0
		rts


wrt_lbl_5000:
wrt_lbl_5001:
wrt_lbl_5002:
wrt_lbl_5003:
wrt_lbl_5004:
wrt_lbl_5005:	* SXhas
wrt_lbl_5006:	* SXhas
wrt_lbl_5007:	* SXhas
wrt_lbl_5008:	* SXhas
wrt_lbl_5009:	* SXhas
wrt_lbl_500a:	* SXhas
wrt_lbl_5100:
wrt_lbl_5101:
wrt_lbl_5102:
wrt_lbl_5103:
wrt_lbl_5104:
wrt_lbl_5105:	* SXhas
wrt_lbl_5106:	* SXhas
wrt_lbl_5107:	* SXhas
wrt_lbl_5108:	* SXhas
wrt_lbl_5109:	* SXhas
wrt_lbl_510a:	* SXhas
wrt_lbl_5200:
wrt_lbl_5201:
wrt_lbl_5202:
wrt_lbl_5203:
wrt_lbl_5204:
wrt_lbl_5205:	* SXhas
wrt_lbl_5206:	* SXhas
wrt_lbl_5207:	* SXhas
wrt_lbl_5208:	* SXhas
wrt_lbl_5209:	* SXhas
wrt_lbl_520a:	* SXhas
wrt_lbl_5300:
wrt_lbl_5301:
wrt_lbl_5302:
wrt_lbl_5303:
wrt_lbl_5304:
wrt_lbl_5305:	* SXhas
wrt_lbl_5306:	* SXhas
wrt_lbl_5307:	* SXhas
wrt_lbl_5308:	* SXhas
wrt_lbl_5309:	* SXhas
wrt_lbl_530a:	* SXhas
wrt_lbl_5600:
wrt_lbl_5601:
wrt_lbl_5602:
wrt_lbl_5603:
wrt_lbl_5604:
wrt_lbl_5605:	* SXhas
wrt_lbl_5606:	* SXhas
wrt_lbl_5607:	* SXhas
wrt_lbl_5608:	* SXhas
wrt_lbl_5609:	* SXhas
wrt_lbl_560a:	* SXhas
		addq.l		#8,a0
		rts


def_lbl_b0ff:
def_lbl_b2fc:	* SXhas
def_lbl_b2fd:	* SXhas
def_lbl_b2fe:
def_lbl_b2ff:
def_lbl_b200:
def_lbl_b201:
def_lbl_b202:
def_lbl_b203:
def_lbl_b204:
def_lbl_b205:	* SXhas
def_lbl_b206:	* SXhas
def_lbl_b207:	* SXhas
def_lbl_b208:	* SXhas
def_lbl_b209:	* SXhas
def_lbl_b20a:	* SXhas
obj_head_c001:
obj_head_c002:
obj_head_c003:
obj_head_c004:
obj_head_c005:	* SXhas
obj_head_c006:	* SXhas
obj_head_c007:	* SXhas
obj_head_c008:	* SXhas
obj_head_c009:	* SXhas
obj_head_c00a:	* SXhas
obj_head_c00c:
obj_head_c00d:
obj_name:
		addq.l		#4,a0
		bra		skip_string
*		rts


req_obj:
		bra		skip_string
*		rts

*------------------------------------------------------------------------------
*
*	skip string
*
*	in:	a0.l (even)
*
*	out:	a0.l (even)
*
*------------------------------------------------------------------------------

**skip_string::
**		tst.b	(a0)+
**		bne	skip_string
**		move	a0,-(sp)
**		lsr	(sp)+
**		bcc	@f
**		addq.l	#1,a0
**@@:		rts


@@:		tst.b	(a0)+
		beq	@f
skip_string::	tst.b	(a0)+
		bne	@b
		addq.l	#1,a0
@@:		rts


*------------------------------------------------------------------------------

index_table:
		.dc	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0		;$0x??($0000は特別扱い)
		.dc	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0		;$1x??($01xxは特別扱い)
		.dc	(cmd0x2000-command_table)		;$2x??
		.dc	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.dc	(cmd0x3000-command_table)		;$3x??
		.dc	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.dc	(cmd0x4000-command_table)		;$4x??
		.dc	(cmd0x4100-command_table)
		.dc	(cmd0x4200-command_table)
		.dc	(cmd0x4300-command_table)
		.dc	0
		.dc	(cmd0x4500-command_table)
		.dc	(cmd0x4600-command_table)
		.dc	(cmd0x4700-command_table)
		.dc	0,0,0,0
		.dc	(cmd0x4c00-command_table)
		.dc	(cmd0x4d00-command_table)
		.dc	0,0
		.dc	(cmd0x5000-command_table)		;$5x??
		.dc	(cmd0x5100-command_table)
		.dc	(cmd0x5200-command_table)
		.dc	(cmd0x5300-command_table)
		.dc	0
		.dc	(cmd0x5500-command_table)
		.dc	(cmd0x5600-command_table)
		.dc	(cmd0x5700-command_table)
		.dc	0,0,0,0,0,0,0,0
		.dc	0,0,0,0,0				;$6x??
		.dc	(cmd0x6500-command_table)
		.dc	0,0,0
		.dc	(cmd0x6900-command_table)
		.dc	0
		.dc	(cmd0x6b00-command_table)
		.dc	0,0,0,0
		.dc	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0		;$7x??
		.dc	(cmd0x8000-command_table)		;$8x??
		.dc	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.dc	(cmd0x9000-command_table)		;$9x??
		.dc	(cmd0x9100-command_table)
		.dc	(cmd0x9200-command_table)
		.dc	(cmd0x9300-command_table)
		.dc	0,0
		.dc	(cmd0x9600-command_table)
		.dc	0,0
		.dc	(cmd0x9900-command_table)
		.dc	0,0,0,0,0,0
		.dc	(cmd0xa000-command_table)		;$ax??
		.dc	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.dc	(cmd0xb000-command_table)		;$bx??
		.dc	0
		.dc	(cmd0xb200-command_table)
		.dc	0,0,0,0,0,0,0,0,0,0,0,0,0
		.dc	(cmd0xc000-command_table)		;$cx??
		.dc	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.dc	(cmd0xd000-command_table)		;$dx??
		.dc	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.dc	(cmd0xe000-command_table)		;$ex??
		.dc	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		.dc	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0		;$fx??


		.ds		128
command_table:
		.dc		0
cmd0x2000:	.dc		0
		.dc		$2001
		.dc		$2002
		.dc		$2003
		.dc		$2004
		.dc		$2005		* SXhas
		.dc		$2006		* SXhas
		.dc		$2007		* SXhas
		.dc		$2008		* SXhas
		.dc		$2009		* SXhas
		.dc		$200a		* SXhas

cmd0x3000:	.dc		$3000

		.dc		$40fc		* SXhas
		.dc		$40fd		* SXhas
		.dc		$40fe
		.dc		$40ff
cmd0x4000:	.dc		$4000
		.dc		$4001
		.dc		$4002
		.dc		$4003
		.dc		$4004
		.dc		$4005		* SXhas
		.dc		$4006		* SXhas
		.dc		$4007		* SXhas
		.dc		$4008		* SXhas
		.dc		$4009		* SXhas
		.dc		$400a		* SXhas

		.dc		$41fc		* SXhas
		.dc		$41fd		* SXhas
		.dc		$41fe
		.dc		$41ff
cmd0x4100:	.dc		$4100
		.dc		$4101
		.dc		$4102
		.dc		$4103
		.dc		$4104
		.dc		$4105		* SXhas
		.dc		$4106		* SXhas
		.dc		$4107		* SXhas
		.dc		$4108		* SXhas
		.dc		$4109		* SXhas
		.dc		$410a		* SXhas

		.dc		$42fc		* SXhas
		.dc		$42fd		* SXhas
		.dc		$42fe
		.dc		$42ff
cmd0x4200:	.dc		$4200
		.dc		$4201
		.dc		$4202
		.dc		$4203
		.dc		$4204
		.dc		$4205		* SXhas
		.dc		$4206		* SXhas
		.dc		$4207		* SXhas
		.dc		$4208		* SXhas
		.dc		$4209		* SXhas
		.dc		$420a		* SXhas

		.dc		$43fc		* SXhas
		.dc		$43fd		* SXhas
		.dc		$43fe
		.dc		$43ff
cmd0x4300:	.dc		$4300
		.dc		$4301
		.dc		$4302
		.dc		$4303
		.dc		$4304
		.dc		$4305		* SXhas
		.dc		$4306		* SXhas
		.dc		$4307		* SXhas
		.dc		$4308		* SXhas
		.dc		$4309		* SXhas
		.dc		$430a		* SXhas

		.dc		$45fe		* v2.00
		.dc		$45ff		* v2.00
cmd0x4500:	.dc		0		* reserved
		.dc		0		* reserved
		.dc		0		* reserved
		.dc		0		* reserved
		.dc		0		* reserved

		.dc		$46fc		* SXhas
		.dc		$46fd		* SXhas
		.dc		$46fe
		.dc		$46ff
cmd0x4600:	.dc		$4600
		.dc		$4601
		.dc		$4602
		.dc		$4603
		.dc		$4604
		.dc		$4605		* SXhas
		.dc		$4606		* SXhas
		.dc		$4607		* SXhas
		.dc		$4608		* SXhas
		.dc		$4609		* SXhas
		.dc		$460a		* SXhas

		.dc		$47fe		* v2.00
		.dc		$47ff		* v2.00
cmd0x4700:	.dc		0		* reserved
		.dc		0		* reserved
		.dc		0		* reserved
		.dc		0		* reserved
cmd0x4c00:	.dc		0		* reserved

cmd0x4d00:	.dc		$4c01		+ .ctor adr.l
		.dc		$4d01		+ .dtor adr.l

		.dc		$50fc		* SXhas
		.dc		$50fd		* SXhas
		.dc		$50fe
		.dc		$50ff
cmd0x5000:	.dc		$5000
		.dc		$5001
		.dc		$5002
		.dc		$5003
		.dc		$5004
		.dc		$5005		* SXhas
		.dc		$5006		* SXhas
		.dc		$5007		* SXhas
		.dc		$5008		* SXhas
		.dc		$5009		* SXhas
		.dc		$500a		* SXhas

		.dc		$51fc		* SXhas
		.dc		$51fd		* SXhas
		.dc		$51fe		* v2.00 ??
		.dc		$51ff
cmd0x5100:	.dc		$5100
		.dc		$5101
		.dc		$5102
		.dc		$5103
		.dc		$5104
		.dc		$5105		* SXhas
		.dc		$5106		* SXhas
		.dc		$5107		* SXhas
		.dc		$5108		* SXhas
		.dc		$5109		* SXhas
		.dc		$510a		* SXhas

		.dc		$52fc		* SXhas
		.dc		$52fd		* SXhas
		.dc		$52fe		* v2.00 ??
		.dc		$52ff
cmd0x5200:	.dc		$5200
		.dc		$5201
		.dc		$5202
		.dc		$5203
		.dc		$5204
		.dc		$5205		* SXhas
		.dc		$5206		* SXhas
		.dc		$5207		* SXhas
		.dc		$5208		* SXhas
		.dc		$5209		* SXhas
		.dc		$520a		* SXhas

		.dc		$53fc		* SXhas
		.dc		$53fd		* SXhas
		.dc		$53fe		* v2.00 ??
		.dc		$53ff
cmd0x5300:	.dc		$5300
		.dc		$5301
		.dc		$5302
		.dc		$5303
		.dc		$5304
		.dc		$5305		* SXhas
		.dc		$5306		* SXhas
		.dc		$5307		* SXhas
		.dc		$5308		* SXhas
		.dc		$5309		* SXhas
		.dc		$530a		* SXhas

		.dc		$55fe		* v2.00 ??
		.dc		$55ff		* v2.00
cmd0x5500:	.dc		0		* reserved
		.dc		0		* reserved
		.dc		0		* reserved
		.dc		0		* reserved
		.dc		0		* reserved

		.dc		$56fc		* SXhas
		.dc		$56fd		* SXhas
		.dc		$56fe		* v2.00 ??
		.dc		$56ff
cmd0x5600:	.dc		$5600
		.dc		$5601
		.dc		$5602
		.dc		$5603
		.dc		$5604
		.dc		$5605		* SXhas
		.dc		$5606		* SXhas
		.dc		$5607		* SXhas
		.dc		$5608		* SXhas
		.dc		$5609		* SXhas
		.dc		$560a		* SXhas

		.dc		$57fe		* v2.00 ??
		.dc		$57ff		* v2.00
cmd0x5700:	.dc		0		* reserved
		.dc		0		* reserved
		.dc		0		* reserved
		.dc		0		* reserved
cmd0x6500:	.dc		0		* reserved

		.dc		$6501
		.dc		$6502
		.dc		$6503
		.dc		$6504
		.dc		$6505		* SXhas
		.dc		$6506		* SXhas
		.dc		$6507		* SXhas
		.dc		$6508		* SXhas
		.dc		$6509		* SXhas
cmd0x6900:	.dc		$650a		* SXhas

		.dc		$6901		* v2.00
		.dc		$6902		* v2.00
		.dc		$6903		* v2.00
		.dc		$6904		* v2.00
		.dc		$6905		* SXhas
		.dc		$6906		* SXhas
		.dc		$6907		* SXhas
		.dc		$6908		* SXhas
		.dc		$6909		* SXhas
cmd0x6b00:	.dc		$690a		* SXhas

		.dc		$6b01		* v2.00
		.dc		$6b02		* v2.00
		.dc		$6b03		* v2.00
		.dc		$6b04		* v2.00
		.dc		$6b05		* SXhas
		.dc		$6b06		* SXhas
		.dc		$6b07		* SXhas
		.dc		$6b08		* SXhas
		.dc		$6b09		* SXhas
		.dc		$6b0a		* SXhas

		.dc		$80fc		* SXhas
		.dc		$80fd		* SXhas
		.dc		$80fe		* v2.00 ?? (found)
		.dc		$80ff
cmd0x8000:	.dc		$8000
		.dc		$8001
		.dc		$8002
		.dc		$8003
		.dc		$8004
		.dc		$8005		* SXhas
		.dc		$8006		* SXhas
		.dc		$8007		* SXhas
		.dc		$8008		* SXhas
		.dc		$8009		* SXhas
		.dc		$800a		* SXhas

cmd0x9000:	.dc		$9000

cmd0x9100:	.dc		$9100

cmd0x9200:	.dc		$9200

cmd0x9300:	.dc		$9300

cmd0x9600:	.dc		$9600

cmd0x9900:
cmd0xa000:	.dc		$9900

		.dc		$a001
		.dc		$a002
		.dc		$a003
		.dc		$a004
		.dc		$a005
		.dc		$a006
		.dc		$a007
		.dc		0		* reserved
		.dc		$a009
		.dc		$a00a
		.dc		$a00b
		.dc		$a00c
		.dc		$a00d
		.dc		$a00e
		.dc		$a00f
		.dc		$a010
		.dc		$a011
		.dc		$a012
		.dc		$a013
		.dc		$a014
		.dc		$a015
		.dc		$a016
		.dc		$a017
		.dc		$a018
		.dc		$a019
		.dc		$a01a
		.dc		$a01b
		.dc		$a01c
		.dc		$a01d
		.dc		0		* reserved
		.dc		0		* reserved

		.dc		$b0ff

cmd0xb000:	.dc		$b2fc		* SXhas
		.dc		$b2fd		* SXhas
		.dc		$b2fe
		.dc		$b2ff
cmd0xb200:	.dc		$b200
		.dc		$b201
		.dc		$b202
		.dc		$b203
		.dc		$b204
		.dc		$b205		* SXhas
		.dc		$b206		* SXhas
		.dc		$b207		* SXhas
		.dc		$b208		* SXhas
		.dc		$b209		* SXhas
cmd0xc000:	.dc		$b20a		* SXhas

		.dc		$c001
		.dc		$c002
		.dc		$c003
		.dc		$c004
		.dc		$c005		* SXhas
		.dc		$c006		* SXhas
		.dc		$c007		* SXhas
		.dc		$c008		* SXhas
		.dc		$c009		* SXhas
		.dc		$c00a		* SXhas

		.dc		0		+
		.dc		$c00c		+ ctor size.l 'ctor',0
		.dc		$c00d		+ dtor size.l 'ctor',0

cmd0xd000:	.dc		$d000

cmd0xe000:	.dc		$e000
		.dc		$e001

		.dc		0,0,0,0,0,0,0,0,0,0
		.dc		$e00c		+ .doctor
		.dc		$e00d		+ .dodtor

		.ds		114

*------------------------------------------------------------------------------

sub_list:	.macro	call_adr
		.dc	call_adr-jump_table
		.endm

jump_table:
		sub_list	object_end		* $00

		sub_list	define_const		* $10

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

		sub_list	define_space		* $30

		sub_list	wrt_lbl_40fc		* $40fc		SXhas
		sub_list	wrt_lbl_40fd		* $40fd		SXhas
		sub_list	wrt_lbl_40fe		* $40fe
		sub_list	wrt_lbl_40ff		* $40ff
		sub_list	wrt_lbl_4000		* $4000
		sub_list	wrt_lbl_4001		* $4001
		sub_list	wrt_lbl_4002		* $4002
		sub_list	wrt_lbl_4003		* $4003
		sub_list	wrt_lbl_4004		* $4004
		sub_list	wrt_lbl_4005		* $4005		SXhas
		sub_list	wrt_lbl_4006		* $4006		SXhas
		sub_list	wrt_lbl_4007		* $4007		SXhas
		sub_list	wrt_lbl_4008		* $4008		SXhas
		sub_list	wrt_lbl_4009		* $4009		SXhas
		sub_list	wrt_lbl_400a		* $400a		SXhas

		sub_list	wrt_lbl_41fc		* $41fc		SXhas
		sub_list	wrt_lbl_41fd		* $41fd		SXhas
		sub_list	wrt_lbl_41fe		* $41fe
		sub_list	wrt_lbl_41ff		* $41ff
		sub_list	wrt_lbl_4100		* $4100
		sub_list	wrt_lbl_4101		* $4101
		sub_list	wrt_lbl_4102		* $4102
		sub_list	wrt_lbl_4103		* $4103
		sub_list	wrt_lbl_4104		* $4104
		sub_list	wrt_lbl_4105		* $4105		SXhas
		sub_list	wrt_lbl_4106		* $4106		SXhas
		sub_list	wrt_lbl_4107		* $4107		SXhas
		sub_list	wrt_lbl_4108		* $4108		SXhas
		sub_list	wrt_lbl_4109		* $4109		SXhas
		sub_list	wrt_lbl_410a		* $410a		SXhas

		sub_list	wrt_lbl_42fc		* $42fc		SXhas
		sub_list	wrt_lbl_42fd		* $42fd		SXhas
		sub_list	wrt_lbl_42fe		* $42fe
		sub_list	wrt_lbl_42ff		* $42ff
		sub_list	wrt_lbl_4200		* $4200
		sub_list	wrt_lbl_4201		* $4201
		sub_list	wrt_lbl_4202		* $4202
		sub_list	wrt_lbl_4203		* $4203
		sub_list	wrt_lbl_4204		* $4204
		sub_list	wrt_lbl_4205		* $4205		SXhas
		sub_list	wrt_lbl_4206		* $4206		SXhas
		sub_list	wrt_lbl_4207		* $4207		SXhas
		sub_list	wrt_lbl_4208		* $4208		SXhas
		sub_list	wrt_lbl_4209		* $4209		SXhas
		sub_list	wrt_lbl_420a		* $420a		SXhas

		sub_list	wrt_lbl_43fc		* $43fc		SXhas
		sub_list	wrt_lbl_43fd		* $43fd		SXhas
		sub_list	wrt_lbl_43fe		* $43fe
		sub_list	wrt_lbl_43ff		* $43ff
		sub_list	wrt_lbl_4300		* $4300
		sub_list	wrt_lbl_4301		* $4301
		sub_list	wrt_lbl_4302		* $4302
		sub_list	wrt_lbl_4303		* $4303
		sub_list	wrt_lbl_4304		* $4304
		sub_list	wrt_lbl_4305		* $4305		SXhas
		sub_list	wrt_lbl_4306		* $4306		SXhas
		sub_list	wrt_lbl_4307		* $4307		SXhas
		sub_list	wrt_lbl_4308		* $4308		SXhas
		sub_list	wrt_lbl_4309		* $4309		SXhas
		sub_list	wrt_lbl_430a		* $430a		SXhas

		sub_list	wrt_lbl_45fe		* $45fe		v2.00
		sub_list	wrt_lbl_45ff		* $45ff
		sub_list	skip_com_err
		sub_list	skip_com_err
		sub_list	skip_com_err
		sub_list	skip_com_err
		sub_list	skip_com_err

		sub_list	wrt_lbl_46fc		* $46fc		SXhas
		sub_list	wrt_lbl_46fd		* $46fd		SXhas
		sub_list	wrt_lbl_46fe		* $46fe
		sub_list	wrt_lbl_46ff		* $46ff
		sub_list	wrt_lbl_4600		* $4600
		sub_list	wrt_lbl_4601		* $4601
		sub_list	wrt_lbl_4602		* $4602
		sub_list	wrt_lbl_4603		* $4603
		sub_list	wrt_lbl_4604		* $4604
		sub_list	wrt_lbl_4605		* $4605		SXhas
		sub_list	wrt_lbl_4606		* $4606		SXhas
		sub_list	wrt_lbl_4607		* $4607		SXhas
		sub_list	wrt_lbl_4608		* $4608		SXhas
		sub_list	wrt_lbl_4609		* $4609		SXhas
		sub_list	wrt_lbl_460a		* $460a		SXhas

		sub_list	wrt_lbl_47fe		* $47fe		v2.00
		sub_list	wrt_lbl_47ff		* $47ff
		sub_list	skip_com_err
		sub_list	skip_com_err
		sub_list	skip_com_err
		sub_list	skip_com_err
		sub_list	skip_com_err

		sub_list	wrt_ctor_4c01		+ $4c01 .ctor adr.l
		sub_list	wrt_dtor_4d01		+ $4d01 .dtor adr.l

		sub_list	wrt_lbl_50fc		* $50fc		SXhas
		sub_list	wrt_lbl_50fd		* $50fd		SXhas
		sub_list	wrt_lbl_50fe		* $50fe
		sub_list	wrt_lbl_50ff		* $50ff
		sub_list	wrt_lbl_5000		* $5000
		sub_list	wrt_lbl_5001		* $5001
		sub_list	wrt_lbl_5002		* $5002
		sub_list	wrt_lbl_5003		* $5003
		sub_list	wrt_lbl_5004		* $5004
		sub_list	wrt_lbl_5005		* $5005		SXhas
		sub_list	wrt_lbl_5006		* $5006		SXhas
		sub_list	wrt_lbl_5007		* $5007		SXhas
		sub_list	wrt_lbl_5008		* $5008		SXhas
		sub_list	wrt_lbl_5009		* $5009		SXhas
		sub_list	wrt_lbl_500a		* $500a		SXhas

		sub_list	wrt_lbl_51fc		* $51fc		SXhas
		sub_list	wrt_lbl_51fd		* $51fd		SXhas
		sub_list	wrt_lbl_51fe		* $51fe		v2.00 ??
		sub_list	wrt_lbl_51ff		* $51ff
		sub_list	wrt_lbl_5100		* $5100
		sub_list	wrt_lbl_5101		* $5101
		sub_list	wrt_lbl_5102		* $5102
		sub_list	wrt_lbl_5103		* $5103
		sub_list	wrt_lbl_5104		* $5104
		sub_list	wrt_lbl_5105		* $5105		SXhas
		sub_list	wrt_lbl_5106		* $5106		SXhas
		sub_list	wrt_lbl_5107		* $5107		SXhas
		sub_list	wrt_lbl_5108		* $5108		SXhas
		sub_list	wrt_lbl_5109		* $5109		SXhas
		sub_list	wrt_lbl_510a		* $510a		SXhas

		sub_list	wrt_lbl_52fc		* $52fc		SXhas
		sub_list	wrt_lbl_52fd		* $52fd		SXhas
		sub_list	wrt_lbl_52fe		* $52fe		v2.00 ??
		sub_list	wrt_lbl_52ff		* $52ff
		sub_list	wrt_lbl_5200		* $5200
		sub_list	wrt_lbl_5201		* $5201
		sub_list	wrt_lbl_5202		* $5202
		sub_list	wrt_lbl_5203		* $5203
		sub_list	wrt_lbl_5204		* $5204
		sub_list	wrt_lbl_5205		* $5205		SXhas
		sub_list	wrt_lbl_5206		* $5206		SXhas
		sub_list	wrt_lbl_5207		* $5207		SXhas
		sub_list	wrt_lbl_5208		* $5208		SXhas
		sub_list	wrt_lbl_5209		* $5209		SXhas
		sub_list	wrt_lbl_520a		* $520a		SXhas

		sub_list	wrt_lbl_53fc		* $53fc		SXhas
		sub_list	wrt_lbl_53fd		* $53fd		SXhas
		sub_list	wrt_lbl_53fe		* $53fe		v2.00 ??
		sub_list	wrt_lbl_53ff		* $53ff
		sub_list	wrt_lbl_5300		* $5300
		sub_list	wrt_lbl_5301		* $5301
		sub_list	wrt_lbl_5302		* $5302
		sub_list	wrt_lbl_5303		* $5303
		sub_list	wrt_lbl_5304		* $5304
		sub_list	wrt_lbl_5305		* $5305		SXhas
		sub_list	wrt_lbl_5306		* $5306		SXhas
		sub_list	wrt_lbl_5307		* $5307		SXhas
		sub_list	wrt_lbl_5308		* $5308		SXhas
		sub_list	wrt_lbl_5309		* $5309		SXhas
		sub_list	wrt_lbl_530a		* $530a		SXhas

		sub_list	wrt_lbl_55fe		* $55fe		v2.00 ??
		sub_list	wrt_lbl_55ff		* $55ff		v2.00
		sub_list	skip_com_err
		sub_list	skip_com_err
		sub_list	skip_com_err
		sub_list	skip_com_err
		sub_list	skip_com_err

		sub_list	wrt_lbl_56fc		* $56fc		SXhas
		sub_list	wrt_lbl_56fd		* $56fd		SXhas
		sub_list	wrt_lbl_56fe		* $56fe		v2.00 ??
		sub_list	wrt_lbl_56ff		* $56ff
		sub_list	wrt_lbl_5600		* $5600
		sub_list	wrt_lbl_5601		* $5601
		sub_list	wrt_lbl_5602		* $5602
		sub_list	wrt_lbl_5603		* $5603
		sub_list	wrt_lbl_5604		* $5604
		sub_list	wrt_lbl_5605		* $5605		SXhas
		sub_list	wrt_lbl_5606		* $5606		SXhas
		sub_list	wrt_lbl_5607		* $5607		SXhas
		sub_list	wrt_lbl_5608		* $5608		SXhas
		sub_list	wrt_lbl_5609		* $5609		SXhas
		sub_list	wrt_lbl_560a		* $560a		SXhas

		sub_list	wrt_lbl_57fe		* $57fe		v2.00 ??
		sub_list	wrt_lbl_57ff		* $57ff		v2.00
		sub_list	skip_com_err
		sub_list	skip_com_err
		sub_list	skip_com_err
		sub_list	skip_com_err
		sub_list	skip_com_err

		sub_list	wrt_lbl_6501		* $6501
		sub_list	wrt_lbl_6502		* $6502
		sub_list	wrt_lbl_6503		* $6503
		sub_list	wrt_lbl_6504		* $6504
		sub_list	wrt_lbl_6505		* $6505		SXhas
		sub_list	wrt_lbl_6506		* $6506		SXhas
		sub_list	wrt_lbl_6507		* $6507		SXhas
		sub_list	wrt_lbl_6508		* $6508		SXhas
		sub_list	wrt_lbl_6509		* $6509		SXhas
		sub_list	wrt_lbl_650a		* $650a		SXhas

		sub_list	wrt_lbl_6901		* $6901		v2.00
		sub_list	wrt_lbl_6902		* $6902		v2.00
		sub_list	wrt_lbl_6903		* $6903		v2.00
		sub_list	wrt_lbl_6904		* $6904		v2.00
		sub_list	wrt_lbl_6905		* $6905		SXhas
		sub_list	wrt_lbl_6906		* $6906		SXhas
		sub_list	wrt_lbl_6907		* $6907		SXhas
		sub_list	wrt_lbl_6908		* $6908		SXhas
		sub_list	wrt_lbl_6909		* $6909		SXhas
		sub_list	wrt_lbl_690a		* $690a		SXhas

		sub_list	wrt_lbl_6b01		* $6b01		v2.00
		sub_list	wrt_lbl_6b02		* $6b02		v2.00
		sub_list	wrt_lbl_6b03		* $6b03		v2.00
		sub_list	wrt_lbl_6b04		* $6b04		v2.00
		sub_list	wrt_lbl_6b05		* $6b05		SXhas
		sub_list	wrt_lbl_6b06		* $6b06		SXhas
		sub_list	wrt_lbl_6b07		* $6b07		SXhas
		sub_list	wrt_lbl_6b08		* $6b08		SXhas
		sub_list	wrt_lbl_6b09		* $6b09		SXhas
		sub_list	wrt_lbl_6b0a		* $6b0a		SXhas

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
		sub_list	skip_com_err
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
		sub_list	skip_com_err
		sub_list	skip_com_err

		sub_list	def_lbl_b0ff		* $b0ff

		sub_list	def_lbl_b2fc		* $b2fc		SXhas
		sub_list	def_lbl_b2fd		* $b2fd		SXhas
		sub_list	def_lbl_b2fe		* $b2fe
		sub_list	def_lbl_b2ff		* $b2ff
		sub_list	def_lbl_b200		* $b200
		sub_list	def_lbl_b201		* $b201
		sub_list	def_lbl_b202		* $b202
		sub_list	def_lbl_b203		* $b203
		sub_list	def_lbl_b204		* $b204
		sub_list	def_lbl_b205		* $b205		SXhas
		sub_list	def_lbl_b206		* $b206		SXhas
		sub_list	def_lbl_b207		* $b207		SXhas
		sub_list	def_lbl_b208		* $b208		SXhas
		sub_list	def_lbl_b209		* $b209		SXhas
		sub_list	def_lbl_b20a		* $b20a		SXhas

		sub_list	obj_head_c001		* $c001
		sub_list	obj_head_c002		* $c002
		sub_list	obj_head_c003		* $c003
		sub_list	obj_head_c004		* $c004
		sub_list	obj_head_c005		* $c005		SXhas
		sub_list	obj_head_c006		* $c006		SXhas
		sub_list	obj_head_c007		* $c007		SXhas
		sub_list	obj_head_c008		* $c008		SXhas
		sub_list	obj_head_c009		* $c009		SXhas
		sub_list	obj_head_c00a		* $c00a		SXhas

		sub_list	skip_com_err		+
		sub_list	obj_head_c00c		+ $c00c size.l 'ctor',0
		sub_list	obj_head_c00d		+ $c00d size.l 'dtor',0

		sub_list	obj_name		* $d000

		sub_list	set_exec_adr		* $e000
		sub_list	req_obj			* $e001

	.rept	$e00c-($e001+1)
		sub_list	skip_com_err		+
	.endm
		sub_list	do_ctor_e00c		+ $e00c .doctor
		sub_list	do_dtor_e00d		+ $e00d .dodtor

		.end

* End of File --------------------------------- *
