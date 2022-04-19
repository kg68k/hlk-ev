# Makefile for HLK evolution

AS	= has
ASFLAGS	= -c4 -s__CRLF__
LD	= hlk

#

HLK_R		= hlk.r
G2LK_R		= g2lk.r

HLK_X		= hlk.x
G2LK_X		= g2lk.x

#

OBJS0	= getarg.o analyze.o label.o object.o \
	  make_exe.o make_map.o roffset.o file.o string.o

OBJS1	= hlk.o $(OBJS0)
OBJS2	= g2lk.o $(OBJS0)

#

SRCS	= $(OBJS0:.o=.s) main.s
TXTS	= hlkev.txt kaiseki.txt
SRC_ZIP	= src.zip
HLK_ZIP	= hlkev.zip

#

all: $(HLK_R) #$(G2LK_R)

#

$(SRC_ZIP): $(SRCS) Makefile hlk.mac string.mac
	rm -f $@
	zip -9 $@ $^

$(HLK_ZIP): $(SRC_ZIP) $(HLK_R) $(TXTS)
	rm -f $@
	zip -9 $@ $^

#

$(HLK_R): $(OBJS1)
	$(LD) $(LDFLAGS) -r -o$@ $^

$(G2LK_R): $(OBJS2)
	$(LD) $(LDFLAGS) -r -o$@ $^

$(HLK_X): $(OBJS1)
	$(LD) $(LDFLAGS) -o$@ $^

$(G2LK_X): $(OBJS2)
	$(LD) $(LDFLAGS) -o$@ $^

#

.s.o:
	$(AS) $(ASFLAGS) $<

hlk.o:	main.s hlk.mac string.mac	; $(AS) $(ASFLAGS) -o$@ main.s
g2lk.o:	main.s hlk.mac string.mac	; $(AS) $(ASFLAGS) -o$@ main.s -s__G2LK__
#

getarg.o:	hlk.mac
analize.o:	hlk.mac
display.o:	hlk.mac
label.o:	hlk.mac
object.o:	hlk.mac
file.o:		hlk.mac string.mac
roffset.o:	hlk.mac
string.o:	hlk.mac
make_exe.o:	hlk.mac
make_map.o:	hlk.mac

#

clean:
	rm *.o *.r *.bak

# EOF
