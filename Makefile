#!/usr/bin/make -f

all: build

build: build-indep

clean:
	cd x2goserver && make $@
	cd x2goserver-extensions && make $@

build-arch:
	cd x2goserver && make $@
	cd x2goserver-extensions && make $@

build-indep:
	cd x2goserver && make $@
	cd x2goserver-extensions && make $@

install:
	cd x2goserver && make $@
	cd x2goserver-extensions && make $@

uninstall:
	cd x2goserver && make $@
	cd x2goserver-extensions && make $@


