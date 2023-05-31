		.title		HLK/ev (object.s - object link, init & etc. module)


* Include File -------------------------------- *

		.include	hlk.mac
		.include	doscall.mac


* Fixed Number -------------------------------- *

HASH_SIZE:	.equ		4096		;HASH_SIZE must be 2^n


* Global Symbol ------------------------------- *

		.xdef		get_object
		.xdef		get_object2
		.xdef		regist_object
		.xdef		do_request
		.xdef		search_and_link


		.xref		print_crlf

		.xref		read_file

		.xref		make_xdef_table
		.xref		make_xref_table
		.xref		search_xdef

		.xref		malloc_err

		.xref		align_size


* Text Section -------------------------------- *

		.cpu		68000

		.text
		.even


*------------------------------------------------------------------------------
*
*	get_object2 (form mem)
*
*	in:	d7.l = file size
*		a0.l = object file name
*		a1.l = object file name (full path)
*		a2.l = object_image
*
*	out:	a0.l = obj_list (= 0 ... arc, lib file)
*
*------------------------------------------------------------------------------

get_object2::
		PUSH		d1-d4/d7/a1-a4
		bra		get_object2_ent


*------------------------------------------------------------------------------
*
*	get_object
*
*	in:	a0.l = file_name
*
*	out:	d0.l = status
*			-2 ... error (not obj, arc file)
*			-1 ... error (not found)
*			 0 ... ok
*			 1 ... already read
*		a0.l = obj_list (= 0 ... arc, lib file)
*
*------------------------------------------------------------------------------

get_object::
		PUSH		d1-d4/d7/a1-a4

		bsr		read_file
		tst.l		d0
		bne		get_obj_error

get_object2_ent:
							* a2.l = object_image
		cmpi		#$d100,(a2)
		beq		get_obj_b1		* is arc
		cmpi		#$0068,(a2)
		beq		get_obj_b10		* is lib

		moveq		#0,d1			* obj file
		moveq		#0,d2			* no label_info
		moveq		#0,d3			* label_info_size
		bsr		make_obj_list
							* d0.l = obj_list

		movea.l		a2,a0			* a0.l = obj image
		movea.l		d0,a1			* a1.l = obj_list
		bsr		make_xdef_table
		movea.l		a1,a0			* a0.l = obj_list
		bra		get_obj_b21

get_obj_b1	move.l		a0,d1			* arc file
		moveq		#0,d2			* no label_info
		moveq		#0,d3			* label_info_size
		lea		(6,a2),a4		* a4.l = obj info (arc)
get_obj_l1	tst		(a4)
		beq		get_obj_b20

		move.l		a1,-(sp)		* save arc_name
		move.l		($18,a4),d7		* d7.l = obj_file_size
		movea.l		a4,a0			* a0.l = obj_file_name
		lea		($20,a4),a2		* a2.l = obj_file_image
		bsr		make_obj_list
							* d0.l = obj_list

		movea.l		a2,a0			* a0.l = obj_image
		movea.l		d0,a1			* a1.l = obj_list
		bsr		make_xdef_table
		movea.l		(sp)+,a1
		lea		($20,a4,d7.l),a4
		bra		get_obj_l1

get_obj_b10	move.l		a0,d1			* arc file
		moveq.l		#0,d2			* no label_info
		moveq.l		#0,d3			* label_info_size
		movea.l		a2,a3			* a3.l = lib_image
		lea		($40,a3),a4		* a4.l = obj_info
		move.l		($24,a3),d4		* d4.l = obj_info_size
		beq		get_obj_b20		* no obj_info
get_obj_l10	move.l		a1,-(sp)		* save lib_name
		move.l		($20,a4),d7		* d7.l = obj_file_size
		movea.l		a4,a0			* a0.l = obj_file_name
		move.l		($1c,a4),a2
		add.l		a3,a2			* a2.l = obj_file_image
		bsr		make_obj_list
							* d0.l = obj_list

		movea.l		a2,a0			* a0.l = obj_image
		movea.l		d0,a1			* a1.l = obj_list
		bsr		make_xdef_table
		movea.l		(sp)+,a1
		lea		($30,a4),a4
		sub.l		#$30,d4
		bne		get_obj_l10

get_obj_b20	suba.l		a0,a0			* (= clr.l	a0 )

get_obj_b21	moveq.l		#0,d0
get_obj_end	POP		d1-d4/d7/a1-a4
		rts
get_obj_error:
		bpl		get_obj_end		;already read

* エラーメッセージは read_file で表示されている.
		move		#1,(EXIT_CODE,a6)
		bra		get_obj_end		;error


*------------------------------------------------------------------------------
*
*	make_obj_list
*
*	in:	d1.l = lib_name
*		d2.l = label_info
*		d3.l = label_info_s
*		d7.l = file_size
*		a0.l = obj_name
*		a1.l = file_name (full path)
*		a2.l = object_file image
*
*	out:	d0.l = obj_list
*
*	make obj_list
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a5,0

make_obj_list:
		PUSH		d1-d5/a0-a6

		moveq.l		#0,d4			* d4.l = 0
		move.l		#__obj_list__,d5	* d5.l = malloc size

		lea		(workbuf+MALLOC_PTR_HEAD,pc),a3	;a3.l = malloc_ptr_head
		lea		(workbuf+MALLOC_LEFT,pc),a4	;a4.l = malloc_left

		sub.l		d5,(a4)			* a4.l = malloc_left
		bmi		malloc_err
		movea.l		(a3),a5			* a5.l = obj_list
		add.l		d5,(a3)			* forward malloc_ptr_head

		lea		(workbuf+OBJ_LIST_WP,pc),a3
							;a3.l = obj_list_wp
		movea.l		(a3),a6			;a6.l = obj_list_next
		move.l		a5,(a6)
		lea		obj_list_next,a6	* a6.l = obj_list_next (new)
		move.l		a6,(a3)			*  (obj_list_wp)  = obj_list_next
		move.l		d4,(a6)			* (obj_list_next) = 0

		move.l		a1,obj_list_full_path
		move.l		d1,obj_list_lib_name
		move.l		a0,obj_list_obj_name
		move.l		d7,obj_list_obj_size
		move.l		d4,obj_list_scdinfo	* 取敢えず初期化
		move.l		d4,obj_list_scdinfo_s	*
		move.l		d2,obj_list_labelinfo
		move.l		d3,obj_list_labelinfo_s
		move.l		a2,obj_list_obj_image
		move.w		d4,obj_list_link_flag
		move.l		d4,obj_list_text_size	* 取敢えず初期化
		move.l		d4,obj_list_data_size	*
		move.l		d4,obj_list_bss_size	*
		move.l		d4,obj_list_stack_size	*
		move.l		d4,obj_list_rdata_size	*
		move.l		d4,obj_list_rbss_size	*
		move.l		d4,obj_list_rstack_size	*
		move.l		d4,obj_list_rldata_size	*
		move.l		d4,obj_list_rlbss_size	*
		move.l		d4,obj_list_rlstack_size *
		move.l		d4,obj_list_req_list
		move.l		d4,obj_list_xdef_tbl
		move.l		d4,obj_list_xref_tbl
		move.l		d4,obj_list_xref_begin
		move.l		d4,obj_list_xref_end	*
		move.l		(align_size,pc),obj_list_align_size

		move.l		d4,obj_list_xdef_fc
		move.l		d4,obj_list_xdef_00
		move.l		d4,obj_list_xdef_04
		move.l		d4,obj_list_xdef_08

*		move.b		d4,obj_list_doctor_flag
*		move.b		d4,obj_list_dodtor_flag
		move		d4,obj_list_doctor_flag
		move.l		d4,obj_list_ctor_size
		move.l		d4,obj_list_dtor_size

		move.l		a5,d0			* d0.l = obj_list
		POP		d1-d5/a0-a6
		rts


* obj_list_xdef_fc～0aは、そのセクションにシンボル定義があるか、または
* サイズが 0 以外である事を表すフラグです. フラグが立っていれば「中身」
* のあるセクションで、そうでなければ本当に空のセクションです.
* 空のセクションはリンク時に先頭アドレスのアラインを補正する必要はありません.


*------------------------------------------------------------------------------
*
*	regist_object
*
*	in:	a0.l = obj_list
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a0,0
		_link_list_	link_list,a3,0

regist_object::
		PUSH		d1-d2/a1-a3/a6
		lea		(workbuf,pc),a6
		tst.b		(VERBOSE_FLAG,a6)
		beq		@f

		pea		(reg_obj_msg,pc)
		DOS		_PRINT
		pea		(24-9)			;length
		pea		(a0)
		bsr		print_objname
		bsr		print_crlf
		lea		(12,sp),sp
@@:
		move.l		#__link_list__,d1
		sub.l		d1,(MALLOC_LEFT,a6)
		bmi		malloc_err
		movea.l		(MALLOC_PTR_HEAD,a6),a3		;a3.l = link_list
		add.l		d1,(MALLOC_PTR_HEAD,a6)		;forward malloc_ptr_head

		move		#-1,obj_list_link_flag

*		move.b		obj_list_doctor_flag,d0
*		or.b		d0,(DO_CTOR_FLAG,a6)
*		move.b		obj_list_dodtor_flag,d0
*		or.b		d0,(DO_DTOR_FLAG,a6)
		move		obj_list_doctor_flag,d0
		or		d0,(DO_CTOR_FLAG,a6)

		movea.l		(LINK_LIST_WP,a6),a2
		move.l		a3,(a2)
		move.l		a0,link_list_obj_list
		lea		link_list_next,a3
		clr.l		(a3)
		move.l		a3,(LINK_LIST_WP,a6)

* ここでオブジェクトサイズを補正する必要はない.
* また、オブジェクトの直前の補正量はリンクの直前まで(正確には全ての
* オブジェクトが読み込まれるまで)分らないので、この時点では各セクション
* のサイズを計算できないし、しなくてよい.

		POP		d1-d2/a1-a3/a6
		rts

*------------------------------------------------------------------------------
*
*	do_request
*
*	in:	a0.l = obj_list
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a0,0
		_req_list_	req_list,a1,0

do_request::
		PUSH		a0-a1

		move.l		obj_list_req_list,d0
		beq		do_req_end
do_req_l:
		movea.l		d0,a1
		movea.l		req_list_name,a0
		addq.l		#2,a0			* a0.l = request file
		bsr		get_object
		tst.l		d0
		bne		do_req_b		* failed get object
		move.l		a0,d0
		beq		do_req_b		* is arc, lib file
		bsr		regist_object

do_req_b:	move.l		req_list_next,d0
		bne		do_req_l

do_req_end:	POP		a0-a1
		rts

*------------------------------------------------------------------------------
*
*	search_and_link
*
*	in:	a0.l = obj_list
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a0,0
		_xdef_list_	xdef_list,a0,0

search_and_link::
		PUSH		a0-a1

		bsr		make_xref_table

		movea.l		obj_list_xref_tbl,a1	* a1.l = xref_table
		move.l		(a1)+,d0
		beq		search_link_end
search_link_l:
		move.l		d0,a0
		addq.l		#6,a0
		bsr		search_xdef
		move.l		d0,(a1)+
		beq		search_link_next

		movea.l		d0,a0			* a0.l = xdef_list
		movea.l		xdef_list_obj_list,a0	* a0.l = obj_list
		tst		obj_list_link_flag
		bne		search_link_next	* already linked

		bsr		regist_object

		tst.l		obj_list_lib_name
		beq		search_link_next	* obj file
		tst.l		obj_list_req_list
		beq		search_link_next	* no request

		pea		(req_err,pc)
		DOS		_PRINT
		clr.l		-(sp)			;length
		pea		(a0)
		bsr		print_objname
		bsr		print_crlf
		lea		(12,sp),sp
search_link_next:
		move.l		(a1)+,d0
		bne		search_link_l
search_link_end:
		POP		a0-a1
		rts

*------------------------------------------------------------------------------
*
*	print_objname
*
*	in:
*		 8(a6)		objlist
*		12(a6)		length
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a0,0

print_objname:
		link		a6,#0
		PUSH		d1-d2/a0-a1

		movea.l		arg1,a0			* a0.l = obj_list
		move.l		arg2,d1			* d1.l = length

		movea.l		obj_list_obj_name,a1	* a1.l = obj_name
		move.l		obj_list_lib_name,d2	* d2.l = lib_name

		pea		(a1)
		DOS		_PRINT
		move.l		d2,(sp)+
		beq		pr_objname_end

		addq		#1,d1
pr_objname_l1:	subq		#1,d1
		tst.b		(a1)+
		bne		pr_objname_l1

pr_objname_l2:	move		#TAB,-(sp)
		DOS		_PUTCHAR
		addq.l		#2,sp
		subq		#8,d1
		bgt		pr_objname_l2

		move		#'(',-(sp)
		DOS		_PUTCHAR
		move.l		d2,-(sp)
		DOS		_PRINT
		move		#')',-(sp)
		DOS		_PUTCHAR
		addq.l		#8,sp

pr_objname_end:	POP		d1-d2/a0-a1
		unlk		a6
		rts

*------------------------------------------------------------------------------

reg_obj_msg:	.dc.b		'リンク: '
		.dc.b		0

req_err:	.dc.b		'リクエストエラー: '
		.dc.b		0
		.even


		.end

* End of File --------------------------------- *
