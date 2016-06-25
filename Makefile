#!/usr/bin/make -f

RM_FILE=rm -f
RM_DIR=rmdir -p --ignore-fail-on-non-empty

DESTDIR ?=
PREFIX ?= /usr/local
ETCDIR=/etc/x2go
LIBDIR=$(PREFIX)/lib/x2go
SHAREDIR=$(PREFIX)/share/x2go

PERL ?= /usr/bin/perl
PERL_INSTALLDIRS ?= vendor

all: build

build: build-arch build-indep

# make man2html build available from project's base folder...
build_man2html:
	$(MAKE) -C x2goserver-common $@
	$(MAKE) -C x2goserver $@
	$(MAKE) -C libx2go-server-db-perl $@
	$(MAKE) -C x2goserver-x2goagent $@
	$(MAKE) -C x2goserver-printing $@
	$(MAKE) -C x2goserver-extensions $@
	$(MAKE) -C x2goserver-xsession $@
	$(MAKE) -C x2goserver-fmbindings $@

clean:
	-$(MAKE) -f Makefile.perl clean
	$(MAKE) -C x2goserver-common $@
	$(MAKE) -C x2goserver $@
	$(MAKE) -C libx2go-server-db-perl $@
	$(MAKE) -C x2goserver-x2goagent $@
	$(MAKE) -C x2goserver-printing $@
	$(MAKE) -C x2goserver-extensions $@
	$(MAKE) -C x2goserver-xsession $@
	$(MAKE) -C x2goserver-fmbindings $@

distclean:
	-$(MAKE) -f Makefile.perl realclean
	$(MAKE) -C x2goserver-common clean
	$(MAKE) -C x2goserver clean
	$(MAKE) -C libx2go-server-db-perl clean
	$(MAKE) -C x2goserver-x2goagent clean
	$(MAKE) -C x2goserver-printing clean
	$(MAKE) -C x2goserver-extensions clean
	$(MAKE) -C x2goserver-xsession clean
	$(MAKE) -C x2goserver-fmbindings clean

build-arch:
	$(MAKE) -C x2goserver-common $@
	$(MAKE) -C x2goserver $@
	$(MAKE) -C libx2go-server-db-perl $@
	$(MAKE) -C x2goserver-x2goagent $@
	$(MAKE) -C x2goserver-printing $@
	$(MAKE) -C x2goserver-extensions $@
	$(MAKE) -C x2goserver-xsession $@
	$(MAKE) -C x2goserver-fmbindings $@

build-indep:
	$(PERL) Makefile.PL INSTALLDIRS=$(PERL_INSTALLDIRS)
	$(MAKE) -f Makefile.perl
	$(MAKE) -C x2goserver-common $@
	$(MAKE) -C x2goserver $@
	$(MAKE) -C libx2go-server-db-perl $@
	$(MAKE) -C x2goserver-x2goagent $@
	$(MAKE) -C x2goserver-printing $@
	$(MAKE) -C x2goserver-extensions $@
	$(MAKE) -C x2goserver-xsession $@
	$(MAKE) -C x2goserver-fmbindings $@

install:
	$(MAKE) -f Makefile.perl pure_install
	$(MAKE) -C x2goserver-common $@
	$(MAKE) -C x2goserver $@
	$(MAKE) -C libx2go-server-db-perl $@
	$(MAKE) -C x2goserver-x2goagent $@
	$(MAKE) -C x2goserver-printing $@
	$(MAKE) -C x2goserver-extensions $@
	$(MAKE) -C x2goserver-xsession $@
	$(MAKE) -C x2goserver-fmbindings $@

uninstall:
	$(MAKE) -C x2goserver-printing $@
	$(MAKE) -C x2goserver-x2goagent $@
	$(MAKE) -C x2goserver-xsession $@
	$(MAKE) -C x2goserver-fmbindings $@
	$(MAKE) -C x2goserver-extensions $@
	$(MAKE) -f Makefile.perl uninstall
	$(MAKE) -C libx2go-server-db-perl $@
	$(MAKE) -C x2goserver $@
	$(MAKE) -C x2goserver-common $@
	if test -d $(DESTDIR)$(LIBDIR); then $(RM_DIR) $(DESTDIR)$(LIBDIR); fi
	if test -d $(DESTDIR)$(SHAREDIR)/x2gofeature.d; then $(RM_DIR) $(DESTDIR)$(SHAREDIR)/x2gofeature.d; fi
	if test -d $(DESTDIR)$(SHAREDIR); then $(RM_DIR) $(DESTDIR)$(SHAREDIR); fi
	if test -d $(DESTDIR)$(ETCDIR); then $(RM_DIR) $(DESTDIR)$(ETCDIR); fi
