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

sub has_agent_state_file
{
	my $sess=@_[1];
	my $user=@_[2];
	my $stateFile;
	if ( -d "/tmp-inst/${user}/.x2go-${user}" ) {
		$stateFile="/tmp-inst/${user}/.x2go-".$user."/C-".$sess."/state";
	} else {
		$stateFile = "/tmp/.x2go-".$user."/C-".$sess."/state";
	}
	if ( -e $stateFile )
	{
		return 1;
	}
	return 0;
}

sub get_agent_state
{
	my $sess=@_[1];
	my $user=@_[2];
	my $state;
	my $stateFile;
	if ( -d "/tmp-inst/${user}/.x2go-${user}" ) {
		$stateFile="/tmp-inst/${user}/.x2go-".$user."/C-".$sess."/state";
	} else {
		$stateFile = "/tmp/.x2go-".$user."/C-".$sess."/state";
	}
	if (! -e $stateFile )
	{
		syslog('warning', "$sess: state file for this session does not exists: $stateFile (this can be ignored during session startups)");
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
