# Makefile for hlk test
#   Do not use non-ASCII characters in this file.

AS = has060
ASFLAGS =
LD = ../build/hlk
LDFLAGS =

SRCS = adrs_not_long.s div_zero.s dup_entry.s exp.s overflow.s \
       reltbl_odd.s r_entry.s r_reltbl.s xdef.s

OBJS = $(SRCS:.s=.o)
TXTS = $(filter-out xdef.txt,$(SRCS:.s=.txt))


.PHONY: all clean test

all: test

test: $(OBJS)
	echo $(TXTS)
	-$(LD) $(LDFLAGS) adrs_not_long.o xdef.o >&! adrs_not_long.txt
	-$(LD) $(LDFLAGS) div_zero.o xdef.o >&! div_zero.txt
	-$(LD) $(LDFLAGS) dup_entry.o r_entry.o >&! dup_entry.txt
	-$(LD) $(LDFLAGS) exp.o xdef.o >&! exp.txt
	-$(LD) $(LDFLAGS) overflow.o xdef.o >&! overflow.txt
	-$(LD) $(LDFLAGS) reltbl_odd.o >&! reltbl_odd.txt
	-$(LD) $(LDFLAGS) -r r_entry.o >&! r_entry.txt
	-$(LD) $(LDFLAGS) -r r_reltbl.o >&! r_reltbl.txt

%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $^


clean:
	-rm $(TXTS) $(OBJS)


# EOF
