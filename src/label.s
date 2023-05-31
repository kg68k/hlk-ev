		.title		HLK/ev (label.s - label control module)


* Include File -------------------------------- *

		.include	hlk.mac
		.include	doscall.mac


* Fixed Number -------------------------------- *

HASH_SIZE:	.equ		4096		;HASH_SIZE must be 2^n


* Global Symbol ------------------------------- *

		.xdef		init_hash
		.xdef		make_xdef_table
		.xdef		make_xref_table
		.xdef		activate_xdef
		.xdef		search_xdef
		.xdef		set_xdef_value
		.xdef		set_xref_value

		.xref		skip_com
		.xref		skip_string

		.xref		print_hex8
		.xref		print_spc
		.xref		print_crlf

		.xref		align_size

		.xref		program_err
		.xref		malloc_err
		.xref		unknown_cmd


* Text Section -------------------------------- *

		.cpu		68000

		.text
		.even

*------------------------------------------------------------------------------
*
*	init_hash
*
*------------------------------------------------------------------------------

init_hash:
		move.l		a0,-(sp)

		pea		(HASH_SIZE*4)
		DOS		_MALLOC
		move.l		d0,(sp)+
		bmi		malloc_err

		lea		(workbuf+HASH_TABLE,pc),a0
		move.l		d0,(a0)
		movea.l		d0,a0			;a0.l = hash_table
		move		#HASH_SIZE-1,d0
		moveq		#0,d1
init_hash_l:	move.l		d1,(a0)+
		dbra		d0,init_hash_l

		movea.l		(sp)+,a0
		rts


*------------------------------------------------------------------------------
*
*	make_xdef_table
*
*	in:	a0.l = object_file image
*		a1.l = obj_list
*
*	make requrst_list and xdef_table form obj_file image
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a1,0
		_req_list_	req_list,a4,0
		_xdef_table_	xdef_table,a5,0

make_xdef_table:
		PUSH		d1-d3/a0-a6

		moveq.l		#0,d2			;d2.l = 0
		lea		(workbuf+MALLOC_PTR_HEAD,pc),a2	;a2.l = malloc_ptr_head
		lea		(workbuf+MALLOC_LEFT,PC),a3	;a3.l = malloc_left

		lea		obj_list_req_list,a4	* a4.l = obj_list_req_list

		subq.l		#4,(a3)			* a3.l = malloc_left
		bmi		malloc_err
		movea.l		(a2),a5			* a5.l = xdef_table
		addq.l		#4,(a2)			* forward malloc_ptr_head

		move.l		a5,obj_list_xdef_tbl
		move.l		d2,(a5)			* clear xdef_table
		bra		make_xdef_l

make_xdef_l_ss:
		bsr		skip_string
make_xdef_l:
		move		(a0),d1
		beq		make_xdef_end

		cmpi		#$b2ff,d1
		beq		reference_label
		cmpi		#$b0ff,d1
		beq		reference_label

		cmpi		#$b2fc,d1
		bcs		@f
		cmpi		#$b2fe,d1
*		bls		reference_label		;common領域は参照ではなく定義
		bls		define_label_comm	;$b2_fc ～ $b2_fe
@@:
		cmpi		#$b200,d1
		bcs		@f
		cmpi		#$b20a,d1
		bls		define_label		;$b2_00 ～ $b2_0a
@@:
		cmpi		#$c001,d1
		bcs		@f
		beq		obj_head_c001
		cmpi		#$c003,d1
		bcs		obj_head_c002
		beq		obj_head_c003
		cmpi		#$c005,d1
		bcs		obj_head_c004
		beq		obj_head_c005
		cmpi		#$c007,d1
		bcs		obj_head_c006
		beq		obj_head_c007
		cmpi		#$c009,d1
		bcs		obj_head_c008
		beq		obj_head_c009
		cmpi		#$c00b,d1
		bcs		obj_head_c00a
		beq		@f			;$c0_0b
		cmpi		#$c00d,d1
		bcs		obj_head_c00c
		beq		obj_head_c00d
@@:
		cmpi		#$e001,d1
		beq		req_obj_e001
		cmpi		#$e00c,d1
		beq		req_obj_e00c
		cmpi		#$e00d,d1
		beq		req_obj_e00d

		move		d1,d0
		bsr		skip_com
		tst.l		d0
		bpl		make_xdef_l
*make_xdef_err:						* a0.l = unknown command
		bra		unknown_cmd		* a1.l = obj_list

make_xdef_end:	POP		d1-d3/a0-a6
		rts


reference_label:
		lea		obj_list_xref_begin,a6
		tst.l		(a6)
		bne		ref_label_b
		move.l		a0,(a6)

ref_label_b:	move.l		a0,obj_list_xref_end

		addq.l		#6,a0
		bra		make_xdef_l_ss


define_label_comm:
		lea		obj_list_xref_begin,a6	* def & ref
		tst.l		(a6)
		bne		def_label_b2
		move.l		a0,(a6)

def_label_b2:	move.l		a0,obj_list_xref_end

define_label:
		cmp.b		#'*',(6,a0)
		beq		set_align_size

* 「このセクションには外部定義が存在する」事を示すフラグを立てる.

		lea		obj_list_xdef_00,a6
		move		d1,d0
		ext		d0			;$fffc～$000a
		st		(a6,d0.w)

		exg		a0,a1			;a1.l = xdef_data
		bsr		regist_xdef		;a0.l = obj_list
		exg		a0,a1

		move.l		#__xdef_table__,d3
		sub.l		d3,(a3)			;a3.l = malloc_left
		bmi		malloc_err
		add.l		d3,(a2)			;forward malloc_ptr_head

		move.l		a0,(a5)+		;xdef_data
		move.l		d0,(a5)+		;xdef_list
		move.l		d2,(a5)			;clear

		addq.l		#6,a0
		bra		make_xdef_l_ss

	* 外部定義シンボル名の先頭文字が '*' ならば align 値

set_align_size:
		move.l		(2,a0),d0		;d0.l = align size
		moveq		#1,d1
		lsl.l		d0,d1
		move.l		d1,obj_list_align_size

		subq.l		#ALIGN_MIN,d1
		cmpi.l		#ALIGN_MAX,d1
		bhi		set_align_err		;illegal align size
set_al_sz_end:
		addq.l		#6,a0
		bra		make_xdef_l_ss


set_align_err:
		pea		(illegal_align_msg,pc)
		DOS		_PRINT
		addq.l		#4,sp
		move.l		obj_list_align_size,d0
		bsr		print_hex8
		bsr		print_crlf

		pea		(dup_err_in,pc)
		DOS		_PRINT
		move.l		obj_list_obj_name,-(sp)
		DOS		_PRINT
		addq.l		#8,sp

		move.l		obj_list_lib_name,d1
		beq		set_al_err_end
		pea		(dup_err_in,pc)
		DOS		_PRINT
		move.l		d1,-(sp)
		DOS		_PRINT
		addq.l		#8,sp

set_al_err_end:	bsr		print_crlf

		move.l		(align_size,pc),obj_list_align_size
		bra		set_al_sz_end


* セクションサイズが 0 でないなら、空ではないというフラグを立てる.
* ただし、相対セクションの$c0_xxコマンドが含まれない時もあるので
* 初期化はあらかじめしておかなければならない.
* $c0_xxは$b2_xxより先にあるので、クリアする分には問題ない.

obj_head_c001:
		addq.l		#2,a0
		move.l		(a0)+,d0
		addq.l		#1,d0
		andi		#$fffe,d0
		move.l		d0,obj_list_text_size
		sne		obj_list_xdef_01
		bra		make_xdef_l_ss

obj_head_c002:
		addq.l		#2,a0
		move.l		(a0)+,d0
		addq.l		#1,d0
		andi		#$fffe,d0
		move.l		d0,obj_list_data_size
		sne		obj_list_xdef_02
		bra		make_xdef_l_ss

obj_head_c003:
		addq.l		#2,a0
		move.l		(a0)+,d0
		addq.l		#1,d0
		andi		#$fffe,d0
		move.l		d0,obj_list_bss_size
		sne		obj_list_xdef_03
		bra		make_xdef_l_ss

obj_head_c004:
		addq.l		#2,a0
		move.l		(a0)+,d0
		addq.l		#1,d0
		andi		#$fffe,d0
		move.l		d0,obj_list_stack_size
		sne		obj_list_xdef_04
		bra		make_xdef_l_ss

obj_head_c005:							* SXhas
		addq.l		#2,a0
		move.l		(a0)+,d0
		addq.l		#1,d0
		andi		#$fffe,d0
		move.l		d0,obj_list_rdata_size
		sne		obj_list_xdef_05
		bra		make_xdef_l_ss

obj_head_c006:							* SXhas
		addq.l		#2,a0
		move.l		(a0)+,d0
		addq.l		#1,d0
		andi		#$fffe,d0
		move.l		d0,obj_list_rbss_size
		sne		obj_list_xdef_06
		bra		make_xdef_l_ss

obj_head_c007:							* SXhas
		addq.l		#2,a0
		move.l		(a0)+,d0
		addq.l		#1,d0
		andi		#$fffe,d0
		move.l		d0,obj_list_rstack_size
		sne		obj_list_xdef_07
		bra		make_xdef_l_ss

obj_head_c008:							* SXhas
		addq.l		#2,a0
		move.l		(a0)+,d0
		addq.l		#1,d0
		andi		#$fffe,d0
		move.l		d0,obj_list_rldata_size
		sne		obj_list_xdef_08
		bra		make_xdef_l_ss

obj_head_c009:							* SXhas
		addq.l		#2,a0
		move.l		(a0)+,d0
		addq.l		#1,d0
		andi		#$fffe,d0
		move.l		d0,obj_list_rlbss_size
		sne		obj_list_xdef_09
		bra		make_xdef_l_ss

obj_head_c00a:							* SXhas
		addq.l		#2,a0
		move.l		(a0)+,d0
		addq.l		#1,d0
		andi		#$fffe,d0
		move.l		d0,obj_list_rlstack_size
		sne		obj_list_xdef_0a
		bra		make_xdef_l_ss


obj_head_c00c:
		addq.l		#2,a0
		move.l		(a0)+,obj_list_ctor_size
		bra		make_xdef_l_ss
obj_head_c00d:
		addq.l		#2,a0
		move.l		(a0)+,obj_list_dtor_size
		bra		make_xdef_l_ss

req_obj_e00c:
		addq.l		#2,a0
		st		obj_list_doctor_flag
		bra		make_xdef_l

req_obj_e00d:
		addq.l		#2,a0
		st		obj_list_dodtor_flag
		bra		make_xdef_l


req_obj_e001:
		lea		(workbuf+MALLOC_PTR_TAIL,pc),a2
		move.l		#__req_list__,d3
		sub.l		d3,(a3)			* a3.l = malloc_left
		bmi		malloc_err
		sub.l		d3,(a2)			* backward malloc_ptr_tail
		move.l		(a2),d0			* a2.l = malloc_ptr_tail
		move.l		d0,(a4)			* a4.l = req_list link pointer
		lea		(workbuf+MALLOC_PTR_HEAD,pc),a2

		movea.l		d0,a4
		move.l		a0,req_list_name
		lea		req_list_next,a4
		move.l		d2,(a4)			* clear

		addq.l		#2,a0
		bra		make_xdef_l_ss

*------------------------------------------------------------------------------
*
*	make_xref_table
*
*	in:	a0.l = obj_list
*
*	make xref_table from obj_list
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a1,0
		_xref_table_	xref_tbl,a4,0

make_xref_table:
		PUSH		d1-d3/a0-a4

		moveq.l		#0,d2
		moveq.l		#4,d3
		movea.l		a0,a1				;a1.l = obj_list
		lea		(workbuf+MALLOC_PTR_HEAD,pc),a2	;a2.l = malloc_ptr_head
		lea		(workbuf+MALLOC_LEFT,pc),a3	;a3.l = malloc_left

		sub.l		d3,(a3)			* a3.l = malloc_left
		bmi		malloc_err
		movea.l		(a2),a4			* a4.l = xref_table
		add.l		d3,(a2)			* forward malloc_ptr_head

		move.l		a4,obj_list_xref_tbl
		move.l		d2,(a4)

		move.l		#__xref_table__,d3
		move.l		obj_list_xref_begin,d0
		beq		make_xref_end
		movea.l		d0,a0			* a0.l = obj_image
make_xref_l	cmp.l		obj_list_xref_end,a0
		bhi		make_xref_end

		move.w		(a0),d1

		cmpi		#$b2fc,d1		* SXhas
		beq		regist_xref
		cmpi		#$b2fd,d1		* SXhas
		beq		regist_xref
		cmpi		#$b2fe,d1
		beq		regist_xref
		cmpi		#$b2ff,d1
		beq		regist_xref
		cmpi		#$b0ff,d1
		beq		regist_xref

		move		d1,d0
		bsr		skip_com
		tst.l		d0
		bpl		make_xref_l
*make_xref_err:						;a0.l = unknown command
		bra		unknown_cmd		;a1.l = obj_list


make_xref_end:	POP		d1-d3/a0-a4
		rts


regist_xref:
		sub.l		d3,(a3)			* a3.l = malloc_left
		bmi		malloc_err
		add.l		d3,(a2)			* forward malloc_head_ptr

		move.l		a0,(a4)+		* xref_data
		move.l		d2,(a4)+		* xdef_list
		move.l		d2,(a4)

		addq.l		#6,a0
		bsr		skip_string
		bra		make_xref_l

*------------------------------------------------------------------------------
*
*	activate_xdef
*
*	in:	a0.l = obj_list
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a0,0
		_xdef_table_	xdef_tbl,a1,0
		_xdef_list_	xdef_list,a3,0
		_err_list_	err_list,a0,0
		_err_list_	err_list2,a5,0

activate_xdef:
		PUSH		d1-d2/a0-a5
		lea		(workbuf,pc),a4		;a4.l = work buffer

		movea.l		obj_list_xdef_tbl,a1	* a1.l = xdef_tbl
act_xdef_l1:	move.l		(a1)+,d0
		beq		act_xdef_end
		movea.l		d0,a2			* a2.l = xdef_data
		move.l		(a1)+,a3		* a3.l = xdef_list

		move.l		xdef_list_err_list,d0
		bne		act_xdef_b400		* error xdef label

		move		xdef_list_type,d0
		cmp.l		xdef_list_obj_list,a0
		bne		act_xdef_b200		* not label owner
		cmpi		#$fe,d0			* common ?
		bne		act_xdef_b101
		move.l		xdef_list_size,d0
		add.l		d0,(COMMON_SIZE,a4)	;add common area
		st		xdef_list_stat
		bra		act_xdef_l1

act_xdef_b101	cmpi		#$fd,d0			* rcommon ?
		bne		act_xdef_b102
		move.l		xdef_list_size,d0
		add.l		d0,(RCOMMON_SIZE,a4)	;add rcommon area
		st		xdef_list_stat
		bra		act_xdef_l1

act_xdef_b102	cmpi		#$fc,d0			* rlcommon ?
		bne		act_xdef_l1		* not comm label
		move.l		xdef_list_size,d0
		add.l		d0,(RLCOMMON_SIZE,a4)	;add rlcommon area
		st		xdef_list_stat
		bra		act_xdef_l1


							* not label owner
act_xdef_b200	cmpi		#$fe,d0
		bne		act_xdef_b220		* not comm label
		cmp.b		(1,a2),d0
		bne		act_xdef_b210		* not comm label
		move.l		(2,a2),d0
		move.l		xdef_list_size,d1
		cmp.l		d1,d0			* compare comm size
		bls		act_xdef_l1		* >=
		move.l		d0,xdef_list_size
		sub.l		d1,d0
		add.l		d0,(COMMON_SIZE,a4)	;add common area
		bra		act_xdef_l1

act_xdef_b210	move		(a2),d0
		cmpi.b		#$fd,d0
		beq		act_xdef_b400		* not comm label (error!!)
		cmpi.b		#$fc,d0
		beq		act_xdef_b400		* not comm label (error!!)

		tst		xdef_list_stat
		beq		act_xdef_b251
		move.l		xdef_list_size,d0
		sub.l		d0,(COMMON_SIZE,a4)	;delete common area
		bra		act_xdef_b251

act_xdef_b220	cmpi		#$fd,d0
		bne		act_xdef_b240		* not rcomm label
		cmp.b		(1,a2),d0
		bne		act_xdef_b230		* not rcomm label
		move.l		(2,a2),d0
		move.l		xdef_list_size,d1
		cmp.l		d1,d0			* compare rcomm size
		bls		act_xdef_l1		* >=
		move.l		d0,xdef_list_size
		sub.l		d1,d0
		add.l		d0,(RCOMMON_SIZE,a4)	;add rcommon area
		bra		act_xdef_l1

act_xdef_b230	move		(a2),d0
		cmpi.b		#$fe,d0
		beq		act_xdef_b400		* not rcomm label (error!!)
		cmpi.b		#$fc,d0
		beq		act_xdef_b400		* not rcomm label (error!!)

		tst		xdef_list_stat
		beq		act_xdef_b251
		move.l		xdef_list_size,d0
		sub.l		d0,(RCOMMON_SIZE,a4)	;delete rcommon area
		bra		act_xdef_b251

act_xdef_b240	cmpi		#$fd,d0
		bne		act_xdef_b300		* not comm, rcomm, rlcomm label
		cmp.b		(1,a2),d0
		bne		act_xdef_b250		* not rlcomm label
		move.l		(2,a2),d0
		move.l		xdef_list_size,d1
		cmp.l		d1,d0			* compare rlcomm size
		bls		act_xdef_l1		* >=
		move.l		d0,xdef_list_size
		sub.l		d1,d0
		add.l		d0,(RLCOMMON_SIZE,a4)	;add rlcommon area
		bra		act_xdef_l1

act_xdef_b250	move		(a2),d0
		cmpi.b		#$fd,d0
		beq		act_xdef_b400		* not rlcomm label (error!!)
		cmpi.b		#$fc,d0
		beq		act_xdef_b400		* not rlcomm label (error!!)

		tst		xdef_list_stat
		beq		act_xdef_b251
		move.l		xdef_list_size,d0
		sub.l		d0,(RLCOMMON_SIZE,a4)	;delete rlcommon area

act_xdef_b251
		moveq.l		#0,d0			* d0.l = 0
		move		d0,d1
		move.b		(1,a2),d1		* d1.w = label type
		move.l		(2,a2),d2		* d2.l = value or size

		move.l		a0,xdef_list_obj_list	* obj_list
		move		d1,xdef_list_type	* type
		move.l		d2,xdef_list_value	* value
		move.l		d0,xdef_list_size	* size
act_xdef_b301:
		move		#1,xdef_list_stat	* warning!!
		bra		act_xdef_l1

act_xdef_b300:
* 同じ値の定数同士ならエラーにしない.
		tst		d0
		bne		@f
		tst.b		(1,a2)
		bne		@f
		move.l		xdef_list_value,d0
		cmp.l		(2,a2),d0
		beq		act_xdef_l1
@@:
		move		(a2),d0
		cmpi.b		#$fe,d0
		beq		act_xdef_b301
		cmpi.b		#$fd,d0
		beq		act_xdef_b301
		cmpi.b		#$fc,d0
		beq		act_xdef_b301
							* not comm, rcomm, rlcomm label
							* (error!!)
act_xdef_b400	PUSH		a0-a1
		lea		(workbuf+MALLOC_PTR_HEAD,pc),a0	;a0.l = malloc_ptr_head
		lea		(workbuf+MALLOC_LEFT,pc),a1	;a1.l = malloc_left
		move.l		#__err_list__,d0

		sub.l		d0,(a1)			* a1.l = malloc_left
		bmi		malloc_err
		movea.l		(a0),a5			* a5.l = err_list2
		add.l		d0,(a0)			* forward malloc_ptr_head

		lea		xdef_list_err_list,a0	* a0.l = err_list
act_xdef_l400	move.l		(a0),d0
		beq		act_xdef_b401
		movea.l		d0,a0
		lea		err_list_next,a0
		bra		act_xdef_l400

act_xdef_b401	move.l		a5,(a0)
		POP		a0-a1

		move.l		a0,err_list2_obj_list
		clr.l		err_list2_next
		bra		act_xdef_l1

act_xdef_end	POP		d1-d2/a0-a5
		rts

*------------------------------------------------------------------------------
*
*	regist_xdef
*
*	in:	a0.l	obj_table	pointer of obj_table
*		a1.l	xdef_data	pointer of xdef_command
*
*	out:	d0.l	pointer of xdef_list
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a0,0
		_obj_list_	obj_list2,a4,0
		_xdef_list_	list,a2,0

regist_xdef:
		PUSH		d1-d2/a0-a5

		moveq		#0,d0
		lea		(6,a1),a2		* a2.l = label name
		lea		(hash_key,pc),a3	* a3.l = hash key
regist_xdef_l1	moveq.l		#0,d1
		move.b		(a2)+,d1
		beq		regist_xdef_b1
		rol		#3,d0
		add		d1,d1
		add		(a3,d1.w),d0
		bra		regist_xdef_l1

regist_xdef_b1	andi		#HASH_SIZE-1,d0		* d0.l = hash value
		asl.l		#2,d0
		movea.l		(workbuf+HASH_TABLE,pc),a2
		adda.l		d0,a2
regist_xdef_l2	move.l		(a2),d0
		beq		regist_xdef_b10		* regist xdef
		exg		d0,a2

		lea		(6,a1),a3		* label name
		movea.l		list_label_name,a4	* xdef label name
regist_xdef_l3	move.b		(a3)+,d1
		beq		regist_xdef_b2
		cmp.b		(a4)+,d1
		beq		regist_xdef_l3
		bra		regist_xdef_b3
regist_xdef_b2	tst.b		(a4)
		beq		regist_xdef_b30		* match !!

regist_xdef_b3	lea		list_next,a2
		bra		regist_xdef_l2

regist_xdef_b10	move.l		#__xdef_list__,d0	* regist xdef label
		lea		(workbuf+MALLOC_PTR_TAIL,pc),a4
		lea		(workbuf+MALLOC_LEFT,pc),a5

		sub.l		d0,(a5)			* a5.l = malloc_left
		bmi		malloc_err
		sub.l		d0,(a4)			* backward malloc_ptr_tail
		movea.l		(a4),a3			* a4.l = malloc_ptr_tail

		move.l		a3,(a2)			* link xdef_list

regist_xdef_b20	moveq.l		#0,d0			* d0.l = 0
		move		d0,d1
		move.b		(1,a1),d1		* d1.w = label type
		move.l		(2,a1),d2		* d2.l = value or size
		lea		(6,a1),a4		* a4.l = label name

		move.l		a0,(a3)+		* obj_table
		move.l		a4,(a3)+		* label_name
		move		d0,(a3)+		* stat
		move		d1,(a3)+		* type
		cmpi		#$fe,d1			* comm ??
		beq		regist_xdef_b21
		cmpi		#$fd,d1			* rcomm ??
		beq		regist_xdef_b21
		cmpi		#$fc,d1			* rlcomm ??
		beq		regist_xdef_b21
		move.l		d2,(a3)+		* value
		move.l		d0,(a3)+		* size
		bra		regist_xdef_b22
regist_xdef_b21	addq.l		#1,d2
		andi		#$fffe,d2
		move.l		d0,(a3)+		* value
		move.l		d2,(a3)+		* size

regist_xdef_b22	move.l		d0,(a3)+		* err_list
		move.l		d0,(a3)+		* next
		move.l		(a2),d0
		bra		regist_xdef_end

regist_xdef_b30	movea.l		list_obj_list,a4	* a4.l = obj_list2
		tst.l		obj_list_lib_name
		bne		regist_xdef_b31
		tst.l		obj_list2_lib_name
		beq		regist_xdef_b31
		movea.l		d0,a2
		movea.l		(a2),a3
		bra		regist_xdef_b20

regist_xdef_b31	exg		d0,a2

regist_xdef_end	POP		d1-d2/a0-a5
		rts

*------------------------------------------------------------------------------
*
*	search_xdef
*
*	in:	a0.l = name		pointer of xref label name
*
*	out:	d0.l = xdef_list	pointer of xdef_list
*		       0		not found
*
*------------------------------------------------------------------------------

		_xdef_list_	list,a1,0

search_xdef:
		PUSH		d1-d2/a0-a3

		moveq		#0,d0
		movea.l		a0,a1			* a1.l = label name
		lea		(hash_key,pc),a2	* a2.l = hash key
search_xdef_l1	moveq.l		#0,d1
		move.b		(a1)+,d1
		beq		search_xdef_b1
		add		d1,d1
		rol		#3,d0
		add		(a2,d1.w),d0
		bra		search_xdef_l1

search_xdef_b1	andi		#HASH_SIZE-1,d0		* d0.l = hash value
		asl.l		#2,d0
		movea.l		(workbuf+HASH_TABLE,pc),a1
		adda.l		d0,a1
search_xdef_l2	move.l		(a1),d0
		beq		search_xdef_end		* not found !
		movea.l		d0,a1

		movea.l		a0,a2			* label name
		movea.l		list_label_name,a3	* xdef label name
search_xdef_l3	move.b		(a2)+,d1
		beq		search_xdef_b2
		cmp.b		(a3)+,d1
		beq		search_xdef_l3
		bra		search_xdef_b3
search_xdef_b2	tst.b		(a3)
		beq		search_xdef_end		* match !!

search_xdef_b3	lea		list_next,a1
		bra		search_xdef_l2

search_xdef_end	POP		d1-d2/a0-a3
		rts

*------------------------------------------------------------------------------
*
*	set_xdef_value
*
*	in:	a0.l = obj_list
*
*	out:	exit_code = EXIT_FAILURE ( if label error )
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a0,0
		_xdef_list_	xdef_list,a2,0
		_err_list_	err_list,a3,0
		_obj_list_	obj_list2,a4,0

set_xdef_value:
		PUSH		d1/a0-a4

		movea.l		obj_list_xdef_tbl,a1	* a1.l = xdef_table
set_xdef_l1:	move.l		(a1)+,d0
		beq		set_xdef_end
		movea.l		(a1)+,a2		* a2.l = xdef_list
		cmp.l		xdef_list_obj_list,a0	* owner ??
		bne		set_xdef_l1
		tst.l		xdef_list_err_list
		bne		set_xdef_b100		* duplicate definition
		tst		xdef_list_stat
		ble		@f
		move.b		(workbuf+WARNOFF_FLAG,pc),d0
		bne		@f
		pea		(dup_warn,pc)		* Warning, duplicate definition
		DOS		_PRINT
		move.l		xdef_list_label_name,-(sp)
		DOS		_PRINT
		addq.l		#8,sp
		bsr		print_crlf
@@:
		move.l		xdef_list_value,d1
		move		xdef_list_type,d0
		addq.b		#4,d0			;$fc -> $00
		cmpi		#$0a+4,d0
		bhi		set_xdef_err_func
		move.b		(@f,pc,d0.w),d0
		jmp		(@f,pc,d0.w)
@@:
		.dc.b		set_xdef_b12-@b		;$fc : rlcommon
		.dc.b		set_xdef_b9-@b		;$fd : rcommon
		.dc.b		set_xdef_b5-@b		;$fe : common
		.dc.b		set_xdef_err_func-@b	;$ff : error
		.dc.b		set_xdef_b15-@b		;$00 : abs
		.dc.b		set_xdef_b2-@b		;$01 : text
		.dc.b		set_xdef_b3-@b		;$02 : data
		.dc.b		set_xdef_b4-@b		;$03 : bss
		.dc.b		set_xdef_b6-@b		;$04 : stack
		.dc.b		set_xdef_b7-@b		;$05 : rdata
		.dc.b		set_xdef_b8-@b		;$06 : rbss
		.dc.b		set_xdef_b10-@b		;$07 : rstack
		.dc.b		set_xdef_b11-@b		;$08 : rldata
		.dc.b		set_xdef_b13-@b		;$09 : rlbss
		.dc.b		set_xdef_b14-@b		;$0a : rlstack
		.even

set_xdef_err_func:
		lea		(set_xdef_value,pc),a0	;error function
		bra		program_err

set_xdef_b2:	add.l		obj_list_text_pos,d1
		bra		set_xdef_b15
set_xdef_b3:	add.l		obj_list_data_pos,d1
		bra		set_xdef_b15
set_xdef_b4:	add.l		obj_list_bss_pos,d1
		bra		set_xdef_b15

set_xdef_b6:	add.l		obj_list_stack_pos,d1
		bra		set_xdef_b15
set_xdef_b7:	add.l		obj_list_rdata_pos,d1
		bra		set_xdef_b15
set_xdef_b8:	add.l		obj_list_rbss_pos,d1
		bra		set_xdef_b15

set_xdef_b10:	add.l		obj_list_rstack_pos,d1
		bra		set_xdef_b15
set_xdef_b11:	add.l		obj_list_rldata_pos,d1
		bra		set_xdef_b15

set_xdef_b13:	add.l		obj_list_rlbss_pos,d1
		bra		set_xdef_b15
set_xdef_b14:	add.l		obj_list_rlstack_pos,d1
		bra		set_xdef_b15

set_xdef_b5:	lea		(workbuf+COMMON_POS,pc),a4
		bra		@f
set_xdef_b9:	lea		(workbuf+RCOMMON_POS,pc),a4
		bra		@f
set_xdef_b12:	lea		(workbuf+RLCOMMON_POS,pc),a4
@@:		add.l		(a4),d1
		move.l		xdef_list_size,d0
		add.l		d0,(a4)
		bra		set_xdef_b15

set_xdef_b15:	move.l		d1,xdef_list_value
		bra		set_xdef_l1

set_xdef_b100:	pea		(dup_err,pc)
		DOS		_PRINT
		move.l		xdef_list_label_name,-(sp)
		DOS		_PRINT
		addq.l		#8,sp
		bsr		print_crlf

		pea		(dup_err_in,pc)
		DOS		_PRINT
		move.l		obj_list_obj_name,-(sp)
		DOS		_PRINT
		addq.l		#8,sp

		move.l		xdef_list_err_list,d1
*		beq		set_xdef_b101			;不要
set_xdef_l2:
		movea.l		d1,a3				;a3.l = err_list
		movea.l		err_list_obj_list,a4		;a4.l = obj_list2
		bsr		print_spc
		move.l		obj_list2_obj_name,-(sp)
		DOS		_PRINT
		addq.l		#4,sp
		move.l		err_list_next,d1
		bne		set_xdef_l2
*set_xdef_b101:
		lea		(workbuf+EXIT_CODE,pc),a4
		move		#EXIT_FAILURE,(a4)		;error exit !!

		bsr		print_crlf
		bra		set_xdef_l1
set_xdef_end:
		POP		d1/a0-a4
		rts

*------------------------------------------------------------------------------
*
*	set_xref_value
*
*	in:	a0.l = obj_list
*
*	out:	exit_code = EXIT_FAILURE ( if label error )
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a0,0

set_xref_value:
		PUSH		d1-d3/a0-a1

		moveq		#0,d3			;no undefined error
		movea.l		obj_list_xref_tbl,a1	;a1.l = xref_table
set_xref_l	move.l		(a1)+,d1
		beq		set_xref_b2
		move.l		(a1)+,d2
		bne		set_xref_l

		tas		d3
		bne		set_xref_b1		;二度目以降はシンボル名だけ表示

		pea		(undef_err,pc)
		DOS		_PRINT
		move.l		obj_list_obj_name,-(sp)
		DOS		_PRINT
		addq.l		#8,sp
		bsr		print_crlf
		move.l		a0,-(sp)
		lea		(workbuf+EXIT_CODE,pc),a0
		move		#EXIT_FAILURE,(a0)
		movea.l		(sp)+,a0

set_xref_b1:	addq.l		#6,d1
		move.l		d1,-(sp)
		DOS		_PRINT
		addq.l		#4,sp
		bsr		print_crlf
		bra		set_xref_l

set_xref_b2:	tst.b		d3
		beq		set_xref_end
		bsr		print_crlf

set_xref_end:	POP		d1-d3/a0-a1
		rts

*------------------------------------------------------------------------------

illegal_align_msg:
		.dc.b		'警告: 不正なアライン値です: ',0

dup_warn:	.dc.b		'警告: シンボル名が重複しています: ',0

dup_err:	.dc.b		'シンボル名が重複しています: '
		.dc.b		0

dup_err_in:	.dc.b		' in '
		.dc.b		0

undef_err:	.dc.b		'未定義のシンボル in '
		.dc.b		0

		.even

*------------------------------------------------------------------------------

hash_key:	.dc		$a75b,$ae8e,$66c2,$f127,$36f8,$75cb,$d6dc,$9882
		.dc		$ae45,$c35f,$e3c2,$b38f,$e65a,$a9a0,$2f4c,$99cf
		.dc		$2dd6,$a241,$d0e0,$0a4a,$64ca,$b89f,$5541,$4e8f
		.dc		$e0d5,$7b6d,$dad5,$33a6,$7b0f,$ef08,$fc74,$fc10
		.dc		$8909,$9b23,$d16f,$6dd5,$e3db,$841b,$eda5,$d284
		.dc		$e824,$38a3,$6f67,$f725,$67f5,$c411,$e394,$1e39
		.dc		$bfed,$a02d,$6f7d,$14c8,$c224,$df38,$9ffa,$1d61
		.dc		$cb24,$0201,$9371,$050c,$ad1a,$1ac9,$e4a5,$0e4a
		.dc		$cb90,$aa5f,$a3fc,$0623,$f19e,$bc04,$6c4e,$2f26
		.dc		$82e3,$d087,$54ec,$5654,$5170,$fa29,$f8b5,$c53c
		.dc		$b2e4,$b9b9,$6efa,$3ae6,$8057,$2178,$4b9a,$07d3
		.dc		$0f5a,$ab35,$ace6,$f20b,$4705,$6231,$26bd,$431d
		.dc		$6ef7,$d53b,$d070,$ba11,$6041,$0894,$44d7,$ae68
		.dc		$7782,$8b0b,$9b51,$d82a,$94d2,$52e1,$67b6,$87e6
		.dc		$ffc2,$fce5,$c857,$83a4,$986a,$7f58,$5813,$14e5
		.dc		$bb69,$7009,$203b,$01b1,$3ad0,$cc39,$c9ae,$9397
		.dc		$6c3e,$22b7,$5dbd,$9798,$2fcb,$7ec4,$7e47,$4943
		.dc		$d408,$6128,$429d,$75a0,$390d,$ce39,$3e97,$6d30
		.dc		$ad79,$5baa,$899b,$eefb,$185d,$ffd8,$be6c,$4490
		.dc		$c158,$5776,$fb70,$33f7,$8f82,$58e1,$cd7f,$06b1
		.dc		$ca6c,$92cc,$4bea,$89c6,$592e,$1094,$1890,$06c5
		.dc		$8a67,$52ec,$4ac2,$35b6,$3e28,$6c2a,$6f5f,$6e1a
		.dc		$c310,$d616,$abb8,$75f9,$f237,$a2f1,$8ca5,$8fe2
		.dc		$2f27,$5a8a,$308c,$81dd,$450d,$0122,$2b30,$9c6b
		.dc		$9073,$2588,$9af7,$a594,$e371,$c4fd,$13b9,$dfe7
		.dc		$a8a6,$6e50,$acc7,$1865,$a423,$25c2,$0100,$919d
		.dc		$3287,$7322,$27b5,$1f97,$33ea,$68b1,$b4c5,$f6d4
		.dc		$f6dd,$803e,$c681,$f25c,$5478,$cc0a,$f0c8,$54be
		.dc		$b05a,$d3e4,$4aeb,$dd02,$d594,$950d,$6fc2,$dba9
		.dc		$20c5,$9e54,$76ac,$16bb,$6405,$fafa,$f381,$d7c7
		.dc		$02e5,$32ce,$0492,$e4d5,$cf7d,$4a11,$3dbe,$8766
		.dc		$1f6c,$c892,$bd56,$8582,$cbc3,$b992,$1039,$28b8


		.end

* End of File --------------------------------- *
