.SILENT: all

all: dependencies
	# Done!

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