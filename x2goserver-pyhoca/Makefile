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
#SBIN_SCRIPTS=$(shell cd sbin && echo *)
#LIB_FILES=$(shell cd lib && echo *)
FEATURE_SCRIPTS=$(shell cd share/x2gofeature.d && echo *.features)

#man_pages = `cd man && find * -type f`

#MAN2HTML_BIN  = man2html
#MAN2HTML_SRC  = man
#MAN2HTML_DEST = .build_man2html/html

all: clean build

build: build-arch build-indep

build-arch:

build-indep: build_man2html

build_man2html:

clean: clean_man2html

clean_man2html:

install: install_scripts install_config install_man install_version

install_scripts:

install_config:

install_man:

install_version:
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/versions
	$(INSTALL_FILE) VERSION.x2goserver-pyhoca     $(DESTDIR)$(SHAREDIR)/versions/VERSION.x2goserver-pyhoca

uninstall: uninstall_scripts uninstall_config uninstall_man uninstall_version

uninstall_scripts:

uninstall_config:

uninstall_man:

uninstall_version:
	$(RM_FILE) $(DESTDIR)$(SHAREDIR)/versions/VERSION.x2goserver-pyhoca
	$(RM_DIR)  $(DESTDIR)$(SHAREDIR)/versions || true
