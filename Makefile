# I suck at make file... :/
# 
# Refs...
# 
# [1]: https://www.gnu.org/prep/standards/html_node/Makefile-Basics.html#Makefile-Basics
# 
# [.PHONY]: https://stackoverflow.com/a/2145605
# 

# > Every Makefile should contain this line: [1][]
SHELL = /bin/sh

# > it is a good idea to set the suffix list explicitly using only the suffixes
# > you need in the particular Makefile [1][]
.SUFFIXES:
.SUFFIXES: .cr

CRYSTAL=crystal
SRC=./src
OUT=./bin

# All the Crystal files. We depend on all of these for compilation so that 
# it triggers when any change.
SOURCES := $(shell find $(SRC) -name '*.cr')

# What's we gotta make
DEBUG_TARGETS := $(OUT)/rbenv-lock-exec-file-debug
RELEASE_TARGETS := $(OUT)/rbenv-lock-exec-file


# Build 'em all!
# 
# Want this to the the default task, which can be acomplished by simply 
# putting it first (among other ways... <https://stackoverflow.com/a/30176470>)
# 
.PHONY: all # [.PHONY][] means `all` is not a file, but just a task (I think...)
all: debug release
	@echo Everything... MAKED!


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
.PHONY: debug
debug: $(DEBUG_TARGETS)
	@echo Debug executables... BUILT!
	@echo


# Build the release executables
.PHONY: release
release: $(RELEASE_TARGETS)
	@echo Release executables... BUILT!
	@echo


# Do a poor job cleaning
.PHONY: clean
clean:	
	rm -f $(RELEASE_TARGETS)
	rm -f $(DEBUG_TARGETS)
	rm -f $(OUT)/*.dwarf
	
	@echo Output directory... CLEANED!
	@echo


# Re-make everything by cleaning then making everything
.PHONY: remake
remake: clean all


# Me trying figure out make
.PHONY: blah
blah:
	@echo "SOURCES: $(SOURCES)"
