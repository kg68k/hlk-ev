		.title		HLK/ev (main.s - main control module)

PROGRAM:	.reg		'HLK evolution'
VERSION:	.reg		'3.01'
PATCHLEVEL:	.reg		'+17'
PATCHDATE:	.reg		'2023-07-10'
PATCHAUTHOR:	.reg		'TcbnErik'

	.ifdef	__G2LK__
PROGNAME:	.reg		'g2lk'
ENVNAME:	.reg		'G2LK'
TYPE:		.reg		'[g2lk]'
	.else
PROGNAME:	.reg		'hlk'
ENVNAME:	.reg		'HLK'
TYPE:		.reg		''
	.endif


* Include File -------------------------------- *

		.include	hlk.mac
		.include	string.mac
		.include	doscall.mac


* Global Symbol ------------------------------- *

		.xref		init_arg
		.xref		hup_get_arg
		.xref		fget_arg

		.xref		to_slash

		.xref		init_hash

		.xref		search_xdef

		.xref		get_object
		.xref		get_object2
		.xref		regist_object
		.xref		do_request
		.xref		activate_xdef
		.xref		search_and_link
		.xref		set_xdef_value
		.xref		set_xref_value
		.xref		calc_roff_sz
		.xref		make_exe
		.xref		make_map


* Fixed Number -------------------------------- *

SYS_INFO_LEN:	.equ		$40

MAX_ARGC:	.equ		4096
MY_STACK_SIZE:	.equ		32*1024
CALC_STACK_SIZE:.equ		1024

.ifndef _MALLOC3
_MALLOC3:       .equ    $ff90
.endif


* Text Section -------------------------------- *

		.cpu		68000

		.text
		.even

		_obj_list_	obj_list,a0,0
		_link_list_	link_list,a1,0
		_xdef_list_	xdef_list,a0,0

main:
		bra.s		@f
		.dc.b		'#HUPAIR',0
		.even
@@:
		lea		(16,a0),a0
		suba.l		a0,a1
		adda.l		#WORK_SIZE+MY_STACK_SIZE,a1
		move.l		a1,-(sp)
		move.l		a0,-(sp)
		DOS		_SETBLOCK
		addq.l		#8,sp
		tst.l		d0
		bmi		malloc_err
		lea		(a0,a1.l),sp

		lea		(workbuf,pc),a6

;ワーク初期化
		lea		(a6),a1
		moveq		#0,d0
		move		#WORK_SIZE/4-1,d1
@@:		move.l		d0,(a1)+
		dbra		d1,@b

		move.l		(main-$100+$c4,pc),d0
	.ifdef	__G2LK__
		andi.l		#$dfdfdf00,d0
		cmpi.l		#'HLK'<<8,d0
		sne		(G2LK_MODE_FLAG,a6)
	.else
		andi.l		#$dfffdfdf,d0
		cmpi.l		#'G2LK',d0
		seq		(G2LK_MODE_FLAG,a6)
	.endif

		lea		(OBJ_LIST_HEAD,a6),a0
		move.l		a0,(OBJ_LIST_WP,a6)
		lea		(LINK_LIST_HEAD,a6),a0
		move.l		a0,(LINK_LIST_WP,a6)
		lea		(LIB_PATH_HEAD,a6),a0
		move.l		a0,(LIB_PATH_WP,a6)

;$SLASH 収得
		moveq		#'\',d1
		pea		(TEMP,a6)
		clr.l		-(sp)
		pea		(env_slash,pc)
		DOS		_GETENV
		addq.l		#12-4,sp
		move.l		d0,(sp)+
		bmi		@f
		cmpi		#'/'<<8,(TEMP,a6)
		bne		@f
		moveq		#'/',d1
@@:		move.b		d1,(SLASH_CHAR,a6)

;引数関係初期化
		pea		(MAX_ARGC*4+4)
		DOS		_MALLOC
		move.l		d0,(sp)+
		bmi		malloc_err
		move.l		d0,d2			;d2.l = argv_buf

		bsr		malloc_all

		move.l		d0,-(sp)		;arg_buf
		move.l		d2,-(sp)		;argv_buf
		move.l		d1,-(sp)		;arg_buf_size
		pea		(MAX_ARGC)		;max_argc
		bsr		init_arg
		lea		(16,sp),sp

		pea		(TEMP,a6)
		clr.l		-(sp)
		pea		(env_hlk,pc)
		DOS		_GETENV
		addq.l		#12-4,sp
		move.l		d0,(sp)+
		bmi		@f
		pea		(TEMP,a6)
		bsr		hup_get_arg
		move.l		d0,(sp)+
		bmi		main_err1		;too many argumets
@@:
		pea		(1,a2)
		bsr		hup_get_arg
		move.l		d0,(sp)+
		bmi		main_err1		;too many argumets
		beq		print_usage_err

		move.l		(ARG_SIZE,a6),d0
		st		d0
		addq.l		#1,d0			;align 256
		move.l		d0,-(sp)
		move.l		(ARG_BUF,a6),-(sp)
		DOS		_SETBLOCK
		addq.l		#8,sp

		bsr		init_hash

		bsr		malloc_huge
		move.l		d0,d2			;d0.l = malloc_ptr_head
		add.l		d1,d2			;d2.l = malloc_ptr_tail
							;d1.l = malloc_left
		moveq		#16*6,d3		;気休め
		sub.l		d3,d1
		bmi		malloc_err
		add.l		d3,d0			;d0.l = calc_stack_top
		move.l		d0,(CALC_STACK_TOP,a6)

		move.l		#CALC_STACK_SIZE*6,d3
		sub.l		d3,d1
		bmi		malloc_err
		add.l		d3,d0			;d0.l = calc_stack_bot
		move.l		d0,(CALC_STACK_BOT,a6)
		move.l		d0,(CALC_STACK_PTR,a6)

		moveq		#16*6,d3		;気休め
		sub.l		d3,d1			;d1.l = malloc_left
		bmi		malloc_err
		add.l		d3,d0			;d0.l = headder_adr

		move.l		d0,(MALLOC_PTR_HEAD,a6)
		move.l		d2,(MALLOC_PTR_TAIL,a6)
		move.l		d1,(MALLOC_LEFT,a6)

		bsr		analyze_opt
		tst		(EXIT_CODE,a6)
		bne		main_end

;擬似オブジェクト'*SYSTEM*'を作成する
		movea.l		(MALLOC_PTR_HEAD,a6),a5
		move.l		(MALLOC_LEFT,a6),d7
		bsr		makeobj_cdtor_def
		bsr		makeobj_sysinfo
		bsr		makeobj_cdtor_dsb
		bsr		makeobj_endcmd
		move.l		a5,(MALLOC_PTR_HEAD,a6)
		move.l		d7,(MALLOC_LEFT,a6)

		move.l		(SYS_INFO_ADR,a6),d7
		beq		no_system_obj

;作成した'*SYSTEM*'を登録する
		lea		(sys_info_name,pc),a0	;a0 = filename
		movea.l		a0,a1			;a1 = filename(full path)
		movea.l		d7,a2			;a2 = object address
		sub.l		(MALLOC_PTR_HEAD,a6),d7
		neg.l		d7			;d7 = object size
*		move.l		d7,(SYS_INFO_SIZE,a6)
		bsr		get_object2
no_system_obj:

		tst.b		(TITLE_FLAG,a6)
		beq		@f
		move		#STDERR,-(sp)		;起動時にタイトル表示
		pea		(title_msg,pc)
		DOS		_FPUTS
		addq.l		#6,sp
@@:
		movea.l		(ARGV,a6),a1
		tst.l		(a1)
		beq		print_usage_err
main_l30:	move.l		(a1)+,d1		;read object & make xdef
		beq		main_b35
		movea.l		d1,a0
		cmp.b		#'+',(a0)+
		bne		main_l30

		bsr		get_object
		tst.l		d0
		ble		main_l30

		bsr		print_already_msg
		bra		main_l30

main_b35:	movea.l		(ARGV,a6),a1
		tst.l		(a1)
		beq		print_usage_err
main_l35:	move.l		(a1)+,d1		* read object & make xdef
		beq		main_b40
		movea.l		d1,a0
		cmp.b		#'+',(a0)
		beq		main_l35
		bsr		get_object
		tst.l		d0
		ble		main_l35

		bsr		print_already_msg
		bra		main_l35
main_b40:
		tst		(EXIT_CODE,a6)		;オブジェクトファイルが
		bne		main_end		;見付からなかった

		move.l		(OBJ_LIST_HEAD,a6),d0
		beq		main_end		;オブジェクトが指定されてない
		tst.l		(SYS_INFO_ADR,a6)
		beq		@f
		movea.l		d0,a0
		tst.l		obj_list_next
		beq		main_end		;'*SYSTEM*'しかなかった
@@:

		move.l		(OBJ_LIST_HEAD,a6),d0
*		beq		main_end
main_l40:
		movea.l		d0,a0			;a0.l = obj_list
		tst.l		obj_list_lib_name
		bne		main_b41
		bsr		regist_object
main_b41:
		move.l		obj_list_next,d0
		bne		main_l40

		move.l		(LINK_LIST_HEAD,a6),d0
		beq		print_usage_err
		movea.l		d0,a1
		move.l		link_list_obj_list,a0
		move.l		(SYS_INFO_ADR,a6),d0
		cmp.l		obj_list_obj_image,d0
		bne		@f
		tst.l		link_list_next
		beq		print_usage_err
@@:
		bsr		make_exec_name
		bsr		make_map_name

;do request
		move.l		(LINK_LIST_HEAD,a6),d0
main_l50:
		movea.l		d0,a1			;a1.l = link_list
		movea.l		link_list_obj_list,a0	;a0.l = obj_list
		bsr		do_request
		move.l		link_list_next,d0
		bne		main_l50

;search xref & link
		move.l		(LINK_LIST_HEAD,a6),d0
main_l60:
		movea.l		d0,a1			;a1.l = link_list
		movea.l		link_list_obj_list,a0	;a0.l = obj_list
		bsr		activate_xdef
		bsr		search_and_link
		move.l		link_list_next,d0
		bne		main_l60

		tst		(EXIT_CODE,a6)
		bne		main_end

* ctor/dtorサイズを計算する
		moveq		#0,d1
		moveq		#0,d2
		move.l		(LINK_LIST_HEAD,a6),d0
calc_cdtor_size_loop:
		movea.l		d0,a1			;a1.l = link_list
		movea.l		link_list_obj_list,a0	;a0.l = obj_list
		add.l		obj_list_ctor_size,d1
		add.l		obj_list_dtor_size,d2
		move.l		link_list_next,d0
		bne		calc_cdtor_size_loop

		move.l		d1,(CTOR_SIZE,a6)
		move.l		d2,(DTOR_SIZE,a6)

* ctor/dtor関係はg2lkモード専用.
		tst.b		(G2LK_MODE_FLAG,a6)
		bne		@f

		tst		(DO_CTOR_FLAG,a6)	do_ctor_flag|do_dtor_flag
		bne		no_g2lk_error		;-0 && .do?torあり
		move.l		(CTOR_SIZE,a6),d0
		add.l		(DTOR_SIZE,a6),d0
		bne		no_g2lk_error		;-0 && .?torあり
		bra		g2lk_mode_check_ok
@@:
		move.l		(CTOR_SIZE,a6),d6
		tst.b		(DO_CTOR_FLAG,a6)
		bne		1f
		tst.l		d6
		bne		no_doxtor_error		;-1 && .doctorなし && .ctorあり
		bra		@f
1:		addq.l		#8,d6			;header+footerの分
@@:
		move.l		(DTOR_SIZE,a6),d7
		tst.b		(DO_DTOR_FLAG,a6)
		bne		1f
		tst.l		d7
		bne		no_doxtor_error		;-1 && .dodtorなし && .dtorあり
		bra		@f
1:		addq.l		#8,d7			;header+footerの分
@@:
		movea.l		(SYS_INFO_ADR,a6),a4
		move.l		(sys_info_data+2-sys_info_h,a4),d1

* ___CTOR_LIST__の実際のアドレスを計算
		movea.l		(CTOR_LIST_PTR,a6),a1
		move.l		d1,(a1)
		move.l		d1,(CTOR_LIST_PTR,a6)	;後でobj_list_data_posを足す
		lea		(ctor_list_lbl+6,pc),a0
		bsr		search_xdef
		move.l		d0,a0
		move.l		d1,xdef_list_value
		add.l		d6,d1			;d6.l = ctor table size

* ___DTOR_LIST__の実際のアドレスを計算
		movea.l		(DTOR_LIST_PTR,a6),a1
		move.l		d1,(a1)
		move.l		d1,(DTOR_LIST_PTR,a6)	;後でobj_list_data_posを足す
		lea		(dtor_list_lbl+6,pc),a0
		bsr		search_xdef
		move.l		d0,a0
		move.l		d1,xdef_list_value
		add.l		d7,d1			;d7.l = dtor table size

		move.l		d1,(sys_info_data+2-sys_info_h,a4)

		movea.l		(CDTOR_DSB_PTR,a6),a1
		move.l		d6,d0
		add.l		d7,d0
		add.l		d0,(a1)

		movea.l		(OBJ_LIST_HEAD,a6),a0
		add.l		d0,obj_list_data_size
g2lk_mode_check_ok:

* この時点で必要なオブジェクトは全て読み込まれている.

* オブジェクトごとのアライン補正はまだ行われておらず、セクションサイズも
* 計算されていないので、ここで計算する. 書き込み位置も同時に計算している.
* セクション毎にオブジェクトの直前でアライン補正を行っているので、
* セクションサイズの最大アラインサイズへの補正は不要.

		lea		(calc_obj_pos,pc),a3
		moveq		#0,d0			;d0.l = text_pos

		lea		(calc_obj_pos_text,pc),a4
		jsr		(a3)
		move.l		d1,(TEXT_SIZE,a6)

		lea		(calc_obj_pos_data,pc),a4
		jsr		(a3)
		move.l		d1,(DATA_SIZE,a6)

		lea		(calc_obj_pos_rdata,pc),a4
		jsr		(a3)
		move.l		d1,(RDATA_D_SIZE,a6)	;実体のサイズ

		lea		(calc_obj_pos_rldata,pc),a4
		jsr		(a3)
		move.l		d1,(RLDATA_D_SIZE,a6)	;実体のサイズ

		lea		(calc_obj_pos_bss,pc),a4
		jsr		(a3)
		move.l		d1,(BSS_SIZE,a6)

*		lea		(calc_obj_pos_common,pc),a4
*		jsr		(a3)
*		move.l		d1,(COMMON_SIZE,a2)
		add.l		(COMMON_SIZE,a6),d0

		lea		(calc_obj_pos_stack,pc),a4
		jsr		(a3)
		move.l		d1,(STACK_SIZE,a6)

		move.l		#-32768,d0		;d0.l = rdata_pos

		lea		(calc_obj_pos_rdata,pc),a4
		jsr		(a3)
		move.l		d1,(RDATA_SIZE,a6)

		lea		(calc_obj_pos_rbss,pc),a4
		jsr		(a3)
		move.l		d1,(RBSS_SIZE,a6)

*		lea		(calc_obj_pos_rcommon,pc),a4
*		jsr		(a3)
*		move.l		d1,(RCOMMON_SIZE,a6)
		add.l		(RCOMMON_SIZE,a6),d0

		lea		(calc_obj_pos_rstack,pc),a4
		jsr		(a3)
		move.l		d1,(RSTACK_SIZE,a6)

		lea		(calc_obj_pos_rldata,pc),a4
		jsr		(a3)
		move.l		d1,(RLDATA_SIZE,a6)

		lea		(calc_obj_pos_rlbss,pc),a4
		jsr		(a3)
		move.l		d1,(RLBSS_SIZE,a6)

*		lea		(calc_obj_pos_rlcommon,pc),a4
*		jsr		(a3)
*		move.l		d1,(RLCOMMON_SIZE,a6)
		add.l		(RLCOMMON_SIZE,a6),d0

		lea		(calc_obj_pos_rlstack,pc),a4
		jsr		(a3)
		move.l		d1,(RLSTACK_SIZE,a6)

		tst.b		(MK_SZ_INFO_FLAG,a6)
		beq		@f

		move.l		(RDATA_SIZE,a6),d1	;___rsizeの値を設定
		add.l		(RBSS_SIZE,a6),d1
		add.l		(RCOMMON_SIZE,a6),d1
		add.l		(RSTACK_SIZE,a6),d1
		add.l		(RLDATA_SIZE,a6),d1
		add.l		(RLBSS_SIZE,a6),d1
		add.l		(RLCOMMON_SIZE,a6),d1
		add.l		(RLSTACK_SIZE,a6),d1

		lea		(rsize_lbl+6,pc),a0
		bsr		search_xdef
		move.l		d0,a0
		move.l		d1,xdef_list_value
@@:
;set xref value
		move.l		(LINK_LIST_HEAD,a6),d0
main_l70:
		movea.l		d0,a1			;a1.l = link_list
		movea.l		link_list_obj_list,a0	;a0.l = obj_list
		bsr		set_xref_value
		move.l		link_list_next,d0
		bne		main_l70

		tst		(EXIT_CODE,a6)
		bne		main_end

* 相対オフセットテーブルのサイズを求める.
* ただしデータサイズには含まないので、必要に応じて合計する.

		bsr		calc_roff_sz

* オブジェクト単位の作業は終わっているので、
* obj_size及び(rl)common_posの計算のみ.

		move.l		(TEXT_SIZE,a6),d0
		add.l		(DATA_SIZE,a6),d0
		add.l		(RDATA_D_SIZE,a6),d0	;実体のサイズ
		add.l		(RLDATA_D_SIZE,a6),d0	;〃
		add.l		(ROFF_TBL_SIZE,a6),d0
		move.l		d0,(OBJ_SIZE,a6)
		add.l		(BSS_SIZE,a6),d0
		move.l		d0,(COMMON_POS,a6)

		move.l		#-32768,d0
		add.l		(RDATA_SIZE,a6),d0
		add.l		(RBSS_SIZE,a6),d0
		move.l		d0,(RCOMMON_POS,a6)

		add.l		(RCOMMON_SIZE,a6),d0
		add.l		(RSTACK_SIZE,a6),d0
		add.l		(RLDATA_SIZE,a6),d0
		add.l		(RLBSS_SIZE,a6),d0
		move.l		d0,(RLCOMMON_POS,a6)

;set xdef value
		move.l		(LINK_LIST_HEAD,a6),d0
main_l100:
		movea.l		d0,a1			;a1.l = link_list
		movea.l		link_list_obj_list,a0	;a0.l = obj_list
		bsr		set_xdef_value
		move.l		link_list_next,d0
		bne		main_l100

		tst		(EXIT_CODE,a6)
		beq		@f
		bsr		print_crlf
@@:
		bsr		make_exe

		tst.b		(MK_MAP_FLAG,a6)
		beq		main_end
		bsr		make_map
main_end:
		move		(EXIT_CODE,a6),-(sp)
		DOS		_EXIT2



* オブジェクトの直前のアライン補正及びセクションサイズの計算.

		_obj_list_	obj_list,a0,0
		_link_list_	link_list,a1,0

calc_obj_pos:
		move.l		d0,d2
		move.l		(LINK_LIST_HEAD,a6),d1
		beq		calc_obj_pos_end
calc_obj_pos_loop:
		movea.l		d1,a1			;a1.l = link_list
		movea.l		link_list_obj_list,a0	;a0.l = obj_list

		jsr		(a4)			;section毎のpos決定,size加算

		move.l		link_list_next,d1
		bne		calc_obj_pos_loop
calc_obj_pos_end:
		move.l		d0,d1
		sub.l		d2,d1			;セクションサイズ
		rts

calc_obj_pos_text:
		tst.b		obj_list_xdef_01
		beq		@f
		bsr		align_d0
@@:		move.l		d0,obj_list_text_pos
		add.l		obj_list_text_size,d0
		rts
calc_obj_pos_data:
		tst.b		obj_list_xdef_02
		beq		@f
		bsr		align_d0
@@:		move.l		d0,obj_list_data_pos
		add.l		obj_list_data_size,d0
		rts
calc_obj_pos_bss:
		tst.b		obj_list_xdef_03
		beq		@f
		bsr		align_d0
@@:		move.l		d0,obj_list_bss_pos
		add.l		obj_list_bss_size,d0
		rts
*calc_obj_pos_common:
*		tst.b		obj_list_xdef_fe
*		beq		@f
*		bsr		align_d0
*@@:		move.l		d0,obj_list_common_pos
*		add.l		obj_list_common_size,d0
*		rts
calc_obj_pos_stack:
		tst.b		obj_list_xdef_04
		beq		@f
		bsr		align_d0
@@:		move.l		d0,obj_list_stack_pos
		add.l		obj_list_stack_size,d0
		rts

calc_obj_pos_rdata:
		tst.b		obj_list_xdef_05
		beq		@f
		bsr		align_d0
@@:		move.l		d0,obj_list_rdata_pos
		add.l		obj_list_rdata_size,d0
		rts
calc_obj_pos_rbss:
		tst.b		obj_list_xdef_06
		beq		@f
		bsr		align_d0
@@:		move.l		d0,obj_list_rbss_pos
		add.l		obj_list_rbss_size,d0
		rts
*calc_obj_pos_rcommon:
*		tst.b		obj_list_xdef_fc
*		beq		@f
*		bsr		align_d0
*@@:		move.l		d0,obj_list_rcommon_pos
*		add.l		obj_list_rcommon_size,d0
*		rts
calc_obj_pos_rstack:
		tst.b		obj_list_xdef_07
		beq		@f
		bsr		align_d0
@@:		move.l		d0,obj_list_rstack_pos
		add.l		obj_list_rstack_size,d0
		rts

calc_obj_pos_rldata:
		tst.b		obj_list_xdef_08
		beq		@f
		bsr		align_d0
@@:		move.l		d0,obj_list_rldata_pos
		add.l		obj_list_rldata_size,d0
		rts
calc_obj_pos_rlbss:
		tst.b		obj_list_xdef_09
		beq		@f
		bsr		align_d0
@@:		move.l		d0,obj_list_rlbss_pos
		add.l		obj_list_rlbss_size,d0
		rts
*calc_obj_pos_rlcommon:
*		tst.b		obj_list_xdef_fd
*		beq		@f
*		bsr		align_d0
*@@:		move.l		d0,obj_list_rlcommon_pos
*		add.l		obj_list_rlcommon_size,d0
*		rts
calc_obj_pos_rlstack:
		tst.b		obj_list_xdef_0a
		beq		@f
		bsr		align_d0
@@:		move.l		d0,obj_list_rlstack_pos
		add.l		obj_list_rlstack_size,d0
		rts


		_obj_list_	obj_list,a0,0

align_d0::
		move.l		d1,-(sp)
		move.l		obj_list_align_size,d1
		subq.l		#1,d1			* d1.l = (align - 1)
		add.l		d1,d0
		not.l		d1
		and.l		d1,d0
		move.l		(sp)+,d1
		rts


*------------------------------------------------------------------------------
*
*	already read
*
*------------------------------------------------------------------------------

print_already_msg:
		pea		(already_msg,pc)	;already read
		DOS		_PRINT
		move.l		d1,-(sp)
		DOS		_PRINT
		addq.l		#8,sp
		bra		print_crlf
*		rts


*------------------------------------------------------------------------------
*
*	malloc_err
*
*------------------------------------------------------------------------------

malloc_err::
		pea		(malloc_err_msg,pc)
		bra		error_exit_p


*------------------------------------------------------------------------------
*
*	too many arguments
*
*------------------------------------------------------------------------------

main_err1:	pea		(too_many_args,pc)
error_exit_p:
		DOS		_PRINT
		addq.l		#4,sp
error_exit:
		move		#EXIT_FAILURE,-(sp)
		DOS		_EXIT2


*------------------------------------------------------------------------------
*
*	no g2lk / no do?tor
*
*------------------------------------------------------------------------------

no_g2lk_error:
		pea		(no_g2lk_msg,pc)
		bra		error_exit_p

no_doxtor_error:
		pea		(no_doxtor_msg,pc)
		bra		error_exit_p


*------------------------------------------------------------------------------
*
*	print_usage / print_version
*
*------------------------------------------------------------------------------

* エラー終了
print_usage_err:
		tst.b		(TITLE_FLAG,a6)
		bne		@f			;タイトル表示済み
		pea		(title_msg,pc)
		DOS		_PRINT
		addq.l		#4,sp
@@:
		pea		(usage_msg,pc)
		bra		error_exit_p

* 正常終了(-?,-h,--help)
print_usage:
		pea		(title_msg,pc)
		DOS		_PRINT
		pea		(usage_msg,pc)
		DOS		_PRINT
		addq.l		#8,sp
		bra		main_end


print_version:
		lea		(ver_msg_end,pc),a0
	.ifdef	__CRLF__
		move.b		#CR,(a0)+
	.endif
		move.b		#LF,(a0)+
		clr.b		(a0)
		pea		(title_msg,pc)
		DOS		_PRINT
		addq.l		#4,sp
		bra		main_end


*------------------------------------------------------------------------------
*
*	program_err
*
*	in:	a0.l = function adr
*
*	これは出て欲しくないぞぉ(^_^;
*
*------------------------------------------------------------------------------

program_err::
		pea		(prog_err_msg,pc)
		DOS		_PRINT
		addq.l		#4,sp
		move.l		a0,d0
		pea		(main,pc)
		sub.l		(sp)+,d0		;プロセス先頭からのオフセット
		bsr		print_hex8
		bsr		print_crlf
		pea		(prog_err_msg2,pc)
		bra		error_exit_p


*------------------------------------------------------------------------------
*
*	malloc_huge
*
*	out:	d0.l	メモリ管理ポインタ
*		d1.l	確保できたメモリのサイズ
*
*	メモリを確保できるだけ取る(大容量ハイメモリ対応)
*	確保できない場合はエラー終了する
*
*------------------------------------------------------------------------------

UNEXPECTED_MARK:	.equ	$deadface	;DOS _MALLOC3の未実装、成功、失敗時に取り得ない値

malloc_huge:
		move.l		#UNEXPECTED_MARK,d1
		pea		(-1)
		move.l		d1,d0
		DOS		_MALLOC3
		addq.l		#4,sp
		cmp.l		d1,d0
		beq		malloc3_unexpected_err
		move.l		d0,d1
		addq.l		#1,d0
		beq		malloc_all		;060turbo.sysは組み込まれていない

		lsl.l		#1,d1
		lsr.l		#1,d1			;andi.l #$7fff_ffff,d1
		move.l		d1,-(sp)
		DOS		_MALLOC3
		move.l		d0,(sp)+
		bmi		malloc_err
		rts

malloc3_unexpected_err:
		pea		(malloc3_err_msg,pc)
		bra		error_exit_p


*------------------------------------------------------------------------------
*
*	malloc_all
*
*	out:	d0.l	メモリ管理ポインタ
*		d1.l	確保できたメモリのサイズ
*
*	メモリを確保できるだけ取る
*	確保できない場合はエラー終了する
*
*------------------------------------------------------------------------------

malloc_all:
		pea		(-1)
		DOS		_MALLOC
		move.l		d0,d1
		andi.l		#$00ffffff,d1
		move.l		d1,(sp)
		DOS		_MALLOC
		move.l		d0,(sp)+
		bmi		malloc_err
		rts


*------------------------------------------------------------------------------
*
*	unknown_cmd
*
*	a0.l = unknown command ptr
*	a1.l = obj_list
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a1,0

unknown_cmd::
		pea		(unknown_msg,pc)
		DOS		_PRINT
		addq.l		#4,sp
		move		(a0),d0
		bsr		print_hex4
		pea		(at_msg,pc)
		DOS		_PRINT
		addq.l		#4,sp
		move.l		a0,d0
		sub.l		obj_list_obj_image,d0
		bsr		print_hex8
		bsr		print_crlf

		pea		(in_msg,pc)
		DOS		_PRINT
		move.l		obj_list_obj_name,-(sp)
		DOS		_PRINT
		addq.l		#8,sp

		move.l		obj_list_lib_name,d1
		beq		unknown_cmd_end
		pea		(in_msg,pc)
		DOS		_PRINT
		move.l		d1,-(sp)
		DOS		_PRINT
		addq.l		#8,sp
unknown_cmd_end:
		bsr		print_crlf
		bra		error_exit


*------------------------------------------------------------------------------
*
*	analyze_opt
*
*	オプションを評価してコマンドラインから削除します
*
*------------------------------------------------------------------------------

* in	a6.l	workbuf

analyze_opt:
		PUSH		d1-d2/d7/a0-a5
		movea.l		(MALLOC_PTR_HEAD,a6),a5	;a5.l = malloc_ptr_head
		move.l		(MALLOC_LEFT,a6),d7	;d7.l = malloc_left

		movea.l		(ARGV,a6),a1		;a1.l = argv
ana_opt_l10:	move.l		(a1)+,d0
		beq		ana_opt_end
		movea.l		d0,a2			;a2.l = arg
		cmpi.b		#'-',(a2)+
		bne		ana_opt_l10

		subq.l		#4,a1
		movea.l		a1,a4
@@:		move.l		(4,a4),(a4)+
		bne		@b
		subq.l		#1,(ARGC,a6)		;delete arg

		move.b		(a2)+,d0
		beq		ana_opt_b30_		;'-'
		cmpi.b		#'-',d0
		beq		ana_opt_long_opt	;'--'
		bra		@f
ana_opt_next:
		move.b		(a2)+,d0		;続けて指定した場合
		beq		ana_opt_l10
@@:
		cmpi.b		#'?',d0
		beq		print_usage
		cmpi.b		#'0',d0
		beq		option_0_g2lk_off
		cmpi.b		#'1',d0
		beq		option_1_g2lk_on

		moveq		#$20,d1
		or.b		d0,d1
		subi.b		#'a',d1
		cmpi.b		#'z'-'a',d1
		bhi		ana_opt_b30
		add		d1,d1
		move		(@f,pc,d1.w),d1
		jmp		(@f,pc,d1.w)
@@:
		.dc		ana_opt_b650-@b		;-a = no 'x' ext.
		.dc		option_b_baseadr-@b	;-b = base address
		.dc		ana_opt_b30-@b
		.dc		option_d_define-@b	;-d = define
		.dc		ana_opt_b700-@b		;-e = set align
		.dc		ana_opt_b30-@b
		.dc		option_g_loadmode-@b	;-g = load mode
		.dc		print_usage-@b		;-h = help
		.dc		option_i_indirect-@b	;-i = indirect
		.dc		ana_opt_b30-@b
		.dc		ana_opt_b30-@b
		.dc		option_l-@b		;-l = lib path
		.dc		ana_opt_b250-@b		;-m = max label
		.dc		ana_opt_b30-@b
		.dc		ana_opt_b300-@b		;-o = obj name
		.dc		ana_opt_b350-@b		;-p = map
		.dc		ana_opt_b30-@b
		.dc		option_r_rtype-@b	;-r = .r type exec file
		.dc		option_s_secinfo-@b	;-s = link secsion info
		.dc		ana_opt_b600-@b		;-t = print title
		.dc		ana_opt_b30-@b
		.dc		ana_opt_b400-@b		;-v = verbose
		.dc		ana_opt_b450-@b		;-w = warning off
		.dc		ana_opt_b500-@b		;-x = symbol cut
		.dc		ana_opt_b30-@b
		.dc		ana_opt_b550-@b		;-z = verbose off


* long option : --help, --version, ...
ana_opt_long_opt:
		lea		(long_opt_table,pc),a4
ana_opt_long_opt_loop:
		move		(a4)+,d0
		beq		ana_opt_b30_		;unknown option
		move		(a4)+,d1
		_strcmp		(a2),(long_opt_table,pc,d0.w)
		bne		ana_opt_long_opt_loop

@@:		tst.b		(a2)+
		bne		@b
		subq.l		#1,a2
		jmp		(long_opt_table,pc,d1.w)

long_opt_table:
@@:		.dc		str_help-@b	,print_usage-@b
		.dc		str_quiet-@b	,ana_opt_b550-@b
		.dc		str_verbose-@b	,ana_opt_b400-@b
		.dc		str_version-@b	,print_version-@b
		.dc		0


ana_opt_b30_:
		subq.l		#1,a2
ana_opt_b30:	pea		(unknown_opt_msg,pc)	;unknown option
		DOS		_PRINT
		bsr		ana_opt_print_arg
ana_opt_err_next:
		addq.l		#4,sp
		bsr		print_crlf
		move		#EXIT_FAILURE,(EXIT_CODE,a6)
		bra		ana_opt_l10

ana_opt_print_arg:
		move.l		a2,-(sp)
@@:		cmpi.b		#'-',-(a2)
		bne		@b
		move.l		a2,-(sp)
		DOS		_PRINT
		addq.l		#4,sp
		movea.l		(sp)+,a2
		rts

ana_opt_b40:	pea		(bad_opt_msg,pc)	;bad option
		DOS		_PRINT
		bsr		ana_opt_print_arg
		tst.b		(a2)
		bne		ana_opt_err_next

		bsr		print_spc
		move.l		a3,(sp)
		DOS		_PRINT
		bra		ana_opt_err_next

ana_opt_b50:	pea		(bad_opt_msg,pc)	;bad option
		DOS		_PRINT
		bsr		ana_opt_print_arg
		bra		ana_opt_err_next

ana_opt_b60:	pea		(undef_env_lib,pc)	;undefined env. value 'lib'
		DOS		_PRINT
		addq.l		#4,sp
		bra		ana_opt_next

ana_opt_end:
		move.l		a5,(MALLOC_PTR_HEAD,a6)
		move.l		d7,(MALLOC_LEFT,a6)
		POP		d1-d2/d7/a0-a5
		rts


* -i file (indirect)
option_i_indirect:
		bsr		get_arg_adr
		beq		ana_opt_b50		;bad option

		clr		-(sp)
		pea		(a3)
		DOS		_OPEN
		addq.l		#6,sp
		move.l		d0,d1
		bmi		indir_open_err

		move		#2,-(sp)		;SEEK_END
		clr.l		-(sp)
		move		d1,-(sp)
		DOS		_SEEK
		move.l		d0,d2			;d2.l = filesize
		clr		(6,sp)
		DOS		_SEEK
		addq.l		#8,sp
		or.l		d2,d0
		bmi		option_i_file_err

;バッファは'*SYSTEM*'で使っているため、末尾から切り出す.
		moveq		#$fe,d0
		and.l		d2,d0
		addq.l		#2,d0			;NUL付加及び偶数化の分
		sub.l		d0,d7
		bmi		malloc_err
		sub.l		d0,(MALLOC_PTR_TAIL,a6)
		movea.l		(MALLOC_PTR_TAIL,a6),a0

		move.l		d2,-(sp)
		pea		(a0)
		move		d1,-(sp)
		DOS		_READ
		addq.l		#10-4,sp
		cmp.l		(sp)+,d2
		bne		option_i_file_err

		clr.b		(a0,d2.l)		;end of file

		move		d1,-(sp)
		DOS		_CLOSE
		addq.l		#2,sp

		pea		(a0)
		bsr		fget_arg
		move.l		d0,(sp)+
		bmi		main_err1		;too many arguments error
		bra		ana_opt_l10

option_i_file_err:
		move		d1,-(sp)
		DOS		_CLOSE
		addq.l		#2,sp
		bra		ana_opt_l10


* -l (lib path)
option_l:
		cmpi.b		#'L',d0
		beq		option_L_libpath	;大文字ならライブラリ検索パスの指定
		tst.b		(a2)
		bne		option_l_lib

		lea		(TEMP,a6),a3
		pea		(a3)
		clr.l		-(sp)
		pea		(env_lib,pc)
		DOS		_GETENV
		addq.l		#12-4,sp
		move.l		d0,(sp)+
		bmi		ana_opt_b60		;undefined env. value 'lib'

		bsr		append_lib_path
		bra		ana_opt_next

append_lib_path:
		_strlen		(a3)
		tst.l		d0
		beq		append_lib_path_end
		addq.l		#4+2+1,d0
		andi		#$fffe,d0

		sub.l		d0,d7
		bmi		malloc_err
		sub.l		d0,(MALLOC_PTR_TAIL,a6)
		movea.l		(MALLOC_PTR_TAIL,a6),a0

		pea		(a0)
		clr.l		(a0)+			;next ptr
@@:		move.b		(a3)+,(a0)+
		bne		@b
		subq.l		#2,a0
		cmpi.b		#':',(a0)+		;"d:"なら補完しない
		beq		@f
		move.b		#'\',(a0)+		;末尾にパスデリミタを補完
		clr.b		(a0)
@@:		bsr		to_slash
		movea.l		(sp)+,a0

		movea.l		(LIB_PATH_WP,a6),a3
		move.l		a0,(a3)
		move.l		a0,(LIB_PATH_WP,a6)
append_lib_path_end:
		rts

* -l<lib> (lib)
option_l_lib:
		_strlen		(a2)
		addq.l		#6+1,d0			;"lib" + ".a\0" + even
		andi		#$fffe,d0

		sub.l		d0,d7
		bmi		malloc_err
		sub.l		d0,(MALLOC_PTR_TAIL,a6)
		movea.l		(MALLOC_PTR_TAIL,a6),a0

		_strcpy		(a0),(lib_head,pc)	;"lib"
		_strcat		(a0),(a2)
		_strcat		(a0),(ext_a,pc)		;".a"

		lea		(a1),a2
@@:		tst.l		(a2)+
		bne		@b
		clr.l		(a2)			;コマンドラインの最後に
		move.l		a0,-(a2)		;ライブラリ名を追加する

		subq.l		#1,(ARGC,a6)		;append arg
		bra		ana_opt_l10


* -L <path> (lib path)
option_L_libpath:
		bsr		get_arg_adr
		beq		ana_opt_b50		;bad option

		bsr		append_lib_path
		bra		ana_opt_l10


* -m num (max label)
ana_opt_b250:
		bsr		get_arg_adr
		beq		ana_opt_b50		;bad option
		bsr		get_number
		bmi		ana_opt_b40		;bad option

		bra		ana_opt_l10		;数値を無視するだけ


* -o file (obj name)
ana_opt_b300:
		bsr		get_arg_adr
		beq		ana_opt_b50		;bad option

		moveq		#96-1,d0
		movea.l		a3,a4
		lea		(EXEC_NAME,a6),a0
@@:		move.b		(a4)+,(a0)+
		dbeq		d0,@b
		beq		ana_opt_l10
		bra		ana_opt_b40		;bad option


* -p[file] (map)
ana_opt_b350:
		st		(MK_MAP_FLAG,a6)

		moveq		#96-1,d0
		lea		(a2),a4
		lea		(MAP_NAME,a6),a0
@@:		move.b		(a4)+,(a0)+
		dbeq		d0,@b
		beq		ana_opt_l10
		bra		ana_opt_b50		;bad option

* hlk foo.o -p	-> foo.map
* hlk -p foo.o	-> foo.map
* hlk -pbar foo.o  -> bar.map
* hlk -pfoo	-> error


* -0 (g2lk mode off)
option_0_g2lk_off:
		sf		(G2LK_MODE_FLAG,a6)
		bra		ana_opt_next

* -1 (g2lk mode on)
option_1_g2lk_on:
		st		(G2LK_MODE_FLAG,a6)
		bra		ana_opt_next


* -z (verbose off)
ana_opt_b550:	sf		(VERBOSE_FLAG,a6)
		bra		ana_opt_next

* -v (verbose)
ana_opt_b400:	st		(VERBOSE_FLAG,a6)
		bra		ana_opt_next


* -w (warning off)
ana_opt_b450:	st		(WARNOFF_FLAG,a6)
		bra		ana_opt_next


* -x (symbol cut)
ana_opt_b500:	st		(CUT_SYM_FLAG,a6)
		bra		ana_opt_next


* -t (print title)
ana_opt_b600:	st		(TITLE_FLAG,a6)
		bra		ana_opt_next


* -a (no 'x' ext.)
ana_opt_b650:	lea		(NO_X_EXT_FLAG,a6),a4
		bra		ana_opt_check_an_rn

* -r / -rn (.r type exec file)
option_r_rtype:
		lea		(EXEC_FILE_TYPE,a6),a4
		bra		ana_opt_check_an_rn

ana_opt_check_an_rn:
		st		(a4)+
		moveq		#$20,d0
		or.b		(a2)+,d0
		cmpi.b		#'n',d0
		seq		(a4)			;opt_[ar]n_flag
		beq		@f
		subq.l		#1,a2
@@:		bra		ana_opt_next


* -e num (set align)
ana_opt_b700:
		bsr		get_arg_adr
		beq		ana_opt_b50		;bad option
		bsr		get_number
		bmi		ana_opt_b40		;bad option

		move.l		d0,d1
		subq.l		#ALIGN_MIN,d1
		cmpi.l		#ALIGN_MAX-ALIGN_MIN,d1
		bhi		ana_opt_b40		;値が範囲外

		move.l		d0,d1
@@:		lsr.l		#1,d1
		bcc		@b
		bne		ana_opt_b40		;2^nでない

		lea		(align_size,pc),a4
		move.l		d0,(a4)
		bra		ana_opt_l10


* -s (option_s_secinfo)
option_s_secinfo:
		st		(MK_SZ_INFO_FLAG,a6)
		bra		ana_opt_next


* -b num (base address)
option_b_baseadr:
		bsr		get_arg_adr
		beq		ana_opt_b50		;bad option
		bsr		get_number
		bmi		ana_opt_b40		;bad option

		move.l		d0,(BASE_ADDRESS,a6)
		bra		ana_opt_l10


* -g num (load mode)
option_g_loadmode:
		bsr		get_arg_adr
		beq		ana_opt_b50		;bad option
		bsr		get_number
		bmi		ana_opt_b40		;bad option

		moveq		#2,d1
		cmp.l		d1,d0
		bhi		ana_opt_b40		;bad option

		move.b		d0,(LOADMODE,a6)
		bra		ana_opt_l10


* -d lebel = num (define symbol)
option_d_define:
		bsr		get_arg_adr
		beq		ana_opt_b50		;bad option

		bsr		makeobj_system_header

		subq.l		#2+4,d7
		bmi		malloc_err
		move		#$b200,(a5)+		;xdef(abs)
		lea		(a5),a0			;a0.l = label vaule ptr
		clr.l		(a5)+

		movea.l		a3,a4
option_d_sym_loop:
		move.b		(a4)+,d1
		beq		option_d_sym_end	;bad option
		cmpi.b		#'=',d1
		beq		option_d_sym_end
		subq.l		#1,d7
		bmi		malloc_err
		move.b		d1,(a5)+
		bra		option_d_sym_loop
option_d_sym_end:
		move		a5,d0
		ori		#1,d0
		sub		a5,d0			;even->1 odd->0
@@:
		subq.l		#1,d7
		bmi		malloc_err
		clr.b		(a5)+			;'\0' + even
		dbra		d0,@b

		tst.b		d1
		beq		ana_opt_b40		;'='で終わっていなければエラー
		movea.l		a4,a3
		bsr		get_number_hex
		bmi		ana_opt_b40		;bad option

		move.l		d0,(a0)
		bra		ana_opt_l10


* オプションの引数が分割されて指定された場合、引数のアドレスを得る.
* 分割されていなかったらそのまま.
* in	a1.l	次の引数アドレスへのポインタ(0なら引数列の終わり)
*	a2.l	オプション文字列のアドレス
* out	a3.l	引数のアドレス
*	ccr	Z=0:正常終了 Z=1:エラー(これ以上引数がない)
* break	d0/a4

get_arg_adr:
		movea.l		a2,a3
		tst.b		(a2)
		bne		get_arg_adr_end

		move.l		(a1),d0
		beq		get_arg_adr_end
		movea.l		d0,a3
		cmpi.b		#'-',(a3)
		beq		get_arg_adr_end
		movea.l		a1,a4
@@:		move.l		(4,a4),(a4)+
		bne		@b
		subq.l		#1,(ARGC,a6)		;delete arg
		moveq		#1,d0			;not eq.
get_arg_adr_end:
		rts


* 16進数接頭辞($、0x)がある場合はその長さを返す
* in	a3.l	文字列
* out	d0.l	接頭辞のバイト数(0なら接頭辞なし)
*	ccr	Z=1:接頭辞なし Z=0:接頭辞あり

get_hex_prefix_length:
		cmpi.b		#'$',(a3)
		bne		@f
		moveq		#1,d0			;'$'
		rts
@@:
		cmpi.b		#'0',(a3)
		bne		@f
		moveq		#$20,d0
		or.b		(1,a3),d0
		cmpi.b		#'x',d0
		bne		@f
		moveq		#2,d0			;'0x' or '0X'
		rts
@@:
		moveq		#0,d0
		rts


* 数値収得(16進数)
* in	a3.l	文字列
* out	d0.l	数値
*	ccr	N=0/Z=1:正常終了 N=1/Z=0:エラー

get_number_hex:
		PUSH		d1/a3
		bsr		get_hex_prefix_length
		adda.l		d0,a3			;$または0xを飛ばす

		moveq		#0,d0
		move.b		(a3)+,d1
		beq		get_numhex_error
get_numhex_loop:
		cmpi.b		#'9',d1
		bls		@f
		andi.b		#$df,d1
		cmpi.b		#'A',d1
		bcs		get_numhex_error
		subq.b		#'A'-('9'+1),d1
@@:		subi.b		#'0',d1
		cmpi.b		#$f,d1
		bhi		get_numhex_error
		cmpi.l		#$0fff_ffff,d0
		bhi		get_numhex_error
		lsl.l		#4,d0
		or.b		d1,d0

		move.b		(a3)+,d1
		bne		get_numhex_loop
		moveq		#0,d1
		bra		@f
get_numhex_error:
		moveq		#-1,d1
@@:		POP		d1/a3
		rts


* 数値収得(10進/16進判別)
* in	a3.l	文字列
* out	d0.l	数値
*	ccr	N=0/Z=1:正常終了 N=1/Z=0:エラー

get_number::
		bsr		get_hex_prefix_length
		bne		get_number_hex

		PUSH		d1-d2/a3
		moveq		#0,d0
		moveq		#0,d1
		move.b		(a3)+,d1
		beq		get_number_error
get_num_dec_loop:
		subi.b		#'0',d1
		cmpi.b		#9,d1
		bhi		get_number_error
		cmpi.l		#429496729.5,d0		;$ffff_ffff/10
		bhi		get_number_error
		add.l		d0,d0
		move.l		d0,d2
		lsl.l		#2,d0
		add.l		d2,d0			;*10
		add.l		d1,d0
		bcs		get_number_error

		move.b		(a3)+,d1
		bne		get_num_dec_loop
		moveq		#0,d1
		bra		@f
get_number_error:
		moveq		#-1,d1
@@:		POP		d1-d2/a3
		rts


* エラー終了

indir_open_err:
		pea		(nf_indir_msg,pc)
		DOS		_PRINT
		pea		(a3)
		DOS		_PRINT
		addq.l		#8,sp
		bsr		print_crlf
		bra		error_exit


*------------------------------------------------------------------------------
*
*	擬似オブジェクト'*SYSTEM*'の作成
*
*------------------------------------------------------------------------------
* i/o	d7.l	バッファ空き容量
*	a5.l	バッファアドレス
*	a6.l	workbuf


* ___CTOR/DTOR_LIST__のアドレス定義コマンドをバッファに転送.

makeobj_cdtor_def:
		tst.b		(G2LK_MODE_FLAG,a6)
		beq		makeobj_cdtor_def_end

		bsr		makeobj_system_header

		pea		(2,a5)
		move.l		(sp)+,(CTOR_LIST_PTR,a6)

		moveq		#ctor_list_lbl_sz,d0	;___CTOR_LIST__(data)定義
		lea		(ctor_list_lbl,pc),a4
		bsr		makeobj_trans_cmd

		pea		(2,a5)
		move.l		(sp)+,(DTOR_LIST_PTR,a6)

		moveq		#dtor_list_lbl_sz,d0	;___DTOR_LIST__(data)定義
		lea		(dtor_list_lbl,pc),a4
		bsr		makeobj_trans_cmd
makeobj_cdtor_def_end:
		rts


* ___CTOR/DTOR_LIST__領域確保コマンドをバッファに転送.

makeobj_cdtor_dsb:
		tst.b		(G2LK_MODE_FLAG,a6)
		beq		makeobj_cdtor_dsb_end

		pea		(6+2,a5)		;サイズは後で書き込む
		move.l		(sp)+,(CDTOR_DSB_PTR,a6)

		moveq		#cdtor_list_dsb_sz,d0	;領域確保
		lea		(cdtor_list_dsb,pc),a4
		bsr		makeobj_trans_cmd
makeobj_cdtor_dsb_end:
		rts


* sysinfo領域確保コマンドをバッファに転送.

makeobj_sysinfo:
		tst.b		(MK_SZ_INFO_FLAG,a6)
		beq		makeobj_sysinfo_end

		bsr		makeobj_system_header

		moveq		#sz_info_lbl_sz,d0	;___size_info(data)定義
		lea		(sz_info_lbl,pc),a4
		bsr		makeobj_trans_cmd

		moveq		#rsize_lbl_sz,d0	;___rsize(abs)定義
		lea		(rsize_lbl,pc),a4
		bsr		makeobj_trans_cmd

		moveq		#sz_info_dsb_sz,d0	;領域確保
		lea		(sz_info_dsb,pc),a4
		bsr		makeobj_trans_cmd

		moveq		#SYS_INFO_LEN,d0
		movea.l		(SYS_INFO_ADR,a6),a4
		add.l		d0,(sys_info_data+2-sys_info_h,a4)
makeobj_sysinfo_end:
		rts


* 擬似オブジェクト*SYSTEM*のヘッダをバッファに転送.
* break	d0/a4

makeobj_system_header:
		tst.l		(SYS_INFO_ADR,a6)
		bne		makeobj_system_header_end

		move.l		a5,(SYS_INFO_ADR,a6)	;sys_info_adr

		move.l		#sys_info_h_len,d0
		lea		(sys_info_h,pc),a4
		bsr		makeobj_trans_cmd
makeobj_system_header_end:
		rts


* オブジェクト終了コマンドを転送.
* break	d0

makeobj_endcmd:
		tst.l		(SYS_INFO_ADR,a6)
		beq		makeobj_endcmd_end

		subq.l		#2,d7
		bmi		malloc_err
		clr		(a5)+
makeobj_endcmd_end:
		rts


* コマンド転送. メモリ不足ならエラー終了.
* in	d0.l	コマンド長
*	a4.l	コマンド列
* break	d0/a4

makeobj_trans_cmd:
		sub.l		d0,d7
		bmi		malloc_err

		subq.l		#1,d0
@@:		move.b		(a4)+,(a5)+
		dbra		d0,@b
		rts


*------------------------------------------------------------------------------
*
*	make_exec_name
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a0,0
		_link_list_	link_list,a1,0

make_exec_name:
		PUSH		d1/a0-a3
		lea		(EXEC_NAME,a6),a0
		movea.l		a0,a2
		move.b		(a0),d1
		bne		mk_exec_name_b2

		movea.l		(LINK_LIST_HEAD,a6),a1
							;a1.l = link_list_head
		movea.l		link_list_obj_list,a0	;a0.l = obj_list (head)
		move.l		(SYS_INFO_ADR,a6),d0
		cmp.l		obj_list_obj_image,d0
		bne		@f
		movea.l		link_list_next,a1
		movea.l		link_list_obj_list,a0	;a0.l = obj_list (head)
@@:		movea.l		obj_list_obj_name,a0	;a0.l = obj_name

mk_exec_name_b2:
		lea		(TEMP,a6),a3
		pea		(a3)
		pea		(a0)
		DOS		_NAMECK
		addq.l		#8,sp
		_strcpy		(a2),(NAMECK_Drive,a3)
		_strcat		(a2),(NAMECK_Name,a3)
		pea		(a2)
		bsr		to_slash
		addq.l		#4,sp

		tst.b		d1
		beq		@f
		lea		(NAMECK_Ext,a3),a0
		tst.b		(a0)
		bne		mk_exname_b3
@@:		lea		(ext_r,pc),a0
		tst.b		(EXEC_FILE_TYPE,a6)
		bne		mk_exname_b3		;-aでも".r"は必ず付ける

		addq.l		#ext_x-ext_r,a0
		tst.b		d1
		bne		@f
		tst.b		(OPT_AN_FLAG,a6)
		bne		mk_exname_b3
@@:		tst.b		(NO_X_EXT_FLAG,a6)
		bne		mk_exname_end
mk_exname_b3:
		_strcat		(a2),(a0)

		neg.b		(OPT_AN_FLAG,a6)	;=$01ならchmod +xしない(-an時)
mk_exname_end:
		POP		d1/a0-a3
		rts

* hlk foo		->	foo.x
* hlk foo -o bar	->	bar.x
* hlk foo	 -a	->	foo	(chmod +x)
* hlk foo -o bar -a	->	bar	(chmod +x)
* hlk foo	 -an	->	foo.x
* hlk foo -o bar -an	->	bar	(chmod +x)

* -an は実行ファイル名未指定時には.xを補完します.


*------------------------------------------------------------------------------
*
*	make_map_name
*
*------------------------------------------------------------------------------

make_map_name:
		PUSH		d1/a0-a2
		tst.b		(MK_MAP_FLAG,a6)
		beq		mk_mapname_end

		lea		(MAP_NAME,a6),a0
		lea		(a0),a1
		lea		(TEMP,a6),a2
		move.b		(a0),d1
		bne		@f
;-pだけの場合は.xを.mapに変える
		lea		(EXEC_NAME,a6),a1
@@:
		pea		(a2)
		pea		(a1)
		DOS		_NAMECK
		addq.l		#8,sp
		tst.l		d0
		bmi		mk_mapname_end

		_strcpy		(a0),(NAMECK_Drive,a2)
		_strcat		(a0),(NAMECK_Name,a2)
		pea		(a0)
		bsr		to_slash
		addq.l		#4,sp

		tst.b		d1
		beq		mk_mapname_map
		lea		(NAMECK_Ext,a2),a2
		tst.b		(a2)
		bne		mk_mapname_ext
mk_mapname_map:
		lea		(ext_map,pc),a2
mk_mapname_ext:	_strcat		(a0),(a2)

mk_mapname_end:
		POP		d1/a0-a2
		rts


*------------------------------------------------------------------------------

print_spc::
		move	#SPACE,-(sp)
		DOS	_PUTCHAR
		addq.l	#2,sp
		rts


print_crlf::
		pea	(crlf,pc)
		DOS	_PRINT
		addq.l	#4,sp
		rts

*------------------------------------------------------------------------------
*
*	print_hex2
*
*	in:	d0.l
*
*------------------------------------------------------------------------------

print_hex2::
		PUSH		d1-d2/a0
		moveq		#2-1,d2
		ror.l		#8,d0
		bra		print_hex


*------------------------------------------------------------------------------
*
*	print_hex4
*
*	in:	d0.l
*
*------------------------------------------------------------------------------

print_hex4::
		PUSH		d1-d2/a0
		move		#4-1,d2
		swap		d0
		bra		print_hex


*------------------------------------------------------------------------------
*
*	print_hex8
*
*	in:	d0.l
*
*------------------------------------------------------------------------------

print_hex8::
		PUSH		d1-d2/a0
		moveq		#8-1,d2
		bra		print_hex


print_hex:
		move.l		d0,d1
print_hex_loop:
		rol.l		#4,d1
		moveq		#$f,d0
		and		d1,d0
		move.b		(hex_table,pc,d0.w),d0
		move		d0,-(sp)
		DOS		_PUTCHAR
		addq.l		#2,sp
		dbra		d2,print_hex_loop

		POP		d1-d2/a0
		rts


hex_table::	.dc.b		'0123456789abcdef'
		.even


* Data Section -------------------------------- *

*		.data
		.even

align_size::	.dc.l		ALIGN_DEFAULT

*title_msg:	.dc.b		'X68k SILK Hi-Speed Linker v3.01 Copyright 1989-94 SALT',CRLF
title_msg:	.dc.b		PROGRAM,' version ',VERSION,PATCHLEVEL,TYPE
ver_msg_end:	.dc.b		' Copyright 1989-94 SALT, ',PATCHDATE,' ',PATCHAUTHOR,'.',CRLF
		.dc.b		0

usage_msg:	.dc.b		'usege: ',PROGNAME,' [switch] file [+file] ...',CRLF
		.dc.b		'	-a / -an	実行ファイルの拡張子省略時に .x を付けない',CRLF
		.dc.b		'	-b num		ベースアドレスの設定',CRLF
		.dc.b		'	-d label=num	シンボルの定義',CRLF
		.dc.b		'	-e num		アライメント値の設定',CRLF
		.dc.b		'	-g num		ロードモードの設定(0～2)',CRLF
		.dc.b		'	-i file		インダイレクトファイルの指定',CRLF
		.dc.b		'	-l		ライブラリのパスとして環境変数 lib を使用する',CRLF
		.dc.b		'	-l<lib>		lib<lib>.a をリンクする',CRLF
		.dc.b		'	-L path		ライブラリ検索パスの指定',CRLF
****		.dc.b		'	-m num		最大シンボル数の設定(無効)',CRLF
		.dc.b		'	-o file		実行ファイル名の指定',CRLF
		.dc.b		'	-p[file]	マップファイルの作成',CRLF
		.dc.b		'	-r / -rn	.r 形式実行ファイルの作成',CRLF
		.dc.b		'	-s		セクション情報を実行ファイルに埋め込む',CRLF
		.dc.b		'	-t		起動時にタイトルを表示する',CRLF
		.dc.b		'	-w		警告の出力禁止',CRLF
		.dc.b		'	-x		シンボルテーブルの出力禁止',CRLF
****		.dc.b		'	-z		.z 形式実行ファイルの作成',CRLF
		.dc.b		'	-0 / -1		.ctor/.dtor に対応しない / する',CRLF
		.dc.b		CRLF
		.dc.b		'	-h / --help	使用法表示',CRLF
		.dc.b		'	-z / --quiet	-v/--verbose オプションを取り消す',CRLF
		.dc.b		'	-v / --verbose	詳細表示',CRLF
		.dc.b		'	--version	バージョン表示',CRLF
		.dc.b		CRLF
		.dc.b		'	環境変数 ',ENVNAME,' の内容がコマンドラインの手前に挿入されます。',CRLF
		.dc.b		'	ファイル名先頭に + をつけたオブジェクトを先頭にリンクします。',CRLF
		.dc.b		0

str_help:	.dc.b		'help',0
str_quiet:	.dc.b		'quiet',0
str_verbose:	.dc.b		'verbose',0
str_version:	.dc.b		'version',0

too_many_args:	.dc.b		'引数が多すぎます。',CRLF
		.dc.b		0

prog_err_msg:	.dc.b		'内部エラー at : '
		.dc.b		0

prog_err_msg2:	.dc.b		'このエラーはプログラムのバグによって発生した可能性が大です。',CRLF
		.dc.b		'作者にお知らせ下さい。できる限りの事はやってみます。(;_;)',CRLF
		.dc.b		CRLF
		.dc.b		0

malloc_err_msg:	.dc.b		'メモリが不足しています。',CRLF
		.dc.b		0

malloc3_err_msg:.dc.b		'DOS _MALLOC3 の戻り値が想定外の値です。',CRLF
		.dc.b		0

unknown_opt_msg:.dc.b		'対応していないオプション: '
		.dc.b		0

bad_opt_msg:	.dc.b		'オプションの指定が正しくありません: '
		.dc.b		0

nf_indir_msg:	.dc.b		'インダイレクトファイルがありません: '
		.dc.b		0

undef_env_lib:	.dc.b		'環境変数 lib が定義されていません。',CRLF
		.dc.b		0

already_msg:	.dc.b		'読み込み済み: '
		.dc.b		0

unknown_msg:	.dc.b		'未対応のコマンド: '
		.dc.b		0

at_msg:		.dc.b		' at '
		.dc.b		0

in_msg:		.dc.b		' in '
		.dc.b		0

no_g2lk_msg:	.dc.b		'(do)ctor/dtor には -1 オプションの指定が必要です。',CRLF
		.dc.b		0

no_doxtor_msg:	.dc.b		'.doctor/.dodtor なしに ctor/dtor が使われています。',CRLF
		.dc.b		0

crlf:		.dc.b		CRLF,0

lib_head:*	.dc.b		'lib',0
env_lib:	.dc.b		'lib',0
env_hlk:	.dc.b		ENVNAME,0
env_slash:	.dc.b		'SLASH',0

ext_a:		.dc.b		'.a',0
ext_r:		.dc.b		'.r',0
ext_x:		.dc.b		'.x',0
ext_map:	.dc.b		'.map',0

		.even

*------------------------------------------------------------------------------
*
*	  -- size information table map --
*
*	+$0000	text size
*	+$0004	data size
*	+$0008	bss size
*	+$000c	comm size
*	+$0010	stack size
*	+$0014	rdata size
*	+$0018	rbss size
*	+$001c	rcomm size
*	+$0020	rstack size
*	+$0024	rldata size
*	+$0028	rlbss size
*	+$002c	rlcomm size
*	+$0030	rlstack size
*	+$0034	roffset size
*	+$0038
*	   .
*	   .	reserved
*	   .
*	+$0040
*
*------------------------------------------------------------------------------

obj_head:	.macro		code,name
		.dc		code
		.dc.l		0
		.dc.b		name,0
		.even
		.endm

*------------------------------------------------------------------------------

*sys_info_name:	.dc.b		'*SYSTEM*',0
*		.even
sys_info_name:	.equ		sys_info_h+6

;;;;;;;;
sys_info_h:	obj_head	$d000,'*SYSTEM*'
		obj_head	$c001,'text'
sys_info_data:	obj_head	$c002,'data'
		obj_head	$c003,'bss'
		obj_head	$c004,'stack'
		obj_head	$c005,'rdata'
		obj_head	$c006,'rbss'
		obj_head	$c007,'rstack'
		obj_head	$c008,'rldata'
		obj_head	$c009,'rlbss'
		obj_head	$c00a,'rlstack'
sys_info_h_len:	.equ		*-sys_info_h

;;;;;;;;
sz_info_lbl:	obj_head	$b202,'___size_info'	;data xdef
sz_info_lbl_sz:	.equ		$-sz_info_lbl

;;;;;;;;
rsize_lbl:	obj_head	$b200,'___rsize'	;abs xdef
rsize_lbl_sz:	.equ		$-rsize_lbl

;;;;;;;;
sz_info_dsb:	.dc		$2002			;chgsec data
		.dc.l		0
		.dc		$3000			;ds.b
		.dc.l		SYS_INFO_LEN
sz_info_dsb_sz:	.equ		$-sz_info_dsb

;;;;;;;;
ctor_list_lbl:	obj_head	$b202,'___CTOR_LIST__'	;data xdef
ctor_list_lbl_sz:.equ		$-ctor_list_lbl

;;;;;;;;
dtor_list_lbl:	obj_head	$b202,'___DTOR_LIST__'	;data xdef
dtor_list_lbl_sz:.equ		$-dtor_list_lbl

;;;;;;;;
cdtor_list_dsb:	.dc		$2002			;chgsec data
		.dc.l		0
		.dc		$3000			;ds.b
		.dc.l		0
cdtor_list_dsb_sz:.equ		$-cdtor_list_dsb


* Block Storage Section ----------------------- *

		.bss
		.quad
workbuf::
**		.ds.b		WORK_SIZE	;setblockで確保する


		.end		main

* End of File --------------------------------- *
