# global paths 
BASE = $(shell pwd)/jenkins
TOOLS = $(BASE)/tools/
REPORTS := $(BASE)/reports

# report names
UNIT_TEST_REPORT := $(REPORTS)/test.xml
COMPILATION_REPORT := compile_commands.json
OCLINT_REPORT = $(REPORTS)/oclint.xml
COBERTURA_REPORT = $(REPORTS)/coverage.xml
COVERAGE_INFO = $(REPORTS)/coverage.info
COVERAGE_ENV = $(REPORTS)/covenv

# settings
PROJECT := `find . -name '*xcodeproj' | sort | head -n1 | sed -e 's|\./||g'`
SCHEME := $(shell echo $(PROJECT) | sed -e 's/\.xcodeproj//g')
BUILD_PARAMETERS := -scheme $(SCHEME) -project $(PROJECT) -configuration Debug -sdk iphonesimulator
OCLINT_ON := 1
OCLINT_PARAMETERS := -max-priority-2=100 -max-priority-3=100 -rc=LONG_LINE=120
COVERAGE_ON := 1
COVERAGE_EXCLUDES := "Developer/SDKs/*" "main*"

# important macros DO NOT MODIFY
XCTOOL := $(TOOLS)/xctool/xctool.sh
CLANG_FORMAT := $(TOOLS)/clangformat/bin/clang-format
OCLINT := $(TOOLS)/oclint/bin/oclint-json-compilation-database
LCOV := $(TOOLS)/coverage/lcov-1.10/bin/lcov
LCOV_COBERTURA := $(TOOLS)/cobertura/lcov_cobertura/lcov_cobertura.py
MOD_PBXPROJ := $(TOOLS)/mod_pbxproj/mod_pbxproj.py
BUILT_PRODUCTS_DIR := `cat $(COVERAGE_ENV) | egrep '( BUILT_PRODUCTS_DIR)' | sed -e 's/^[ \t]*//g' -e 's/BUILT_PRODUCTS_DIR = //g' | head -n1`
SRCROOT := `cat $(COVERAGE_ENV) | egrep '( SRCROOT)' | sed -e 's/^[ \t]*//g' -e 's/SRCROOT = //g' | head -n1`
OBJECT_FILE_DIR_normal := `cat $(COVERAGE_ENV) | egrep '( OBJECT_FILE_DIR_normal)' | sed -e 's/^[ \t]*//g' -e 's/OBJECT_FILE_DIR_normal = //g' | head -n1`
CURRENT_ARCH := $(shell ls $(OBJECT_FILE_DIR_normal) | head -n1)
OBJ_DIR := ${OBJECT_FILE_DIR_normal}/${CURRENT_ARCH}

# targets 
.SILENT: clean post-cleanup build test report report-oclint report-coverage check-dependencies install-xctool install-clangformat install-coverage install-cobertura install-mod-pbxproj

all: clean build test report
	# done!
	make -C . post-cleanup

clean: 
	# remove intermediate files and reports
	rm -rf $(REPORTS)/*
	rm -rf $(COMPILATION_REPORT)

post-cleanup:
	rm -rf $(COMPILATION_REPORT)
	rm -rf $(COVERAGE_INFO) $(COVERAGE_ENV)

build: check-dependencies 
	# ensure the test coverage parameter are set up
	python $(MOD_PBXPROJ) $(PROJECT) Debug -af GCC_GENERATE_TEST_COVERAGE_FILES=YES -af GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES -b
	# export the build settings
	$(XCTOOL) build $(BUILD_PARAMETERS) -showBuildSettings | egrep '( BUILT_PRODUCTS_DIR)|(CURRENT_ARCH)|(OBJECT_FILE_DIR_normal)|(SRCROOT)|(OBJROOT)' > $(COVERAGE_ENV)
	# execute the build command
	$(XCTOOL) clean build $(BUILD_PARAMETERS) -reporter json-compilation-database:$(COMPILATION_REPORT) -reporter plain

test: clean build 
	# execute the test command
	$(XCTOOL) test -freshSimulator $(BUILD_PARAMETERS) -reporter junit:$(UNIT_TEST_REPORT) -reporter plain

deploy:
	# how to deploy the framework (upload to a repo, public git? maven?, ftp?)
	# 

report: 
	# oclint
	if [ '$(OCLINT_ON)' == '1' ]; then make -C . report-oclint; fi
	# coverage
	if [ '$(COVERAGE_ON)' == '1' ]; then make -C . report-coverage; fi

report-oclint: 
	$(OCLINT) $(COMPILATION_REPORT) -- $(OCLINT_PARAMETERS) --report-type=pmd -o "$(OCLINT_REPORT)"

report-coverage: 
	echo "Coverage generation"
	
	# gather the info
	$(LCOV) --capture --derive-func-data -b "$(SRCROOT)" -d "$(OBJ_DIR)" -o "$(COVERAGE_INFO)" --gcov-tool $(TOOLS)/coverage/llvm-cov-wrapper.sh
	
	# exclude what needed
	for exclude in $(COVERAGE_EXCLUDES); \
	do \
		$(LCOV) --remove $(COVERAGE_INFO) $$exclude -d "$(OBJ_DIR)" -o $(COVERAGE_INFO);\
	done;

	# export the cobertura compatible file.
	$(LCOV_COBERTURA) $(COVERAGE_INFO) -b "$(SRCROOT)" -o $(COBERTURA_REPORT)

install: check-dependencies

check-dependencies:
	echo "Checking dependencies"

	# check the dirs
	test -d $(TOOLS) || mkdir -p $(TOOLS) 
	test -d $(REPORTS) || mkdir -p $(REPORTS)

	# check the building tools
	test -f $(XCTOOL) || make -C . install-xctool
	
	# check the format tools
	test -f $(CLANG_FORMAT) || make -C . install-clangformat
	
	# check the oclint tools
	test -f $(OCLINT) || make -C . install-oclint

	# check for the coverage tools
	test -f $(LCOV) || make -C . install-coverage
	test -f $(LCOV_COBERTURA) || make -C . install-cobertura

	# download the mod_pbxproj and check for the stuff needed.
	test -f $(MOD_PBXPROJ) || make -C . install-mod-pbxproj

install-xctool:
	echo "Installing xctool"
	git clone https://github.com/facebook/xctool $(TOOLS)/xctool
	$(XCTOOL) -help &> /dev/null || echo "Installed xctool"

install-clangformat:
	echo "Installing clangformat"
	git clone https://github.com/travisjeffery/ClangFormat-Xcode.git $(TOOLS)/clangformat

install-oclint:
	echo "Installing oclint"
	mkdir -p $(TOOLS)/oclint
	curl -o $(TOOLS)/oclint.tar.gz http://archives.oclint.org/releases/0.8/oclint-0.8.1-x86_64-darwin-14.0.0.tar.gz
	tar xfvz $(TOOLS)/oclint.tar.gz -C $(TOOLS)
	rm -rf $(TOOLS)/oclint.tar.gz
	mv $(TOOLS)/oclint-0.8.1/* $(TOOLS)/oclint
	rm -rf $(TOOLS)/oclint-0.8.1/
	
install-coverage:
	echo "Installing lcov"
	mkdir -p $(TOOLS)/coverage
	git clone https://github.com/jonreid/XcodeCoverage.git $(TOOLS)/coverage

install-cobertura:
	echo "Installing Cobertura converter"
	git clone https://github.com/eriwen/lcov-to-cobertura-xml.git $(TOOLS)/cobertura

install-mod-pbxproj:
	echo "Installing mod_pbxproj"
	git clone https://github.com/kronenthaler/mod-pbxproj.git $(TOOLS)/mod_pbxproj
