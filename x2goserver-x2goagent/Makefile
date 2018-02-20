#!/usr/bin/make -f

SRC_DIR=$(CURDIR)
SHELL=/bin/bash

INSTALL_DIR=install -d -o root -g root -m 755
INSTALL_FILE=install -o root -g root -m 644
INSTALL_PROGRAM=install -o root -g root -m 755
INSTALL_SYMLINK=ln -s -f

RM_FILE=rm -f
RM_DIR=rmdir -p --ignore-fail-on-non-empty

DESTDIR ?=
PREFIX ?= /usr/local
ETCDIR=/etc/x2go
BINDIR=$(PREFIX)/bin
LIBDIR=$(PREFIX)/lib/x2go
NXLIBDIR ?= $(LIBDIR)/../nx
MANDIR=$(PREFIX)/share/man
SHAREDIR=$(PREFIX)/share/x2go

BIN_SCRIPTS=$(shell cd bin && echo *)
FEATURE_SCRIPTS=$(shell cd share/x2go/x2gofeature.d && echo *.features)

man_pages = `cd man && find * -type f`

MAN2HTML_BIN  = $(shell which man2html)
MAN2HTML_SRC  = man
MAN2HTML_DEST = .build_man2html/html

all: clean build

build: build-arch build-indep

build-arch:

build-indep: build_man2html

build_man2html:
	if [ -n "$(MAN2HTML_BIN)" ]; then \
	    mkdir -p $(MAN2HTML_DEST); \
	    for man_page in $(man_pages); do mkdir -p `dirname $(MAN2HTML_DEST)/$$man_page`; done; \
	    for man_page in $(man_pages); do $(MAN2HTML_BIN) $(MAN2HTML_SRC)/$$man_page > $(MAN2HTML_DEST)/$$man_page.html; done; \
	fi

clean: clean_man2html

clean_man2html:
	rm -rf `dirname $(MAN2HTML_DEST)`

install: install_scripts install_config install_data install_man install_version

install_scripts:
	$(INSTALL_DIR) $(DESTDIR)$(BINDIR)
	$(INSTALL_PROGRAM) bin/x2goagent $(DESTDIR)$(BINDIR)/
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/x2gofeature.d
	$(INSTALL_PROGRAM) share/x2go/x2gofeature.d/*.features $(DESTDIR)$(SHAREDIR)/x2gofeature.d/
	$(INSTALL_DIR) $(DESTDIR)$(NXLIBDIR)/bin/
	$(INSTALL_SYMLINK) nxagent $(DESTDIR)$(NXLIBDIR)/bin/x2goagent

install_data:
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/../pixmaps/
	$(INSTALL_FILE) share/pixmaps/x2go.xpm $(DESTDIR)$(SHAREDIR)/../pixmaps/

install_config:
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/
	$(INSTALL_FILE) etc/x2goagent.options $(DESTDIR)$(ETCDIR)/
	$(INSTALL_FILE) etc/x2goagent.keyboard $(DESTDIR)$(ETCDIR)/
	$(INSTALL_FILE) etc/keystrokes.cfg $(DESTDIR)$(ETCDIR)/

install_man:
	$(INSTALL_DIR) $(DESTDIR)$(MANDIR)
	$(INSTALL_DIR) $(DESTDIR)$(MANDIR)/man1
	$(INSTALL_FILE) man/man1/*.1           $(DESTDIR)$(MANDIR)/man1
	gzip -f $(DESTDIR)$(MANDIR)/man1/x2go*.1

install_version:
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/versions
	$(INSTALL_SYMLINK) ../../nx/VERSION.nxagent $(DESTDIR)$(SHAREDIR)/versions/VERSION.x2goserver-x2goagent

uninstall: uninstall_scripts uninstall_config uninstall_data uninstall_man uninstall_version

uninstall_scripts:
	for file in $(BIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(BINDIR)/$$file; done
	for file in x2goagent; do $(RM_FILE) $(DESTDIR)$(NXLIBDIR)/$$file; done
	for file in $(FEATURE_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(SHAREDIR)/x2gofeature.d/$$file; done

uninstall_data:
	cd share && for file in pixmaps/x2go.xpm; do \
	    $(RM_FILE) $(DESTDIR)$(SHAREDIR)/../$$file; \
	    $(RM_DIR) $(shell dirname $(DESTDIR)$(SHAREDIR)/../$$file); \
	done

uninstall_config:
	$(RM_FILE) $(DESTDIR)$(ETCDIR)/x2goagent.options
	$(RM_FILE) $(DESTDIR)$(ETCDIR)/x2goagent.keyboard
	$(RM_FILE) $(DESTDIR)$(ETCDIR)/keystrokes.cfg
	$(RM_DIR)  $(DESTDIR)$(ETCDIR) || true

uninstall_man:
	for file in $(BIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(MANDIR)/man1/$$file.1.gz; done
	$(RM_DIR)  $(DESTDIR)$(MANDIR) || true

uninstall_version:
	$(RM_FILE) $(DESTDIR)$(SHAREDIR)/versions/VERSION.x2goserver-x2goagent
	$(RM_DIR)  $(DESTDIR)$(SHAREDIR)/versions || true
