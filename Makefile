# Makefile for HLK evolution (convert source code from UTF-8 to Shift_JIS)
#   Do not use non-ASCII characters in this file.

MKDIR_P = mkdir -p
U8TOSJ = u8tosj

SRC_DIR = src
BLD_DIR = build


DOCS = hlkev.txt kaiseki.txt
SJ_DOCS = $(addprefix $(BLD_DIR)/,$(DOCS))

SRCS = $(wildcard $(SRC_DIR)/*)
SJ_SRCS = $(subst $(SRC_DIR)/,$(BLD_DIR)/,$(SRCS))


.PHONY: all directories clean

all: directories $(SJ_DOCS) $(SJ_SRCS)

directories: $(BLD_DIR)

$(BLD_DIR):
	$(MKDIR_P) $@


$(BLD_DIR)/%.txt: %.txt
	$(U8TOSJ) < $^ >! $@

$(BLD_DIR)/%: $(SRC_DIR)/%
	$(U8TOSJ) < $^ >! $@


clean:
	-rm -f $(SJ_DOCS) $(SJ_SRCS)
	-rmdir $(BLD_DIR)


# EOF
