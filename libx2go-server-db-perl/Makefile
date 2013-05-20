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

DESTDIR ?=
PREFIX ?= /usr/local
ETCDIR=/etc/x2go
BINDIR=$(PREFIX)/bin
SBINDIR=$(PREFIX)/sbin
LIBDIR=$(PREFIX)/lib/x2go
MANDIR=$(PREFIX)/share/man
SHAREDIR=$(PREFIX)/share/x2go

#BIN_SCRIPTS=$(shell cd bin && echo *)
#SBIN_SCRIPTS=$(shell cd sbin && echo *)
LIB_FILES=libx2go-server-db-sqlite3-wrapper libx2go-server-db-sqlite3-wrapper.pl
#FEATURE_SCRIPTS=$(shell cd share/x2gofeature.d && echo *.features)

#man_pages = `cd man && find * -type f`

#MAN2HTML_BIN  = man2html
#MAN2HTML_SRC  = man
#MAN2HTML_DEST = .build_man2html/html

all: clean build

build: build-arch build-indep

build-arch:
	$(CC) $(CFLAGS) $(LDFLAGS) -DTRUSTED_BINARY=\"$(LIBDIR)/libx2go-server-db-sqlite3-wrapper.pl\" -o lib/libx2go-server-db-sqlite3-wrapper src/libx2go-server-db-sqlite3-wrapper.c

build-indep:

clean: clean-arch clean-indep

clean-arch:
	rm -f lib/libx2go-server-db-sqlite3-wrapper

clean-indep:

install: install_scripts install_config

install_scripts:
	$(INSTALL_DIR) $(DESTDIR)$(LIBDIR)
	$(INSTALL_PROGRAM) lib/*                   $(DESTDIR)$(LIBDIR)/
	getent group x2gouser &>/dev/null && chown root:x2gouser $(DESTDIR)$(LIBDIR)/libx2go-server-db-sqlite3-wrapper || true
	chmod 2755 $(DESTDIR)$(LIBDIR)/libx2go-server-db-sqlite3-wrapper

install_config:
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/x2gosql
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/x2gosql/passwords
	$(INSTALL_FILE) etc/x2gosql/sql         $(DESTDIR)$(ETCDIR)/x2gosql

uninstall: uninstall_scripts uninstall_config

uninstall_scripts:
	for file in $(LIB_FILES); do $(RM_FILE) $(DESTDIR)$(LIBDIR)/$$file; done

uninstall_config:
	$(RM_FILE) $(DESTDIR)$(ETCDIR)/x2gosql/sql
	$(RM_DIR)  $(DESTDIR)$(ETCDIR)/x2gosql/passwords || true
	$(RM_DIR)  $(DESTDIR)$(ETCDIR)/x2gosql || true
	$(RM_DIR)  $(DESTDIR)$(ETCDIR) || true
