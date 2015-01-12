.SILENT: all

all: dependencies
	# Done!

uninstall:
	rm -rf bin lib

clear:
	# remove all dependencies

dependencies: coverage-deps format-deps oclint-deps common-deps
	# install all dependencies required by all scripts 

coverage-deps:
	# check and install if necessary

format-deps:
	# check and install if necessary
	
oclint-deps:
	# check and install if necessary

common-deps:
	# check and install if necessary
	mkdir -p bin lib

	# xcpretty 
	test -f bin/xcpretty/bin/xcpretty || make -C . xcpretty-install

xcpretty-install:
	rm -rf xcpretty*
	git clone https://github.com/kronenthaler/xcpretty.git 
	mv xcpretty/bin/* bin/
	mv xcpretty/lib/* lib/
	rm -rf xcpretty*
