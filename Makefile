# I suck at makefile... :/

CRYSTAL=crystal
SRC=./src
OUT=./bin

SOURCES := $(wildcard $(SRC_DIR)/*.cr)
TARGETS := $(SRC_DIR)/rbenv-lock-run-cr.cr


$(OUT)/rbenv-lock-run-cr-debug: $(SOURCES)
	$(CRYSTAL) build \
		-o $(OUT)/rbenv-lock-run-cr-debug \
		$(SRC)/rbenv-lock-run-cr.cr

$(OUT)/rbenv-lock-run-cr: $(SOURCES)
	$(CRYSTAL) build \
		--release \
		--no-debug \
		-o $(OUT)/rbenv-lock-run-cr \
		$(SRC)/rbenv-lock-run-cr.cr

debug: $(OUT)/rbenv-lock-run-cr-debug

release: $(OUT)/rbenv-lock-run-cr

all: debug release

.PHONY: clean
clean:
	@echo Cleaning...
	
	@rm -f $(OUT)/rbenv-lock-run-cr
	@rm -f $(OUT)/rbenv-lock-run-cr-debug
	@rm -f $(OUT)/rbenv-lock-run-cr-debug.dwarf
	@echo Done cleaning.
