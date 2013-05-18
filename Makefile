#!/usr/bin/make -f

RM_FILE=rm -f
RM_DIR=rmdir -p --ignore-fail-on-non-empty

DESTDIR=
PREFIX ?= /usr/local
ETCDIR=/etc/x2go
LIBDIR=$(PREFIX)/lib/x2go
SHAREDIR=$(PREFIX)/share/x2go

all: build

build: build-arch build-indep

# make man2html build available from project's base folder...
build_man2html:
	$(MAKE) -C x2goserver $@
	$(MAKE) -C x2goserver-printing $@
	$(MAKE) -C x2goserver-compat $@
	$(MAKE) -C x2goserver-extensions $@
	$(MAKE) -C x2goserver-xsession $@
	$(MAKE) -C x2goserver-fmbindings $@
	$(MAKE) -C x2goserver-pyhoca $@

clean:
	$(MAKE) -C x2goserver $@
	$(MAKE) -C x2goserver-printing $@
	$(MAKE) -C x2goserver-compat $@
	$(MAKE) -C x2goserver-extensions $@
	$(MAKE) -C x2goserver-xsession $@
	$(MAKE) -C x2goserver-fmbindings $@
	$(MAKE) -C x2goserver-pyhoca $@

build-arch:
	$(MAKE) -C x2goserver $@
	$(MAKE) -C x2goserver-printing $@
	$(MAKE) -C x2goserver-compat $@
	$(MAKE) -C x2goserver-extensions $@
	$(MAKE) -C x2goserver-xsession $@
	$(MAKE) -C x2goserver-fmbindings $@
	$(MAKE) -C x2goserver-pyhoca $@

build-indep:
	$(MAKE) -C x2goserver $@
	$(MAKE) -C x2goserver-printing $@
	$(MAKE) -C x2goserver-compat $@
	$(MAKE) -C x2goserver-extensions $@
	$(MAKE) -C x2goserver-xsession $@
	$(MAKE) -C x2goserver-fmbindings $@
	$(MAKE) -C x2goserver-pyhoca $@

install:
	$(MAKE) -C x2goserver $@
	$(MAKE) -C x2goserver-printing $@
	$(MAKE) -C x2goserver-compat $@
	$(MAKE) -C x2goserver-extensions $@
	$(MAKE) -C x2goserver-xsession $@
	$(MAKE) -C x2goserver-fmbindings $@
	$(MAKE) -C x2goserver-pyhoca $@

uninstall:
	$(MAKE) -C x2goserver-printing $@
	$(MAKE) -C x2goserver-compat $@
	$(MAKE) -C x2goserver-xsession $@
	$(MAKE) -C x2goserver-fmbindings $@
	$(MAKE) -C x2goserver-pyhoca $@
	$(MAKE) -C x2goserver-extensions $@
	$(MAKE) -C x2goserver $@
	if test -d $(DESTDIR)$(LIBDIR); then $(RM_DIR) $(DESTDIR)$(LIBDIR); fi
	if test -d $(DESTDIR)$(SHAREDIR)/x2gofeature.d; then $(RM_DIR) $(DESTDIR)$(SHAREDIR)/x2gofeature.d; fi
	if test -d $(DESTDIR)$(SHAREDIR); then $(RM_DIR) $(DESTDIR)$(SHAREDIR); fi
	if test -d $(DESTDIR)$(ETCDIR); then $(RM_DIR) $(DESTDIR)$(ETCDIR); fi
