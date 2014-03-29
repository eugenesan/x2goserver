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
BINDIR=$(PREFIX)/bin
SBINDIR=$(PREFIX)/sbin
LIBDIR=$(PREFIX)/lib/x2go
MANDIR=$(PREFIX)/share/man
SHAREDIR=$(PREFIX)/share/x2go

XSESSIONDIR ?= /etc/X11/Xsession.d
XSESSIONOPTIONFILE ?= /etc/X11/Xsession.options
XINITRCDIR ?= /etc/X11/xinit/xinitrc.d
XCLIENTSDIR ?= /etc/X11/xinit/Xclients.d

ETC_FILES=$(shell cd etc && echo *)
FEATURE_SCRIPTS=$(shell cd share/x2gofeature.d && echo *.features)

all: clean build

build: build-arch build-indep

build-arch:

build-indep: build_man2html

build_man2html:

clean: clean_man2html

clean_man2html:

install: install_scripts install_config install_man install_version

install_scripts:
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/x2gofeature.d
	$(INSTALL_PROGRAM) share/x2gofeature.d/*.features $(DESTDIR)$(SHAREDIR)/x2gofeature.d/

install_config:
	$(INSTALL_DIR) $(DESTDIR)$(ETCDIR)
#       provide target dirs for X11 related symlinks
	$(INSTALL_PROGRAM) etc/Xsession                 $(DESTDIR)$(ETCDIR)/
	$(INSTALL_SYMLINK) /etc/X11/Xresources          $(DESTDIR)$(ETCDIR)/
	if [ -e /etc/debian_version ]; then if [ -e $(XSESSIONOPTIONFILE) ]; then $(INSTALL_SYMLINK) $(XSESSIONOPTIONFILE) $(DESTDIR)$(ETCDIR)/Xsession.options; else touch $(DESTDIR)$(ETCDIR)/Xsession.options; fi; fi
	if [ -e /etc/debian_version ]; then if [ -d $(XSESSIONDIR) ]; then $(INSTALL_SYMLINK) $(XSESSIONDIR) $(DESTDIR)$(ETCDIR)/Xsession.d; else $(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/Xsession.d; fi; fi
	if [ -e /etc/redhat-release ]; then if [ -d $(XINITRCDIR) ]; then $(INSTALL_SYMLINK) $(XINITRCDIR) $(DESTDIR)$(ETCDIR)/xinitrc.d; else $(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/xinitrc.d; fi; fi
	if [ -e /etc/redhat-release ]; then if [ -d $(XCLIENTSDIR) ]; then $(INSTALL_SYMLINK) $(XCLIENTSDIR) $(DESTDIR)$(ETCDIR)/Xclients.d; else $(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/Xclients.d; fi; fi
	if [ -e /etc/gentoo-release ]; then if [ -d $(XINITRCDIR) ]; then $(INSTALL_SYMLINK) $(XINITRCDIR) $(DESTDIR)$(ETCDIR)/xinitrc.d; else $(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/xinitrc.d; fi; fi
	if [ -e /etc/gentoo-release ]; then if [ -d $(XCLIENTSDIR) ]; then $(INSTALL_SYMLINK) $(XCLIENTSDIR) $(DESTDIR)$(ETCDIR)/Xclients.d; else $(INSTALL_DIR) $(DESTDIR)$(ETCDIR)/Xclients.d; fi; fi

install_man:

install_version:
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)
	$(INSTALL_DIR) $(DESTDIR)$(SHAREDIR)/versions
	$(INSTALL_FILE) VERSION.x2goserver-xsession     $(DESTDIR)$(SHAREDIR)/versions/VERSION.x2goserver-xsession

uninstall: uninstall_scripts uninstall_config uninstall_man uninstall_version

uninstall_scripts:
	for file in $(FEATURE_SCRIPTS); do $(RM_FILE) $(DESTDIR)$(SHAREDIR)/x2gofeature.d/$$file; done

uninstall_config:
	for file in $(ETC_FILES); do $(RM_FILE) $(DESTDIR)$(ETCDIR)/$$file; done

uninstall_man:

uninstall_version:
	$(RM_FILE) $(DESTDIR)$(SHAREDIR)/versions/VERSION.x2goserver-xsession
	$(RM_DIR)  $(DESTDIR)$(SHAREDIR)/versions || true
