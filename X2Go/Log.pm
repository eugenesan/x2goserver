#!/usr/bin/perl

# Copyright (C) 2007-2018 X2Go Project - https://wiki.x2go.org
# Copyright (C) 2007-2018 Oleksandr Shneyder <oleksandr.shneyder@obviously-nice.de>
# Copyright (C) 2007-2018 Heinz-Markus Graesing <heinz-m.graesing@obviously-nice.de>
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

package X2Go::Log;

=head1 NAME

X2Go::Log - X2Go Logging package for Perl

=head1 DESCRIPTION

X2Go::Log Perl package for X2Go components.

=cut

use strict;
use Sys::Syslog qw( :standard :macros );
use X2Go::Config qw( get_config );

use base 'Exporter';
our @EXPORT = ( 'loglevel' );

my $Config = get_config();
my $strloglevel = $Config->param("log.loglevel");

sub loglevel {
	my $loglevel = LOG_NOTICE;
	if    ( $strloglevel eq "emerg" )  { $loglevel = LOG_EMERG; }
	elsif ( $strloglevel eq "alert" )  { $loglevel = LOG_ALERT; }
	elsif ( $strloglevel eq "crit" )   { $loglevel = LOG_CRIT; }
	elsif ( $strloglevel eq "err" )    { $loglevel = LOG_ERR; }
	elsif ( $strloglevel eq "warning" )   { $loglevel = LOG_WARNING; }
	elsif ( $strloglevel eq "notice" ) { $loglevel = LOG_NOTICE; }
	elsif ( $strloglevel eq "info" )   { $loglevel = LOG_INFO; }
	elsif ( $strloglevel eq "debug" )  { $loglevel = LOG_DEBUG; }
	return $loglevel;
}

1;
