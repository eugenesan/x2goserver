# x2goserver  
This document provides an overview of the sources of the x2goserver project and it's codebase.
The most of different folder are documented with README.md files as well. The goal of this 
documentation is to provice a quick overview of what is where how the differen components 
interact.

 * debian 

   This folder contains all the stuff thats needed to build the debian package.

 * x2goserver

   This folder contains the x2goserver core component. Look into this folders README.md file.

 * x2goserver-compat

   This folder contains the compatibility scripts.

 * x2goserver-extensions
   
   This folder contains the extensions to the x2goservers core component. The x2goserver-run-extensions 
   is called from within a number of X2Go Server core scripts.

 * x2goserver-fmbindings

   X2Go wrapper for Browsing X2Go Shared Folders

 * x2goserver-printing

   This folder contains the X2Go print jobs library.

 * x2goserver-pyhoca

   This folder contains the pyhoca extension for including the pyhoca libraries from the pyhoca libraries.

 * x2goserver-xsession

   This folder contains the project for fiddling arround with Xsession files of your own system and 
   the remote servers Xsession files.

 * INSTALL
 
   This File contains installation instructions for building and installing it from a tarball.

 * Makefile 

   This file is used by [http://www.gnu.org/software/make/manual/make.html](make) to build and install the code with the appropriate compiler.

 * Makefile.docupload
   
   This file is used by [http://www.gnu.org/software/make/manual/make.html](make) to build and upload the x2goserver documentation.

 * UNINSTALL

   This file is used by [http://www.gnu.org/software/make/manual/make.html](make) to uninstall all previously installed components of the x2goserver.

