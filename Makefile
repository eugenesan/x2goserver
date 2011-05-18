#!/usr/bin/make -f

SRC_DIR=$(CURDIR)
SHELL=/bin/bash

INSTALL_DIR=install -d -o root -g root -m 755
INSTALL_FILE=install -o root -g root -m 644
INSTALL_PROGRAM=install -o root -g root -m 755

RM_FILE=rm -f
RM_DIR=rmdir -p --ignore-fail-on-non-empty

DESTDIR=
PREFIX=/usr/local
ETCDIR=/etc/x2go
BINDIR=$(PREFIX)/bin
SBINDIR=$(PREFIX)/sbin
LIBDIR=$(PREFIX)/lib/x2go

BIN_SCRIPTS=$(shell cd bin && ls)
SBIN_SCRIPTS=$(shell cd sbin && ls)
LIB_FILES=$(shell cd lib && ls)

all:

install:
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/x2gosql
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/x2gosql/passwords
	$(INSTALL_DIR) $(DESTDIR)$(BINDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SBINDIR)
	$(INSTALL_DIR) $(DESTDIR)$(LIBDIR)
	$(INSTALL_PROGRAM) bin/*                $(DESTDIR)$(BINDIR)/
	$(INSTALL_PROGRAM) sbin/*               $(DESTDIR)$(SBINDIR)/
	$(INSTALL_FILE) lib/*                   $(DESTDIR)$(LIBDIR)/
	$(INSTALL_FILE) etc/x2goserver.conf     $(DESTDIR)$(ETCDIR)/
	$(INSTALL_FILE) etc/x2gosql/sql         $(DESTDIR)$(ETCDIR)/x2gosql

uninstall: uninstall_scripts uninstall_config

uninstall_scripts:
	for file in $(BIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(BINDIR)/$$file; done
	for file in $(SBIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(SBINDIR)/$$file; done
	for file in $(LIB_FILES); do $(RM_FILE) $(DESTDIR)$(LIBDIR)/$$file; done
	$(RM_DIR) $(DESTDIR)$(LIBDIR)

uninstall_config:
	$(RM_FILE) $(DESTDIR)$(ETCDIR)/x2goserver.conf
	$(RM_FILE) $(DESTDIR)$(ETCDIR)/x2gosql/sql
	$(RM_DIR)  $(DESTDIR)$(ETCDIR)
	$(RM_DIR)  $(DESTDIR)$(ETCDIR)/x2gosql/passwords
	$(RM_DIR)  $(DESTDIR)$(ETCDIR)/x2gosql
