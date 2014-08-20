#!/usr/bin/perl

# Copyright (C) 2013 X2Go Project - http://wiki.x2go.org
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Copyright (C) 2013  Oleksandr Shneyder <oleksandr.shneyder@obviously-nice.de>
# Copyright (C) 2013  Heinz-Markus Graesing <heinz-m.graesing@obviously-nice.de>
# Copyright (C) 2013  Mike Gabriel <mike.gabriel@das-netzwerkteam.de>

package x2goutils;

use strict;
use Capture::Tiny qw( :all );
use base 'Exporter';
our @EXPORT = ( 'system_capture_merged_output', 'sanitizer', );


# same applies for the sanitizer code shipped in x2goutils.pm
sub sanitizer {
	my $type   = $_[0];
	my $string = $_[1];
	if ($type eq "num") {
		$string =~ s/\D//g;
		if ($string =~ /^([0-9]*)$/) {
			$string = $1;
			return $string;
		} else {return 0;}
	} elsif ($type eq "pnixusername") {
		$string =~ s/[^a-zA-Z0-9\_\-\.]//g;
		if ($string =~ /^([a-zA-Z0-9\_\-\.]*)$/) {
			$string = $1;
			return $string;
		} else {return 0;}
	} elsif ($type eq "x2gosid") {
		$string =~ s/[^a-zA-Z0-9\_\-\$\.\@]//g;
		if ($string =~ /^([a-zA-Z0-9\_\-\$\.\@]*)$/) {
			$string = $1;
			if ($string =~ /^([a-zA-Z\_][a-zA-Z0-9\_\-\.\@]{0,47}[\$]?)\-([\d]{2,4})\-([\d]{9,12})\_[a-zA-Z0-9\_\-]*\_dp[\d]{1,2}$/) {
				if ((length($1) > 0) and (length($1) < 48)){
					return $string;
				} else {return 0;}
			} else {return 0;}
		} else {return 0;}
	} elsif ($type eq "SOMETHINGELSE") {
		return 0;
	} else {
		return 0;
	}
}

sub system_capture_merged_output {
	my $cmd = shift;
	my @args = @_;
	return capture_merged { system( $cmd, @args ); };
}

1;
