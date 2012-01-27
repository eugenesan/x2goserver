#!/usr/bin/make -f

all: build

build: build-arch build-indep

# make man2html build available from project's base folder...
build_man2html:
	-$(MAKE) -C x2goserver $@
	-$(MAKE) -C x2goserver-printing $@
	-$(MAKE) -C x2goserver-compat $@
	-$(MAKE) -C x2goserver-extensions $@
	-$(MAKE) -C x2goserver-xsession $@
	-$(MAKE) -C x2goserver-pyhoca $@

clean:
	-$(MAKE) -C x2goserver $@
	-$(MAKE) -C x2goserver-printing $@
	-$(MAKE) -C x2goserver-compat $@
	-$(MAKE) -C x2goserver-extensions $@
	-$(MAKE) -C x2goserver-xsession $@
	-$(MAKE) -C x2goserver-pyhoca $@

build-arch:
	-$(MAKE) -C x2goserver $@
	-$(MAKE) -C x2goserver-printing $@
	-$(MAKE) -C x2goserver-compat $@
	-$(MAKE) -C x2goserver-extensions $@
	-$(MAKE) -C x2goserver-xsession $@
	-$(MAKE) -C x2goserver-pyhoca $@

build-indep:
	-$(MAKE) -C x2goserver $@
	-$(MAKE) -C x2goserver-printing $@
	-$(MAKE) -C x2goserver-compat $@
	-$(MAKE) -C x2goserver-extensions $@
	-$(MAKE) -C x2goserver-xsession $@
	-$(MAKE) -C x2goserver-pyhoca $@

install:
	-$(MAKE) -C x2goserver $@
	-$(MAKE) -C x2goserver-printing $@
	-$(MAKE) -C x2goserver-compat $@
	-$(MAKE) -C x2goserver-extensions $@
	-$(MAKE) -C x2goserver-xsession $@
	-$(MAKE) -C x2goserver-pyhoca $@

uninstall:
	-$(MAKE) -C x2goserver $@
	-$(MAKE) -C x2goserver-printing $@
	-$(MAKE) -C x2goserver-compat $@
	-$(MAKE) -C x2goserver-extensions $@
	-$(MAKE) -C x2goserver-xsession $@
	-$(MAKE) -C x2goserver-pyhoca $@
