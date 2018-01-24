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
SBINDIR=$(PREFIX)/sbin
LIBDIR=$(PREFIX)/lib/x2go
MANDIR=$(PREFIX)/share/man
SHAREDIR=$(PREFIX)/share/x2go

BIN_SCRIPTS=$(shell cd bin && echo *)
SBIN_SCRIPTS=$(shell cd sbin && echo *)
LIB_FILES=$(shell cd lib && echo *)
FEATURE_SCRIPTS=$(shell cd share/x2gofeature.d && echo *.features)

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

clean: clean-arch clean-indep

clean-arch:

clean-indep: clean_man2html

clean_man2html:
	rm -Rf `dirname $(MAN2HTML_DEST)`

install: install_scripts install_config install_man install_version

install_scripts:

install_config:
	$(INSTALL_DIR)  $(DESTDIR)$(ETCDIR)
	$(INSTALL_FILE) etc/x2goserver.conf            $(DESTDIR)$(ETCDIR)/
	$(INSTALL_DIR)  $(DESTDIR)$(ETCDIR)/x2gosql
	$(INSTALL_DIR)  $(DESTDIR)$(ETCDIR)/x2gosql/passwords
	$(INSTALL_FILE) etc/x2gosql/sql                $(DESTDIR)$(ETCDIR)/x2gosql
	$(INSTALL_DIR)  $(DESTDIR)/etc/tmpfiles.d || true
	$(INSTALL_FILE) etc/tmpfiles.d/x2goserver.conf $(DESTDIR)/etc/tmpfiles.d/

install_man:
	$(INSTALL_DIR) $(DESTDIR)$(MANDIR)/man5
	$(INSTALL_FILE) man/man5/*.5           $(DESTDIR)$(MANDIR)/man5
	gzip -f $(DESTDIR)$(MANDIR)/man5/x2go*.5

install_version:
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/versions
	$(INSTALL_FILE) VERSION.x2goserver-common     $(DESTDIR)$(SHAREDIR)/versions/VERSION.x2goserver-common

uninstall: uninstall_scripts uninstall_config uninstall_man uninstall_version

uninstall_scripts:

uninstall_config:
	$(RM_FILE) $(DESTDIR)$(ETCDIR)/x2goserver.conf
	$(RM_FILE) $(DESTDIR)$(ETCDIR)/x2gosql/sql
	$(RM_DIR)  $(DESTDIR)$(ETCDIR)/x2gosql/passwords || true
	$(RM_DIR)  $(DESTDIR)$(ETCDIR)/x2gosql || true
	$(RM_DIR)  $(DESTDIR)$(ETCDIR) || true
	$(RM_FILE) $(DESTDIR)/etc/tmpfiles.d/x2goserver.conf
	$(RM_DIR)  $(DESTDIR)/etc/tmpfiles.d || true

uninstall_man:
	for file in $(BIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(MANDIR)/man5/$$file.5.gz; done
	for file in $(SBIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(MANDIR)/man5/$$file.5.gz; done
	$(RM_DIR)  $(DESTDIR)$(MANDIR) || true

uninstall_version:
	$(RM_FILE) $(DESTDIR)$(SHAREDIR)/versions/VERSION.x2goserver-common
	$(RM_DIR)  $(DESTDIR)$(SHAREDIR)/versions || true
