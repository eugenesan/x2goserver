# X2Go Server
This document provides an overview of the sources of the X2Go Server project and its codebase.
The most of different folders are documented with README.md files, as well. The goal of this
documentation is to provide a quick overview of what is where and how the different components
interact.

 * debian

   This folder contains all the stuff that is needed to build the Debian package.

 * x2goserver

   This folder contains the X2Go Server core component. Look into this folder's README.md file.

 * x2goserver-compat

   This folder contains the compatibility scripts.

 * x2goserver-extensions

   This folder contains the extensions to the X2Go Server's core component. The x2goserver-run-extensions
   is called from within a number of X2Go Server core scripts.

 * x2goserver-fmbindings

   X2Go wrapper for Browsing X2Go Shared Folders

 * x2goserver-printing

   This folder contains the X2Go print jobs library.

 * x2goserver-pyhoca

   This folder contains the pyhoca extension for including the pyhoca libraries from the pyhoca libraries.
   The approach is to move everything provided in this package over to one of the other components (once
   new ideas have been accepted by the other developers).

 * x2goserver-xsession

   This folder contains the project for fiddling around with Xsession files of your own system and
   the X2Go Server's Xsession files.

 * INSTALL

   This file contains installation instructions for building and installing it from a tarball.

 * Makefile

   This file is used by [http://www.gnu.org/software/make/manual/make.html](make) to build and install the code with the appropriate compiler.

 * Makefile.docupload

   This file is used by [http://www.gnu.org/software/make/manual/make.html](make) to build and upload the x2goserver documentation.

 * UNINSTALL

   This File contains instructions for uninstalling X2GO Server in case it was installed via tarball.

