.xref abs100,abs10000
.xref label

  move.b #abs100,d0  ;$40ff

  .dc.b abs100  ;$43ff
  .even

  move.b #abs100+1,d0  ;$50ff

  .dc abs10000+1  ;$51ff

  .dc.b abs100+1  ;$53ff
  .even

  bsr.w label  ;$6501
.data
  bsr.w label  ;$6502
.text
  bsr.s label  ;$6b01
.data
  bsr.s label  ;$6b02
.text

  move.b #abs100*2+1,d0  ;$9000

  .dc abs10000*2  ;$9100

  .dc.b abs100*2  ;$9300
  .even

  move ($+abs10000,pc),d0  ;$9900

