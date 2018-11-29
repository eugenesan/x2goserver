# Copyright (C) 2007-2018 X2Go Project - https://wiki.x2go.org
# Copyright (C) 2007-2018 Oleksandr Shneyder <o.shneyder@phoca-gmbh.de>
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

package X2Go::Server::Agent::NX;

=head1 NAME

X2Go::Server::Agent::NX - X2Go Server NX Agent package for Perl

=head1 DESCRIPTION

X2Go::Server::Agent::NX Perl package for X2Go::Server.

=cut

use strict;
use POSIX;
use Sys::Syslog qw( :standard :macros );

use X2Go::Log qw( loglevel );

setlogmask( LOG_UPTO(loglevel()) );


sub session_has_terminated
{
	my $state=get_agent_state(@_);
	if(($state eq 'TERMINATING')||($state eq 'TERMINATED'))
	{
		return 1;
	}
	return 0;
}


sub session_is_suspended
{
	my $state=get_agent_state(@_);
	if(($state eq 'SUSPENDING')||($state eq 'SUSPENDED'))
	{
		return 1;
	}
	return 0;
}


sub session_is_running
{
	my $state=get_agent_state(@_);
	if(($state eq 'STARTING')||($state eq 'RESUMING')||($state eq 'RUNNING'))
	{
		return 1;
	}
	return 0;
}

sub get_agent_state_file
{
	my $sess=@_[1];
	my $user;

	if ( $sess =~ m/.*-[0-9]{2,}-[0-9]{10,}_stS(0|1)XSHAD.*XSHADPP.*/ ) {
		my $shadow_user = $sess;
		$shadow_user =~ s/.*XSHAD(.*)XSHADPP.*/$1/;
		$user = $shadow_user;
	} else {
		$user=@_[2];
	}

	my $stateFile;
	if ( -d "/tmp-inst/${user}/.x2go-${user}" ) {
		$stateFile="/tmp-inst/${user}/.x2go-".$user."/C-".$sess."/state";
	} else {
		$stateFile = "/tmp/.x2go-".$user."/C-".$sess."/state";
	}
	return $stateFile;
}

sub has_agent_state_file
{
	my $stateFile = get_agent_state_file(@_);
	if ( -e "$stateFile" )
	{
		return 1;
	}
	return 0;
}

sub get_agent_state
{
	my $state;
	my $stateFile = get_agent_state_file(@_);
	if (! -e "$stateFile" )
	{
		syslog('warning', "@_[1]: state file for this session does not exist: $stateFile (this can be ignored during session startups)");
		$state="UNKNOWN";
	}
	else
	{
		open(F,"<$stateFile");
		$state=<F>;
		close(F);
	}
	return $state;
}

1;
