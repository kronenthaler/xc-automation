# xcode-automation-suite
A collection of xcode automation tools for CI purposes (lint, test &amp; coverage reports, build utilities)

## tools automatically downloaded
* [xctool](https://github.com/facebook/xctool)
* [mod_pbxproj](https://github.com/kronenthaler/mod_pbxproj)
* [XCodeCoverage](https://github.com/jonreid/XcodeCoverage)
* [lcov-to-cobertura-xml](https://github.com/eriwen/lcov-to-cobertura-xml)
* [ClangFormat-Xcode](https://github.com/travisjeffery/ClangFormat-Xcode)
* [oclint-0.8.1](http://oclint.org/)

## Usage

### Instalation
Install this as a git submodule
```
cd /path/to/your/project
git submodule add https://github.com/kronenthaler/xc-automation.git jenkins
git submodule init && git submodule update
```
It will create a .gitmodules file if it doesn't exists and it will create a module folder jenkins. It assumes the project file will be in the direct parent folder, if not, check the settings below to fix.

Or just copy the Makefile into a folder under your project. Please adjust the project paths if necessary.

### Dependencies
Execute, and this will download all dependencies required once.
```
cd jenkins
make install
```

### Build, Test and Report
* Clean: `make clean`
* Build: `make build`
* Test: `make test`
* Report: `make report`
* All: `make` or `make clean build test report`

### Report paths
All reports will end up in the default path: `jenkins/reports/` with the following names:

* Unit test (junit format): `tests.xml`
* OCLint (PMD format): `oclint.xml`
* Coverage (Cobertura XML): `coverage.xml`

### Modifying behaviour
This make file relies in some default values that can be modified (carefully).

* Project name: the project name it's inferred from the parent folder .xcodeproj file. To change it modify the `PROJECT` variable
* Scheme name: the scheme is assumed to be the main scheme (a.k.a. project name). To change it modify the `SCHEME` variable
* Tools/Report path: a convenient jenkins folder is created to contain all the dependencies and results of this automation process. To change it to a different location change the variable `REPORTS` and/or `BASE`
* Report names: all variables ending with `_REPORT` can be modified to change the name of the desired report.
* Build parameters: sometimes especial parameters are necessary to build your project with the command line. Specify them on the `BUILD_PARAMETERS` variable.
* Disable/Enable OCLint report: if you need to or don't want to generate the OCLint report switch `OCLINT_ON` to 1 or 0.
* OCLint parameters: sometimes you may want to be more strict/loose with the oclint validation, if needed, change the parameters in the `OCLINT_PARAMETERS`
* Disable/Enable Coverage report: if you need to or don't want to generate the coverage report switch `COVERAGE_ON` to 1 or 0.
* Coverage excludes: sometimes you need to exclude some coverage results (3rd party libraries, etc), if needed, add all the patterns to be excluded in `COVERAGE_EXCLUDES` separated by spaces.

Additionally all this values don't need to be written down in the makefile, they can be overriden by simply passing them to make in the invocation call like:
```make clean build SCHEME=MyWeirdSchemeName```

