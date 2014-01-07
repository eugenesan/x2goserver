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
# Copyright (C) 2007-2014  Oleksandr Shneyder <oleksandr.shneyder@obviously-nice.de>
# Copyright (C) 2007-2014  Heinz-Markus Graesing <heinz-m.graesing@obviously-nice.de>

package X2Go::Server::Agent;

=head1 NAME

X2Go::Server::Agent - X2Go Server Agent package for Perl

=head1 DESCRIPTION

X2Go::Server::Agent Perl package for X2Go::Server.

=cut

use strict;
use X2Go::Utils qw( load_module );

# TODO: when other agents may come into play, the AGENT var has to be read from config file or
# somehow else...
my $DEFAULT_AGENT="NX";
my $AGENT=$DEFAULT_AGENT;
my $agent_module = "X2Go::Server::Agent::$AGENT";
load_module $agent_module;

use base 'Exporter';

our @EXPORT=( 'session_has_terminated', 'session_is_running', 'session_is_suspended' );



sub session_has_terminated {
	return $agent_module->session_has_terminated(@_);
}


sub session_is_running {
	return $agent_module->session_is_running(@_);
}


sub session_is_suspended {
	return $agent_module->session_is_suspended(@_);
}

1;
