# global paths 
BASE = $(shell pwd)
TOOLS = $(BASE)/tools
REPORTS := $(BASE)/reports

# report names
UNIT_TEST_REPORT := $(REPORTS)/test.xml
COMPILATION_REPORT := compile_commands.json
OCLINT_REPORT = $(REPORTS)/oclint.xml
COBERTURA_REPORT = $(REPORTS)/coverage.xml
COVERAGE_INFO = $(REPORTS)/coverage.info
COVERAGE_ENV = $(REPORTS)/covenv

# settings
PROJECT := `find .. -maxdepth 1 -name '*xcodeproj' | sort | head -n1`
SCHEME := $(shell xcodebuild -list -project $(PROJECT)| grep "Schemes" -A1 | tail -n1 | sed '/^$$/d;s/[[:blank:]]//g')
BUILD_PARAMETERS := -scheme $(SCHEME) -project $(PROJECT) -configuration Debug -sdk iphonesimulator
OCLINT_ON := 1
OCLINT_PARAMETERS := -max-priority-2=100 -max-priority-3=100 -rc=LONG_LINE=120
COVERAGE_ON := 1
COVERAGE_EXCLUDES := "Developer/SDKs/*" "main*"

# important macros DO NOT MODIFY
XCTOOL := $(TOOLS)/bin/xctool
CLANG_FORMAT := $(TOOLS)/bin/clang-format
OCLINT := $(TOOLS)/bin/oclint-json-compilation-database
LCOV := $(TOOLS)/bin/lcov
LCOV_COBERTURA := $(TOOLS)/bin/lcov_cobertura.py
MOD_PBXPROJ := $(TOOLS)/bin/mod_pbxproj.py
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
	$(LCOV) --capture --derive-func-data -b "$(SRCROOT)" -d "$(OBJ_DIR)" -o "$(COVERAGE_INFO)" --gcov-tool $(TOOLS)/bin/llvm-cov-wrapper.sh
	
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
	test -d $(TOOLS) || mkdir -p $(TOOLS)/bin $(TOOLS)/lib $(TOOLS)/libexec $(TOOLS)/reporters
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
	rm -rf $(TOOLS)/xctool*
	git clone https://github.com/facebook/xctool $(TOOLS)/xctool
	$(TOOLS)/xctool/xctool.sh -help &> /dev/null || echo "Installed xctool"
	cp -rf $(TOOLS)/xctool/build/*/*/Products/Release/bin $(TOOLS)
	cp -rf $(TOOLS)/xctool/build/*/*/Products/Release/lib $(TOOLS)
	cp -rf $(TOOLS)/xctool/build/*/*/Products/Release/libexec $(TOOLS)
	cp -rf $(TOOLS)/xctool/build/*/*/Products/Release/reporters $(TOOLS)
	rm -rf $(TOOLS)/xctool*

install-clangformat:
	echo "Installing clangformat"
	rm -rf $(TOOLS)/clangformat*
	git clone https://github.com/travisjeffery/ClangFormat-Xcode.git $(TOOLS)/clangformat
	cp -rf $(TOOLS)/clangformat/bin $(TOOLS)
	rm -rf $(TOOLS)/clangformat*

install-oclint:
	echo "Installing oclint"
	rm -rf $(TOOLS)/oclint*
	mkdir -p $(TOOLS)/oclint
	curl -o $(TOOLS)/oclint.tar.gz http://archives.oclint.org/releases/0.8/oclint-0.8.1-x86_64-darwin-14.0.0.tar.gz
	tar xfvz $(TOOLS)/oclint.tar.gz -C $(TOOLS)
	cp -rf $(TOOLS)/oclint-0.8.1/bin $(TOOLS)
	cp -rf $(TOOLS)/oclint-0.8.1/lib $(TOOLS)
	rm -rf $(TOOLS)/oclint*
	
install-coverage:
	echo "Installing lcov"
	rm -rf $(TOOLS)/coverage*
	mkdir -p $(TOOLS)/coverage
	git clone https://github.com/jonreid/XcodeCoverage.git $(TOOLS)/coverage
	cp -rf $(TOOLS)/coverage/lcov*/bin $(TOOLS)
	cp -rf $(TOOLS)/coverage/llvm-cov-wrapper.sh $(TOOLS)/bin/
	rm -rf $(TOOLS)/coverage*

install-cobertura:
	echo "Installing Cobertura converter"
	rm -rf $(TOOLS)/cobertura*
	git clone https://github.com/eriwen/lcov-to-cobertura-xml.git $(TOOLS)/cobertura
	cp -rf $(TOOLS)/cobertura/lcov_cobertura/* $(TOOLS)/bin/
	rm -rf $(TOOLS)/cobertura*

install-mod-pbxproj:
	echo "Installing mod_pbxproj"
	rm -rf $(TOOLS)/mod_pbxproj*
	git clone https://github.com/kronenthaler/mod-pbxproj.git $(TOOLS)/mod_pbxproj
	cp -rf $(TOOLS)/mod_pbxproj/mod_pbxproj.py $(TOOLS)/bin/
	rm -rf $(TOOLS)/mod_pbxproj*
