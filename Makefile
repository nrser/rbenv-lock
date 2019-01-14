# I suck at make file... :/

CRYSTAL=crystal
SRC=./src
OUT=./bin

# All the Crystal files. We depend on all of these for compilation so that 
# it triggers when any change.
SOURCES := $(shell find $(SRC) -name '*.cr')


# Turn a Crystal file `//src/<NAME>.cr`
# to an debug executable `//bin/<NAME>-debug`
$(OUT)/%-debug: $(SRC)/%.cr $(SOURCES)
	$(CRYSTAL) build \
		-o $@ \
		$<


# Turn a Crystal file `//src/<NAME>.cr`
# to an optimized executable `//bin/<NAME>`
$(OUT)/%: $(SRC)/%.cr $(SOURCES)
	$(CRYSTAL) build \
		--release \
		--no-debug \
		-o $@ \
		$<


# Build the debug executables
debug: $(OUT)/rbenv-lock-run-cr-debug


# Build the release executables
release: $(OUT)/rbenv-lock-run-cr


# Build 'em both
all: debug release


# Do a poor job cleaning
.PHONY: clean
clean:
	@echo Cleaning...
	
	@rm -f $(OUT)/rbenv-lock-run-cr
	@rm -f $(OUT)/rbenv-lock-run-cr-debug
	@rm -f $(OUT)/*.dwarf
	
	@echo Done cleaning.


# Me trying figure out make
.PHONY: blah
blah:
	@echo "SOURCES: $(SOURCES)"