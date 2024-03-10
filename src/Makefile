# Makefile for HLK evolution

AS	= has060
ASFLAGS	= -c4 -s__CRLF__
LD	= hlk

U8TOSJ = u8tosj

SRCDIR_MK = ../srcdir.mk
SRC_DIR = ../src
-include $(SRCDIR_MK)

#

HLK_R	= hlk.r
HLK_X	= hlk.x

#

SRCS	= main.s getarg.o analyze.o label.o object.o \
	  make_exe.o make_map.o roffset.o file.o string.o
OBJS	= $(SRCS:.s=.o)

TXTS	= hlkev.txt kaiseki.txt CHANGELOG.txt

HLK_ZIP	= hlkev.zip

#

.PHONY: all archive

all: $(HLK_R)

archive: $(HLK_ZIP)

#

$(HLK_ZIP): $(HLK_R) $(TXTS)
	rm -f $@
	zip -9 $@ $^

hlkev.txt: $(SRC_DIR)/../hlkev.txt
	$(U8TOSJ) < $^ > $@

kaiseki.txt: $(SRC_DIR)/../kaiseki.txt
	$(U8TOSJ) < $^ > $@

CHANGELOG.txt: $(SRC_DIR)/../CHANGELOG.md
	$(U8TOSJ) < $^ > $@

#

$(HLK_R): $(OBJS)
	$(LD) $(LDFLAGS) -r -o$@ $^

$(HLK_X): $(OBJS)
	$(LD) $(LDFLAGS) -o$@ $^

#

.s.o:
	$(AS) $(ASFLAGS) $<

main.o:		hlk.mac string.mac
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
