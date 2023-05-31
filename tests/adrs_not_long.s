.comm commlabel,4
.xref label
.xref abs0

  move.b #commlabel,d0  ;$40fe
  move.b #label,d0      ;$40ff

  .dc commlabel  ;$41fe
  .dc label      ;$41ff

  .dc.b commlabel  ;$43fe
  .dc.b label      ;$43ff

.ifdef AS_V2
  move label(a0),d0     ;$45ff
  move label(a0,d0),d0  ;$47ff
.endif

  move.b #label-1,d0  ;$50ff

  .dc label-1  ;$51ff

  .dc.b label-1  ;$53ff
  .even

.ifdef AS_V2
  move label-1(a0),d0     ;$55ff
  move label-1(a0,d0),d0  ;$57ff
.endif

  bsr.w abs0  ;$6501
.data
  bsr.w abs0  ;$6502
.text
  bsr.s abs0  ;$6b01
.data
  bsr.s abs0  ;$6b02
.text

  move.b #label-label+label,d0  ;$9000

  .dc label-label+label    ;$9100

  .dc.b label-label+label  ;$9300
  .even

.end
