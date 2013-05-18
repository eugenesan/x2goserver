#!/usr/bin/make -f

SRC_DIR=$(CURDIR)
SHELL=/bin/bash

CC      ?= gcc
CFLAGS  += -fPIE
LDFLAGS += -pie

INSTALL_DIR=install -d -o root -g root -m 755
INSTALL_FILE=install -o root -g root -m 644
INSTALL_PROGRAM=install -o root -g root -m 755

RM_FILE=rm -f
RM_DIR=rmdir -p --ignore-fail-on-non-empty

DESTDIR=
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

MAN2HTML_BIN  = man2html
MAN2HTML_SRC  = man
MAN2HTML_DEST = .build_man2html/html

all: clean build

build: build-arch build-indep

build-arch: build_setgidwrappers

build_setgidwrappers:
	$(CC) $(CFLAGS) $(LDFLAGS) -DTRUSTED_BINARY=\"$(DESTDIR)$(LIBDIR)/x2gosqlitewrapper.pl\" -o x2gosqlitewrapper x2gosqlitewrapper.c

build-indep: build_man2html

build_man2html:
	mkdir -p $(MAN2HTML_DEST)
	for man_page in $(man_pages); do mkdir -p `dirname $(MAN2HTML_DEST)/$$man_page`; done
	for man_page in $(man_pages); do $(MAN2HTML_BIN) $(MAN2HTML_SRC)/$$man_page > $(MAN2HTML_DEST)/$$man_page.html; done

clean: clean_arch clean_man2html

clean_arch:
	rm -f x2gosqlitewrapper

clean_man2html:
	rm -Rf `dirname $(MAN2HTML_DEST)`

install: install_scripts install_config install_man install_version

install_scripts:
	$(INSTALL_DIR) $(DESTDIR)$(BINDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SBINDIR)
	$(INSTALL_DIR) $(DESTDIR)$(LIBDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/x2gofeature.d
	$(INSTALL_PROGRAM) bin/*                $(DESTDIR)$(BINDIR)/
	$(INSTALL_PROGRAM) sbin/*               $(DESTDIR)$(SBINDIR)/
	$(INSTALL_PROGRAM) x2gosqlitewrapper       $(DESTDIR)$(LIBDIR)/
	$(INSTALL_PROGRAM) lib/*                   $(DESTDIR)$(LIBDIR)/
	$(INSTALL_PROGRAM) share/x2gofeature.d/*.features $(DESTDIR)$(SHAREDIR)/x2gofeature.d/
	chmod a-x $(DESTDIR)$(LIBDIR)/*.pm
	getent group x2gouser &>/dev/null && chown root:x2gouser $(DESTDIR)$(LIBDIR)/x2gosqlitewrapper || true
	chmod 2755 $(DESTDIR)$(LIBDIR)/x2gosqlitewrapper

install_config:
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/x2gosql
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/x2gosql/passwords
	$(INSTALL_FILE) etc/x2goserver.conf     $(DESTDIR)$(ETCDIR)/
	$(INSTALL_FILE) etc/x2goagent.options   $(DESTDIR)$(ETCDIR)/
	$(INSTALL_FILE) etc/x2gosql/sql         $(DESTDIR)$(ETCDIR)/x2gosql
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/x2go_logout.d
	$(INSTALL_FILE) etc/x2go_logout     $(DESTDIR)$(ETCDIR)/
	$(INSTALL_FILE) etc/x2go_logout.d/* $(DESTDIR)$(ETCDIR)/x2go_logout.d/

install_man:
	$(INSTALL_DIR) $(DESTDIR)$(MANDIR)
	$(INSTALL_DIR) $(DESTDIR)$(MANDIR)/man8
	$(INSTALL_FILE) man/man8/*.8           $(DESTDIR)$(MANDIR)/man8
	gzip -f $(DESTDIR)$(MANDIR)/man8/x2go*.8

install_version:
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/versions
	$(INSTALL_FILE) VERSION.x2goserver     $(DESTDIR)$(SHAREDIR)/versions/VERSION.x2goserver

uninstall: uninstall_scripts uninstall_config uninstall_man uninstall_version

uninstall_scripts:
	for file in $(BIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(BINDIR)/$$file; done
	for file in $(SBIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(SBINDIR)/$$file; done
	for file in $(LIB_FILES); do $(RM_FILE) $(DESTDIR)$(LIBDIR)/$$file; done
	for file in $(FEATURE_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(SHAREDIR)/x2gofeature.d/$$file; done
	$(RM_FILE) $(DESTDIR)$(LIBDIR)/x2gosqlitewrapper
	$(RM_DIR) $(DESTDIR)$(LIBDIR) || true
	$(RM_DIR) $(DESTDIR)$(SHAREDIR)/x2gofeature.d || true
	$(RM_DIR) $(DESTDIR)$(SHAREDIR) || true

uninstall_config:
	$(RM_FILE) $(DESTDIR)$(ETCDIR)/x2goserver.conf
	$(RM_FILE) $(DESTDIR)$(ETCDIR)/x2gosql/sql
	$(RM_DIR)  $(DESTDIR)$(ETCDIR) || true
	$(RM_DIR)  $(DESTDIR)$(ETCDIR)/x2gosql/passwords || true
	$(RM_DIR)  $(DESTDIR)$(ETCDIR)/x2gosql || true

uninstall_man:
	for file in $(BIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(MANDIR)/man8/$$file.8.gz; done
	for file in $(SBIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(MANDIR)/man8/$$file.8.gz; done
	$(RM_DIR)  $(DESTDIR)$(MANDIR) || true

uninstall_version:
	$(RM_FILE) $(DESTDIR)$(SHAREDIR)/versions/VERSION.x2goserver
	$(RM_DIR)  $(DESTDIR)$(SHAREDIR)/versions || true
