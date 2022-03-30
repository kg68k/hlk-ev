		.title		HLK/ev (make_map.s - make map file module)


* Include File -------------------------------- *

		.include	hlk.mac
		.include	doscall.mac


* Global Symbol ------------------------------- *

		.xdef		make_map
		.xdef		align16_malloc_buf

		.xref		print_crlf

		.xref		hex_table


* Register Map -------------------------------- *

d5~ferror:	.reg		d5


* Text Section -------------------------------- *

		.cpu		68000

		.text
		.even

*------------------------------------------------------------------------------
*
*	make_map
*
*	マップファイルを作成します。本当にマップファイルと言うのだ
*	ろうか？？？
*
*	後で作ると汚くなるのね、許してちょ。あっ、元からか・・・
*
*------------------------------------------------------------------------------

		_link_list_	linklist,a0,0

make_map::
		move.b		(workbuf+VERBOSE_FLAG,pc),d0
		beq		@f

		pea		(make_map_mes,pc)
		DOS		_PRINT
		addq.l		#4,sp
@@:
		move		#1<<ARCHIVE,-(sp)
		pea		(workbuf+MAP_NAME,pc)
		DOS		_CREATE
		addq.l		#6,sp
		move.l		d0,d7			;d7.w = file handle
		bmi		make_map_err1		;file open error

		bsr		align16_malloc_buf
		bsr		malloc_write_buf

		moveq		#0,d5~ferror
		moveq		#0,d6			;d6.l = stored buffer size
		movea.l		(workbuf+MAP_BUF_ADR,pc),a4
							;a4.l = write buffer

		pea		(bar,pc)		;'===== ... ===='
		bsr		fprint
*		addq.l		#4,sp
		pea		(workbuf+EXEC_NAME,pc)
		bsr		fprint
		addq.l		#4,sp
		bsr		fprint_crlf
*		pea		(bar,pc)		;'===== ... ===='
		bsr		fprint
		addq.l		#4,sp
		tst		d5~ferror
		bne		make_map_err2		;file write error

		move.l		(workbuf+EXEC_ADDRESS,pc),-(sp)
		bsr		fprint_execadr

		moveq		#0,d1
		move.l		(workbuf+TEXT_SIZE,pc),d2
		pea		(text_msg,pc)
		PUSH		d1-d2
		bsr		fprint_secinfo

		add.l		d2,d1
		move.l		(workbuf+DATA_SIZE,pc),d2
		add.l		(workbuf+ROFF_TBL_SIZE,pc),d2
		add.l		(workbuf+RDATA_D_SIZE,pc),d2
		add.l		(workbuf+RLDATA_D_SIZE,pc),d2
		pea		(data_msg,pc)
		PUSH		d1-d2
		bsr		fprint_secinfo

		add.l		d2,d1
		move.l		(workbuf+BSS_SIZE,pc),d2
		pea		(bss_msg,pc)
		PUSH		d1-d2
		bsr		fprint_secinfo

		add.l		d2,d1
		move.l		(workbuf+COMMON_SIZE,pc),d2
		pea		(common_msg,pc)
		PUSH		d1-d2
		bsr		fprint_secinfo

		add.l		d2,d1
		move.l		(workbuf+STACK_SIZE,pc),d2
		pea		(stack_msg,pc)
		PUSH		d1-d2
		bsr		fprint_secinfo

		moveq		#0,d1
		move.l		(workbuf+RDATA_SIZE,pc),d2
		pea		(rdata_msg,pc)
		PUSH		d1-d2
		bsr		fprint_secinfo

		add.l		d2,d1
		move.l		(workbuf+RBSS_SIZE,pc),d2
		pea		(rbss_msg,pc)
		PUSH		d1-d2
		bsr		fprint_secinfo

		add.l		d2,d1
		move.l		(workbuf+RCOMMON_SIZE,pc),d2
		pea		(rcommon_msg,pc)
		PUSH		d1-d2
		bsr		fprint_secinfo

		add.l		d2,d1
		move.l		(workbuf+RSTACK_SIZE,pc),d2
		pea		(rstack_msg,pc)
		PUSH		d1-d2
		bsr		fprint_secinfo

		add.l		d2,d1
		move.l		(workbuf+RLDATA_SIZE,pc),d2
		pea		(rldata_msg,pc)
		PUSH		d1-d2
		bsr		fprint_secinfo

		add.l		d2,d1
		move.l		(workbuf+RLBSS_SIZE,pc),d2
		pea		(rlbss_msg,pc)
		PUSH		d1-d2
		bsr		fprint_secinfo

		add.l		d2,d1
		move.l		(workbuf+RLCOMMON_SIZE,pc),d2
		pea		(rlcommon_msg,pc)
		PUSH		d1-d2
		bsr		fprint_secinfo

		add.l		d2,d1
		move.l		(workbuf+RLSTACK_SIZE,pc),d2
		pea		(rlstack_msg,pc)
		PUSH		d1-d2
		bsr		fprint_secinfo

		bsr		fprint_crlf
		bsr		fprint_crlf

		lea		(12*13+4,sp),sp
		tst		d5~ferror
		bne		make_map_err2		* file write error

		movea.l		(workbuf+LINK_LIST_HEAD,pc),a0
make_map_l	move.l		a0,d0
		beq		make_map_end
		move.l		linklist_obj_list,a1
		pea		(a1)
		bsr		fprint_head
		bsr		fprint_xref
		bsr		fprint_xdef
		bsr		fprint_comm
		bsr		fprint_rcomm
		bsr		fprint_rlcomm
		addq.l		#4,sp

		tst.l		linklist_next
		beq		make_map_end

		bsr		fprint_crlf
		bsr		fprint_crlf

		tst		d5~ferror
		bne		make_map_err2		* file write error
		movea.l		linklist_next,a0
		bra		make_map_l

make_map_end:
		bsr		flush_fprint
		tst		d5~ferror
		bne		make_map_err2		* file write error

		move		d7,-(sp)
		DOS		_CLOSE
		addq.l		#2,sp
		tst.l		d0
		bmi		make_map_err2		* file write error
		rts

make_map_err1:	pea		(cant_open_msg,pc)
		bra		make_map_err

make_map_err2:	pea		(device_full_msg,pc)
*		bra		make_map_err

make_map_err:	DOS		_PRINT
		pea		(workbuf+MAP_NAME,pc)
		DOS		_PRINT
		addq.l		#8,sp
		bsr		print_crlf
		lea		(workbuf+EXIT_CODE,pc),a0
		move		#EXIT_FAILURE,(a0)
		rts


* 確保したバッファの先頭アドレスを16バイト境界に合わせる.
* out	d0.l	0:OK -1:error

align16_malloc_buf::
		move.l		a0,-(sp)
		lea		(workbuf,pc),a0
		moveq		#0,d0
		sub.b		(MALLOC_PTR_HEAD+3,a0),d0
		and.b		#$0f,d0
		sub.l		d0,(MALLOC_LEFT,a0)
		bmi		align16_malloc_buf_err

		add.l		d0,(MALLOC_PTR_HEAD,a0)
		moveq		#0,d0
@@:		movea.l		(sp)+,a0
		rts
align16_malloc_buf_err:
		add.l		d0,(MALLOC_LEFT,a0)
		moveq		#-1,d0
		bra		@b


* 書き込みバッファを確保する.
* 足りなければchar temp[TEMP_SIZE]を使用.

malloc_write_buf:
		move.l		a6,-(sp)
		lea		(workbuf,pc),a6
		move.l		(MALLOC_LEFT,a6),d0
		andi.l		#.not.(1024-1),d0
		beq		use_temp

		move.l		(MALLOC_PTR_HEAD,a6),(MAP_BUF_ADR,a6)
		add.l		d0,(MALLOC_PTR_HEAD,a6)
		sub.l		d0,(MALLOC_LEFT,a6)
@@:		move.l		d0,(MAP_BUF_SIZE,a6)
		movea.l		(sp)+,a6
		rts
use_temp:
		pea		(TEMP,a6)
		move.l		(sp)+,(MAP_BUF_ADR,a6)
		move.l		#TEMP_SIZE,d0
		bra		@b


*------------------------------------------------------------------------------
*
*	fprint_execadr
*
*	in:
*		8(a6)		exec_adr
*
*------------------------------------------------------------------------------

fprint_execadr:
		link		a6,#0

		pea		(exec_msg,pc)
		bsr		fprint_label
		move.l		arg1,-(sp)
		bsr		fprint_hex8
		bsr		fprint_crlf
		addq.l		#8,sp

		unlk		a6
		rts

*------------------------------------------------------------------------------
*
*	fprint_head
*
*	in:
*		8(sp)		obj_list
*
*------------------------------------------------------------------------------

		_obj_list_	objlist,a0,0

fprint_head:
		link		a6,#-256
		move.l		a0,-(sp)

		movea.l		arg1,a0			* a0.l = objlist

		pea		(bar,pc)
		bsr		fprint
		pea		(16)			;length
		pea		(a0)
		bsr		fpr_objname
		bsr		fprint_crlf
		pea		(bar,pc)
		bsr		fprint
		lea		(16,sp),sp

		pea		(align_msg,pc)
		bsr		fprint_label
		move.l		objlist_align_size,-(sp)
		bsr		fprint_hex8
		addq.l		#8,sp
		bsr		fprint_crlf

		pea		(text_msg,pc)
		move.l		objlist_text_size,-(sp)
		move.l		objlist_text_pos,-(sp)
		bsr		fprint_secinfo

		pea		(data_msg,pc)
		move.l		objlist_data_size,-(sp)
		move.l		objlist_data_pos,-(sp)
		bsr		fprint_secinfo

		pea		(bss_msg,pc)
		move.l		objlist_bss_size,-(sp)
		move.l		objlist_bss_pos,-(sp)
		bsr		fprint_secinfo

		pea		(stack_msg,pc)
		move.l		objlist_stack_size,-(sp)
		move.l		objlist_stack_pos,-(sp)
		bsr		fprint_secinfo

		move.l		objlist_rdata_size,d0
		beq		fprint_head_b1
		pea		(rdata_msg,pc)
		move.l		d0,-(sp)
		move.l		objlist_rdata_pos,d0
		add.l		#$8000,d0
		move.l		d0,-(sp)
		bsr		fprint_secinfo
		lea		12(sp),sp

fprint_head_b1	move.l		objlist_rbss_size,d0
		beq		fprint_head_b2
		pea		(rbss_msg,pc)
		move.l		d0,-(sp)
		move.l		objlist_rbss_pos,d0
		add.l		#$8000,d0
		move.l		d0,-(sp)
		bsr		fprint_secinfo
		lea		12(sp),sp

fprint_head_b2	move.l		objlist_rstack_size,d0
		beq		fprint_head_b3
		pea		(rstack_msg,pc)
		move.l		d0,-(sp)
		move.l		objlist_rstack_pos,d0
		add.l		#$8000,d0
		move.l		d0,-(sp)
		bsr		fprint_secinfo
		lea		12(sp),sp

fprint_head_b3	move.l		objlist_rldata_size,d0
		beq		fprint_head_b4
		pea		(rldata_msg,pc)
		move.l		d0,-(sp)
		move.l		objlist_rldata_pos,d0
		add.l		#$8000,d0
		move.l		d0,-(sp)
		bsr		fprint_secinfo
		lea		12(sp),sp

fprint_head_b4	move.l		objlist_rlbss_size,d0
		beq		fprint_head_b5
		pea		(rlbss_msg,pc)
		move.l		d0,-(sp)
		move.l		objlist_rlbss_pos,d0
		add.l		#$8000,d0
		move.l		d0,-(sp)
		bsr		fprint_secinfo
		lea		12(sp),sp

fprint_head_b5	move.l		objlist_rlstack_size,d0
		beq		fprint_head_b6
		pea		(rlstack_msg,pc)
		move.l		d0,-(sp)
		move.l		objlist_rlstack_pos,d0
		add.l		#$8000,d0
		move.l		d0,-(sp)
		bsr		fprint_secinfo
		lea		12(sp),sp

fprint_head_b6	lea		12*4(sp),sp

		move.l		(sp)+,a0
		unlk		a6
		rts

*------------------------------------------------------------------------------
*
*	fprint_xref
*
*	in:
*		8(sp)		obj_list
*
*------------------------------------------------------------------------------

		_obj_list_	objlist,a0,0
*		_xref_table_	xreftbl,a1,0
		_xdef_list_	xdeflist,a2,0

fprint_xref:
		link		a6,#0
		PUSH		a0-a2

		movea.l		arg1,a0			* a0.l = objlist

		movea.l		objlist_xref_tbl,a1
		tst.l		(a1)
		beq		fprint_xref_end

		pea		(xref_bar,pc)
		bsr		fprint
		addq.l		#4,sp

fprint_xref_l	tst.l		(a1)+
		beq		fprint_xref_end
		movea.l		(a1)+,a2
		move.l		xdeflist_label_name,-(sp)
		bsr		fprint_label
		pea		(in_msg,pc)
		bsr		fprint

		clr.l		-(sp)
		move.l		xdeflist_obj_list,-(sp)
		bsr		fpr_objname
		bsr		fprint_crlf
		lea		(16,sp),sp
		bra		fprint_xref_l
fprint_xref_end:
		POP		a0-a2
		unlk		a6
		rts

*------------------------------------------------------------------------------
*
*	fprint_xdef
*
*	in:
*		8(sp)		obj_list
*
*------------------------------------------------------------------------------

		_obj_list_	objlist,a0,0
*		_xdef_table_	xdeftbl,a1,0
		_xdef_list_	xdeflist,a2,0

fprint_xdef:
		link		a6,#0
		PUSH		a0-a3

		movea.l		arg1,a0			* a0.l = objlist

		movea.l		objlist_xdef_tbl,a1
		tst.l		(a1)
		beq		fprint_xdef_end

		pea		(xdef_bar,pc)
		bsr		fprint
		addq.l		#4,sp

fprint_xdef_l	tst.l		(a1)+
		beq		fprint_xdef_end
		movea.l		(a1)+,a2
		cmp.w		#$fc,xdeflist_type
		beq		fprint_xdef_l
		cmp.w		#$fd,xdeflist_type
		beq		fprint_xdef_l
		cmp.w		#$fe,xdeflist_type
		beq		fprint_xdef_l

		move.l		xdeflist_label_name,-(sp)
		bsr		fprint_label
		move.w		xdeflist_type,d0
		move.l		xdeflist_value,d1
		cmp.w		#$0004,d0
		bls		fprint_xdef_b10
		add.l		#$8000,d1
fprint_xdef_b10	move.l		d1,-(sp)
		bsr		fprint_hex8
		bsr		fprint_spc
		addq.l		#8,sp

		move		xdeflist_type,d0
		cmpi		#$0a,d0
		bls		@f
		moveq		#0,d0			;一応...
@@:		add		d0,d0
		move		(@f,pc,d0.w),d0
		pea		(@f,pc,d0.w)
		bsr		fprint
		addq.l		#4,sp
		bsr		fprint_crlf
		bra		fprint_xdef_l
@@:
		.dc		abs_msg-@b
		.dc		textsec_msg-@b
		.dc		datasec_msg-@b
		.dc		bsssec_msg-@b
		.dc		stacksec_msg-@b
		.dc		rdatasec_msg-@b
		.dc		rbsssec_msg-@b
		.dc		rstacksec_msg-@b
		.dc		rldatasec_msg-@b
		.dc		rlbsssec_msg-@b
		.dc		rlstacksec_msg-@b

fprint_xdef_end:
		POP		a0-a3
		unlk		a6
		rts

*------------------------------------------------------------------------------
*
*	fprint_comm
*
*	in:
*		8(sp)		obj_list
*
*------------------------------------------------------------------------------

		_obj_list_	objlist,a0,0
*		_xdef_table_	xdeftbl,a1,0
		_xdef_list_	xdeflist,a2,0

fprint_comm:
		link		a6,#0
		PUSH		d1-d2/a0-a2

		movea.l		arg1,a0			* a0.l = objlist

		movea.l		objlist_xdef_tbl,a1
		tst.l		(a1)
		beq		fprint_comm_end

		moveq.l		#0,d1
fprint_comm_l	tst.l		(a1)
		beq		fprint_comm_end
		movea.l		(a1)+,a2
		cmp.w		#$fe,xdeflist_type
		bne		fprint_comm_l

		tst.w		d1
		bne		fprint_comm_b
		pea		(common_bar,pc)
		bsr		fprint
		addq.l		#4,sp
		moveq.l		#-1,d1

fprint_comm_b	move.l		xdeflist_label_name,-(sp)
		move.l		xdeflist_size,-(sp)
		move.l		xdeflist_value,-(sp)
		bsr		fprint_secinfo
		lea		12(sp),sp
		bra		fprint_comm_l
fprint_comm_end:
		POP		d1-d2/a0-a2
		unlk		a6
		rts

*------------------------------------------------------------------------------
*
*	fprint_rcomm
*
*	in:
*		8(sp)		obj_list
*
*------------------------------------------------------------------------------

		_obj_list_	objlist,a0,0
*		_xdef_table_	xdeftbl,a1,0
		_xdef_list_	xdeflist,a2,0

fprint_rcomm:
		link		a6,#0
		PUSH		d1-d2/a0-a2

		movea.l		arg1,a0			* a0.l = objlist

		movea.l		objlist_xdef_tbl,a1
		tst.l		(a1)
		beq		fprint_rcomm_e

		moveq.l		#0,d1
fprint_rcomm_l	tst.l		(a1)
		beq		fprint_rcomm_e
		movea.l		(a1)+,a2
		cmp.w		#$fd,xdeflist_type
		bne		fprint_rcomm_l

		tst.w		d1
		bne		fprint_rcomm_b
		pea		(rcommon_bar,pc)
		bsr		fprint
		addq.l		#4,sp
		moveq.l		#-1,d1

fprint_rcomm_b	move.l		xdeflist_label_name,-(sp)
		move.l		xdeflist_size,-(sp)
		move.l		xdeflist_value,d0
		add.l		#$8000,d0
		move.l		d0,-(sp)
		bsr		fprint_secinfo
		lea		12(sp),sp
		bra		fprint_rcomm_l
fprint_rcomm_e:
		POP		d1-d2/a0-a2
		unlk		a6
		rts

*------------------------------------------------------------------------------
*
*	fprint_rlcomm
*
*	in:
*		8(sp)		obj_list
*
*------------------------------------------------------------------------------

		_obj_list_	objlist,a0,0
*		_xdef_table_	xdeftbl,a1,0
		_xdef_list_	xdeflist,a2,0

fprint_rlcomm:
		link		a6,#0
		PUSH		d1-d2/a0-a2

		movea.l		arg1,a0			* a0.l = objlist

		movea.l		objlist_xdef_tbl,a1
		tst.l		(a1)
		beq		fprint_rlcomm_e

		moveq.l		#0,d1
fprint_rlcomm_l	tst.l		(a1)
		beq		fprint_rlcomm_e
		movea.l		(a1)+,a2
		cmp.w		#$fc,xdeflist_type
		bne		fprint_rlcomm_l

		tst.w		d1
		bne		fprint_rlcomm_b
		pea		(rlcommon_bar,pc)
		bsr		fprint
		addq.l		#4,sp
		moveq.l		#-1,d1

fprint_rlcomm_b	move.l		xdeflist_label_name,-(sp)
		move.l		xdeflist_size,-(sp)
		move.l		xdeflist_value,d0
		add.l		#$8000,d0
		move.l		d0,-(sp)
		bsr		fprint_secinfo
		lea		12(sp),sp
		bra		fprint_rlcomm_l
fprint_rlcomm_e:
		POP		d1-d2/a0-a2
		unlk		a6
		rts

*------------------------------------------------------------------------------
*
*	fprint_secinfo
*
*	in:
*		 8(a6)		pos
*		12(a6)		size
*		16(a6)		name
*
*	output format:
*		name		pos - pos+size (size)
*
*------------------------------------------------------------------------------

fprint_secinfo:
		link		a6,#0

		move.l		arg3,-(sp)
		bsr		fprint_label
		addq.l		#4,sp

		tst.l		arg2
		beq		fpr_secinfo_end

		move.l		arg1,-(sp)
		bsr		fprint_hex8
		pea		(fprint_mes1,pc)	;' - '
		bsr		fprint
		move.l		arg1,d0
		add.l		arg2,d0
		subq.l		#1,d0
		move.l		d0,-(sp)
		bsr		fprint_hex8
		pea		(fprint_mes2,pc)	;' ('
		bsr		fprint
		move.l		arg2,-(sp)
		bsr		fprint_hex8
		pea		(fprint_mes3,pc)	;')'
		bsr		fprint
		lea		(20,sp),sp

fpr_secinfo_end	bsr		fprint_crlf

		unlk		a6
		rts

*------------------------------------------------------------------------------
*
*	fpr_objname
*
*	in:
*		 8(a6)		objlist
*		12(a6)		length
*
*------------------------------------------------------------------------------

		_obj_list_	objlist,a0,0

work		reg		-256(a6)

fpr_objname:
		link		a6,#-256
		PUSH		a0-a2

		movea.l		arg1,a0			* a0.l = objlist
		move.l		arg2,d0			* d0.l = length

		movea.l		objlist_obj_name,a1	* a1.l = obj_name
		lea		work,a2			* a2.l = work
		addq.w		#1,d0
fpr_objname_l1	subq.w		#1,d0
		move.b		(a1)+,(a2)+
		bne		fpr_objname_l1
		subq.l		#1,a2

		tst.l		objlist_lib_name
		beq		fpr_objname_b2

fpr_objname_l2	move.b		#TAB,(a2)+
		subq.w		#8,d0
		bgt		fpr_objname_l2
		clr.b		(a2)

fpr_objname_b2	pea		work
		bsr		fprint
		addq.l		#4,sp
		tst.l		objlist_lib_name
		beq		fpr_objname_end

		pea		(fprint_mes4,pc)
		bsr		fprint
		move.l		objlist_lib_name,(sp)
		bsr		fprint
		pea		(fprint_mes3,pc)
		bsr		fprint
		addq.l		#8,sp
fpr_objname_end:
		POP		a0-a2
		unlk		a6
		rts

*------------------------------------------------------------------------------
*
*	fprint_label
*
*	in:
*		8(sp)		mes
*
*------------------------------------------------------------------------------

work		reg		-256(a6)

fprint_label:
		link		a6,#-256
		PUSH		a0-a1

		movea.l		arg1,a0			* a0.l = mes
		lea		work,a1			* a1.l = work
		move.w		#24+1,d0
fprint_label_l1	subq.w		#1,d0
		move.b		(a0)+,(a1)+
		bne		fprint_label_l1
		subq.l		#1,a1

fprint_label_l2	move.b		#TAB,(a1)+
		subq.w		#8,d0
		bgt		fprint_label_l2

		move.b		#' ',(a1)+
		move.b		#':',(a1)+
		move.b		#' ',(a1)+
		clr.b		(a1)

		pea		work
		bsr		fprint
		addq.l		#4,sp

		POP		a0-a1
		unlk		a6
		rts

*------------------------------------------------------------------------------
*
*	fprint_hex8
*
*	in:
*		8(sp)		num
*
*------------------------------------------------------------------------------

work:		.reg		(-16,a6)

fprint_hex8:
		link		a6,#-16
		PUSH		d1-d2/a0-a1

		lea		work,a0
		lea		(hex_table,pc),a1
		move.l		arg1,d1

		moveq		#8-1,d0
fprint_hex8_l:	rol.l		#4,d1
		moveq		#$f,d2
		and		d1,d2
		move.b		(a1,d2.w),(a0)+
		dbra		d0,fprint_hex8_l
		clr.b		(a0)

		pea		work
		bsr		fprint
		addq.l		#4,sp

		POP		d1-d2/a0-a1
		unlk		a6
		rts


*------------------------------------------------------------------------------
*
*	fprint_spc
*
*------------------------------------------------------------------------------

fprint_spc	pea		(fprint_spc_mes,pc)
		bsr		fprint
		addq.l		#4,sp
		rts

*------------------------------------------------------------------------------
*
*	fprint_crlf
*
*------------------------------------------------------------------------------

fprint_crlf	pea		(fprint_crlf_mes,pc)
		bsr		fprint
		addq.l		#4,sp
		rts

*------------------------------------------------------------------------------
*
*	fprint
*
*	in:
*		8(a6)		mes
*
*------------------------------------------------------------------------------

fprint:
		link		a6,#0
		PUSH		d1/a0

		tst		d5~ferror
		bmi		fprint_end

		move.l		arg1,a0
		move.l		(workbuf+MAP_BUF_SIZE,pc),d1
fprint_l:	move.b		(a0)+,d0
		beq		fprint_end
		move.b		d0,(a4)+
		addq.l		#1,d6
		cmp.l		d6,d1
		bne		fprint_l

		bsr		flush_fprint
		tst		d5~ferror
		beq		fprint_l
fprint_end:
		POP		d1/a0
		unlk		a6
		rts

*------------------------------------------------------------------------------
*
*	flush_fprint
*
*------------------------------------------------------------------------------

flush_fprint:
		movea.l		(workbuf+MAP_BUF_ADR,pc),a4
		move.l		d6,-(sp)
		move.l		a4,-(sp)
		move		d7,-(sp)
		DOS		_WRITE
		addq.l		#10-4,sp
		cmp.l		(sp)+,d0
		beq		flush_fpr_end
		moveq		#-1,d5~ferror
flush_fpr_end:
		moveq		#0,d6
		rts


*------------------------------------------------------------------------------

cant_open_msg:	.dc.b		"Can't open file : ",0

device_full_msg:.dc.b		'Device full : ',0

make_map_mes:	.dc.b		'Making map file...'
fprint_crlf_mes:.dc.b		CRLF,0

bar:		.dc.b		'=========================================================='
		.dc.b		CRLF,0

xref_bar:	.dc.b		'-------------------------- xref --------------------------'
		.dc.b		CRLF,0

xdef_bar:	.dc.b		'-------------------------- xdef --------------------------'
		.dc.b		CRLF,0

common_bar:	.dc.b		'-------------------------- comm --------------------------'
		.dc.b		CRLF,0

rcommon_bar:	.dc.b		'-------------------------- rcomm -------------------------'
		.dc.b		CRLF,0

rlcommon_bar:	.dc.b		'-------------------------- rlcomm ------------------------'
		.dc.b		CRLF,0

align_msg:	.dc.b		'align',0

text_msg:	.dc.b		'text',0

data_msg:	.dc.b		'data',0

bss_msg:	.dc.b		'bss',0

common_msg:	.dc.b		'common',0

stack_msg:	.dc.b		'stack',0

rdata_msg:	.dc.b		'rdata',0

rbss_msg:	.dc.b		'rbss',0

rcommon_msg:	.dc.b		'rcommon',0

rstack_msg:	.dc.b		'rstack',0

rldata_msg:	.dc.b		'rldata',0

rlbss_msg:	.dc.b		'rlbss',0

rlcommon_msg:	.dc.b		'rlcommon',0

rlstack_msg:	.dc.b		'rlstack',0

exec_msg:	.dc.b		'exec',0

abs_msg:	.dc.b		'(abs    )',0

textsec_msg:	.dc.b		'(text   )',0

datasec_msg:	.dc.b		'(data   )',0

bsssec_msg:	.dc.b		'(bss    )',0

stacksec_msg:	.dc.b		'(stack  )',0

rdatasec_msg:	.dc.b		'(rdata  )',0

rbsssec_msg:	.dc.b		'(rbss   )',0

rstacksec_msg:	.dc.b		'(rstack )',0

rldatasec_msg:	.dc.b		'(rldata )',0

rlbsssec_msg:	.dc.b		'(rlbss  )',0

rlstacksec_msg:	.dc.b		'(rlstack)',0

in_msg:		.dc.b		'in ',0

fprint_mes1:	.dc.b		' - ',0

fprint_mes2:	.dc.b		' (',0

fprint_mes3:	.dc.b		')',0

fprint_mes4:	.dc.b		'(',0

fprint_spc_mes:	.dc.b		' ',0

		.even


		.end

* End of File --------------------------------- *
