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

clean:
	cd x2goserver && make $@
	cd x2goserver-printing && make $@
	cd x2goserver-compat && make $@
	cd x2goserver-extensions && make $@
	cd x2goserver-xsession && make $@

build-arch:
	cd x2goserver && make $@
	cd x2goserver-printing && make $@
	cd x2goserver-compat && make $@
	cd x2goserver-extensions && make $@
	cd x2goserver-xsession && make $@

build-indep:
	cd x2goserver && make $@
	cd x2goserver-printing && make $@
	cd x2goserver-compat && make $@
	cd x2goserver-extensions && make $@
	cd x2goserver-xsession && make $@

install:
	cd x2goserver && make $@
	cd x2goserver-printing && make $@
	cd x2goserver-compat && make $@
	cd x2goserver-extensions && make $@
	cd x2goserver-xsession && make $@

uninstall:
	cd x2goserver-extensions && make $@
	cd x2goserver-compat && make $@
	cd x2goserver-printing && make $@
	cd x2goserver && make $@
	cd x2goserver-xsession && make $@


