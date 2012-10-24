#!/usr/bin/perl

# Copyright (C) 2007-2012 X2Go Project - http://wiki.x2go.org
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
# Copyright (C) 2007-2012  Oleksandr Shneyder <oleksandr.shneyder@obviously-nice.de>
# Copyright (C) 2007-2012  Heinz-Markus Graesing <heinz-m.graesing@obviously-nice.de>

package X2Go::Utils;

=head1 NAME

X2Go::Utils - X2Go utilities and helper functions for Perl

=head1 DESCRIPTION

X2Go::Utils Perl package.

=cut

use strict;
use base 'Exporter';

our @EXPORT = ('source_environment');

sub source_environment {
	my $name = shift;

	open my $fh, "<", $name
	     or die "could not open $name: $!";

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

1;
