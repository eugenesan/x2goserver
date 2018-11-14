#!/usr/bin/make -f

SRC_DIR=$(CURDIR)
SHELL=/bin/bash

INSTALL_DIR=install -d -o root -g root -m 755
INSTALL_FILE=install -o root -g root -m 644
INSTALL_PROGRAM=install -o root -g root -m 755

RM_FILE=rm -f
RM_DIR=rmdir -p --ignore-fail-on-non-empty

DESTDIR ?=
PREFIX ?= /usr/local
ETCDIR=/etc/x2go
BINDIR=$(PREFIX)/bin
LIBDIR=$(PREFIX)/lib/x2go
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

install: install_scripts install_config install_man install_version

install_scripts:
	$(INSTALL_DIR) $(DESTDIR)$(BINDIR)
	$(INSTALL_PROGRAM) bin/x2go* $(DESTDIR)$(BINDIR)/
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/desktopsharing
	$(INSTALL_FILE) etc/desktopsharing/settings $(DESTDIR)$(ETCDIR)/desktopsharing/
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/x2gofeature.d
	$(INSTALL_PROGRAM) share/x2gofeature.d/*.features $(DESTDIR)$(SHAREDIR)/x2gofeature.d/

install_config:

install_man:
	$(INSTALL_DIR) $(DESTDIR)$(MANDIR)
	$(INSTALL_DIR) $(DESTDIR)$(MANDIR)/man8
	$(INSTALL_FILE) man/man8/*.8           $(DESTDIR)$(MANDIR)/man8
	gzip -f $(DESTDIR)$(MANDIR)/man8/x2go*.8

install_version:
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/versions
	$(INSTALL_FILE) VERSION.x2goserver-desktopsharing     $(DESTDIR)$(SHAREDIR)/versions/

uninstall: uninstall_scripts uninstall_config uninstall_man uninstall_version

uninstall_scripts:
	for file in $(FEATURE_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(SHAREDIR)/x2gofeature.d/$$file; done

uninstall_config:

uninstall_config:
	$(RM_FILE) $(DESTDIR)$(ETCDIR)/desktopsharing/settings
	$(RM_DIR)  $(DESTDIR)$(ETCDIR)/desktopsharing || true
	$(RM_DIR)  $(DESTDIR)$(ETCDIR) || true

uninstall_man:
	for file in $(BIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(MANDIR)/man8/$$file.8.gz; done
	for file in $(SBIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(MANDIR)/man8/$$file.8.gz; done
	$(RM_DIR)  $(DESTDIR)$(MANDIR) || true

uninstall_version:
	$(RM_FILE) $(DESTDIR)$(SHAREDIR)/versions/VERSION.x2goserver-desktopsharing
	$(RM_DIR)  $(DESTDIR)$(SHAREDIR)/versions || true
