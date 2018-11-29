#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(FIRST_MAKEFILE => 'Makefile.perl',
	      PMLIBDIRS => ['X2Go'],
	      NAME => '',
	      VERSION => '4.1.0.4',
	     );
