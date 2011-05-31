#!/usr/bin/make -f

all: build

build: build-indep

clean:
	cd x2goserver && make $@
	cd x2goserver-extras && make $@

build-indep:
	cd x2goserver && make $@
	cd x2goserver-extras && make $@

install:
	cd x2goserver && make $@
	cd x2goserver-extras && make $@

uninstall:
	cd x2goserver && make $@
	cd x2goserver-extras && make $@


