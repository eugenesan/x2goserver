#!/usr/bin/make -f

SRC_DIR=$(CURDIR)
SHELL=/bin/bash

INSTALL_DIR=install -d -o root -g root -m 755
INSTALL_FILE=install -o root -g root -m 644
INSTALL_SYMLINK=ln -s -f
INSTALL_PROGRAM=install -o root -g root -m 755

RM_FILE=rm -f
RM_DIR=rmdir -p --ignore-fail-on-non-empty

DESTDIR ?=
PREFIX ?= /usr/local
ETCDIR=/etc/x2go
#BINDIR=$(PREFIX)/bin
#SBINDIR=$(PREFIX)/sbin
#LIBDIR=$(PREFIX)/lib/x2go
MANDIR=$(PREFIX)/share/man
SHAREDIR=$(PREFIX)/share/x2go

XSESSIONDIR ?= /etc/X11/Xsession.d
XSESSIONOPTIONFILE ?= /etc/X11/Xsession.options
XINITRCDIR ?= /etc/X11/xinit/xinitrc.d
XCLIENTSDIR ?= /etc/X11/xinit/Xclients.d

ETC_FILES=$(shell cd etc && echo *)
FEATURE_SCRIPTS=$(shell cd share/x2gofeature.d && echo *.features)

all: clean build

build: build-indep

build-indep: build_man2html

build-arch:

build_man2html:
#	mkdir -p $(MAN2HTML_DEST)
#	for man_page in $(man_pages); do mkdir -p `dirname $(MAN2HTML_DEST)/$$man_page`; done
#	for man_page in $(man_pages); do $(MAN2HTML_BIN) $(MAN2HTML_SRC)/$$man_page > $(MAN2HTML_DEST)/$$man_page.html; done

clean: clean_man2html

clean_man2html:
#	rm -rf `dirname $(MAN2HTML_DEST)`

install: install_scripts install_config install_man install_version

install_scripts:
#	$(INSTALL_DIR) $(DESTDIR)$(BINDIR)
#	$(INSTALL_DIR) $(DESTDIR)$(SBINDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/x2gofeature.d
#	$(INSTALL_PROGRAM) bin/*                $(DESTDIR)$(BINDIR)/
#	$(INSTALL_PROGRAM) sbin/*               $(DESTDIR)$(SBINDIR)/
	$(INSTALL_PROGRAM) share/x2gofeature.d/*.features $(DESTDIR)$(SHAREDIR)/x2gofeature.d/

install_config:
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)
#       provide target dirs for X11 related symlinks
	$(INSTALL_PROGRAM) etc/Xsession                 $(DESTDIR)$(ETCDIR)/
	$(INSTALL_SYMLINK) /etc/X11/Xresources          $(DESTDIR)$(ETCDIR)/
	if [ -e /etc/debian_version ]; if [ -e $(XSESSIONOPTIONFILE) ]; then $(INSTALL_SYMLINK) $(XSESSIONOPTIONFILE) $(DESTDIR)$(ETCDIR)/Xsession.options; else touch $(DESTDIR)$(ETCDIR)/Xsession.options; fi; fi
	if [ -e /etc/debian_version ]; if [ -d $(XSESSIONDIR) ]; then $(INSTALL_SYMLINK) $(XSESSIONDIR) $(DESTDIR)$(ETCDIR)/Xsession.d; else $(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/Xsession.d; fi; fi
	if [ -e /etc/redhat-release ]; if [ -d $(XINITRCDIR) ]; then $(INSTALL_SYMLINK) $(XINITRCDIR) $(DESTDIR)$(ETCDIR)/xinitrc.d; else $(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/xinitrc.d; fi; fi
	if [ -e /etc/redhat-release ]; if [ -d $(XCLIENTSDIR) ]; then $(INSTALL_SYMLINK) $(XCLIENTSDIR) $(DESTDIR)$(ETCDIR)/Xclients.d; else $(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/Xclients.d; fi; fi

install_man:
#	$(INSTALL_DIR) $(DESTDIR)$(MANDIR)
#	$(INSTALL_DIR) $(DESTDIR)$(MANDIR)/man8
#	$(INSTALL_FILE) man/man8/*.8           $(DESTDIR)$(MANDIR)/man8
#	gzip -f $(DESTDIR)$(MANDIR)/man8/x2go*.8

install_version:
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/versions
	$(INSTALL_FILE) VERSION.x2goserver-xsession     $(DESTDIR)$(SHAREDIR)/versions/VERSION.x2goserver-xsession

uninstall: uninstall_scripts uninstall_config uninstall_man uninstall_version

uninstall_scripts:
#	for file in $(BIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(BINDIR)/$$file; done
#	for file in $(SBIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(SBINDIR)/$$file; done
	for file in $(FEATURE_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(SHAREDIR)/x2gofeature.d/$$file; done

uninstall_config:
	for file in $(ETC_FILES); do $(RM_FILE) $(DESTDIR)$(ETCDIR)/$$file; done

uninstall_man:
#	for file in $(BIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(MANDIR)/man8/$$file.8.gz; done
#	for file in $(SBIN_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(MANDIR)/man8/$$file.8.gz; done
#	$(RM_DIR)  $(DESTDIR)$(MANDIR) || true

uninstall_version:
	$(RM_FILE) $(DESTDIR)$(SHAREDIR)/versions/VERSION.x2goserver-xsession
	$(RM_DIR)  $(DESTDIR)$(SHAREDIR)/versions || true
