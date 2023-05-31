		.title	HLK/ev (make_exe.s - make executable file module)


* Include File -------------------------------- *

		.include	hlk.mac
		.include	doscall.mac


* Global Symbol ------------------------------- *

		.xref		search_xdef

		.xref		get_com_no
		.xref		skip_com

		.xref		print_hex8
		.xref		print_crlf

		.xref		program_err
		.xref		malloc_err
		.xref		unknown_cmd

		.xref		align16_malloc_buf


* Text Section -------------------------------- *

		.cpu	68000

		.text
		.even

*------------------------------------------------------------------------------
*
*	MOVEW_D1_A5PI
*
*	in:	a5.l = write_pointer
*		d1.w = data
*
*	out:	a5.l += 2
*
*------------------------------------------------------------------------------

MOVEW_D1_A5PI:	.macro
		move		d1,-(sp)
		move.b		(sp)+,(a5)+
		move.b		d1,(a5)+
		.endm

*------------------------------------------------------------------------------
*
*	MOVEL_D1_A5PI
*
*	in:	a5.l = write_pointer
*		d1.l = data
*
*	out:	a5.l += 4
*
*------------------------------------------------------------------------------

MOVEL_D1_A5PI:	.macro
		.local		movel_even
		move		a5,-(sp)
		lsr		(sp)+
		bcc		movel_even
		bsr		movel_d1_a5pi_odd
movel_even:	move.l		d1,(a5)+
		.endm

;直後がrtsの時のみ使用.
MOVEL_D1_A5PI_RTS:	.macro
		move		a5,-(sp)
		lsr		(sp)+
		bcs		movel_d1_a5pi_odd_rts
		move.l		d1,(a5)+
		.endm


*------------------------------------------------------------------------------
*
*	set_rp_bound
*
*	in:	a0.l = obj_image
*
*	out:	a0.l = (obj_image + (2 - 1)) & ~(2 - 1)
*
*------------------------------------------------------------------------------

set_rp_bound:	.macro
		move		a0,d0
		andi		#1,d0
		adda		d0,a0
		.endm

*------------------------------------------------------------------------------
*
*	store_offset
*
*	in:	d1.l = offset data
*		d7.l = malloc_left
*
*	out:	d1.l += base address
*
*------------------------------------------------------------------------------

store_offset:	.macro
		subq.l		#6,d7			;store 6 bytes
		bmi		malloc_err
		addq.l		#6,offset_size
		clr		(a4)+
		move.l		a5,(a4)+
		add.l		(workbuf+BASE_ADDRESS,pc),d1
		.endm

*------------------------------------------------------------------------------
*
*	store_offset2
*
*	in:	d7.l = malloc_left
*
*	out:
*
*	これはもう泥沼...
*
*------------------------------------------------------------------------------

store_offset2:	.macro
		.local		store_off2_b
		.local		store_off2_end

		move.l		roff_tbl_size2,d0
		cmp.l		(workbuf+ROFF_TBL_SIZE,pc),d0
		beq		make_exe_err5
		addq.l		#4,roff_tbl_size2

		move.l		a4,d0			* d0.l = work
		movea.l		roff_tbl_ptr,a4
		suba.l		rdata_top,a5
		cmpa.l		(workbuf+RDATA_D_SIZE,pc),a5
		bcc		store_off2_b

		suba.l		rdata_off,a5
		move.l		a5,(a4)+
		adda.l		rdata_off,a5
		bra		store_off2_end

store_off2_b:	suba.l		rldata_off,a5
		move.l		a5,(a4)+
		adda.l		rldata_off,a5

store_off2_end:
		move.l		a4,roff_tbl_ptr
		move.l		d0,a4
		adda.l		rdata_top,a5
		.endm

*------------------------------------------------------------------------------
*
*	make_exe
*
*	実行ファイルを作成します．（オンメモリバージョン）
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a1,0
		_link_list_	link_list,a2,0
		_xdef_list_	xdef_list,a3,0

offset_table:	.reg		(-94,a6)
offset_size:	.reg		(-90,a6)
symbol_size:	.reg		(-86,a6)

rdata_off:	.reg		(-82,a6)
rldata_off:	.reg		(-78,a6)

rdata_top:	.reg		(-74,a6)
roff_tbl_ptr:	.reg		(-70,a6)
roff_tbl_size2:	.reg		(-66,a6)

text_w_adr:	.reg		(-62,a6)
data_w_adr:	.reg		(-58,a6)
rdata_w_adr:	.reg		(-54,a6)
rldata_w_adr:	.reg		(-50,a6)

linfo_pos:	.reg		(-46,a6)
sinfo_pos:	.reg		(-42,a6)
einfo_pos:	.reg		(-38,a6)
ninfo_pos:	.reg		(-34,a6)
linfo_size:	.reg		(-30,a6)
sinfo_size:	.reg		(-26,a6)
einfo_size:	.reg		(-22,a6)
ninfo_size:	.reg		(-18,a6)

exec_stat:	.reg		(-14,a6)
**exec_obj_list:.reg		(-12,a6)
**exec_section:	.reg		 (-8,a6)
**exec_adr:	.reg		 (-4,a6)

header_adr:	.reg		(-12,a6)
object_top:	.reg		 (-8,a6)
**unused:	.reg		 (-4,a6)

make_exe::
		link		a6,#-94
		PUSH		d1-d7/a0-a5

		lea		(workbuf,pc),a0

		tst.b		(VERBOSE_FLAG,a0)
		beq		@f
		pea		(make_exe_mes,pc)
		DOS		_PRINT
		addq.l		#4,sp
@@:
		moveq		#X_HEADER_SIZE,d0
		add.l		d0,(MALLOC_PTR_HEAD,a0)	;ヘッダの分を確保
		sub.l		d0,(MALLOC_LEFT,a0)
		bmi		@f
		bsr		align16_malloc_buf	;object_bufferを16バイト境界に
@@:		bmi		malloc_err		;合わせる

		movea.l		(MALLOC_PTR_HEAD,a0),a5	;a5.l = object_buffer
		move.l		a5,object_top

		lea		(a5),a1
		moveq.l		#0,d0
		move.l		#X_HEADER_SIZE/4-1,d1
make_exe_l1	move.l		d0,-(a1)
		dbra		d1,make_exe_l1
		move.l		a1,header_adr		;a1.l = header_buffer

		move.l		d0,offset_size
		move.l		d0,symbol_size
		move.l		d0,linfo_pos
		move.l		d0,sinfo_pos
		move.l		d0,einfo_pos
		move.l		d0,ninfo_pos
		move.l		d0,linfo_size
		move.l		d0,sinfo_size
		move.l		d0,einfo_size
		move.l		d0,ninfo_size

		move		d0,exec_stat
**		move.l		d0,exec_obj_list
**		move.l		d0,exec_section
**		move.l		d0,exec_adr

		move.l		d0,roff_tbl_size2
		move.l		d0,rdata_off

*		lea		(workbuf,pc),a0
		sub.l		(RBSS_SIZE,a0),d0
		sub.l		(RCOMMON_SIZE,a0),d0
		sub.l		(RSTACK_SIZE,a0),d0
		move.l		d0,rldata_off

		move.l		a5,d0
		move.l		d0,text_w_adr
		add.l		(TEXT_SIZE,a0),d0
		move.l		d0,data_w_adr
		add.l		(DATA_SIZE,a0),d0
		move.l		d0,rdata_w_adr
		move.l		d0,rdata_top
		add.l		(RDATA_D_SIZE,a0),d0
		move.l		d0,rldata_w_adr
		add.l		(RLDATA_D_SIZE,a0),d0
		move.l		d0,(ROFF_TBL_ADR,a0)
		move.l		d0,roff_tbl_ptr

		move.l		(OBJ_SIZE,a0),d0
		move.l		(MALLOC_LEFT,a0),d7	;d7.l = object_buffer_left
		sub.l		d0,d7
		bmi		malloc_err
		lea		(a5,d0.l),a4		* a4.l = offset data
		move.l		a4,offset_table

* ___[CD]TOR_LIST__の実アドレスを計算する.

		tst.b		(DO_CTOR_FLAG,a0)
		beq		@f
		bsr		get_system_data_pos
		adda.l		(CTOR_LIST_PTR,a0),a3
		addq.l		#4,a3			;move.l #-1,(a3)+
		move.l		a3,(CTOR_LIST_PTR,a0)
@@:
		tst.b		(DO_DTOR_FLAG,a0)
		beq		@f
		bsr		get_system_data_pos
		adda.l		(DTOR_LIST_PTR,a0),a3
		addq.l		#4,a3			;move.l #-1,(a3)+
		move.l		a3,(DTOR_LIST_PTR,a0)
@@:

		lea		(LINK_LIST_HEAD,a0),a2	;a2.l = link_list_head
		move.l		(a2),d0
		beq		make_exe_b20
;オブジェクト単位ループ
make_exe_l2:
		movea.l		d0,a2

		move.l		link_list_obj_list,a1	* a1.l = obj_list

;空のセクションの書き込み位置は補正しなくてよい.
		tst.b		obj_list_xdef_01
		beq		@f
		lea		text_w_adr,a5
		bsr		align_set_text
@@:
		tst.b		obj_list_xdef_02
		beq		@f
		lea		data_w_adr,a5
		bsr		align_set
@@:
		tst.b		obj_list_xdef_05
		beq		@f
		lea		rdata_w_adr,a5
		bsr		align_set
@@:
		tst.b		obj_list_xdef_08
		beq		@f
		lea		rldata_w_adr,a5
		bsr		align_set
@@:
		moveq		#SECT_TEXT,d5		;d5.w = section no.
		movea.l		text_w_adr,a5
		movea.l		obj_list_obj_image,a0	;a0.l = obj_image
		move		(a0),d0
		beq		make_exe_b10
;コマンド単位ループ
make_exe_l3:
		move		d0,d1
		bsr		get_com_no
		bmi		make_exe_err		;unknown command

		add		d0,d0
		lea		(jump_table,pc),a3
		move		(a3,d0.w),d0
		jsr		(a3,d0.w)		;d1.w = command code
		move		(a0),d0
		bne		make_exe_l3
make_exe_b10:
		addq.l		#2,a0
		move.l		a0,obj_list_scdinfo
		move.l		obj_list_obj_size,d0
		sub.l		a0,d0
		add.l		obj_list_obj_image,d0
		move.l		d0,obj_list_scdinfo_s

		subq		#SECT_TEXT,d5
		bne		@f
		move.l		a5,text_w_adr
		bra		make_exe_b19
@@:
		subq		#SECT_DATA-SECT_TEXT,d5
		bne		@f
		move.l		a5,data_w_adr
		bra		make_exe_b19
@@:
		subq		#SECT_RDATA-SECT_DATA,d5
		bne		@f
		move.l		a5,rdata_w_adr
		bra		make_exe_b19
@@:
		subq		#SECT_RLDATA-SECT_RDATA,d5
		bne		@f
		move.l		a5,rldata_w_adr
		bra		make_exe_b19
@@:
make_exe_b19:
		lea		link_list_next,a2	* a2.l = next
		move.l		(a2),d0
		bne		make_exe_l2
make_exe_b20:

* 各オブジェクトの奇数サイズセクションは偶数サイズに補正され、次の
* オブジェクトのリンク直前のアライン補正で0クリアされる.
* しかし、最後のオブジェクトの各セクションの後にはアライン補正はない
* ので1バイト不定の内容となってしまう.
* よって、ここでクリアする.

		lea		text_w_adr,a5
		bsr		align_set_last
		lea		data_w_adr,a5
		bsr		align_set_last
		lea		rdata_w_adr,a5
		bsr		align_set_last
		lea		rldata_w_adr,a5
		bsr		align_set_last

		move		(workbuf+EXIT_CODE,pc),d0
		bne		make_exe_end

		move.l		roff_tbl_size2,d0
		cmp.l		(workbuf+ROFF_TBL_SIZE,pc),d0
		bne		make_exe_err5

		move.b		(workbuf+EXEC_FILE_TYPE,pc),d0
		bne		@f
		bsr		make_offset
		bmi		make_exe_err_ill_offset
@@:

		move.b		(workbuf+CUT_SYM_FLAG,pc),d0
		bne		@f			;-x option

		bsr		make_symbol
		bsr		make_scdinfo
		move		(workbuf+EXIT_CODE,pc),d0
		bne		make_exe_end
@@:
		lea		(workbuf,pc),a0
		tst.b		(MK_SZ_INFO_FLAG,a0)
		beq		@f

		bsr		get_system_data_pos
		move.l		(TEXT_SIZE,a0),(a3)+
		move.l		(DATA_SIZE,a0),(a3)+
		move.l		(BSS_SIZE,a0),(a3)+
		move.l		(COMMON_SIZE,a0),(a3)+
		move.l		(STACK_SIZE,a0),(a3)+
		move.l		(RDATA_SIZE,a0),(a3)+
		move.l		(RBSS_SIZE,a0),(a3)+
		move.l		(RCOMMON_SIZE,a0),(a3)+
		move.l		(RSTACK_SIZE,a0),(a3)+
		move.l		(RLDATA_SIZE,a0),(a3)+
		move.l		(RLBSS_SIZE,a0),(a3)+
		move.l		(RLCOMMON_SIZE,a0),(a3)+
		move.l		(RLSTACK_SIZE,a0),(a3)+
		move.l		(ROFF_TBL_SIZE,a0),(a3)+
*		clr.l		(a3)+			;reserved
*		clr.l		(a3)+			;reserved
@@:

* ___CTOR_LIST__のheader/footer書き込み
		moveq		#-1,d0
		tst.b		(DO_CTOR_FLAG,a0)
		beq		@f
		movea.l		(CTOR_LIST_PTR,a0),a3
		clr.l		(a3)			;end of table
		suba.l		(CTOR_SIZE,a0),a3
		move.l		d0,-(a3)		;top of table
@@:
* ___DTOR_LIST__のheader/footer書き込み
		tst.b		(DO_DTOR_FLAG,a0)
		beq		@f
		movea.l		(DTOR_LIST_PTR,a0),a3
		clr.l		(a3)			;end of table
		suba.l		(DTOR_SIZE,a0),a3
		move.l		d0,-(a3)		;top of table
@@:

* X形式実行ファイルのヘッダ作成
*		lea		(workbuf,pc),a0
		movea.l		header_adr,a3
		move		#X_MAGIC_ID,(X_Magic,a3)
		move.b		(LOADMODE,a0),(X_LoadMode,a3)

		move.l		(BASE_ADDRESS,a0),d0
		move.l		d0,(X_BaseAdr,a3)
		add.l		(EXEC_ADDRESS,a0),d0
		move.l		d0,(X_ExecAdr,a3)

		move.l		(TEXT_SIZE,a0),(X_TextSize,a3)
		move.l		(OBJ_SIZE,a0),d0
		sub.l		(TEXT_SIZE,a0),d0
		move.l		d0,(X_DataSize,a3)
		move.l		(BSS_SIZE,a0),d0
		add.l		(COMMON_SIZE,a0),d0
		add.l		(STACK_SIZE,a0),d0
		move.l		d0,(X_BssSize,a3)

		move.l		offset_size,(X_RelocateSize,a3)
		move.l		symbol_size,(X_SymbolSize,a3)
		move.l		linfo_size,(X_ScdLineSize,a3)
		move.l		sinfo_size,d0
		add.l		einfo_size,d0
		move.l		d0,(X_ScdSymSize,a3)
		move.l		ninfo_size,(X_ScdSym2Size,a3)

		tst.b		(EXEC_FILE_TYPE,a0)
		beq		make_exe_x
*make_exe_r:
		tst.b		(OPT_RN_FLAG,a0)
		bne		make_exe_r_no_check

* 変換可能か調べる.
* リンク作業中に変換不可能な要因を見つけたらエラー表示する方が望ましいけど
* 面倒なのとチェック不要の時の処理速度が落ちてしまうので...

		tst.l		offset_size
		bne		make_exe_err_offset
*		lea		(workbuf,pc),a0
		move.l		(EXEC_ADDRESS,a0),d0
		cmp.l		(BASE_ADDRESS,a0),d0
		bne		make_exe_err_adr

make_exe_r_no_check:
		move.l		(X_BssSize,a3),d0	;bssは確保できるか？
		cmp.l		d0,d7
		bcs		malloc_err

		move.l		(X_TextSize,a3),d1
		add.l		(X_DataSize,a3),d1
		lea		(X_HEADER_SIZE,a3),a3
		bra		make_exe_open

make_exe_x:
		moveq		#X_HEADER_SIZE,d1	;d1.l = file size
		add.l		(X_TextSize,a3),d1
		add.l		(X_DataSize,a3),d1
		add.l		(X_RelocateSize,a3),d1
		add.l		(X_SymbolSize,a3),d1	;symbol_size
		add.l		(X_ScdLineSize,a3),d1	;line_info_size
		add.l		(X_ScdSymSize,a3),d1	;scd_info_size
		add.l		(X_ScdSym2Size,a3),d1	;name_info_size

make_exe_open:
*		lea		(workbuf,pc),a0

		move		#1<<ARCHIVE,-(sp)
		tst.b		(NO_X_EXT_FLAG,a0)
		beq		@f
		tst.b		(OPT_AN_FLAG,a0)
		bgt		@f			;-an -o foo.x
;以下二行を有効にすると.rの時はchmod +xしなくなる
***		tst.b		(EXEC_FILE_TYPE,a0)
***		bne		@f
		ori		#1<<EXEC,(sp)
@@:		pea		(EXEC_NAME,a0)
		DOS		_CREATE
		addq.l		#6,sp
		move.l		d0,d2			;d2.w = file handle
		bmi		make_exe_err2		;can't open

		move.l		d1,-(sp)		;file size
		pea		(a3)
		move		d2,-(sp)
		DOS		_WRITE
		addq.l		#10-4,sp
		move.l		d0,(sp)+
		bmi		make_exe_err3		;file I/O error
		cmp.l		d0,d1
		bne		make_exe_err4		;device full

*		lea		(workbuf,pc),a0
		tst.b		(EXEC_FILE_TYPE,a0)
		beq		make_exe_close
		move.l		(X_BssSize-X_HEADER_SIZE,a3),d1
		beq		make_exe_close

		bsr		clear_bss_buffer	;bss書き出し
		move.l		d1,-(sp)
		pea		(a4)
		move		d2,-(sp)
		DOS		_WRITE
		addq.l		#10-4,sp
		move.l		d0,(sp)+
		bmi		make_exe_err3		;file I/O error
		cmp.l		d0,d1
		bne		make_exe_err4		;device full
make_exe_close:
		move		d2,-(sp)
		DOS		_CLOSE
		addq.l		#2,sp
		tst.l		d0
		bmi		make_exe_err3		;file I/O error
make_exe_end:
		lea		(workbuf,pc),a0
		move.l		a4,(MALLOC_PTR_HEAD,a0)
		move.l		d7,(MALLOC_LEFT,a0)
make_exe_return:
		POP		d1-d7/a0-a5
		unlk		a6
		rts

make_exe_err:						;a0.l = unknown cmd
		bra		unknown_cmd		;a1.l = obj_list

make_exe_err2:
		pea		(cant_open_msg,pc)	;Can't open file
		bra		@f
make_exe_err3:
		pea		(file_io_msg,pc)	;File I/O error
		bra		@f
make_exe_err4:
		pea		(device_full_msg,pc)	;Device full
		bra		@f
make_exe_err_offset:
		pea		(rel_tbl_msg,pc)	;再配置テーブルがある
		bra		@f
make_exe_err_ill_offset:
		pea		(ill_offset_msg,pc)	;奇数番地の再配置は出来ない
		bra		@f
make_exe_err_adr:
		pea		(exec_adr_msg,pc)	;実行アドレスが先頭からではない
		bra		@f
@@:
		DOS		_PRINT
		pea		(workbuf+EXEC_NAME,pc)
		DOS		_PRINT
		addq.l		#8,sp
		bsr		print_crlf
		lea		(workbuf+EXIT_CODE,pc),a0
		move		#EXIT_FAILURE,(a0)
		bra		make_exe_return


make_exe_err5:
		pea		(unmatch_size,pc)
		DOS		_PRINT
		addq.l		#4,sp

		lea		(make_exe,pc),a0	;error function
		bra		program_err


* '*SYSTEM*'のdataセクション先頭アドレスを求める.

get_system_data_pos:
		movea.l		(LINK_LIST_HEAD,a0),a2
		movea.l		link_list_obj_list,a1
		movea.l		obj_list_data_pos,a3
		adda.l		header_adr,a3
		lea		(X_HEADER_SIZE,a3),a3
		rts

* BSSをクリアする ----------------------------- *
* in	d1.l	bssサイズ
*	a4.l	バッファ
* break	d0.l

clear_bss_buffer:
		PUSH		d1/a4
		lsr.l		#3,d1
		moveq		#0,d0
		bra		1f
@@:		move.l		d0,(a4)+	;8byteずつクリア
		move.l		d0,(a4)+
1:		dbra		d1,@b
		clr		d1
		subq.l		#1,d1
		bcc		@b

		moveq		#%111,d1
		and.l		(sp),d1
		bra		1f
@@:		move.b		d0,(a4)+	;7byte以下をクリア
1:		dbra		d1,@b

		POP		d1/a4
		rts


*------------------------------------------------------------------------------
*
*	align_set
*
*	in:	a1.l = obj_list
*		a5.l = ptr of write ptr
*
*	out:	a5.l = ptr of aligned write ptr
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a1,0

align_set:	movem.l		d0-d1/a0,-(sp)
		movea.l		(a5),a0			* a0.l = write ptr
		move.l		object_top,d0
		sub.l		a0,d0
		move.l		obj_list_align_size,d1
		subq.l		#1,d1
		and.l		d1,d0			* d0.l = pad_size
		beq		align_set_skip
		lsr.l		#1,d0
		bcc		@f
		clr.b		(a0)+			* 端数バイトを調整
		bra		@f
align_set_l:
		clr		(a0)+			* ワード単位で調整
@@:		subq.l		#1,d0
		bcc		align_set_l
		move.l		a0,(a5)
align_set_skip:
		movem.l		(sp)+,d0-d1/a0
		rts


* テキストセクションはnopで埋める.
* ooさんの*unofficial* patch level 3を参考にしました.

align_set_text:
		movem.l		d0-d1/a0,-(sp)
		movea.l		(a5),a0			* a0.l = write ptr
		move.l		object_top,d0
		sub.l		a0,d0
		move.l		obj_list_align_size,d1
		subq.l		#1,d1
		and.l		d1,d0			* d0.l = pad_size
		beq		align_set_text_skip
		lsr.l		#1,d0
		bcc		@f
		clr.b		(a0)+			* 端数バイトを調整
		bra		@f
align_set_text_l:
		move		#$4e71,(a0)+		* nop
@@:		subq.l		#1,d0
		bcc		align_set_text_l
		move.l		a0,(a5)
align_set_text_skip:
		movem.l		(sp)+,d0-d1/a0
		rts


* 最後のオブジェクトの奇数→偶数サイズ補正の分(1byte)をクリアする.

align_set_last:
		move.l		a0,-(sp)
		movea.l		(a5),a0
		move		a0,-(sp)
		lsr		(sp)+
		bcc		@f
		clr.b		(a0)+			* 1バイトだけクリア
		move.l		a0,(a5)
@@:		movea.l		(sp)+,a0
		rts


* オブジェクトイメージの先頭アドレス	= object_top
* 現在の書き込みアドレス		= addr
* 境界整合サイズ			= align_size
* 境界整合を行う為に出力するバイト数	= pad_size
* とするとき、
* pad_size = {align_size - (addr - object_top)} & (align_size - 1)
*	   = {align_size + (object_top - addr)} & (align_size - 1)
*	   = {align_size & (align_size - 1)} + {(object_top - addr) & (align_size - 1)}
*	   = (object_top - addr) & (align_size - 1)


*------------------------------------------------------------------------------
*
*	AddXToHeap
*
*	in:	a0.l = A
*		d1.l = R
*		d2.l = N
*		d3.l = L
*		d4.l = X
*
*	out:	d7.l = malloc_left
*		a4.l = tail of offset table
*
*------------------------------------------------------------------------------

AddXToHeap:	.macro
		.local		AddXToHeap_l,AddXToHeap_b1,AddXToHeap_b2

		move.l		d3,d5			* d5.l = I = L
		move.l		d5,d6
		add.l		d6,d6			* d6.l = J = L * 2
AddXToHeap_l:	cmp.l		d6,d2			* while (J <= R)
		bcs		AddXToHeap_b2
		beq		AddXToHeap_b1		* if (J < R)
		move.l		(6+2,a0,d6.l),d7	* d7.l = A[J + 1]
		cmp.l		(2,a0,d6.l),d7		* if (A[J] < A[J + 1])
		bls		AddXToHeap_b1
		addq.l		#6,d6			* J = J + 1
AddXToHeap_b1:	cmp.l		(2,a0,d6.l),d4		* if (A[J] <= X)
		bcc		AddXToHeap_b2		*   break
		move.l		(2,a0,d6.l),(2,a0,d5.l)	* A[I] = A[J]
		move.l		d6,d5			* d5.l = I = J
		add.l		d6,d6			* d6.l = J = J * 2
		bra		AddXToHeap_l
AddXToHeap_b2:	move.l		d4,(2,a0,d5.l)		* A[I] = X
		.endm

*------------------------------------------------------------------------------
*
*	make_offset
*
*	in:	offset_table
*		offset_size
*
*	out:	offset_size
*		d0.l = 0:正常終了 -1:奇数アドレスからの再配置は出来ない.
*
*	オフセットテーブルを作成します
*
*　※コンピュータアルゴリズム辞典より（ヒープソート）
*
*------------------------------------------------------------------------------

make_offset:
		PUSH		d1-d7/a0-a1

		move.l		offset_table,a0
		subq.l		#6,a0			* a0.l = A (= offset_table - 6)
		move.l		offset_size,d1		* d1.l = N (= offset_size)
		move.l		d1,d2			* d2.l = R = N

		move.l		d1,d3
		lsr.l		#1,d3
		btst		#0,d3
		beq		make_offset_l10
		sub.l		#3,d3
							* d3.l = L = (N / 2)

make_offset_l10	tst.l		d3			* while (L != 0)
		beq		make_offset_b20
		move.l		(2,a0,d3.l),d4		* d4.l = X = A[L]
		AddXToHeap
		subq.l		#6,d3
		bra		make_offset_l10

make_offset_b20	moveq.l		#6,d3			* d3.l = L = 1
make_offset_l20	cmp.l		#6,d2			* while (1 < R)
		bls		make_offset_b30
		move.l		(2,a0,d2.l),d4		* d4.l = X = A[R]
		move.l		(6+2,a0),(2,a0,d2.l)	* A[R] = A[1]
		subq.l		#6,d2
		AddXToHeap
		bra		make_offset_l20

make_offset_b30	movea.l		offset_table,a0		* a0.l = src
		movea.l		a0,a1			* a1.l = dst
		move.l		offset_size,d2		* d2.l = offset_size
		move.l		d2,d3			* d3.l = true_offset_size
		move.l		#$10000,d4		* d4.l = $10000
		moveq		#$40,d5
		add.l		header_adr,d5		;d5.l = text_top
		moveq		#0,d7
		bra		make_offset_start
make_offset_l30:
		move.l		d5,d1
		addq.l		#2,a0
		move.l		(a0)+,d5
		or		d5,d7
		move.l		d5,d0
		sub.l		d1,d0
		cmp.l		d4,d0
		bcc		make_offset_b31		* offset >= $10000

		move		d0,(a1)+
		subq.l		#4,d3			;6.bでなく2.b(=6-4)で済んだ
		subq.l		#6,d2
		bcc		make_offset_l30
		bra		make_offset_b40
make_offset_b31:
		move		#$0001,(a1)+
		move.l		d0,(a1)+
make_offset_start:
		subq.l		#6,d2
		bcc		make_offset_l30

make_offset_b40:
		movea.l		a1,a4			* a4.l = tail of offset table
		move.l		offset_size,d0
		sub.l		d3,d0			* d0.l = free mem size
		move.l		d3,offset_size
		lea		(workbuf,pc),a0
		sub.l		d0,(MALLOC_PTR_HEAD,a0)
		add.l		d0,(MALLOC_LEFT,a0)

		moveq		#0,d0
		btst		d0,d7
		beq		@f
		moveq		#-1,d0			;奇数番地があればエラー
@@:		POP		d1-d7/a0-a1
		rts

*------------------------------------------------------------------------------
*
*	make_symbol
*
*	in:	a4.l = write pointer
*
*	out:	symbol_size
*
*	シンボルテーブルを作成します
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a1,0
		_link_list_	link_list,a2,0
		_xdef_table_	xdef_table,a3,0
		_xdef_list_	xdef_list,a0,0

make_symbol:
		PUSH		d1-d3/a0-a3

		moveq.l		#0,d3			* d3.l = symbol_size
		lea		(workbuf+LINK_LIST_HEAD,pc),a2
make_sym_l10	move.l		(a2),d0			;a2.l = link_list_head
		beq		make_sym_end
		movea.l		d0,a2
		move.l		link_list_obj_list,a1	* a1.l = obj_list
		movea.l		obj_list_xdef_tbl,a3	* a3.l = xdef_table
make_sym_l20	tst.l		(a3)
		beq		make_sym_b40
		move.l		xdef_table_xdef_list,a0	* a0.l = xdef_list
		cmp.l		xdef_list_obj_list,a1
		bne		make_sym_b30		* not owner

		move		xdef_list_type,d0
		beq		make_sym_b4		;abs
		cmpi		#$0001,d0
		beq		make_sym_b5		;text
		cmpi		#$0002,d0
		beq		make_sym_b6		;data
		cmpi		#$0003,d0
		beq		make_sym_b7		;bss
		cmpi		#$0004,d0
		beq		make_sym_b8		;stack
		cmpi		#$000a,d0
		bls		make_sym_r		;5:rdata～$a:rlstack
		cmpi		#$00fc,d0
		beq		make_sym_b1		;rlcomm
		cmpi		#$00fd,d0
		beq		make_sym_b2		;rcomm
		cmpi		#$00fe,d0
		beq		make_sym_b3		;comm
		bra		make_sym_err		;program error

make_sym_b1:
make_sym_b2:	moveq		#$0000,d1		;rlcommon/rcommon
		bra		make_sym_b20

make_sym_b3:	moveq		#$0003,d1		;common
		bra		make_sym_b20

make_sym_b5:	move		#$0201,d1		;text
		bra		make_sym_b20

make_sym_b6:	move		#$0202,d1		;data
		bra		make_sym_b20

make_sym_b7:	move		#$0203,d1		;bss
		bra		make_sym_b20

make_sym_b8:	move		#$0204,d1		;stack
		bra		make_sym_b20

make_sym_b4:
make_sym_r:	move		#$0200,d1		;abs/rdata/rbss/rstack
*		bra		make_sym_b20		;rldata/rlbss/rlstack

make_sym_b20:	move.l		xdef_list_value,d2	* d2.l = value

		subq.l		#6,d7			* d7.l = malloc left
		bmi		malloc_err
		addq.l		#6,d3			* d3.l = symbol_size
		move.w		d1,(a4)+
		move.l		d2,(a4)+

		movea.l		xdef_list_label_name,a0	* a0.l = label_name
make_sym_l30	subq.l		#1,d7			* d7.l = malloc_left
		bmi		malloc_err
		addq.l		#1,d3			* d3.l = symbol_size
		move.b		(a0)+,(a4)+
		bne		make_sym_l30

		move.l		a4,d0
		btst.l		#0,d0
		beq		make_sym_b30		* even
		subq.l		#1,d7			* d7.l = malloc_left
		bmi		malloc_err
		addq.l		#1,d3			* d3.l = symbol_size
		clr.b		(a4)+

make_sym_b30	addq.l		#__xdef_table__,a3	* a3.l = xdef_table
		bra		make_sym_l20

make_sym_b40	lea		link_list_next,a2	* a2.l = link_list
		bra		make_sym_l10

make_sym_end	move.l		d3,symbol_size
		POP		d1-d3/a0-a3
		rts

make_sym_err:	lea		(make_symbol,pc),a0	* error function
		bra		program_err

*------------------------------------------------------------------------------
*
*	make_scdinfo
*
*	in:	a4.l = write pointer
*
*	ｓｃｄ用のテーブルを作成します（たぶん完成）
*
*------------------------------------------------------------------------------

		_xdef_list_	xdef_list,a0,0
		_obj_list_	obj_list,a1,0
		_link_list_	link_list,a2,0

make_scdinfo:
		PUSH		d1-d7/a0-a5

		lea		(workbuf+LINK_LIST_HEAD,pc),a2
make_scd_l1	move.l		(a2),d0			;a2.l = link_list_head
		beq		make_scd_b10
		movea.l		d0,a2
		move.l		link_list_obj_list,a1	* a1.l = obj_list

		tst.l		obj_list_scdinfo_s
		beq		make_scd_b1		* no scd info.

		movea.l		obj_list_scdinfo,a3	* a3.l = scdinfo_info
		move.l		(a3)+,d1		* d1.l = linfo_size
		move.l		(a3)+,d3
		move.l		12(a3,d1.l),d2
		mulu		#18,d2			* d2.l = sinfo_size
		sub.l		d2,d3			* d3.l = einfo_size
		bmi		make_scd_err2
		move.l		(a3)+,d4		* d4.l = ninfo_size

		add.l		d1,linfo_size
		add.l		d2,sinfo_size
		add.l		d3,einfo_size
		add.l		d4,ninfo_size

make_scd_b1	lea		link_list_next,a2
		bra		make_scd_l1

make_scd_b10	move.l		linfo_size,d0
		add.l		sinfo_size,d0
		add.l		einfo_size,d0
		add.l		ninfo_size,d0
		sub.l		d0,d7
		bmi		malloc_err
		adda.l		d0,a5
		lea		(workbuf,pc),a2
		move.l		a5,(MALLOC_PTR_HEAD,a2)
		move.l		d7,(MALLOC_LEFT,a2)

		moveq.l		#0,d0
		move.l		d0,linfo_pos
		move.l		d0,sinfo_pos
		move.l		d0,einfo_pos
		move.l		d0,ninfo_pos

		lea		(workbuf+LINK_LIST_HEAD,pc),a2
make_scd_l10:	move.l		(a2),d0			;a2.l = link_list_head
		beq		make_scd_end
		movea.l		d0,a2
		move.l		link_list_obj_list,a1	;a1.l = obj_list

		tst.l		obj_list_scdinfo_s
		beq		make_scd_b90		* no scd info.

		movea.l		obj_list_scdinfo,a3	* a3.l = scdinfo_info
		move.l		(a3)+,d1		* d1.l = linfo_size
		move.l		(a3)+,d3
		move.l		12(a3,d1.l),d2
		mulu		#18,d2			* d2.l = sinfo_size
		sub.l		d2,d3			* d3.l = einfo_size
		move.l		(a3)+,d4		* d4.l = ninfo_size

		move.l		d1,d7			* make line info.
		beq		make_scd_b20
		movea.l		linfo_pos,a5
		adda.l		a4,a5			* a5.l = line info
		move.l		obj_list_text_pos,d5	* d5.l = text_pos
make_scd_l11	move.l		(a3)+,d0
		move.w		(a3)+,d6
		beq		make_scd_b11
		add.l		d5,d0
		move.l		d0,(a5)+
		move.w		d6,(a5)+
		subq.l		#6,d7
		bhi		make_scd_l11
		bra		make_scd_b20

make_scd_b11	add.l		sinfo_pos,d0
		move.l		d0,(a5)+
		move.w		d6,(a5)+
		subq.l		#6,d7
		bhi		make_scd_l11

make_scd_b20	move.l		d2,d7			* make scd info.
		beq		make_scd_b500
		move.l		sinfo_pos,d0
		mulu		#18,d0
		add.l		linfo_size,d0
		lea		(a4,d0.l),a5		* a5.l = scd info

make_scd_l20	move.l		(a3)+,d6
		cmp.l		#'.bf'<<8,d6
		beq		make_scd_b300
		cmp.l		#'.ef'<<8,d6
		beq		make_scd_b310
		cmp.l		#'.bb'<<8,d6
		beq		make_scd_b320
		cmp.l		#'.eb'<<8,d6
		beq		make_scd_b330
		cmp.l		#'.eos',d6
		beq		make_scd_b340
		cmp.l		#'.fil',d6
		beq		make_scd_b350
		cmp.l		#'.tex',d6
		beq		make_scd_b360
		cmp.l		#'.dat',d6
		beq		make_scd_b370
		cmp.l		#'.bss',d6
		beq		make_scd_b380
		cmp.l		#'.rda',d6
		beq		make_scd_b390
		cmp.l		#'.rbs',d6
		beq		make_scd_b400
		cmp.l		#'.rld',d6
		beq		make_scd_b410
		cmp.l		#'.rlb',d6
		beq		make_scd_b420

		move.l		d6,(a5)+
		move.l		(a3)+,(a5)+
		tst.l		d6
		bne		make_scd_b21
		move.l		-(a5),d6
		add.l		ninfo_pos,d6
		move.l		d6,(a5)+

make_scd_b21	move.b		9(a3),d0
		bne		make_scd_b430

		move.l		(a3)+,d6
		move.w		(a3)+,d0
		cmp.w		#$0001,d0
		bne		make_scd_b22
		add.l		obj_list_text_pos,d6
		bra		make_scd_b29

make_scd_b22	cmp.w		#$0002,d0
		bne		make_scd_b23
		add.l		obj_list_data_pos,d6
		sub.l		(workbuf+TEXT_SIZE,pc),d6
		bra		make_scd_b29

make_scd_b23	cmp.w		#$0003,d0
		bne		make_scd_b24
		add.l		obj_list_bss_pos,d6
		sub.l		(workbuf+OBJ_SIZE,pc),d6
		bra		make_scd_b29

make_scd_b24	cmp.w		#$0005,d0
		bne		make_scd_b25
		add.l		obj_list_rdata_pos,d6
		bra		make_scd_b29

make_scd_b25	cmp.w		#$0006,d0
		bne		make_scd_b26
		add.l		obj_list_rbss_pos,d6
**		sub.l		(workbuf+RDATA_SIZE,pc),d6
		bra		make_scd_b29

make_scd_b26	cmp.w		#$0008,d0
		bne		make_scd_b27
		add.l		obj_list_rldata_pos,d6
**		sub.l		(workbuf+RDATA_SIZE,pc),d6
**		sub.l		(workbuf+RBSS_SIZE,pc),d6
**		sub.l		(workbuf+RCOMMON_SIZE,pc),d6
**		sub.l		(workbuf+RSTACK_SIZE,pc),d6
		bra		make_scd_b29

make_scd_b27	cmp.w		#$0009,d0
		bne		make_scd_b28
		add.l		obj_list_rlbss_pos,d6
**		sub.l		(workbuf+RDATA_SIZE,pc),d6
**		sub.l		(workbuf+RBSS_SIZE,pc),d6
**		sub.l		(workbuf+RCOMMON_SIZE,pc),d6
**		sub.l		(workbuf+RSTACK_SIZE,pc),d6
**		sub.l		(workbuf+RLDATA_SIZE,pc),d6
		bra		make_scd_b29

make_scd_b28:
		cmpi		#$fffc,d0		;$ffff	xref
		bcc		make_scd_b29		;$fffe	common
		cmpi		#$00fc,d0		;$fffd	rlcommon
		beq		make_scd_b29		;$fffc	rcommon
		cmpi		#$00fd,d0		;$00fd	rlcommon
		bne		make_scd_err2		;$00fc	rcommon
make_scd_b29:
		move.l		d6,(a5)+
		move.w		d0,(a5)+
		move.l		(a3)+,(a5)+

make_scd_b30	moveq.l		#18,d6
		sub.l		d6,d7
		bhi		make_scd_l20
		bcs		make_scd_err		* program error !!
		bra		make_scd_b500

make_scd_b300						* '.bf'
make_scd_b320						* '.bb'
		move.l		d6,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,d0
		add.l		obj_list_text_pos,d0
		move.l		d0,(a5)+
		move.l		(a3)+,(a5)+
		move.w		(a3)+,(a5)+

		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,d0
		add.l		sinfo_pos,d0
		move.l		d0,(a5)+
		move.w		(a3)+,(a5)+

		moveq.l		#18,d6
		sub.l		d6,d7
		bhi		make_scd_b30
		bra		make_scd_err		* program error !!

make_scd_b310						* '.ef'
make_scd_b330						* '.eb'
		move.l		d6,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,d0
		add.l		obj_list_text_pos,d0
		move.l		d0,(a5)+
		move.l		(a3)+,(a5)+
		move.w		(a3)+,(a5)+

		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.w		(a3)+,(a5)+

		moveq.l		#18,d6
		sub.l		d6,d7
		bhi		make_scd_b30
		bra		make_scd_err		* program error !!

make_scd_b340						* '.eos'
		move.l		d6,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.w		(a3)+,(a5)+

		move.l		(a3)+,d0
		add.l		sinfo_pos,d0
		move.l		d0,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.w		(a3)+,(a5)+

		moveq.l		#18,d6
		sub.l		d6,d7
		bhi		make_scd_b30
		bra		make_scd_err		* program error !!

make_scd_b350						* '.fil'
make_scd_b360						* '.tex'
make_scd_b370						* '.dat'
make_scd_b380						* '.bss'
make_scd_b390						* '.rda'
make_scd_b400						* '.rbs'
make_scd_b410						* '.rld'
make_scd_b420						* '.rlb'
		move.l		d6,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.w		(a3)+,(a5)+

		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.w		(a3)+,(a5)+
		move.l		(a3)+,d0
		beq		make_scd_b421
		add.l		ninfo_pos,d0
make_scd_b421	move.l		d0,(a5)+

		moveq.l		#18,d6
		sub.l		d6,d7
		bhi		make_scd_b30
		bra		make_scd_err		* program error !!

make_scd_b430						* function name etc.
		cmp.b		#$01,d0
		bne		make_scd_err2

		move.l		(a3)+,d6
		move.w		(a3)+,d0

		cmp.w		#$0001,d0
		bne		make_scd_b431
		add.l		obj_list_text_pos,d6
		bra		make_scd_b439

make_scd_b431	cmp.w		#$0002,d0
		bne		make_scd_b432
		add.l		obj_list_data_pos,d6
		sub.l		(workbuf+TEXT_SIZE,pc),d6
		bra		make_scd_b440

make_scd_b432	cmp.w		#$0003,d0
		bne		make_scd_b433
		add.l		obj_list_bss_pos,d6
		sub.l		(workbuf+OBJ_SIZE,pc),d6
		bra		make_scd_b440

make_scd_b433	cmp.w		#$0005,d0
		bne		make_scd_b434
		add.l		obj_list_rdata_pos,d6
		bra		make_scd_b440

make_scd_b434	cmp.w		#$0006,d0
		bne		make_scd_b435
		add.l		obj_list_rbss_pos,d6
**		sub.l		(workbuf+RDATA_SIZE,pc),d6
		bra		make_scd_b440

make_scd_b435	cmp.w		#$0008,d0
		bne		make_scd_b436
		add.l		obj_list_rldata_pos,d6
**		sub.l		(workbuf+RDATA_SIZE,pc),d6
**		sub.l		(workbuf+RBSS_SIZE,pc),d6
**		sub.l		(workbuf+RCOMMON_SIZE,pc),d6
**		sub.l		(workbuf+RSTACK_SIZE,pc),d6
		bra		make_scd_b440

make_scd_b436	cmp.w		#$0009,d0
		bne		make_scd_b437
		add.l		obj_list_rlbss_pos,d6
**		sub.l		(workbuf+RDATA_SIZE,pc),d6
**		sub.l		(workbuf+RBSS_SIZE,pc),d6
**		sub.l		(workbuf+RCOMMON_SIZE,pc),d6
**		sub.l		(workbuf+RSTACK_SIZE,pc),d6
**		sub.l		(workbuf+RLDATA_SIZE,pc),d6
		bra		make_scd_b440

make_scd_b437:
		cmpi		#$ffff,d0
		beq		make_scd_b440
		cmpi		#$fffc,d0
		bcs		make_scd_err2
*make_scd_b438:
		move.w		(a3),d5
		cmp.w		#%1000,d5
		beq		make_scd_b450		* struct
		cmp.w		#%1001,d5
		beq		make_scd_b450		* union
		cmp.w		#%1010,d5
		beq		make_scd_b450		* enum
		bra		make_scd_b440

make_scd_b439	move.w		(a3),d5
		and.w		#%11_0000,d5
		cmp.w		#%10_0000,d5
		beq		make_scd_b460

make_scd_b440	move.l		d6,(a5)+
		move.w		d0,(a5)+
		move.l		(a3)+,(a5)+

		move.l		(a3)+,d0
		beq		make_scd_b441
		add.l		sinfo_pos,d0
make_scd_b441	move.l		d0,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.w		(a3)+,(a5)+

		moveq.l		#18,d6
		sub.l		d6,d7
		bhi		make_scd_b30
		bra		make_scd_err		* program error !!

make_scd_b450	move.l		d6,(a5)+		* tag
		move.w		d0,(a5)+
		move.l		(a3)+,(a5)+

		move.l		(a3)+,d0
		beq		make_scd_b451
		add.l		sinfo_pos,d0
make_scd_b451	move.l		d0,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,d0
		beq		make_scd_b452
		add.l		sinfo_pos,d0
make_scd_b452	move.l		d0,(a5)+
		move.w		(a3)+,(a5)+

		moveq.l		#18,d6
		sub.l		d6,d7
		bhi		make_scd_b30
		bra		make_scd_err		* program error !!

make_scd_b460	move.l		d6,(a5)+		* funciton
		move.w		d0,(a5)+
		move.l		(a3)+,(a5)+

		move.l		(a3)+,d0
		beq		make_scd_b461
		add.l		sinfo_pos,d0
make_scd_b461	move.l		d0,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,d0
		add.l		linfo_pos,d0
		move.l		d0,(a5)+
		move.l		(a3)+,d0
		add.l		sinfo_pos,d0
		move.l		d0,(a5)+
		move.w		(a3)+,(a5)+

		moveq.l		#18,d6
		sub.l		d6,d7
		bhi		make_scd_b30
		bra		make_scd_err		* program error !!

make_scd_b500	move.l		d3,d7			* make extern info.
		beq		make_scd_b70
		move.l		einfo_pos,d0
		mulu		#18,d0
		add.l		sinfo_size,d0
		add.l		linfo_size,d0
		lea		(a4,d0.l),a5		* a5.l = scd info
		move.l		(workbuf+OBJ_SIZE,pc),d5

make_scd_l500	move.l		(a3)+,d6
		move.l		d6,(a5)+
		move.l		(a3)+,(a5)+
		tst.l		d6
		bne		make_scd_b510
		move.l		-(a5),d6
		add.l		ninfo_pos,d6
		move.l		d6,(a5)+

make_scd_b510	move		(4,a3),d6
		cmpi		#$00fe,d6
		bhi		@f
		cmpi		#$00fc,d6
		bcc		make_scd_b520		;$00fc～$00fe
		cmpi		#$fffe,d6
		bhi		@f
		cmpi		#$fffc,d6		;$fffc～$fffe
		bcs		make_scd_b550
make_scd_b520:
		move.l		(-8,a5),d0
		beq		make_scd_b521
		lea		(workbuf+TEMP+8,pc),a0
		clr.b		(a0)
		move.l		(-4,a5),-(a0)
		move.l		d0,-(a0)
		bra		make_scd_b530
make_scd_b521	movea.l		obj_list_scdinfo,a0
		move.l		(a0)+,d0
		add.l		(a0)+,d0
		add.l		(-4,a3),d0
		lea		(4,a0,d0.l),a0

make_scd_b530	bsr		search_xdef
		tst.l		d0
		beq		make_scd_err2
		movea.l		d0,a0
		move.l		xdef_list_value,d0

		move.w		xdef_list_type,d6
		cmp.b		#$fe,d6
		beq		make_scd_b531
		cmp.b		#$fd,d6
		beq		make_scd_b532
*		cmp.b		#$fc,d6
*		beq		make_scd_b533
		bra		make_scd_b533

make_scd_b531	sub.l		d5,d0
		move.l		d0,(a5)+
		move.w		#$0003,(a5)+
		bra		make_scd_b534

make_scd_b532	**sub.l		(workbuf+RDATA_SIZE,pc),d0
		move.l		d0,(a5)+
		move.w		#$0006,(a5)+
		bra		make_scd_b534

make_scd_b533	**sub.l		(workbuf+RDATA_SIZE,pc),d0
		**sub.l		(workbuf+RBSS_SIZE,pc),d0
		**sub.l		(workbuf+RCOMMON_SIZE,pc),d0
		**sub.l		(workbuf+RSTACK_SIZE,pc),d0
		**sub.l		(workbuf+RLDATA_SIZE,pc),d0
		move.l		d0,(a5)+
		move.w		#$0009,(a5)+
*		bra		make_scd_b534

make_scd_b534	addq.l		#6,a3
		move.l		(a3)+,(a5)+

make_scd_b535	move.b		-1(a5),d0
		beq		make_scd_b540
		cmp.b		#$01,d0
		bne		make_scd_err2

		moveq.l		#18,d6
		sub.l		d6,d7
		bls		make_scd_err

		move.l		(a3)+,d0
		beq		make_scd_b536
		add.l		sinfo_pos,d0
make_scd_b536	move.l		d0,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		move.w		(a3)+,(a5)+

make_scd_b540	moveq.l		#18,d6
		sub.l		d6,d7
		bhi		make_scd_l500
		bcs		make_scd_err		* program error !!
		bra		make_scd_b70

make_scd_b550	cmp.w		#$0001,d6
		bne		make_scd_b551
		move.l		obj_list_text_pos,d0
		bra		make_scd_b560

make_scd_b551	cmp.w		#$0002,d6
		bne		make_scd_b552
		move.l		obj_list_data_pos,d0
		sub.l		(workbuf+TEXT_SIZE,pc),d0
		bra		make_scd_b560

make_scd_b552	cmp.w		#$0003,d6
		bne		make_scd_b553
		move.l		obj_list_bss_pos,d0
		sub.l		(workbuf+OBJ_SIZE,pc),d0
		bra		make_scd_b560

make_scd_b553	cmp.w		#$0005,d6
		bne		make_scd_b554
		move.l		obj_list_rdata_pos,d0
		bra		make_scd_b560

make_scd_b554	cmp.w		#$0006,d6
		bne		make_scd_b555
		move.l		obj_list_rbss_pos,d0
**		sub.l		(workbuf+RDATA_SIZE,pc),d0
		bra		make_scd_b560

make_scd_b555	cmp.w		#$0008,d6
		bne		make_scd_b556
		move.l		obj_list_rldata_pos,d0
**		sub.l		(workbuf+RDATA_SIZE,pc),d0
**		sub.l		(workbuf+RBSS_SIZE,pc),d0
**		sub.l		(workbuf+RCOMMON_SIZE,pc),d0
**		sub.l		(workbuf+RSTACK_SIZE,pc),d0
		bra		make_scd_b560

make_scd_b556	cmp.w		#$0009,d6
		bne		make_scd_err2
		move.l		obj_list_rlbss_pos,d0
**		sub.l		(workbuf+RDATA_SIZE,pc),d0
**		sub.l		(workbuf+RBSS_SIZE,pc),d0
**		sub.l		(workbuf+RCOMMON_SIZE,pc),d0
**		sub.l		(workbuf+RSTACK_SIZE,pc),d0
**		sub.l		(workbuf+RLDATA_SIZE,pc),d0
**		bra		make_scd_b560

make_scd_b560	add.l		(a3)+,d0
		move.l		d0,(a5)+
		move.w		(a3)+,(a5)+
		move.l		(a3)+,(a5)+
		bra		make_scd_b535

make_scd_b70	move.l		d4,d7			* make name info.
		beq		make_scd_b80
		move.l		ninfo_pos,d0
		add.l		einfo_size,d0
		add.l		sinfo_size,d0
		add.l		linfo_size,d0
		lea		(a4,d0.l),a5		* a5.l = scd info

make_scd_l70	move.b		(a3)+,(a5)+
		subq.l		#1,d7
		bne		make_scd_l70

make_scd_b80	divu		#18,d2
		divu		#18,d3
		add.l		d1,linfo_pos
		add.l		d2,sinfo_pos
		add.l		d3,einfo_pos
		add.l		d4,ninfo_pos

make_scd_b90	lea		link_list_next,a2	* a2.l = link_list
		bra		make_scd_l10

make_scd_end	POP		d1-d7/a0-a5
		move.l		(workbuf+MALLOC_PTR_HEAD,pc),a5
		move.l		(workbuf+MALLOC_LEFT,pc),d7
		rts


make_scd_err	lea		(make_scdinfo,pc),a0	* error function
		bra		program_err

make_scd_err2	pea		(illegal_scdinfo,pc)
		DOS		_PRINT
		move.l		obj_list_obj_name,-(sp)
		DOS		_PRINT
		addq.l		#8,sp
		move.l		obj_list_lib_name,d0
		beq		make_scd_err2_b
		pea		(in_msg,pc)
		DOS		_PRINT
		move.l		obj_list_lib_name,-(sp)
		DOS		_PRINT
		addq.l		#8,sp
make_scd_err2_b	bsr		print_crlf

		lea		(workbuf+EXIT_CODE,pc),a0
		move		#EXIT_FAILURE,(a0)
		POP		d1-d7/a0-a5
		unlk		a6
		rts

*------------------------------------------------------------------------------
*
*	get_xref_label
*
*	in:	d0.w = label no
*		a0.l = obj_list
*
*	out:	d0.w = type
*		d1.l = value
*		a3.l = xdef_list
*
*------------------------------------------------------------------------------

		_xref_table_	xref_table,a3,0
		_xdef_list_	xdef_list,a3,0

get_xref_label::
		movea.l		obj_list_xref_tbl,a3
		subq.l		#1,d0
		mulu		#__xref_table__,d0
		adda.l		d0,a3
		move.l		xref_table_xdef_list,a3
		moveq.l		#0,d0
		move.w		xdef_list_type,d0	* d0.w = type
		move.l		xdef_list_value,d1	* d1.l = value
		rts

*------------------------------------------------------------------------------
*
*	check_byte_val
*
*	in:	d1.l = value
*
*	out:	exit_code = EXIT_FAILURE (-$80 <= !d1.l <= $ff)
*
*------------------------------------------------------------------------------

check_byte_val:
		cmp.l		#+$ff,d1
		bgt		overflow_byte_err
		cmp.l		#-$80,d1
		blt		overflow_byte_err
		rts

*------------------------------------------------------------------------------
*
*	check_byte2_val
*
*	in:	d1.l = value
*
*	out:	exit_code = EXIT_FAILURE (-$80 <= !d1.l <= $7f)
*
*------------------------------------------------------------------------------

check_byte2_val:
		cmp.l		#+$7f,d1
		bgt		overflow_sbyte_err
		cmp.l		#-$80,d1
		blt		overflow_sbyte_err
		rts

*------------------------------------------------------------------------------
*
*	check_word_val
*
*	in:	d1.l = value
*
*	out:	exit_code = EXIT_FAILURE (-$8000 <= !d1.l <= $ffff)
*
*------------------------------------------------------------------------------

check_word_val:
		cmp.l		#+$ffff,d1
		bgt		overflow_word_err
		cmp.l		#-$8000,d1
		blt		overflow_word_err
		rts

*------------------------------------------------------------------------------
*
*	check_word2_val
*
*	in:	d1.l = value
*
*	out:	exit_code = EXIT_FAILURE (-$8000 <= !d1.l <= $7fff)
*
*------------------------------------------------------------------------------

check_word2_val:
		cmp.l		#+$7fff,d1
		bgt		overflow_sword_err
		cmp.l		#-$8000,d1
		blt		overflow_sword_err
		rts

*------------------------------------------------------------------------------

print_err_loc:	pea		(at_msg,pc)
		DOS		_PRINT

		moveq		#-$40,d0
		add.l		a5,d0
		sub.l		header_adr,d0

		move		d5,d1
		subq		#SECT_TEXT,d1
		beq		prn_err_loc_b1
		subq		#SECT_DATA-SECT_TEXT,d1
		beq		prn_err_loc_b2
		subq		#SECT_RDATA-SECT_DATA,d1
		beq		prn_err_loc_b5
		subq		#SECT_RLDATA-SECT_RDATA,d1
		beq		prn_err_loc_b8

		lea		(print_err_loc,pc),a0	;error function
		bra		program_err

prn_err_loc_b8:
		pea		(rldata_msg,pc)
		sub.l		#$10000,d0
		sub.l		obj_list_rldata_pos,d0
		bra		@f
prn_err_loc_b5:
		pea		(rdata_msg,pc)
		sub.l		#$8000,d0
@@:
		sub.l		obj_list_rdata_pos,d0
		sub.l		(workbuf+DATA_SIZE,pc),d0
		sub.l		(workbuf+TEXT_SIZE,pc),d0
		bra		@f
prn_err_loc_b2:
		pea		(data_msg,pc)
		sub.l		obj_list_data_pos,d0
		bra		@f
prn_err_loc_b1:
		pea		(text_msg,pc)
		sub.l		obj_list_text_pos,d0
		bra		@f
@@:
		bsr		print_hex8
		DOS		_PRINT
		addq.l		#8,sp
		bra		print_crlf
*		rts


overflow_byte_err:
		PUSH		d0-d1/a0
		pea		(overflow_byte_msg,pc)
		bra		@f
overflow_sbyte_err:
		PUSH		d0-d1/a0
		pea		(overflow_sbyte_msg,pc)
		bra		@f
overflow_word_err:
		PUSH		d0-d1/a0
		pea		(overflow_word_msg,pc)
		bra		@f
overflow_sword_err:
		PUSH		d0-d1/a0
		pea		(overflow_sword_msg,pc)
		bra		@f
zero_err:
		PUSH		d0-d1/a0
		pea		(division_msg,pc)
		bra		@f
expression_err:
		PUSH		d0-d1/a0
		pea		(express_msg,pc)
		bra		@f
adrs_byte_err:
		PUSH		d0-d1/a0
		pea		(adrs_byte_msg,pc)
		bra		@f
adrs_word_err:
		PUSH		d0-d1/a0
		pea		(adrs_word_msg,pc)
		bra		@f
@@:
		DOS		_PRINT
		addq.l		#4,sp
		bsr		print_in
		bsr		print_err_loc
set_errorcode:
		lea		(workbuf+EXIT_CODE,pc),a0
		move		#EXIT_FAILURE,(a0)
		POP		d0-d1/a0
		rts

dup_exec_err:
		PUSH		d0-d1/a0
		pea		(dup_exec_msg,pc)
		DOS		_PRINT
		addq.l		#4,sp
		bsr		print_in
		bra		set_errorcode


c_stack_over::
		pea		(stack_over_msg,pc)
		bra		@f
c_stack_under::
		pea		(stack_under_msg,pc)
@@:		DOS		_PRINT
		addq.l		#4,sp
		bsr		print_in
		bsr		print_err_loc
		move		#EXIT_FAILURE,-(sp)
		DOS		_EXIT2


print_in:
		move.l		obj_list_obj_name,-(sp)
		DOS		_PRINT

		move.l		obj_list_lib_name,(sp)
		beq		print_in_end
		pea		(in_msg,pc)
		DOS		_PRINT
		addq.l		#4,sp
		DOS		_PRINT
print_in_end:
		addq.l		#4,sp
		bra		print_crlf
*		rts


*------------------------------------------------------------------------------
*
*	check_section (is writable ?)
*
*------------------------------------------------------------------------------

check_section:	.macro		func_name
		.local		write_ok
		cmpi		#SECT_TEXT,d5
		beq		write_ok
		cmpi		#SECT_DATA,d5
		beq		write_ok
		cmpi		#SECT_RDATA,d5
		beq		write_ok
		cmpi		#SECT_RLDATA,d5
		bne		func_name&_be
write_ok:
		.endm

*------------------------------------------------------------------------------
*
*	define const
*
*	10 (size-1)  data  even
*
*------------------------------------------------------------------------------

define_const:
		addq.l		#2,a0
		andi		#$00ff,d1

		check_section	def_const

def_const_l:	move.b		(a0)+,(a5)+
		dbra		d1,def_const_l
def_const_end:	set_rp_bound
		rts

def_const_be:	adda		d1,a0
		addq.l		#1,a0
		bra		def_const_end

*------------------------------------------------------------------------------
*
*	change section
*
*	20 area  0L
*
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
		tst.l		(2,a0)
		bne		make_exe_err		;Undefined command
		addq.l		#6,a0

		move		d5,d0
		subq		#SECT_TEXT,d0
		beq		chg_sect_from_text
		subq		#SECT_DATA-SECT_TEXT,d0
		beq		chg_sect_from_data
		subq		#SECT_RDATA-SECT_DATA,d0
		beq		chg_sect_from_rdata
		subq		#SECT_RLDATA-SECT_RDATA,d0
		bne		@f
chg_sect_from_rldata:
		move.l		a5,rldata_w_adr
		bra		@f
chg_sect_from_rdata:
		move.l		a5,rdata_w_adr
		bra		@f
chg_sect_from_data:
		move.l		a5,data_w_adr
		bra		@f
chg_sect_from_text:
		move.l		a5,text_w_adr
		bra		@f
@@:
		moveq		#0,d5
		move.b		d1,d5

		subq.b		#SECT_TEXT,d1
		beq		chg_sect_to_text
		subq.b		#SECT_DATA-SECT_TEXT,d1
		beq		chg_sect_to_data
		subq.b		#SECT_RDATA-SECT_DATA,d1
		beq		chg_sect_to_rdata
		subq.b		#SECT_RLDATA-SECT_RDATA,d1
		bne		@f
chg_sect_to_rldata:
		movea.l		rldata_w_adr,a5
@@:		rts
chg_sect_to_rdata:
		movea.l		rdata_w_adr,a5
		rts
chg_sect_to_data:
		movea.l		data_w_adr,a5
		rts
chg_sect_to_text:
		movea.l		text_w_adr,a5
		rts


*------------------------------------------------------------------------------
*
*	define space
*
*	30 00  size.l
*
*------------------------------------------------------------------------------

define_space:
		addq.l		#2,a0
		move.l		(a0)+,d1

		check_section	def_space

		moveq.l		#0,d0
def_space_l	subq.l		#1,d1			* 遅いけど見逃してね (^_^)
		bmi		def_space_end
		move.b		d0,(a5)+
		bra		def_space_l
def_space_be	add.l		d1,a5
def_space_end	rts


*------------------------------------------------------------------------------
*
*	ctor/dtor
*
*	4[cd] 01  adr.l
*
*------------------------------------------------------------------------------

wrt_ctor_4c01:
		PUSH		a3/a5
		lea		(workbuf+CTOR_LIST_PTR,pc),a3
wrt_ctor_dtor:
		addq.l		#2,a0
		move.l		(a0)+,d1
		add.l		obj_list_text_pos,d1
		movea.l		(a3),a5
		store_offset
		MOVEL_D1_A5PI
		move.l		a5,(a3)
		POP		a3/a5
		rts

wrt_dtor_4d01:
		PUSH		a3/a5
		lea		(workbuf+DTOR_LIST_PTR,pc),a3
		bra		wrt_ctor_dtor


movel_d1_a5pi_odd:
		addq.l		#2,(sp)		;skip <move.l d1,(a5)+>
movel_d1_a5pi_odd_rts:
		rol.l		#8,d1
		move.b		d1,(a5)+
		move.l		d1,(a5)+
		ror.l		#8,d1
		subq.l		#1,a5
		rts


*------------------------------------------------------------------------------
*
*	write label
*
*	4? {fc-ff}  label_no
*
*------------------------------------------------------------------------------

wrt_lbl_40fc: * SXhas
wrt_lbl_40fd: * SXhas
wrt_lbl_40fe:
wrt_lbl_40ff:
		addq.l		#2,a0			* write byte (0, value)
		move.w		(a0)+,d0

		check_section	wrt_lbl_40ff

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
		tst		d0			* d1.l = value
		beq		wrt_lbl_40ff_b1		* abs
		bsr		adrs_byte_err
		bra		wrt_lbl_40ff_b2
wrt_lbl_40ff_b1	bsr		check_byte_val
wrt_lbl_40ff_b2:
		clr.b		(a5)+
		move.b		d1,(a5)+
wrt_lbl_40ff_be	rts


wrt_lbl_47fe: * v2.00
wrt_lbl_47ff: * v2.00
wrt_lbl_43fc: * SXhas
wrt_lbl_43fd: * SXhas
wrt_lbl_43fe:
wrt_lbl_43ff:
		addq.l		#2,a0			* write byte (value)
		move.w		(a0)+,d0

		check_section	wrt_lbl_43ff

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
		tst		d0			* d1.l = value
		beq		wrt_lbl_43ff_b1		* abs
		bsr		adrs_byte_err
		bra		wrt_lbl_43ff_b2
wrt_lbl_43ff_b1	bsr		check_byte_val
wrt_lbl_43ff_b2	move.b		d1,(a5)+
wrt_lbl_43ff_be	rts


wrt_lbl_45fe: * v2.00
wrt_lbl_45ff: * v2.00
wrt_lbl_41fc: * SXhas
wrt_lbl_41fd: * SXhas
wrt_lbl_41fe:
wrt_lbl_41ff:
		addq.l		#2,a0			* write word (value)
		move.w		(a0)+,d0

		check_section	wrt_lbl_41ff

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
		tst		d0			* d1.l = value
		beq		wrt_lbl_41ff_b3		* abs
		cmp.w		#$00fe,d0
		beq		wrt_lbl_41ff_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_41ff_b2
wrt_lbl_41ff_b1	bsr		adrs_word_err
		bra		wrt_lbl_41ff_b4
wrt_lbl_41ff_b2	cmp.w		#$0004,d5
		bhi		wrt_lbl_41ff_b1
		bsr		check_word2_val
		bra		wrt_lbl_41ff_b4
wrt_lbl_41ff_b3	bsr		check_word_val
wrt_lbl_41ff_b4:
		MOVEW_D1_A5PI
wrt_lbl_41ff_be	rts


wrt_lbl_42fc: * SXhas
wrt_lbl_42fd: * SXhas
wrt_lbl_42fe:
wrt_lbl_42ff:
wrt_lbl_46fc: * SXhas
wrt_lbl_46fd: * SXhas
wrt_lbl_46fe:
wrt_lbl_46ff:
		addq.l		#2,a0			* write long word (value)
		move.w		(a0)+,d0

		check_section	wrt_lbl_46ff

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
		tst		d0			* d1.l = value
		beq		wrt_lbl_46ff_b2		* abs
		cmp.w		#$0004,d0
		bls		wrt_lbl_46ff_b1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_46ff_b1
		cmp.w		#$0004,d5
		bls		wrt_lbl_46ff_b2
		store_offset2
		bra		wrt_lbl_46ff_b2
wrt_lbl_46ff_b1	store_offset
wrt_lbl_46ff_b2:
		MOVEL_D1_A5PI_RTS
wrt_lbl_46ff_be	rts

*------------------------------------------------------------------------------
*
*	write label
*
*	4? {00-0a}  adr.l
*
*------------------------------------------------------------------------------

wrt_lbl_4000:
		addq.l		#2,a0			* write byte (0, adr)
		move.l		(a0)+,d1		* d1.l = value

		check_section	wrt_lbl_4000

		bsr		check_byte_val
		clr.b		(a5)+
		move.b		d1,(a5)+
wrt_lbl_4000_be	rts


wrt_lbl_4300:
		addq.l		#2,a0			* write byte (adr)
		move.l		(a0)+,d1		* d1.l = value

		check_section	wrt_lbl_4300

		bsr		check_byte_val
		move.b		d1,(a5)+
wrt_lbl_4300_be	rts


wrt_lbl_4100:
		addq.l		#2,a0			* write word (adr)
		move.l		(a0)+,d1		* d1.l = value

		check_section	wrt_lbl_4100

		bsr		check_word_val
		MOVEW_D1_A5PI
wrt_lbl_4100_be	rts


wrt_lbl_4200:
wrt_lbl_4600:
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1		* d1.l = value

		check_section	wrt_lbl_4600

		MOVEL_D1_A5PI_RTS
wrt_lbl_4600_be	rts


wrt_lbl_4001:
wrt_lbl_4002:
wrt_lbl_4003:
wrt_lbl_4004:
wrt_lbl_4005: * SXhas
wrt_lbl_4006: * SXhas
wrt_lbl_4007: * SXhas
wrt_lbl_4008: * SXhas
wrt_lbl_4009: * SXhas
wrt_lbl_400a: * SXhas					;write byte (0, adr)
		addq.l		#6,a0

		check_section	wrt_lbl_400a

		bsr		adrs_byte_err
		clr.b		(a5)+
		clr.b		(a5)+			;何でも良い
wrt_lbl_400a_be	rts

wrt_lbl_4101:
wrt_lbl_4102:
wrt_lbl_4103:
wrt_lbl_4104:
wrt_lbl_4108: * SXhas
wrt_lbl_4109: * SXhas
wrt_lbl_410a: * SXhas					;write word (adr)
		addq.l		#6,a0

		check_section	wrt_lbl_410a

		bsr		adrs_word_err
		clr.b		(a5)+
		clr.b		(a5)+			* 何でも良い
wrt_lbl_410a_be	rts


wrt_lbl_4301:
wrt_lbl_4302:
wrt_lbl_4303:
wrt_lbl_4304:
wrt_lbl_4305: * SXhas
wrt_lbl_4306: * SXhas
wrt_lbl_4307: * SXhas
wrt_lbl_4308: * SXhas
wrt_lbl_4309: * SXhas
wrt_lbl_430a: * SXhas
		addq.l		#6,a0			* write byte (adr)

		check_section	wrt_lbl_430a

		bsr		adrs_byte_err
		clr.b		(a5)+			* 何でも良い
wrt_lbl_430a_be	rts


wrt_lbl_4105: * SXhas
		addq.l		#2,a0			* write word (adr)
		move.l		(a0)+,d1		* d1.l = value

		check_section	wrt_lbl_4105

		add.l		obj_list_rdata_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_4105_b1

		bsr		adrs_word_err
		bra		wrt_lbl_4105_b2

wrt_lbl_4105_b1	bsr		check_word2_val
wrt_lbl_4105_b2:
		MOVEW_D1_A5PI
wrt_lbl_4105_be	rts


wrt_lbl_4106: * SXhas
		addq.l		#2,a0			* write word (adr)
		move.l		(a0)+,d1		* d1.l = value

		check_section	wrt_lbl_4106

		add.l		obj_list_rbss_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_4106_b1

		bsr		adrs_word_err
		bra		wrt_lbl_4106_b2

wrt_lbl_4106_b1	bsr		check_word2_val
wrt_lbl_4106_b2:
		MOVEW_D1_A5PI
wrt_lbl_4106_be	rts


wrt_lbl_4107: * SXhas
		addq.l		#2,a0			* write word (adr)
		move.l		(a0)+,d1		* d1.l = value

		check_section	wrt_lbl_4107

		add.l		obj_list_rstack_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_4107_b1

		bsr		adrs_word_err
		bra		wrt_lbl_4107_b2

wrt_lbl_4107_b1	bsr		check_word2_val
wrt_lbl_4107_b2:
		MOVEW_D1_A5PI
wrt_lbl_4107_be	rts


wrt_lbl_4201:
wrt_lbl_4601:
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1

		check_section	wrt_lbl_4601

		add.l		obj_list_text_pos,d1
		store_offset
		MOVEL_D1_A5PI_RTS
wrt_lbl_4601_be	rts


wrt_lbl_4202:
wrt_lbl_4602:
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1

		check_section	wrt_lbl_4602

		add.l		obj_list_data_pos,d1
		store_offset
		MOVEL_D1_A5PI_RTS
wrt_lbl_4602_be	rts


wrt_lbl_4203:
wrt_lbl_4603:
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1

		check_section	wrt_lbl_4603

		add.l		obj_list_bss_pos,d1
		store_offset
		MOVEL_D1_A5PI_RTS
wrt_lbl_4603_be	rts


wrt_lbl_4204:
wrt_lbl_4604:
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1

		check_section	wrt_lbl_4604

		add.l		obj_list_stack_pos,d1
		store_offset
		MOVEL_D1_A5PI_RTS
wrt_lbl_4604_be	rts


wrt_lbl_4205: * SXhas
wrt_lbl_4605: * SXhas
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1

		check_section	wrt_lbl_4605

		add.l		obj_list_rdata_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_4605_b
		store_offset2
wrt_lbl_4605_b:
		MOVEL_D1_A5PI_RTS
wrt_lbl_4605_be	rts


wrt_lbl_4206: * SXhas
wrt_lbl_4606: * SXhas
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1

		check_section	wrt_lbl_4606

		add.l		obj_list_rbss_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_4606_b
		store_offset2
wrt_lbl_4606_b:
		MOVEL_D1_A5PI_RTS
wrt_lbl_4606_be	rts


wrt_lbl_4207: * SXhas
wrt_lbl_4607: * SXhas
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1

		check_section	wrt_lbl_4607

		add.l		obj_list_rstack_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_4607_b
		store_offset2
wrt_lbl_4607_b
		MOVEL_D1_A5PI_RTS
wrt_lbl_4607_be	rts


wrt_lbl_4208: * SXhas
wrt_lbl_4608: * SXhas
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1

		check_section	wrt_lbl_4608

		add.l		obj_list_rldata_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_4608_b
		store_offset2
wrt_lbl_4608_b:
		MOVEL_D1_A5PI_RTS
wrt_lbl_4608_be	rts


wrt_lbl_4209: * SXhas
wrt_lbl_4609: * SXhas
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1

		check_section	wrt_lbl_4609

		add.l		obj_list_rlbss_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_4609_b
		store_offset2
wrt_lbl_4609_b
		MOVEL_D1_A5PI_RTS
wrt_lbl_4609_be	rts


wrt_lbl_420a: * SXhas
wrt_lbl_460a: * SXhas
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1

		check_section	wrt_lbl_460a

		add.l		obj_list_rlstack_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_460a_b
		store_offset2
wrt_lbl_460a_b
		MOVEL_D1_A5PI_RTS
wrt_lbl_460a_be	rts

*------------------------------------------------------------------------------
*
*	write label (offset)
*
*	5? {fc-ff}  label_no offset
*
*------------------------------------------------------------------------------

wrt_lbl_50fc: * SXhas
wrt_lbl_50fd: * SXhas
wrt_lbl_50fe:
wrt_lbl_50ff:
		addq.l	#2,a0			* write byte (0, value)
		move	(a0)+,d0
		move.l	(a0)+,d2

		check_section	wrt_lbl_50ff

		bsr	get_xref_label		* a3.l = xdef_list
						* d0.w = type
						* d1.l = value
		add.l	d2,d1
		tst	d0
		beq	wrt_lbl_50ff_b1		* abs
		bsr	adrs_byte_err
		bra	wrt_lbl_50ff_b2
wrt_lbl_50ff_b1:
		bsr	check_byte_val
wrt_lbl_50ff_b2:
		clr.b	(a5)+
		move.b	d1,(a5)+
wrt_lbl_50ff_be:
		rts


wrt_lbl_57fe: * v2.00 ??
wrt_lbl_57ff: * v2.00
wrt_lbl_53fc: * SXhas
wrt_lbl_53fd: * SXhas
wrt_lbl_53fe: * v2.00 ??
wrt_lbl_53ff:
		addq.l		#2,a0			* write byte (value)
		move.w		(a0)+,d0
		move.l		(a0)+,d2

		check_section	wrt_lbl_53ff

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		add.l		d2,d1
		tst.w		d0
		beq		wrt_lbl_53ff_b1		* abs
		bsr		adrs_byte_err
		bra		wrt_lbl_53ff_b2
wrt_lbl_53ff_b1	bsr		check_byte_val
wrt_lbl_53ff_b2	move.b		d1,(a5)+
wrt_lbl_53ff_be	rts


wrt_lbl_55fe: * v2.00 ??
wrt_lbl_55ff: * v2.00
wrt_lbl_51fc: * SXhas
wrt_lbl_51fd: * SXhas
wrt_lbl_51fe: * v2.00 ??
wrt_lbl_51ff:
		addq.l		#2,a0			* write word (value)
		move.w		(a0)+,d0
		move.l		(a0)+,d2

		check_section	wrt_lbl_51ff

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		add.l		d2,d1
		tst.w		d0
		beq		wrt_lbl_51ff_b3		* abs
		cmp.w		#$00fe,d0
		beq		wrt_lbl_51ff_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_51ff_b2
wrt_lbl_51ff_b1	bsr		adrs_word_err
		bra		wrt_lbl_51ff_b4
wrt_lbl_51ff_b2	cmp.w		#$0004,d5
		bhi		wrt_lbl_51ff_b1
		bsr		check_word2_val
		bra		wrt_lbl_51ff_b4
wrt_lbl_51ff_b3	bsr		check_word_val
wrt_lbl_51ff_b4:
		MOVEW_D1_A5PI
wrt_lbl_51ff_be	rts


wrt_lbl_52fc: * SXhas
wrt_lbl_52fd: * SXhas
wrt_lbl_52fe: * v2.00 ??
wrt_lbl_52ff:
wrt_lbl_56fc: * SXhas
wrt_lbl_56fd: * SXhas
wrt_lbl_56fe: * v2.00 ??
wrt_lbl_56ff:
		addq.l		#2,a0			* write long word (value)
		move.w		(a0)+,d0
		move.l		(a0)+,d2

		check_section	wrt_lbl_56ff

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		add.l		d2,d1
		tst.w		d0
		beq		wrt_lbl_56ff_b2		* abs
		cmp.w		#$0004,d0
		bls		wrt_lbl_56ff_b1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_56ff_b1
		cmp.w		#$0004,d5
		bls		wrt_lbl_56ff_b2
		store_offset2
		bra		wrt_lbl_56ff_b2
wrt_lbl_56ff_b1	store_offset
wrt_lbl_56ff_b2:
		MOVEL_D1_A5PI_RTS
wrt_lbl_56ff_be	rts

*------------------------------------------------------------------------------
*
*	write label (offset)
*
*	5? {00-0a}  adr.l offset.l
*
*------------------------------------------------------------------------------

wrt_lbl_5000:
		addq.l	#2,a0			* write byte (0, adr)
		move.l	(a0)+,d1		* d1.l = value
		add.l	(a0)+,d1

		check_section	wrt_lbl_5000

		bsr	check_byte_val
		clr.b	(a5)+
		move.b	d1,(a5)+
wrt_lbl_5000_be:
		rts

wrt_lbl_5300:
		addq.l		#2,a0			* write byte (adr)
		move.l		(a0)+,d1		* d1.l = value
		add.l		(a0)+,d1

		check_section	wrt_lbl_5300

		bsr		check_byte_val
		move.b		d1,(a5)+
wrt_lbl_5300_be	rts


wrt_lbl_5100:
		addq.l		#2,a0			* write word (adr)
		move.l		(a0)+,d1		* d1.l = value
		add.l		(a0)+,d1

		check_section	wrt_lbl_5100

		bsr		check_word_val
		MOVEW_D1_A5PI
wrt_lbl_5100_be	rts


wrt_lbl_5200:
wrt_lbl_5600:
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1		* d1.l = value
		add.l		(a0)+,d1

		check_section	wrt_lbl_5600

		MOVEL_D1_A5PI_RTS
wrt_lbl_5600_be	rts


wrt_lbl_5001:
wrt_lbl_5002:
wrt_lbl_5003:
wrt_lbl_5004:
wrt_lbl_5005: * SXhas
wrt_lbl_5006: * SXhas
wrt_lbl_5007: * SXhas
wrt_lbl_5008: * SXhas
wrt_lbl_5009: * SXhas
wrt_lbl_500a: * SXhas					;write byte (0, adr)
		lea		(10,a0),a0

		check_section	wrt_lbl_500a

		bsr		adrs_byte_err
		clr.b		(a5)+
		clr.b		(a5)+			;何でも良い
wrt_lbl_500a_be:
		rts

wrt_lbl_5101:
wrt_lbl_5102:
wrt_lbl_5103:
wrt_lbl_5104:
wrt_lbl_5108: * SXhas
wrt_lbl_5109: * SXhas
wrt_lbl_510a: * SXhas					;write word (adr)
		lea		(10,a0),a0

		check_section	wrt_lbl_510a

		bsr		adrs_word_err
		clr.b		(a5)+
		clr.b		(a5)+			* 何でも良い
wrt_lbl_510a_be:
		rts

wrt_lbl_5301:
wrt_lbl_5302:
wrt_lbl_5303:
wrt_lbl_5304:
wrt_lbl_5305: * SXhas
wrt_lbl_5306: * SXhas
wrt_lbl_5307: * SXhas
wrt_lbl_5308: * SXhas
wrt_lbl_5309: * SXhas
wrt_lbl_530a: * SXhas
		lea		10(a0),a0		* write byte (adr)

		check_section	wrt_lbl_530a

		bsr		adrs_byte_err
		clr.b		(a5)+			* 何でも良い
wrt_lbl_530a_be	rts


wrt_lbl_5105: * SXhas
		addq.l		#2,a0			* write word (adr)
		move.l		(a0)+,d1		* d1.l = value
		add.l		(a0)+,d1

		check_section	wrt_lbl_5105

		add.l		obj_list_rdata_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_5105_b1

		bsr		adrs_word_err
		bra		wrt_lbl_5105_b2

wrt_lbl_5105_b1	bsr		check_word2_val
wrt_lbl_5105_b2:
		MOVEW_D1_A5PI
wrt_lbl_5105_be	rts


wrt_lbl_5106: * SXhas
		addq.l		#2,a0			* write word (adr)
		move.l		(a0)+,d1		* d1.l = value
		add.l		(a0)+,d1

		check_section	wrt_lbl_5106

		add.l		obj_list_rbss_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_5106_b1

		bsr		adrs_word_err
		bra		wrt_lbl_5106_b2

wrt_lbl_5106_b1	bsr		check_word2_val
wrt_lbl_5106_b2
		MOVEW_D1_A5PI
wrt_lbl_5106_be	rts


wrt_lbl_5107: * SXhas
		addq.l		#2,a0			* write word (adr)
		move.l		(a0)+,d1		* d1.l = value
		add.l		(a0)+,d1

		check_section	wrt_lbl_5107

		add.l		obj_list_rstack_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_5107_b1

		bsr		adrs_word_err
		bra		wrt_lbl_5107_b2

wrt_lbl_5107_b1	bsr		check_word2_val
wrt_lbl_5107_b2:
		MOVEW_D1_A5PI
wrt_lbl_5107_be	rts


wrt_lbl_5201:
wrt_lbl_5601:
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1
		add.l		(a0)+,d1

		check_section	wrt_lbl_5601

		add.l		obj_list_text_pos,d1
		store_offset
		MOVEL_D1_A5PI_RTS
wrt_lbl_5601_be	rts


wrt_lbl_5202:
wrt_lbl_5602:
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1
		add.l		(a0)+,d1

		check_section	wrt_lbl_5602

		add.l		obj_list_data_pos,d1
		store_offset
		MOVEL_D1_A5PI_RTS
wrt_lbl_5602_be	rts


wrt_lbl_5203:
wrt_lbl_5603:
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1
		add.l		(a0)+,d1

		check_section	wrt_lbl_5603

		add.l		obj_list_bss_pos,d1
		store_offset
		MOVEL_D1_A5PI_RTS
wrt_lbl_5603_be	rts


wrt_lbl_5204:
wrt_lbl_5604:
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1
		add.l		(a0)+,d1

		check_section	wrt_lbl_5604

		add.l		obj_list_stack_pos,d1
		store_offset
		MOVEL_D1_A5PI_RTS
wrt_lbl_5604_be	rts


wrt_lbl_5205: * SXhas
wrt_lbl_5605: * SXhas
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1
		add.l		(a0)+,d1

		check_section	wrt_lbl_5605

		add.l		obj_list_rdata_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_5605_b
		store_offset2
wrt_lbl_5605_b:
		MOVEL_D1_A5PI_RTS
wrt_lbl_5605_be	rts


wrt_lbl_5206: * SXhas
wrt_lbl_5606: * SXhas
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1
		add.l		(a0)+,d1

		check_section	wrt_lbl_5606

		add.l		obj_list_rbss_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_5606_b
		store_offset2
wrt_lbl_5606_b:
		MOVEL_D1_A5PI_RTS
wrt_lbl_5606_be	rts


wrt_lbl_5207: * SXhas
wrt_lbl_5607: * SXhas
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1
		add.l		(a0)+,d1

		check_section	wrt_lbl_5607

		add.l		obj_list_rstack_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_5607_b
		store_offset2
wrt_lbl_5607_b:
		MOVEL_D1_A5PI_RTS
wrt_lbl_5607_be	rts


wrt_lbl_5208: * SXhas
wrt_lbl_5608: * SXhas
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1
		add.l		(a0)+,d1

		check_section	wrt_lbl_5608

		add.l		obj_list_rldata_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_5608_b
		store_offset2
wrt_lbl_5608_b:
		MOVEL_D1_A5PI_RTS
wrt_lbl_5608_be	rts


wrt_lbl_5209: * SXhas
wrt_lbl_5609: * SXhas
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1
		add.l		(a0)+,d1

		check_section	wrt_lbl_5609

		add.l		obj_list_rlbss_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_5609_b
		store_offset2
wrt_lbl_5609_b:
		MOVEL_D1_A5PI_RTS
wrt_lbl_5609_be	rts


wrt_lbl_520a: * SXhas
wrt_lbl_560a: * SXhas
		addq.l		#2,a0			* write long word (adr)
		move.l		(a0)+,d1
		add.l		(a0)+,d1

		check_section	wrt_lbl_560a

		add.l		obj_list_rlstack_pos,d1
		cmp.w		#$0004,d5
		bls		wrt_lbl_560a_b
		store_offset2
wrt_lbl_560a_b:
		MOVEL_D1_A5PI_RTS
wrt_lbl_560a_be	rts

*------------------------------------------------------------------------------
*
*	write label
*
*	65 {01-0a}  adr.l  label_no
*
*------------------------------------------------------------------------------

wrt_lbl_6901:						* v2.00
wrt_lbl_6501:
		addq.l		#2,a0			* write word (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_text_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6501

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		tst.w		d0
		beq		wrt_lbl_6501_b1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6501_b2
		cmp.w		#$0004,d0
		bls		wrt_lbl_6501_b2
wrt_lbl_6501_b1	bsr		adrs_word_err
		bra		wrt_lbl_6501_b3
wrt_lbl_6501_b2	bsr		check_word2_val		* -$8000 ～ $7fff
wrt_lbl_6501_b3:
		MOVEW_D1_A5PI
wrt_lbl_6501_be	rts


wrt_lbl_6902:						* v2.00
wrt_lbl_6502:
		addq.l		#2,a0			* write word (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_data_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6502

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		tst.w		d0
		beq		wrt_lbl_6502_b1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6502_b2
		cmp.w		#$0004,d0
		bls		wrt_lbl_6502_b2
wrt_lbl_6502_b1	bsr		adrs_word_err
		bra		wrt_lbl_6502_b3
wrt_lbl_6502_b2	bsr		check_word2_val		* -$8000 ～ $7fff
wrt_lbl_6502_b3:
		MOVEW_D1_A5PI
wrt_lbl_6502_be	rts


wrt_lbl_6903:						* v2.00
wrt_lbl_6503:
		addq.l		#2,a0			* write word (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_bss_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6503

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		tst.w		d0
		beq		wrt_lbl_6503_b1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6503_b2
		cmp.w		#$0004,d0
		bls		wrt_lbl_6503_b2
wrt_lbl_6503_b1	bsr		adrs_word_err
		bra		wrt_lbl_6503_b3
wrt_lbl_6503_b2	bsr		check_word2_val		* -$8000 ～ $7fff
wrt_lbl_6503_b3:
		MOVEW_D1_A5PI
wrt_lbl_6503_be	rts


wrt_lbl_6904:						* v2.00
wrt_lbl_6504:
		addq.l		#2,a0			* write word (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_stack_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6504

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		tst.w		d0
		beq		wrt_lbl_6504_b1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6504_b2
		cmp.w		#$0004,d0
		bls		wrt_lbl_6504_b2
wrt_lbl_6504_b1	bsr		adrs_word_err
		bra		wrt_lbl_6504_b3
wrt_lbl_6504_b2	bsr		check_word2_val		* -$8000 ～ $7fff
wrt_lbl_6504_b3:
		MOVEW_D1_A5PI
wrt_lbl_6504_be	rts


wrt_lbl_6905:						* v2.00
wrt_lbl_6505:
		addq.l		#2,a0			* write word (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_rdata_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6505

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6505_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_6505_b2
wrt_lbl_6505_b1	bsr		adrs_word_err
		bra		wrt_lbl_6505_b3
wrt_lbl_6505_b2	bsr		check_word2_val		* -$8000 ～ $7fff
wrt_lbl_6505_b3:
		MOVEW_D1_A5PI
wrt_lbl_6505_be	rts


wrt_lbl_6906:						* v2.00
wrt_lbl_6506:
		addq.l		#2,a0			* write word (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_rbss_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6506

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6506_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_6506_b2
wrt_lbl_6506_b1	bsr		adrs_word_err
		bra		wrt_lbl_6506_b3
wrt_lbl_6506_b2	bsr		check_word2_val		* -$8000 ～ $7fff
wrt_lbl_6506_b3:
		MOVEW_D1_A5PI
wrt_lbl_6506_be	rts


wrt_lbl_6907:						* v2.00
wrt_lbl_6507:
		addq.l		#2,a0			* write word (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_rstack_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6507

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6507_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_6507_b2
wrt_lbl_6507_b1	bsr		adrs_word_err
		bra		wrt_lbl_6507_b3
wrt_lbl_6507_b2	bsr		check_word2_val		* -$8000 ～ $7fff
wrt_lbl_6507_b3:
		MOVEW_D1_A5PI
wrt_lbl_6507_be	rts


wrt_lbl_6908:						* v2.00
wrt_lbl_6508:
		addq.l		#2,a0			* write word (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_rldata_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6508

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6508_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_6508_b2
wrt_lbl_6508_b1	bsr		adrs_word_err
		bra		wrt_lbl_6508_b3
wrt_lbl_6508_b2	bsr		check_word2_val		* -$8000 ～ $7fff
wrt_lbl_6508_b3:
		MOVEW_D1_A5PI
wrt_lbl_6508_be	rts


wrt_lbl_6909:						* v2.00
wrt_lbl_6509:
		addq.l		#2,a0			* write word (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_rlbss_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6509

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		cmp.w		#$00fe,d0
		bhi		wrt_lbl_6509_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_6509_b2
wrt_lbl_6509_b1	bsr		adrs_word_err
		bra		wrt_lbl_6509_b3
wrt_lbl_6509_b2	bsr		check_word2_val		* -$8000 ～ $7fff
wrt_lbl_6509_b3:
		MOVEW_D1_A5PI
wrt_lbl_6509_be	rts


wrt_lbl_690a:						* v2.00
wrt_lbl_650a:
		addq.l		#2,a0			* write word (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_rlstack_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_650a

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_650a_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_650a_b2
wrt_lbl_650a_b1	bsr		adrs_word_err
		bra		wrt_lbl_650a_b3
wrt_lbl_650a_b2	bsr		check_word2_val		* -$8000 ～ $7fff
wrt_lbl_650a_b3:
		MOVEW_D1_A5PI
wrt_lbl_650a_be	rts


*------------------------------------------------------------------------------
*
*	write label
*
*	6b {01-0a}  adr.l  label_no
*
*------------------------------------------------------------------------------

wrt_lbl_6b01:						* v2.00
		addq.l		#2,a0			* write byte (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_text_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6b01

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		tst.w		d0
		beq		wrt_lbl_6b01_b1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6b01_b2
		cmp.w		#$0004,d0
		bls		wrt_lbl_6b01_b2
wrt_lbl_6b01_b1	bsr		adrs_byte_err
		bra		wrt_lbl_6b01_b3
wrt_lbl_6b01_b2	bsr		check_byte2_val		* -$80 ～ $7f
wrt_lbl_6b01_b3	move.b		d1,(a5)+
wrt_lbl_6b01_be	rts


wrt_lbl_6b02:						* v2.00
		addq.l		#2,a0			* write byte (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_data_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6b02

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		tst.w		d0
		beq		wrt_lbl_6b02_b1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6b02_b2
		cmp.w		#$0004,d0
		bls		wrt_lbl_6b02_b2
wrt_lbl_6b02_b1	bsr		adrs_byte_err
		bra		wrt_lbl_6b02_b3
wrt_lbl_6b02_b2	bsr		check_byte2_val		* -$80 ～ $7f
wrt_lbl_6b02_b3	move.b		d1,(a5)+
wrt_lbl_6b02_be	rts


wrt_lbl_6b03:						* v2.00
		addq.l		#2,a0			* write byte (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_bss_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6b03

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		tst.w		d0
		beq		wrt_lbl_6b03_b1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6b03_b2
		cmp.w		#$0004,d0
		bls		wrt_lbl_6b03_b2
wrt_lbl_6b03_b1	bsr		adrs_byte_err
		bra		wrt_lbl_6b03_b3
wrt_lbl_6b03_b2	bsr		check_byte2_val		* -$80 ～ $7f
wrt_lbl_6b03_b3	move.b		d1,(a5)+
wrt_lbl_6b03_be	rts


wrt_lbl_6b04:						* v2.00
		addq.l		#2,a0			* write byte (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_stack_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6b04

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		tst.w		d0
		beq		wrt_lbl_6b04_b1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6b04_b2
		cmp.w		#$0004,d0
		bls		wrt_lbl_6b04_b2
wrt_lbl_6b04_b1	bsr		adrs_byte_err
		bra		wrt_lbl_6b04_b3
wrt_lbl_6b04_b2	bsr		check_byte2_val		* -$80 ～ $7f
wrt_lbl_6b04_b3	move.b		d1,(a5)+
wrt_lbl_6b04_be	rts


wrt_lbl_6b05:						* v2.00
		addq.l		#2,a0			* write byte (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_rdata_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6b05

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6b05_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_6b05_b2
wrt_lbl_6b05_b1	bsr		adrs_byte_err
		bra		wrt_lbl_6b05_b3
wrt_lbl_6b05_b2	bsr		check_byte2_val		* -$80 ～ $7f
wrt_lbl_6b05_b3	move.b		d1,(a5)+
wrt_lbl_6b05_be	rts


wrt_lbl_6b06:						* v2.00
		addq.l		#2,a0			* write byte (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_rbss_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6b06

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6b06_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_6b06_b2
wrt_lbl_6b06_b1	bsr		adrs_byte_err
		bra		wrt_lbl_6b06_b3
wrt_lbl_6b06_b2	bsr		check_byte2_val		* -$80 ～ $7f
wrt_lbl_6b06_b3	move.b		d1,(a5)+
wrt_lbl_6b06_be	rts


wrt_lbl_6b07:						* v2.00
		addq.l		#2,a0			* write byte (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_rstack_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6b07

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6b07_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_6b07_b2
wrt_lbl_6b07_b1	bsr		adrs_byte_err
		bra		wrt_lbl_6b07_b3
wrt_lbl_6b07_b2	bsr		check_byte2_val		* -$80 ～ $7f
wrt_lbl_6b07_b3	move.b		d1,(a5)+
wrt_lbl_6b07_be	rts


wrt_lbl_6b08:						* v2.00
		addq.l		#2,a0			* write byte (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_rldata_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6b08

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6b08_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_6b08_b2
wrt_lbl_6b08_b1	bsr		adrs_byte_err
		bra		wrt_lbl_6b08_b3
wrt_lbl_6b08_b2	bsr		check_byte2_val		* -$80 ～ $7f
wrt_lbl_6b08_b3	move.b		d1,(a5)+
wrt_lbl_6b08_be	rts


wrt_lbl_6b09:						* v2.00
		addq.l		#2,a0			* write byte (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_rlbss_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6b09

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		cmp.w		#$00fe,d0
		bhi		wrt_lbl_6b09_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_6b09_b2
wrt_lbl_6b09_b1	bsr		adrs_byte_err
		bra		wrt_lbl_6b09_b3
wrt_lbl_6b09_b2	bsr		check_byte2_val		* -$80 ～ $7f
wrt_lbl_6b09_b3	move.b		d1,(a5)+
wrt_lbl_6b09_be	rts


wrt_lbl_6b0a:						* v2.00
		addq.l		#2,a0			* write byte (label - adr(a))
		move.l		(a0)+,d2
		add.l		obj_list_rlstack_pos,d2
		move.w		(a0)+,d0

		check_section	wrt_lbl_6b0a

		bsr		get_xref_label		* a3.l = xdef_list
							* d0.w = type
							* d1.l = value
		sub.l		d2,d1
		cmp.w		#$00fe,d0
		beq		wrt_lbl_6b0a_b1
		cmp.w		#$0004,d0
		bhi		wrt_lbl_6b0a_b2
wrt_lbl_6b0a_b1	bsr		adrs_byte_err
		bra		wrt_lbl_6b0a_b3
wrt_lbl_6b0a_b2	bsr		check_byte2_val		* -$80 ～ $7f
wrt_lbl_6b0a_b3	move.b		d1,(a5)+
wrt_lbl_6b0a_be	rts


*------------------------------------------------------------------------------
*
*	push label
*
*	80 {fc-ff}  label_no
*
*------------------------------------------------------------------------------

psh_lbl_80fc: * SXhas
psh_lbl_80fd: * SXhas
psh_lbl_80fe: * v2.00 ??
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

*------------------------------------------------------------------------------
*
*	push label
*
*	80 {00-0a}  num.l
*
*------------------------------------------------------------------------------

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
		addq.l		#2,a0
		move.l		(a0)+,d1
		add.l		obj_list_text_pos,d1
psh_lbl_8001_b	movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_TOP,pc),a3
		beq		c_stack_over		* calc stack over flow
		move.l		d1,-(a3)
		move		#1,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		subq.l		#6,(a3)
		rts


psh_lbl_8002:
		addq.l		#2,a0
		move.l		(a0)+,d1
		add.l		obj_list_data_pos,d1
		bra		psh_lbl_8001_b


psh_lbl_8003:
		addq.l		#2,a0
		move.l		(a0)+,d1
		add.l		obj_list_bss_pos,d1
		bra		psh_lbl_8001_b


psh_lbl_8004:
		addq.l		#2,a0
		move.l		(a0)+,d1
		add.l		obj_list_stack_pos,d1
		bra		psh_lbl_8001_b


psh_lbl_8005:
		addq.l		#2,a0
		move.l		(a0)+,d1
		add.l		obj_list_rdata_pos,d1
psh_lbl_8005_b	movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_TOP,pc),a3
		beq		c_stack_over		* calc stack over flow
		move.l		d1,-(a3)
		move		#2,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		subq.l		#6,(a3)
		rts


psh_lbl_8006:
		addq.l		#2,a0
		move.l		(a0)+,d1
		add.l		obj_list_rbss_pos,d1
		bra		psh_lbl_8005_b


psh_lbl_8007:
		addq.l		#2,a0
		move.l		(a0)+,d1
		add.l		obj_list_rstack_pos,d1
		bra		psh_lbl_8005_b


psh_lbl_8008:
		addq.l		#2,a0
		move.l		(a0)+,d1
		add.l		obj_list_rldata_pos,d1
		bra		psh_lbl_8005_b


psh_lbl_8009:
		addq.l		#2,a0
		move.l		(a0)+,d1
		add.l		obj_list_rlbss_pos,d1
		bra		psh_lbl_8005_b


psh_lbl_800a:
		addq.l		#2,a0
		move.l		(a0)+,d1
		add.l		obj_list_rlstack_pos,d1
		bra		psh_lbl_8005_b

*------------------------------------------------------------------------------
*
*	write stack
*
*	9? 00
*
*------------------------------------------------------------------------------

wrt_stk_9000:
		addq.l		#2,a0			* write stack (0, stk.b)
		movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_BOT,pc),a3
		beq		c_stack_under		* calc stack under flow
		move		(a3)+,d0		* d0.w = type
		move.l		(a3)+,d1		* d1.l = value

		check_section	wrt_stk_9000

		tst		d0
		beq		wrt_stk_9000_b1
		bmi		wrt_stk_9000_b2
		bsr		adrs_byte_err
		bra		wrt_stk_9000_b2
wrt_stk_9000_b1:bsr		check_byte_val
wrt_stk_9000_b2:
		clr.b		(a5)+
		move.b		d1,(a5)+
wrt_stk_9000_be:
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#6,(a3)
		rts


wrt_stk_9300:
		addq.l		#2,a0			* write stack (stk.b)
		movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_BOT,pc),a3
		beq		c_stack_under		* calc stack under flow
		move		(a3)+,d0		* d0.w = type
		move.l		(a3)+,d1		* d1.l = value

		check_section	wrt_stk_9300

		tst		d0
		beq		wrt_stk_9300_b1
		bmi		wrt_stk_9300_b2
		bsr		adrs_byte_err
		bra		wrt_stk_9300_b2
wrt_stk_9300_b1:bsr		check_byte_val
wrt_stk_9300_b2:move.b		d1,(a5)+
wrt_stk_9300_be:
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#6,(a3)
		rts


wrt_stk_9100:
		addq.l		#2,a0			* write stack (stk.w)
		movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_BOT,pc),a3
		beq		c_stack_under		* calc stack under flow
		move		(a3)+,d0		* d0.w = type
		move.l		(a3)+,d1		* d1.l = value

		check_section	wrt_stk_9100

		tst		d0
		beq		wrt_stk_9100_b2
		bmi		wrt_stk_9100_b3
		cmpi		#1,d0
		beq		wrt_stk_9100_b1
		cmpi		#$0004,d5
		bhi		wrt_stk_9100_b1
		bsr		check_word2_val
		bra		wrt_stk_9100_b3
wrt_stk_9100_b1:bsr		adrs_word_err
		bra		wrt_stk_9100_b3
wrt_stk_9100_b2:bsr		check_word_val
wrt_stk_9100_b3:
		MOVEW_D1_A5PI
wrt_stk_9100_be:
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

		check_section	wrt_stk_9600

		tst		d0
		beq		wrt_stk_9600_b2		* abs
		bmi		wrt_stk_9600_b2
		cmpi		#1,d0
		beq		wrt_stk_9600_b1
		cmpi		#$0004,d5
		bls		wrt_stk_9600_b2
		store_offset2
		bra		wrt_stk_9600_b2
wrt_stk_9600_b1:store_offset
wrt_stk_9600_b2:
		MOVEL_D1_A5PI
wrt_stk_9600_be:
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#6,(a3)
		rts


wrt_stk_9900:
		addq.l		#2,a0			* write stack (stk.w)
		movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_BOT,pc),a3
		beq		c_stack_under		* calc stack under flow
		move		(a3)+,d0		* d0.w = type
		move.l		(a3)+,d1		* d1.l = value

		check_section	wrt_stk_9900

		tst		d0
		beq		wrt_stk_9900_b2
		bmi		wrt_stk_9900_b3
		cmpi		#1,d0
		beq		wrt_stk_9900_b1
		cmpi		#$0004,d5
		bls		wrt_stk_9900_b2
wrt_stk_9900_b1:bsr		adrs_word_err
		bra		wrt_stk_9900_b3
wrt_stk_9900_b2:bsr		check_word2_val		* -$8000 ～ $7fff
wrt_stk_9900_b3:
		MOVEW_D1_A5PI
wrt_stk_9900_be:
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#6,(a3)
		rts


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

chk_cstk_err:
		addq.l		#4,sp
		bra		c_stack_under		* calc stack under flow
chk_cstk_und2:
		addq.l		#2,a0
		movea.l		(workbuf+CALC_STACK_PTR,pc),a3
		cmp.l		(workbuf+CALC_STACK_BOT,pc),a3
		beq		chk_cstk_err
		move		(a3)+,d2
		move.l		(a3)+,d0		* d0.l = (stk+0)
		cmp.l		(workbuf+CALC_STACK_BOT,pc),a3
		beq		chk_cstk_err
		move		(a3)+,d3
		move.l		(a3)+,d1		* d1.l = (stk+1)
		rts


*------------------------------------------------------------------------------
*
*	chk_calcexp1
*
*	取り出した値が定数なら何もしない。
*	そうでなければ、エラーを表示して無効な値の属性を設定する。
*
*------------------------------------------------------------------------------

chk_calcexp1:
		tst		d2
		ble		chk_calcexp1_be
		bsr		expression_err
		moveq		#-1,d2
chk_calcexp1_be:rts


*------------------------------------------------------------------------------
*
*	chk_calcexp2
*
*	取り出した２つの値が２つとも定数なら何もしない。
*	そうでなければ、エラーを表示して無効な値の属性を設定する。
*
*------------------------------------------------------------------------------

chk_calcexp2:
		moveq		#0,d4			d4.w = new stat
		tst		d2
		beq		@f			;定数
		bmi		chk_calcexp2_b3
		bsr		expression_err
		bra		chk_calcexp2_b3

@@:		tst		d3
		beq		@f			;定数
		bmi		chk_calcexp2_b3
		bsr		expression_err
chk_calcexp2_b3:
		moveq		#-1,d4			;d4.w = new stat (undefined)
@@:		rts


*------------------------------------------------------------------------------
*
*	calc stack
*
*	a0 {01, 02, 03, 04, 05, 06, 07, 09, 0a, 0b, 0c, 0d, 0e, 0f
*           10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 1a, 1b, 1c, 1d}
*
*------------------------------------------------------------------------------

cal_stk_a001:
		bsr		chk_cstk_und1		* .neg.(stk)

		bsr		chk_calcexp1
		tst.w		d2
		bmi		cal_stk_a001_be
		neg.l		d0

cal_stk_a001_be	move.l		d0,-(a3)
		move.w		d2,-(a3)
		rts


cal_stk_a002:
		bsr		chk_cstk_und1		* (stk)
		move.l		d0,-(a3)
		move		d2,-(a3)
		rts


cal_stk_a003:
		bsr		chk_cstk_und1		* .not.(stk)
		bsr		chk_calcexp1
		tst		d2
		bmi		cal_stk_a003_be

		tst.l		d0
		seq		d0
		ext		d0
		ext.l		d0
cal_stk_a003_be:
		move.l		d0,-(a3)
		move		d2,-(a3)
		rts


cal_stk_a004:
		bsr		chk_cstk_und1		* .high.(stk)
		bsr		chk_calcexp1
		tst		d2
		bmi		cal_stk_a004_be

		lsr		#8,d0
*		andi.l		#$ff,d0
		ext.l		d0
cal_stk_a004_be:
		move.l		d0,-(a3)
		move		d2,-(a3)
		rts


cal_stk_a005:
		bsr		chk_cstk_und1		* .low.(stk)
		bsr		chk_calcexp1
		tst		d2
		bmi		cal_stk_a005_be

		andi.l		#$ff,d0
cal_stk_a005_be:
		move.l		d0,-(a3)
		move		d2,-(a3)
		rts


cal_stk_a006:
		bsr		chk_cstk_und1		* .highw.(stk)
		bsr		chk_calcexp1
		tst		d2
		bmi		cal_stk_a006_be

		clr		d0
		swap		d0
cal_stk_a006_be:
		move.l		d0,-(a3)
		move		d2,-(a3)
		rts


cal_stk_a007:
		bsr		chk_cstk_und1		* .loww.(stk)
		bsr		chk_calcexp1
		tst		d2
		bmi		cal_stk_a007_be

		andi.l		#$0000_ffff,d0
cal_stk_a007_be:
		move.l		d0,-(a3)
		move		d2,-(a3)
		rts


cal_stk_a009:
		bsr		chk_cstk_und2		* (stk+1) * (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a009_be

		bsr		muls_d0d1		* d1.l = (stk+1) * (stk+0)
cal_stk_a009_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)		;pop-pop-push
		rts


cal_stk_a00a:
		bsr		chk_cstk_und2		* (stk+1) / (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a00a_be

		tst.l		d0
		bne		cal_stk_a00a_b
		bsr		zero_err
		moveq		#-1,d4
		bra		cal_stk_a00a_be
cal_stk_a00a_b:	bsr		divs_d0d1		* d1.l = (stk+1) / (stk+0)
cal_stk_a00a_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a00b:
		bsr		chk_cstk_und2		* (stk+1) % (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a00b_be

		tst.l		d0
		bne		cal_stk_a00b_b
		bsr		zero_err
		moveq		#-1,d4
		bra		cal_stk_a00b_be
cal_stk_a00b_b:	bsr		divs_d0d1		* d0.l = (stk+1) % (stk+0)
cal_stk_a00b_be:
		move.l		d0,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a00c:
		bsr		chk_cstk_und2		* (stk+1) .shr. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a00c_be
		lsr.l		d0,d1
cal_stk_a00c_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a00d:
		bsr		chk_cstk_und2		* (stk+1) .shl. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a00d_be
		lsl.l		d0,d1
cal_stk_a00d_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a00e:
		bsr		chk_cstk_und2		* (stk+1) .asr. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a00e_be
		asr.l		d0,d1
cal_stk_a00e_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a00f:
		bsr		chk_cstk_und2		* (stk+1) - (stk+0)

		tst		d2
		beq		cal_stk_a00f_b3
		bgt		@f
		moveq		#-1,d4
		bra		cal_stk_a00f_be
@@:
		tst		d3
		bge		@f
		moveq.l		#-1,d4
		bra		cal_stk_a00f_be

@@:		cmp		d2,d3
		beq		cal_stk_a00f_b3
		bsr		expression_err
		moveq		#-1,d4
		bra		cal_stk_a00f_be
cal_stk_a00f_b3:
		move		d3,d4
		eor		d2,d4
		sub.l		d0,d1			* d1.l = (stk+1) - (stk+0)
cal_stk_a00f_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a010:
		bsr		chk_cstk_und2		* (stk+1) + (stk+0)

		tst		d2
		beq		cal_stk_a010_b3
		bgt		@f
		moveq		#-1,d4
		bra		cal_stk_a010_be

@@:		tst		d3
		beq		cal_stk_a010_b3
		bmi		cal_stk_a010_b2
		bsr		expression_err
cal_stk_a010_b2:moveq		#-1,d4
		bra		cal_stk_a010_be
cal_stk_a010_b3:
		move		d3,d4
		eor		d2,d4
		add.l		d0,d1			* d1.l = (stk+1) + (stk+0)
cal_stk_a010_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts

cal_stk_a011:
		bsr		chk_cstk_und2		* (stk+1) .eq. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a011_be
		cmp.l		d0,d1
		seq		d1
		ext		d1
		ext.l		d1
cal_stk_a011_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a012:
		bsr		chk_cstk_und2		* (stk+1) .ne. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a012_be
		cmp.l		d0,d1
		sne		d1
		ext		d1
		ext.l		d1
cal_stk_a012_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a013:
		bsr		chk_cstk_und2		* (stk+1) .lt. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a013_be
		cmp.l		d0,d1
		scs		d1
		ext		d1
		ext.l		d1
cal_stk_a013_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a014:
		bsr		chk_cstk_und2		* (stk+1) .le. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a014_be
		cmp.l		d0,d1
		sls		d1
		ext		d1
		ext.l		d1
cal_stk_a014_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a015:
		bsr		chk_cstk_und2		* (stk+1) .gt. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a015_be
		cmp.l		d0,d1
		shi		d1
		ext		d1
		ext.l		d1
cal_stk_a015_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a016:
		bsr		chk_cstk_und2		* (stk+1) .ge. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a016_be
		cmp.l		d0,d1
		scc		d1
		ext		d1
		ext.l		d1
cal_stk_a016_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a017:
		bsr		chk_cstk_und2		* (stk+1) .slt. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a017_be
		cmp.l		d0,d1
		slt		d1
		ext		d1
		ext.l		d1
cal_stk_a017_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a018:
		bsr		chk_cstk_und2		* (stk+1) .sle. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a018_be
		cmp.l		d0,d1
		sle		d1
		ext		d1
		ext.l		d1
cal_stk_a018_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a019:
		bsr		chk_cstk_und2		* (stk+1) .sgt. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a019_be
		cmp.l		d0,d1
		sgt		d1
		ext		d1
		ext.l		d1
cal_stk_a019_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a01a:
		bsr		chk_cstk_und2		* (stk+1) .sge. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a01a_be
		cmp.l		d0,d1
		sge		d1
		ext		d1
		ext.l		d1
cal_stk_a01a_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a01b:
		bsr		chk_cstk_und2		* (stk+1) .and. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a01b_be
		and.l		d0,d1
cal_stk_a01b_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a01c:
		bsr		chk_cstk_und2		* (stk+1) .xor. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a01c_be
		eor.l		d0,d1
cal_stk_a01c_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


cal_stk_a01d:
		bsr		chk_cstk_und2		* (stk+1) .or. (stk+0)
		bsr		chk_calcexp2
		tst.l		d4
		bmi		cal_stk_a01d_be
		or.l		d0,d1
cal_stk_a01d_be:
		move.l		d1,-(a3)
		move		d4,-(a3)
		lea		(workbuf+CALC_STACK_PTR,pc),a3
		addq.l		#12-6,(a3)
		rts


*------------------------------------------------------------------------------
*
*	deinfe label
*
*	b0 ff  val.l  label_name  even
*	b2 {fc-ff,00-0a}  val.l  label_name  0 even
*
*------------------------------------------------------------------------------

def_lbl_b0ff:
def_lbl_b2fc: * SXhas
def_lbl_b2fd: * SXhas
def_lbl_b2fe:
def_lbl_b2ff:
def_lbl_b200:
def_lbl_b201:
def_lbl_b202:
def_lbl_b203:
def_lbl_b204:
def_lbl_b205: * SXhas
def_lbl_b206: * SXhas
def_lbl_b207: * SXhas
def_lbl_b208: * SXhas
def_lbl_b209: * SXhas
def_lbl_b20a: * SXhas
		bra		bra_skip_com
*		rts

*------------------------------------------------------------------------------
*
*	object header
*
*	c0 {01-0a}  area_size.l  area_name 0
*
*------------------------------------------------------------------------------

obj_head_c001:
obj_head_c002:
obj_head_c003:
obj_head_c004:
obj_head_c005: * SXhas
obj_head_c006: * SXhas
obj_head_c007: * SXhas
obj_head_c008: * SXhas
obj_head_c009: * SXhas
obj_head_c00a: * SXhas
obj_head_c00c:
obj_head_c00d:
		bra		bra_skip_com
*		rts

*------------------------------------------------------------------------------
*
*	object name
*
*	d0 00  file_size.l  file_name
*
*------------------------------------------------------------------------------
*
*	request obj
*
*	e1 00  obj_name
*
*------------------------------------------------------------------------------

obj_name:
req_obj:
do_ctor_e00c:
do_dtor_e00d:
bra_skip_com:
		bra		skip_com
*		rts


*------------------------------------------------------------------------------
*
*	set execute address
*
*	e0 00  area.w  exec_adr.l
*
*------------------------------------------------------------------------------

set_exec_adr:
		movem.l		(a0),d0/d1		;set exec adr
		subq		#SECT_TEXT,d0		;d0.w = area.w
		beq		set_exec_adr_text	;d1.l = exec_adr
		subq		#SECT_DATA-SECT_TEXT,d0
		beq		set_exec_adr_data
		subq		#SECT_BSS-SECT_DATA,d0
		beq		set_exec_adr_bss
		subq		#SECT_STACK-SECT_BSS,d0
		bne		make_exe_err		;unknown command
set_exec_adr_stack:
		add.l		obj_list_stack_pos,d1
		bra		@f
set_exec_adr_bss:
		add.l		obj_list_bss_pos,d1
		bra		@f
set_exec_adr_data:
		add.l		obj_list_data_pos,d1
		bra		@f
set_exec_adr_text:
		add.l		obj_list_text_pos,d1
		bra		@f
@@:
		tst		exec_stat
		beq		@f
		bsr		dup_exec_err		;実行開始アドレスの二重指定
@@:
		addq		#1,exec_stat
**		move.l		a1,exec_obj_list
**		move.l		d0,exec_section		;d0は破壊されている!
**		move.l		d1,exec_adr

		pea		(8,a0)			;addq.l #8,a0 ;move.l a0,-(sp)
		lea		(workbuf+EXEC_ADDRESS,pc),a0
		move.l		d1,(a0)
		movea.l		(sp)+,a0
		rts


*------------------------------------------------------------------------------

muls_d0d1	PUSH		d2-d4			* d1.l = d1.l * d0.l

		moveq.l		#0,d2			* d2.w = sign

		tst.l		d0
		bpl		muls_d0d1_b1
		neg.l		d0
		not.w		d2

muls_d0d1_b1	tst.l		d1
		bpl		muls_d0d1_b2
		neg.l		d1
		not.w		d2

muls_d0d1_b2	move.w		d1,d3
		mulu		d0,d3			* d3.l = d1.w * d0.w
		swap		d0
		move.w		d1,d4
		mulu		d0,d4			* d4.l = d1.w * d0.w'
		swap		d4
		clr.w		d4
		add.l		d4,d3
		swap		d0
		swap		d1
		move.w		d1,d4
		mulu		d0,d4			* d4.l = d1.w' * d0.w
		swap		d4
		clr.w		d4
		add.l		d4,d3			* d3.l = d1.l * d0.l

		tst.w		d2
		beq		muls_d0d1_b3
		neg.l		d3

muls_d0d1_b3	exg		d1,d3

		POP		d2-d4
		rts


divs_d0d1	PUSH		d2-d5			* d0.l = abs(d1.l mod d0.l)
							* d1.l = d1.l /	d0.l (!= 0)
		moveq.l		#0,d2			* d2.w = sign

		tst.l		d0
		bpl		divs_d0d1_b1
		neg.l		d0
		not		d2

divs_d0d1_b1	tst.l		d1
		bpl		divs_d0d1_b2
		neg.l		d1
		not		d2

divs_d0d1_b2	moveq.l		#0,d3
		moveq.l		#0,d4

		move.w		#32-1,d5		* d5.w = loop counter
divs_d0d1_l	asl.l		#1,d3
		roxl.l		#1,d1
		roxl.l		#1,d4
		cmp.l		d0,d4
		bcs		divs_d0d1_b3
		sub.l		d0,d4
		addq.l		#1,d3
divs_d0d1_b3	dbra		d5,divs_d0d1_l

		move.l		d3,d1
		move.l		d4,d0

		tst.w		d2
		bpl		divs_d0d1_end
		neg.l		d1

divs_d0d1_end	POP		d2-d5
		rts


*------------------------------------------------------------------------------

illegal_scdinfo:.dc.b		'不正なSCD情報 in ',0

adrs_byte_msg:	.dc.b		'アドレス属性シンボルの値をバイトサイズで出力 in ',0
adrs_word_msg:	.dc.b		'アドレス属性シンボルの値をワードサイズで出力 in ',0

division_msg:	.dc.b		'ゼロ除算 in ',0

express_msg:	.dc.b		'不正な式 in ',0

overflow_byte_msg:	.dc.b	'バイトサイズ(-$80～$ff)で表現できない値 in ',0
overflow_sbyte_msg:	.dc.b	'バイトサイズ(-$80～$7f)で表現できない値 in ',0
overflow_word_msg:	.dc.b	'ワードサイズ(-$8000～$ffff)で表現できない値 in ',0
overflow_sword_msg:	.dc.b	'ワードサイズ(-$8000～$7fff)で表現できない値 in ',0

stack_over_msg:	.dc.b		'計算用スタックが溢れました in ',0

stack_under_msg:.dc.b		'計算用スタックに値がありません in ',0

dup_exec_msg:	.dc.b		'複数の実行開始アドレスを指定することはできません in ',0

in_msg:		.dc.b		' in ',0

at_msg:		.dc.b		' at ',0

text_msg:	.dc.b		' (text)',0

data_msg:	.dc.b		' (data)',0

rdata_msg:	.dc.b		' (rdata)',0

rldata_msg:	.dc.b		' (rldata)',0

cant_open_msg:	.dc.b		'実行ファイルが作成できません: ',0

file_io_msg:	.dc.b		'ファイルI/Oエラー: ',0

device_full_msg:.dc.b		'ディスクの空き容量がありません: ',0

rel_tbl_msg:	.dc.b		'再配置テーブルが使われています: ',0

ill_offset_msg:	.dc.b		'再配置対象が奇数アドレスにあります: ',0

exec_adr_msg:	.dc.b		'実行開始アドレスがファイル先頭ではありません: ',0

unmatch_size:	.dc.b		'roffsetサイズ不一致(?_?)!',CRLF,CRLF
		.dc.b		0

make_exe_mes:	.dc.b		'実行ファイルを作成します...',CRLF
		.dc.b		0

		.even

*------------------------------------------------------------------------------

sub_list:	.macro		call_adr
		.dc		call_adr-jump_table
		.endm

jump_table:	sub_list	make_exe_b10		* $0000

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
		sub_list	make_exe_err
		sub_list	make_exe_err
		sub_list	make_exe_err
		sub_list	make_exe_err
		sub_list	make_exe_err

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
		sub_list	make_exe_err
		sub_list	make_exe_err
		sub_list	make_exe_err
		sub_list	make_exe_err
		sub_list	make_exe_err

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
		sub_list	make_exe_err
		sub_list	make_exe_err
		sub_list	make_exe_err
		sub_list	make_exe_err
		sub_list	make_exe_err

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
		sub_list	make_exe_err
		sub_list	make_exe_err
		sub_list	make_exe_err
		sub_list	make_exe_err
		sub_list	make_exe_err

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
		sub_list	make_exe_err
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
		sub_list	make_exe_err
		sub_list	make_exe_err

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

		sub_list	make_exe_err		+
		sub_list	obj_head_c00c		+ $c00c size.l 'ctor',0
		sub_list	obj_head_c00d		+ $c00d size.l 'dtor',0

		sub_list	obj_name		* $d000

		sub_list	set_exec_adr		* $e000
		sub_list	req_obj			* $e001

	.rept	$e00c-($e001+1)
		sub_list	make_exe_err		+
	.endm
		sub_list	do_ctor_e00c		+ $e00c .doctor
		sub_list	do_dtor_e00d		+ $e00d .dodtor


		.end

* End of File --------------------------------- *
