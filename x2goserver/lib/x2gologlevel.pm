#!/usr/bin/perl

# Copyright (C) 2007-2014 X2Go Project - http://wiki.x2go.org
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
# Copyright (C) 2007-2014 Oleksandr Shneyder <oleksandr.shneyder@obviously-nice.de>
# Copyright (C) 2007-2014 Heinz-Markus Graesing <heinz-m.graesing@obviously-nice.de>

package x2gologlevel;

use strict;
use Config::Simple;
use Sys::Syslog qw( :standard :macros );

use base 'Exporter';
our @EXPORT = ( 'x2gologlevel' );

my $Config = new Config::Simple(syntax=>'ini');
$Config->read('/etc/x2go/x2goserver.conf' );

my $strloglevel = $Config->param("log.loglevel");

sub x2gologlevel {
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
