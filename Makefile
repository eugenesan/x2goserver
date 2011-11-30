#!/usr/bin/make -f

all: build

build: build-arch build-indep

# make man2html build available from project's base folder...
build_man2html:
	cd x2goserver && make $@
	cd x2goserver-printing && make $@
	cd x2goserver-compat && make $@
	cd x2goserver-extensions && make $@
	cd x2goserver-xsession && make $@
	cd x2goserver-pyhoca && make $@

clean:
	cd x2goserver && make $@
	cd x2goserver-printing && make $@
	cd x2goserver-compat && make $@
	cd x2goserver-extensions && make $@
	cd x2goserver-xsession && make $@
	cd x2goserver-pyhoca && make $@

build-arch:
	cd x2goserver && make $@
	cd x2goserver-printing && make $@
	cd x2goserver-compat && make $@
	cd x2goserver-extensions && make $@
	cd x2goserver-xsession && make $@
	cd x2goserver-pyhoca && make $@

build-indep:
	cd x2goserver && make $@
	cd x2goserver-printing && make $@
	cd x2goserver-compat && make $@
	cd x2goserver-extensions && make $@
	cd x2goserver-xsession && make $@
	cd x2goserver-pyhoca && make $@

install:
	cd x2goserver && make $@
	cd x2goserver-printing && make $@
	cd x2goserver-compat && make $@
	cd x2goserver-extensions && make $@
	cd x2goserver-xsession && make $@
	cd x2goserver-pyhoca && make $@

uninstall:
	cd x2goserver-extensions && make $@
	cd x2goserver-compat && make $@
	cd x2goserver-printing && make $@
	cd x2goserver && make $@
	cd x2goserver-xsession && make $@
	cd x2goserver-pyhoca && make $@


