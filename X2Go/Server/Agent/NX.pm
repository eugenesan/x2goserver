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
use DBI;
use POSIX;
use Sys::Syslog qw( :standard :macros );
use File::ReadBackwards;

use X2Go::Log qw( loglevel );

setlogmask( LOG_UPTO(loglevel()) );


sub session_has_terminated
{
        my $sess=shift;
        my $user=shift;
        my $log="/tmp/.x2go-${user}/session-C-${sess}.log";
        my $log_line;
        my $log_file = File::ReadBackwards->new( $log ) or return 1;
        while( defined( $log_line = $log_file->readline ) ) {
                next if ( ! ( $log_line =~ m/^Session:/ ) );
                last;
        }
        $log_file->close();
        if ($log_line =~ m/Session terminated/)
        {
                return 1;
        }
        return 0;
}


sub session_is_suspended
{
        my $sess=shift;
        my $user=shift;
        my $log="/tmp/.x2go-${user}/session-C-${sess}.log";
        my $log_line;
        my $log_file = File::ReadBackwards->new( $log ) or return 0;
        while( defined( $log_line = $log_file->readline ) ) {
                next if ( ! ( $log_line =~ m/^Session:/ ) );
                last;
        }
        $log_file->close();
        if ($log_line =~ m/Session suspended/)
        {
                return 1;
        }
        return 0;
}


sub session_is_running
{
        my $sess=shift;
        my $user=shift;
        if (!session_is_suspended($sess, $user) && !session_has_terminated($sess, $user))
        {
                return 1;
        }
        return 0;
}

1;