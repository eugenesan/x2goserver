#!/usr/bin/perl -XU

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

use strict;
use Switch;

use X2Go::Server::DB::SQLite3;

#### NOTE: this script is run setgid <group> and it cannot do system() calls.

sub print_result
{
	my $retval = shift;
	if ( $retval =~ /^(0|1)$/ )
	{
		if ( $retval )
		{
			print "ok";
		}
	} else {
		print $retval;
	}
}

sub print_result_list
{
	my @list = @_;
	print join("\n", @list);
}

my $result;
my @result_list;
my $cmd=shift or die "command not specified";

# call the corresponding function in the X2Go::Server:DB:SQLite3 package
switch ($cmd)
{
	case /.*listsessions.*root/              { @result_list = eval("X2Go::Server::DB::SQLite3::dbsys_$cmd(\@ARGV)") }
	case /.*(listsessions|getmounts).*/      { @result_list = eval("X2Go::Server::DB::SQLite3::db_$cmd(\@ARGV)") }
	case /.*root/                            { $result = eval("X2Go::Server::DB::SQLite3::dbsys_$cmd(\@ARGV)") }
	else                                     { $result = eval("X2Go::Server::DB::SQLite3::db_$cmd(\@ARGV)") }
}

if ( defined(@result_list) )
{
	print_result_list(@result_list);
}
elsif ( defined($result) )
{
	print_result($result);
}

exit (0);
