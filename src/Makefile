# Makefile for HLK evolution

AS	= has060
ASFLAGS	= -c4 -s__CRLF__
LD	= hlk

#

HLK_R		= hlk.r
HLK_X		= hlk.x

#

OBJS0	= getarg.o analyze.o label.o object.o \
	  make_exe.o make_map.o roffset.o file.o string.o

OBJS1	= hlk.o $(OBJS0)

#

SRCS	= $(OBJS0:.o=.s) main.s
TXTS	= hlkev.txt kaiseki.txt CHANGELOG.txt
SRC_ZIP	= src.zip
HLK_ZIP	= hlkev.zip

#

all: $(HLK_R)

#

$(SRC_ZIP): $(SRCS) Makefile hlk.mac string.mac
	rm -f $@
	zip -9 $@ $^

$(HLK_ZIP): $(HLK_R) $(TXTS)
	rm -f $@
	zip -9 $@ $^

#

$(HLK_R): $(OBJS1)
	$(LD) $(LDFLAGS) -r -o$@ $^

$(HLK_X): $(OBJS1)
	$(LD) $(LDFLAGS) -o$@ $^

#

.s.o:
	$(AS) $(ASFLAGS) $<

hlk.o:	main.s hlk.mac string.mac	; $(AS) $(ASFLAGS) -o$@ main.s
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
