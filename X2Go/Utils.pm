#!/usr/bin/perl

# Copyright (C) 2007-2015 X2Go Project - http://wiki.x2go.org
# Copyright (C) 2007-2015 Oleksandr Shneyder <oleksandr.shneyder@obviously-nice.de>
# Copyright (C) 2007-2015 Heinz-Markus Graesing <heinz-m.graesing@obviously-nice.de>
# Copyright (C) 2013-2015 Guangzhou Nianguan Electronics Technology Co.Ltd. <opensource@gznianguan.com>
# Copyright (C) 2013-2015 Mike Gabriel <mike.gabriel@das-netzwerkteam.de>
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

package X2Go::Utils;

=head1 NAME

X2Go::Utils - X2Go utilities and helper functions for Perl

=head1 DESCRIPTION

X2Go::Utils Perl package.

=cut

use strict;

use base 'Exporter';

our @EXPORT = ( 'load_module', 'is_true',
                'source_environment', 'clups', 'sanitizer',
                'system_capture_merged_output', 'system_capture_stdout_output',
                'check_x2go_sessionid');

use Sys::Syslog qw( :standard :macros );
use Capture::Tiny qw ( :all );

sub load_module {
	for (@_) {
		(my $file = "$_.pm") =~ s{::}{/}g;
		require $file;
	}
}


sub is_true {
	my $value = shift;
	if ( $value =~ m/(1|yes|Yes|YES|on|On|ON|True|true|TRUE)/ ) {
		return 1
	}
	return 0
}


sub source_environment {
	my $name = shift;

	open my $fh, "<", $name
	     or return -1;

	while (<$fh>) {
		chomp;
		my $line = $_;
		if ( $line =~ m/^#.*/ )
		{
			next;
		}
		my ($k, $v) = split /=/, $line, 2;
		$v =~ s/^(['"])(.*)\1/$2/; #' fix highlighter
		$v =~ s/\$([a-zA-Z]\w*)/$ENV{$1}/g;
		$v =~ s/`(.*?)`/`$1`/ge; #dangerous
		$ENV{$k} = $v;
	}
}


# Over-zealous string sanitizer that makes perl strict and  perl -T happy...
sub sanitizer {
	my $type   = lc($_[0]);
	my $string = $_[1];
	if ($type eq "anumazcs") {
		$string =~ s/[^a-zA-Z0-9]//g;
		if ($string =~ /^([a-zA-Z0-9]*)$/) {
			$string = $1;
			return $string;
		} else {return 0;}
	} elsif ($type eq "anumazlc") {
		$string = lc($string);
		$string =~ s/[^a-z0-9]//g;
		if ($string =~ /^([a-z0-9]*)$/) {
			$string = $1;
			return $string;
		} else {return 0;}
	} elsif ($type eq "num") {
		$string =~ s/\D//g;
		if ($string =~ /^([0-9]*)$/) {
			$string = $1;
			return $string;
		} else {return 0;}
	} elsif ($type eq "pnnum") {
		$string =~ s/[^0-9\+\-]//g;
		if ($string =~ /^([0-9\+\-]*)$/) {
			$string = $1;
			return $string;
		} else {return 0;}
	} elsif ($type eq "anumazcsdaus") {
		$string =~ s/[^a-zA-Z0-9\_\-]//g;
		if ($string =~ /^([a-zA-Z0-9\_\-]*)$/) {
			$string = $1;
			return $string;
		} else {return 0;} 
	} elsif ($type eq "pnixusername") {
		$string =~ s/[^a-zA-Z0-9\.\_\-\@]//g;
		if ($string =~ /^([a-zA-Z0-9\.\_][a-zA-Z0-9\.\_\-\@]*)$/) {
			$string = $1;
			return $string;
		} else {return 0;}
	} elsif ($type eq "x2gosid") {
		$string =~ s/[^a-zA-Z0-9\.\_\-\@]//g;
		if ($string =~ /^([a-zA-Z0-9\.\_\-\@]*)$/) {
			$string = $1;
			if ($string =~ /^([a-zA-Z0-9\.\_][a-zA-Z0-9\.\_\-\@]*)\-([\d]{2,4})\-([\d]{9,12})\_[a-zA-Z0-9\.\_\-]*\_dp[\d]{1,2}$/) {
				return $string;
			} else {return 0;}
		} else {return 0;}
	} elsif ($type eq "SOMETHINGELSE") {
		return 0;
	} else {
		return 0;
	}
}


sub clups {
	my $string = "@_";
	$string =~ s/\n//g;
	$string =~ s/\ //g;
	$string =~ s/\s//g;
	return $string;
}


sub system_capture_stdout_output {
	my $cmd = shift;
	my @args = @_;
	syslog("debug", "executing external command ,,$cmd'' with args: ".join(",", @args));
	my ($stdout, $stderr, @result) = capture { system( $cmd, @args ); };
	return $stdout;
}


sub system_capture_merged_output {
	my $cmd = shift;
	my @args = @_;
	syslog("debug", "executing external command ,,$cmd'' with args: ".join(",", @args));
	return capture_merged { system( $cmd, @args ); };
}

sub check_x2go_sessionid {
	if (sanitizer("x2gosid",$ARGV[0])) {
		return sanitizer("x2gosid",$ARGV[0]);
	} elsif (sanitizer("x2gosid",$ENV{'X2GO_SESSION'})) {
		return sanitizer("x2gosid",$ENV{'X2GO_SESSION'});
	} else {
		die "No X2Go Session ID in ARGV or ENV!\n";
	}
}

1;
