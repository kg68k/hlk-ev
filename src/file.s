		.title		HLK/ev (file.s - file i/o module)


* Include File -------------------------------- *

		.include	hlk.mac
		.include	string.mac
		.include	doscall.mac


* Global Symbol ------------------------------- *

		.xdef		read_file
		.xdef		to_slash

		.xref		print_crlf
		.xref		malloc_err


* Text Section -------------------------------- *

		.cpu		68000

		.text
		.even

*------------------------------------------------------------------------------
*
*	read_file
*
*	in:	a0.l = file name
*
*	out:	d0.l = status
*			-2 ... error (not obj, arc file)
*			-1 ... error (not found)
*			 0 ... ok
*			 1 ... already read
*		d7.l = file size
*		a0.l = file name
*		a1.l = file name (full path)
*		a2.l = object_image
*
*------------------------------------------------------------------------------

		_obj_list_	obj_list,a4,0

file_buf:	.reg		(-448,a6)
name:		.reg		(-384,a6)
name_name:	.reg		(-317,a6)
name_ext:	.reg		(-298,a6)
full_name:	.reg		(-256,a6)
obj_name:	.reg		(-128,a6)

read_file::
		link		a6,#-448
		PUSH		d1-d4/a3-a4

		pea		name
		pea		(a0)
		DOS		_NAMECK
		addq.l		#8,sp
		tst.l		d0
		bne		read_file_err1		;not found

		move.b		name_ext,d1
		movea.l		a0,a1
@@:		tst.b		(a1)+
		bne		@b
		cmpi.b		#'.',(-2,a1)
		bne		@f
		st		d1			;"foo."
@@:
		lea		(workbuf+LIB_PATH_HEAD,pc),a3
		clr.b		full_name

read_file_search_loop:
		_strcat		full_name,(a0)
		tst.b		d1
		bne		@f
		_strcat		full_name,(o_ext,pc)	;拡張子がなかったら補完
@@:
		move		#1<<ARCHIVE,-(sp)
		pea		full_name
		pea		file_buf
		DOS		_FILES
		addq.l		#10-4,sp
		move.l		d0,(sp)+
		beq		read_file_b100

		move.l		(a3),d0
		beq		read_file_err1		;not found

		movea.l		d0,a3
		_strcpy		full_name,(4,a3)
		bra		read_file_search_loop

read_file_b100:	_strcpy		obj_name,full_name

		pea		name
		pea		full_name
		DOS		_NAMECK
		addq.l		#8,sp

		_strcpy		full_name,name
		_strcat		full_name,name_name
		_strcat		full_name,name_ext
*		_strlwr		full_name
		pea		full_name
		bsr		to_slash
		addq.l		#4,sp

		moveq		#-1,d4			;already read ???
		move.l		(workbuf+OBJ_LIST_HEAD,pc),d0
		beq		read_file_b104
read_file_l100:
		move.l		d0,a4
		move.l		obj_list_lib_name,d0
		beq		read_file_b101		;obj file
		cmp.l		d0,d4
		beq		read_file_b103		;arc,libは先頭のobjだけ調べる
		move.l		d0,d4
		bra		read_file_b102

read_file_b101:	moveq		#-1,d4
read_file_b102:	move.l		obj_list_full_path,-(sp)
		pea		full_name
		bsr		strcmp
		addq.l		#8,sp
		tst.l		d0
		beq		read_file_err5		;already read
read_file_b103:
		move.l		obj_list_next,d0
		bne		read_file_l100

read_file_b104:
		lea		(workbuf+MALLOC_PTR_HEAD,pc),a1	;a1.l = malloc_ptr_head
		lea		(workbuf+MALLOC_LEFT,PC),a2	;a2.l = malloc_left

		moveq		#0,d1			;d1.l = 0
		move		d1,-(sp)
		pea		full_name
		DOS		_OPEN
		addq.l		#6,sp
		move.l		d0,d3			;d3.l = file handle
		bmi		read_file_err3		;file i/o error

		move		#2,-(sp)
		move.l		d1,-(sp)
		move		d3,-(sp)
		DOS		_SEEK
		move.l		d0,d2			;d2.l = file size
		move.l		d0,d7			;d7.l = file size

		move		d1,(6,sp)
		DOS		_SEEK
		addq.l		#8,sp

		btst		#0,d2
		bne		read_file_err2		;illegal file size
		moveq		#$20,d0
		cmp.l		d0,d2
		bcs		read_file_err2		;念の為

		moveq		#$10,d0
		add.l		d0,d2			;気休め
		sub.l		d2,(a2)
		bmi		malloc_err		;CLOSE してないけど、まっいいか
		movea.l		(a1),a3			;a3.l = read_buf
		add.l		d2,(a1)			;forward malloc_ptr_head
		sub.l		d0,d2

		move.l		d2,-(sp)
		pea		(a3)
		move		d3,-(sp)
		DOS		_READ
		lea		(10,sp),sp
		cmp.l		d0,d2
		bne		read_file_err3		;file i/o error

		move		d3,-(sp)
		DOS		_CLOSE
		addq.l		#2,sp
		tst.l		d0
		bmi		read_file_err3		;file i/o error

		move.l		d1,(a3,d2.l)		;気休め

		cmpi		#$d000,(a3)
		beq		read_file_b105		;obj file
		cmpi		#$0068,(a3)
		beq		read_file_b105		;lib file
		cmpi		#$d100,(a3)
		bne		read_file_err4		;not obj, arc file
		moveq		#$00000002,d0
		cmp.l		(2,a3),d0
		bne		read_file_err4		;not obj, arc file
read_file_b105:
		move.l		a3,d1			;d1.l = object_image

		_strlen		obj_name
		addq.l		#8,d0			;気休め
		andi		#$fffe,d0

		sub.l		d0,(a2)
		bmi		malloc_err
		movea.l		(a1),a0			;a0.l = obj_name
		add.l		d0,(a1)			;forward malloc_ptr_head
		_strcpy		(a0),obj_name

		_strlen		full_name
		addq.l		#8,d0			;気休め
		andi		#$fffe,d0

		sub.l		d0,(a2)
		bmi		malloc_err
		movea.l		(a1),a3			;a3.l = full path
		add.l		d0,(a1)			;forward malloc_ptr_head
		_strcpy		(a3),full_name

		movea.l		a3,a1			;a1.l = full path name
		movea.l		d1,a2			;a2.l = object image
							;d7.l = file size
		moveq		#0,d0
read_file_end:
		POP		d1-d4/a3-a4
		unlk		a6
		rts


read_file_err1:
		pea		(not_found,pc)		;not found
		DOS		_PRINT
		pea		(a0)
		DOS		_PRINT
		addq.l		#8,sp
		bsr		print_crlf

		moveq		#-1,d0
		bra		read_file_end

read_file_err2:
		pea		(illegal_file,pc)	;illegal file size
		bra		@f
read_file_err3:
		pea		(file_io,pc)		;file i/o error
@@:		DOS		_PRINT
		pea		full_name
		DOS		_PRINT
		addq.l		#8,sp
		bsr		print_crlf
		move		#EXIT_FAILURE,-(sp)
		DOS		_EXIT2

read_file_err4:
		add.l		#$10,d2
		add.l		d2,(a2)
		sub.l		d2,(a1)

		pea		(not_obj_arc,pc)	;not obj, arc file
		DOS		_PRINT
		pea		full_name
		DOS		_PRINT
		addq.l		#8,sp
		bsr		print_crlf

		moveq		#-2,d0
		bra		read_file_end

read_file_err5:
		moveq		#1,d0			;already read
		bra		read_file_end


*------------------------------------------------------------------------------
*
*	to_slash( char *filename )
*
*	global	workbuf.SLASH_CHAR
*
*	文字列中の '/' 及び '\' を環境変数 SLASH で指定されたパスデリミタ
*	に変換する. それらの文字が連続していた場合は一個に纏める.
*	(SLASH='/' 以外の場合は全て SLASH='\' と見なす.)
*
*------------------------------------------------------------------------------

to_slash::
		PUSH		d0/a0-a1
		movea.l		(3*4+4,sp),a0		;read ptr
		lea		(a0),a1			;write ptr
to_slash_loop:
		move.b		(a0)+,d0
		move.b		d0,(a1)+
		beq		to_slash_end
		bpl		to_slash_sb
		cmpi.b		#$a0,d0
		bcs		to_slash_mb
		cmpi.b		#$e0,d0
		bcs		to_slash_sb
to_slash_mb:
		move.b		(a0)+,(a1)+
		bne		to_slash_loop
to_slash_end:
		POP		d0/a0-a1
		rts

to_slash_sb:
		bsr		to_slash_isslash
		bne		to_slash_loop
		move.b		(workbuf+SLASH_CHAR,pc),(-1,a1)
to_slash_skip_slash:
		move.b		(a0)+,d0
		bsr		to_slash_isslash
		beq		to_slash_skip_slash
		subq.l		#1,a0
		bra		to_slash_loop

to_slash_isslash:
		cmpi.b		#'\',d0
		beq		@f
		cmpi.b		#'/',d0
@@:		rts


*------------------------------------------------------------------------------

o_ext:		.dc.b		'.o',0

not_found:	.dc.b		'Not found : '
		.dc.b		0

illegal_file:	.dc.b		'Illegal file size : '
		.dc.b		0

file_io:	.dc.b		'File I/O error : '
		.dc.b		0

not_obj_arc:	.dc.b		'Not obj, arc file : '
		.dc.b		0

already:	.dc.b		'Already read : '
		.dc.b		0

		.even

		.end

* End of File --------------------------------- *
