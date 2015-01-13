.SILENT: all

all: dependencies
	# Done!
	cp xccoverage bin/

install: dependencies
	# copy the bin & lib folder to the /usr/local/ or the preffix folder if it's specified.

uninstall:
	# remove the files from the /usr/local/bin & lib

clear:
	# remove all dependencies
	rm -rf bin lib

dependencies:
	# check and install if necessary
	mkdir -p bin lib

	# xcpretty 
	test -f bin/xcpretty || make -C . xcpretty-install

	# lcov 
	test -f bin/lcov || make -C . lcov-install

	# lcov-to-cobertura 
	test -f bin/lcov_cobertura.py || make -C . lcov-cobertura-install

xcpretty-install:
	rm -rf xcpretty*
	git clone https://github.com/kronenthaler/xcpretty.git 
	mv xcpretty/bin/* bin/
	mv xcpretty/lib/* lib/
	rm -rf xcpretty*

lcov-install:
	rm -rf lcov*
	git clone https://github.com/linux-test-project/lcov.git
	mv lcov/bin/* bin/
	rm -rf lcov*

lcov-cobertura-install:
	rm -rf lcov-to-cobertura-xml*
	git clone https://github.com/kronenthaler/lcov-to-cobertura-xml.git
	mv lcov-to-cobertura-xml/lcov_cobertura/* bin/
	rm -rf lcov-to-cobertura-xml*