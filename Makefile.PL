#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(FIRST_MAKEFILE => 'Makefile.perl',
	      PMLIBDIRS => ['X2Go'],
	      NAME => '',
	      VERSION => '3.2.0.0',
	     );
