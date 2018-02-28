# Copyright (C) 2007-2018 X2Go Project - http://wiki.x2go.org
# Copyright (C) 2007-2018 Oleksandr Shneyder <oleksandr.shneyder@obviously-nice.de>
# Copyright (C) 2007-2018 Heinz-Markus Graesing <heinz-m.graesing@obviously-nice.de>
# Copyright (C) 2017-2018 Walid Moghrabi <w.moghrabi@servicemagic.eu>
# Copyright (C) 2018      Mihai Moldovan <ionic@ionic.de>
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

package X2Go::Server::DB::MySQL;

=head1 NAME

X2Go::Server::DB::MySQL - X2Go Session Database package for Perl (MySQL backend)

=head1 DESCRIPTION

X2Go::Server::DB::MySQL Perl package for X2Go::Server.

=cut

use strict;
use DBI;
use POSIX;
use Sys::Syslog qw( :standard :macros );

use X2Go::Log qw( loglevel );
use X2Go::Config qw( get_config get_sqlconfig );
use X2Go::Utils qw( sanitizer system_capture_stdout_output is_true );

setlogmask( LOG_UPTO(loglevel()) );

use base 'Exporter';

our @EXPORT=('db_listsessions','db_listsessions_all', 'db_getservers', 'db_getagent', 'db_resume', 'db_changestatus', 'db_getstatus',
             'db_getdisplays', 'db_insertsession', 'db_insertshadowsession', 'db_getports', 'db_insertport', 'db_rmport', 'db_createsession', 'db_insertmount',
             'db_getmounts', 'db_deletemount', 'db_getdisplay', 'dbsys_getmounts', 'dbsys_listsessionsroot',
             'dbsys_listsessionsroot_all', 'dbsys_rmsessionsroot', 'dbsys_deletemounts', 'db_listshadowsessions','db_listshadowsessions_all');

my ($uname, $pass, $uid, $pgid, $quota, $comment, $gcos, $homedir, $shell, $expire) = getpwuid(getuid());

my $host;
my $port;
my $db="x2go_sessions";
my $dbpass;
my $dbuser;
my $sslmode;
my $with_TeKi;

sub init_db
{
	# the $Config is required later (see below...)
	my $Config = get_config;
	$with_TeKi = is_true($Config->param("telekinesis.enable"));

	if ( ! ( $dbuser and $dbpass ) )
	{
		my $SqlConfig = get_sqlconfig;
		my $x2go_lib_path=system_capture_stdout_output("x2gopath", "libexec");

		my $backend=$SqlConfig->param("backend");
		if ( $backend ne "mysql" )
		{
			die "X2Go server is not configured to use the MySQL session db backend";
		}

		$host=$SqlConfig->param("mysql.host");
		$port=$SqlConfig->param("mysql.port");
		if (!$host)
		{
			$host='localhost';
		}
		if (!$port)
		{
			$port='3306';
		}
		my $passfile;
		if ($uname eq 'root')
		{
			$dbuser='x2godbuser';
			$passfile="/etc/x2go/x2gosql/passwords/x2gomysqladmin";
		}
		else
		{
			$dbuser="x2gouser_$uname";
			$passfile="$homedir/.x2go/mysqlpass";
		}
		open (FL,"< $passfile") or die "Can't read password file $passfile<br><b>Use x2godbadmin on server to configure database access for user $uname</b><br>";
		$dbpass=<FL>;
		close(FL);
		chomp($dbpass);
	}

	my $dbh = DBI->connect ("dbi:mysql:database=$db;host=$host;port=$port", "$dbuser", "$dbpass", {AutoCommit => 1}) or die $_;

	return $dbh;
}

sub check_root
{
	die "$uname is not authorized to perform this operation" unless ($uname eq "root");
}

sub validate_session_id
{
	my $sid = shift or die "argument \"session_id\" missing";
	return if $uname eq "root";

	# session id looks like someuser-51-1304005895_stDgnome-session_dp24
	# during DB insertsession it only looks like someuser-51-1304005895

	# derive the session's user from the session name/id
	my $user = "$sid";
	my $uname_ = "$uname";

	# handle ActiveDirectory Domain user accounts gracefully
	$uname_ =~ s/\\//;

	# perform the user check
	$user =~ s/($uname_-[0-9]{2,}-[0-9]{10,}_st(D|R).*|.*-[0-9]{2,}-[0-9]{10,}_stS(0|1)XSHAD$uname_.*)/$uname_/;
	die "$uname_ is not authorized to perform this operation" unless ($uname_ eq $user);
}

sub check_error
{
	my $sth = shift or die "Invalid or no statement handle parameter supplied";
	my $fatal = shift;

	my $func_name = (caller(1))[3];

	$fatal = 1 unless defined($fatal);

	if ($sth->err())
	{
		syslog('error', "$func_name (MySQL session DB backend) failed with exitcode: " . $sth->err() . ": " . $sth->errstr());

		if ($fatal) {
			die "$func_name (MySQL session DB backend): " . $sth->err() . ": " . $sth->errstr();
		}
	}
}

sub fetchrow_array_datasets
{
	my $sth = shift or die "Invalid or no statement handle parameter supplied";
	my @lines;
	while (my @data = $sth->fetchrow_array())
	{
		push @lines, join('|', @data);
	}
	return @lines;
}

sub fetchrow_array_datasets_single_framed
{
	my $sth = shift or die "Invalid or no statement handle parameter supplied";
	my @lines;
	while (my @data = $sth->fetchrow_array())
	{
		push @lines, "|" . @data[0] . "|";
	}
	return @lines;
}

sub fetchrow_array_datasets_double_spacelim
{
	my $sth = shift or die "Invalid or no statement handle parameter supplied";
	my @lines;
	while (my @data = $sth->fetchrow_array())
	{
		push @lines, @data[0] . " " . @data[1];
	}
	return @lines;
}

sub fetchrow_array_single_single
{
	my $sth = shift or die "Invalid or no statement handle parameter supplied";
	my $ret = '';
	if (my @data = $sth->fetchrow_array())
	{
		$ret = @data[0];
	}
	return $ret;
}

sub dbsys_rmsessionsroot
{
	my $dbh = init_db();
	check_root();
	my $sid = shift or die "argument \"session_id\" missing";
	my $sth=$dbh->prepare("delete from sessions where session_id=?");
	$sth->execute($sid);
	check_error($sth);
	$sth->finish();
	undef $dbh;
	return 1;
}

sub dbsys_deletemounts
{
	my $dbh = init_db();
	my $sid = shift or die "argument \"session_id\" missing";
	validate_session_id($sid);
	my $sth=$dbh->prepare("delete from mounts where session_id=?");
	$sth->execute($sid);
	check_error($sth);
	$sth->finish();
	undef $dbh;
	return 1;
}

sub dbsys_listsessionsroot
{
	my $dbh = init_db();
	check_root();
	my $server = shift or die "argument \"server\" missing";
	my @sessions;
	my $sth = undef;
	if ($with_TeKi) {
		$sth=$dbh->prepare("select
		                      agent_pid, session_id, display, server, status,
		                      DATE_FORMAT(init_time, '%Y-%m-%dT%H:%i:%S'), cookie, client,
		                      gr_port, sound_port,
		                      DATE_FORMAT(last_time, '%Y-%m-%dT%H:%i:%S'), uname,
		                      MOD(UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(init_time), 86400),
		                      fs_port, tekictrl_port, tekidata_port
		                    from sessions
		                    where server=? order by status desc");
	} else {
		$sth=$dbh->prepare("select
		                      agent_pid, session_id, display, server, status,
		                      DATE_FORMAT(init_time, '%Y-%m-%dT%H:%i:%S'), cookie, client,
		                      gr_port, sound_port,
		                      DATE_FORMAT(last_time, '%Y-%m-%dT%H:%i:%S'), uname,
		                      MOD(UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(init_time), 86400),
		                      fs_port
		                    from sessions
		                    where server=? order by status desc");
	}
	$sth->execute($server);
	check_error($sth);
	@sessions = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @sessions;
}

sub dbsys_listsessionsroot_all
{
	my $dbh = init_db();
	check_root();
	my @sessions;
	my $sth = undef;
	if ($with_TeKi) {
		$sth=$dbh->prepare("select
		                      agent_pid, session_id, display, server, status,
		                      DATE_FORMAT(init_time, '%Y-%m-%dT%H:%i:%S'), cookie, client,
		                      gr_port, sound_port,
		                      DATE_FORMAT(last_time, '%Y-%m-%dT%H:%i:%S'), uname,
		                      MOD(UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(init_time), 86400),
		                      fs_port, tekictrl_port, tekidata_port
		                    from sessions
		                    order by status desc");
	} else {
		$sth=$dbh->prepare("select
		                      agent_pid, session_id, display, server, status,
		                      DATE_FORMAT(init_time, '%Y-%m-%dT%H:%i:%S'), cookie, client,
		                      gr_port, sound_port,
		                      DATE_FORMAT(last_time, '%Y-%m-%dT%H:%i:%S'), uname,
		                      MOD(UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(init_time), 86400),
		                      fs_port
		                    from sessions
		                    order by status desc");
	}
	$sth->execute();
	check_error($sth);
	@sessions = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @sessions;
}

sub dbsys_getmounts
{
	my $dbh = init_db();
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	validate_session_id($sid);
	my @mounts;
	my $sth=$dbh->prepare("select client, path from mounts where session_id=?");
	$sth->execute($sid);
	check_error($sth);
	@mounts = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @mounts;
}

sub db_getmounts
{
	my $dbh = init_db();
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	validate_session_id($sid);
	my @mounts;
	my $sth=$dbh->prepare("select client, path from mounts where session_id=?");
	$sth->execute($sid);
	check_error($sth);
	@mounts = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @mounts;
}

sub db_deletemount
{
	my $dbh = init_db();
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	validate_session_id($sid);
	my $path = shift or die "argument \"path\" missing";
	my $sth=$dbh->prepare("delete from mounts where session_id=? and path=?");
	$sth->execute($sid, $path);
	check_error($sth);
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_insertmount
{
	my $dbh = init_db();
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	validate_session_id($sid);
	my $path = shift or die "argument \"path\" missing";
	my $client = shift or die "argument \"client\" missing";
	my $sth=$dbh->prepare("insert into mounts (session_id, path, client) values (?, ?, ?)");
	$sth->execute($sid, $path, $client);
	check_error($sth, 0);
	my $success = (!($sth->err()));
	$sth->finish();
	undef $dbh;
	return $success;
}

sub db_insertsession
{
	my $dbh = init_db();
	my $display = shift or die "argument \"display\" missing";
	$display = sanitizer('num', $display) or die "argument \"display\" malformed";
	my $server = shift or die "argument \"server\" missing";
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	validate_session_id($sid);
	my $sth=$dbh->prepare("insert into sessions
	                         (display, server, uname, session_id)
	                       values
	                         (?, ?, ?, ?)");
	$sth->execute($display, $server, $uname, $sid);
	check_error($sth);
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_insertshadowsession
{
	my $dbh = init_db();
	my $display = shift or die "argument \"display\" missing";
	$display = sanitizer('num', $display) or die "argument \"display\" malformed";
	my $server = shift or die "argument \"server\" missing";
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	my $shadreq_user = shift or die "argument \"shadreq_user\" missing";
	(my $fake_sid = $sid) =~ s/$shadreq_user-/$uname-/;
	validate_session_id($fake_sid);
	my $sth=$dbh->prepare("insert into sessions
	                         (display, server, uname, session_id)
	                       values
	                         (?, ?, ?, ?)");
	$sth->execute($display, $server, $shadreq_user, $sid);
	check_error($sth);
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_createsession
{
	my $dbh = init_db();
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	validate_session_id($sid);
	my $cookie = shift or die "argument \"cookie\" missing";
	my $pid = shift or die "argument \"pid\" missing";
	$pid = sanitizer('num', $pid) or die "argument \"pid\" malformed";
	my $client = shift or die "argument \"client\" missing";
	my $gr_port = shift or die "argument \"gr_port\" missing";
	$gr_port = sanitizer('num', $gr_port) or die "argument \"gr_port\" malformed";
	my $snd_port = shift or die "argument \"snd_port\" missing";
	$snd_port = sanitizer('num', $snd_port) or die "argument \"snd_port\" malformed";
	my $fs_port = shift or die "argument \"fs_port\" missing";
	$fs_port = sanitizer('num', $fs_port) or die "argument \"fs_port\" malformed";
	my $sth;
	if ($with_TeKi) {
		my $tekictrl_port = shift or die "argument \"tekictrl_port\" missing";
		$tekictrl_port = sanitizer('pnnum', $tekictrl_port) or die "argument \"tekictrl_port\" malformed";
		my $tekidata_port = shift or die"argument \"tekidata_port\" missing";
		$tekidata_port = sanitizer('pnnum', $tekidata_port) or die "argument \"tekidata_port\" malformed";
		$sth=$dbh->prepare("update sessions set
		                      status='R', last_time=NOW(),
		                      cookie=?, agent_pid=?, client=?, gr_port=?,
		                      sound_port=?, fs_port=?, tekictrl_port=?,
		                      tekidata_port=?
		                    where session_id=?");
		$sth->execute($cookie, $pid, $client, $gr_port, $snd_port, $fs_port, $tekictrl_port, $tekidata_port, $sid);
	} else {
		$sth=$dbh->prepare("update sessions set
		                      status='R', last_time=NOW(),
		                      cookie=?, agent_pid=?, client=?, gr_port=?,
		                      sound_port=?, fs_port=?
		                    where session_id=?");
		$sth->execute($cookie, $pid, $client, $gr_port, $snd_port, $fs_port, $sid);
	}
	check_error($sth);
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_insertport
{
	my $dbh = init_db();
	my $server = shift or die "argument \"server\" missing";
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	validate_session_id($sid);
	my $sshport = shift or die "argument \"port\" missing";
	my $sth=$dbh->prepare("insert into used_ports (server, session_id, port) values (?, ?, ?)");
	$sth->execute($server, $sid, $sshport);
	check_error($sth);
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_rmport
{
	my $dbh = init_db();
	my $server = shift or die "argument \"server\" missing";
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	validate_session_id($sid);
	my $sshport = shift or die "argument \"port\" missing";
	my $sth=$dbh->prepare("delete from used_ports where server=? and session_id=? and port=?");
	$sth->execute($server, $sid, $sshport);
	check_error($sth);
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_resume
{
	my $dbh = init_db();
	my $client = shift or die "argument \"client\" missing";
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	validate_session_id($sid);
	my $gr_port = shift or die "argument \"gr_port\" missing";
	$gr_port = sanitizer('num', $gr_port) or die "argument \"gr_port\" malformed";
	my $snd_port = shift or die "argument \"snd_port\" missing";
	$snd_port = sanitizer('num', $snd_port) or die "argument \"snd_port\" malformed";
	my $fs_port = shift or die "argument \"fs_port\" missing";
	$fs_port = sanitizer('num', $fs_port) or die "argument \"fs_port\" malformed";
	my $sth;
	if ($with_TeKi) {
		my $tekictrl_port = shift or die "argument \"tekictrl_port\" missing";
		$tekictrl_port = sanitizer('pnnum', $tekictrl_port) or die "argument \"tekictrl_port\" malformed";
		my $tekidata_port = shift or die "argument \"tekidata_port\" missing";
		$tekidata_port = sanitizer('pnnum', $tekidata_port) or die "argument \"tekidata_port\" malformed";
		$sth=$dbh->prepare("update sessions set
		                      last_time=NOW(), status='R', client=?, gr_port=?,
		                      sound_port=?, fs_port=?, tekictrl_port=?,
		                      tekidata_port=?
		                    where session_id=?");
		$sth->execute($client, $gr_port, $snd_port, $fs_port, $tekictrl_port, $tekidata_port, $sid);
	} else {
		$sth=$dbh->prepare("update sessions set
		                      last_time=NOW(), status='R', client=?, gr_port=?,
		                      sound_port=?, fs_port=?
		                    where session_id=?");
		$sth->execute($client, $gr_port, $snd_port, $fs_port, $sid);
	}
	check_error($sth);
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_changestatus
{
	my $dbh = init_db();
	my $status = shift or die "argument \"status\" missing";
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	validate_session_id($sid);

	# we need to be able to change the state of normal sessions (real user == effective user)
	# _and_ desktop sharing session (real user != effective user). Thus, extracting the effective
	# username from the session ID...
	(my $effective_user = $sid) =~ s/\-[0-9]+\-[0-9]{10}_.*//;

	my $sth=$dbh->prepare("update sessions set
	                         last_time=NOW(), status=?
	                       where session_id=? and uname=?");
	$sth->execute($status, $sid, $effective_user);
	check_error($sth);
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_getstatus
{
	my $dbh = init_db();
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	validate_session_id($sid);
	my $status = '';
	my $sth=$dbh->prepare("select status from sessions where session_id=?");
	$sth->execute($sid);
	check_error($sth);
	$status = fetchrow_array_single_single($sth);
	$sth->finish();
	undef $dbh;
	return $status;
}

sub db_getdisplays
{
	my $dbh = init_db();
	my $server = shift or die "argument \"server\" missing";
	my @displays;
	my $sth=$dbh->prepare("select display from sessions where server=?");
	$sth->execute($server);
	check_error($sth);
	@displays = fetchrow_array_datasets_single_framed($sth);
	$sth->finish();
	undef $dbh;
	return @displays;
}

sub db_getports
{
	my $dbh = init_db();
	my @ports;
	my $server = shift or die "argument \"server\" missing";
	my $sth=$dbh->prepare("select port from used_ports where server=?");
	$sth->execute($server);
	check_error($sth);
	@ports = fetchrow_array_datasets_single_framed($sth);
	$sth->finish();
	undef $dbh;
	return @ports;
}

sub db_getservers
{
	my $dbh = init_db();
	my @servers;
	my $sth=$dbh->prepare("select server,count(*) from sessions where status!='F' group by server");
	$sth->execute();
	check_error($sth);
	@servers = fetchrow_array_datasets_double_spacelim($sth);
	$sth->finish();
	undef $dbh;
	return @servers;
}

sub db_getagent
{
	my $dbh = init_db();
	my $agent;
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	validate_session_id($sid);
	my $sth=$dbh->prepare("select
	                         agent_pid
	                       from sessions
	                       where session_id=?");
	$sth->execute($sid);
	check_error($sth);
	$agent = fetchrow_array_single_single($sth);
	$sth->finish();
	undef $dbh;
	return $agent;
}

sub db_getdisplay
{
	my $dbh = init_db();
	my $display;
	my $sid = shift or die "argument \"session_id\" missing";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	validate_session_id($sid);
	my $sth=$dbh->prepare("select
	                         display
	                       from sessions
	                       where session_id=?");
	$sth->execute($sid);
	check_error($sth);
	$display = fetchrow_array_single_single($sth);
	$sth->finish();
	undef $dbh;
	return $display;
}

sub db_listsessions
{
	my $dbh = init_db();
	my $server = shift or die "argument \"server\" missing";
	my @sessions;
	my $sth;
	if ($with_TeKi) {
		$sth=$dbh->prepare("select
		                      agent_pid, session_id, display, server, status,
		                      DATE_FORMAT(init_time, '%Y-%m-%dT%H:%i:%S'), cookie, client,
		                      gr_port, sound_port,
		                      DATE_FORMAT(last_time, '%Y-%m-%dT%H:%i:%S'), uname,
		                      MOD(UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(init_time), 86400),
		                      fs_port, tekictrl_port, tekidata_port
		                    from sessions
		                    where status!='F' and server=? and (session_id not like '%XSHAD%')
		                    order by status desc");
	} else {
		$sth=$dbh->prepare("select
		                      agent_pid, session_id, display, server, status,
		                      DATE_FORMAT(init_time, '%Y-%m-%dT%H:%i:%S'), cookie, client,
		                      gr_port, sound_port,
		                      DATE_FORMAT(last_time, '%Y-%m-%dT%H:%i:%S'), uname,
		                      MOD(UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(init_time), 86400),
		                      fs_port
		                    from sessions
		                    where status!='F' and server=? and (session_id not like '%XSHAD%')
		                    order by status desc");
	}
	$sth->execute($server);
	check_error($sth);
	@sessions = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @sessions;
}

sub db_listsessions_all
{
	my $dbh = init_db();
	my @sessions;
	my $sth;
	if ($with_TeKi) {
		$sth=$dbh->prepare("select
		                      agent_pid, session_id, display, server, status,
		                      DATE_FORMAT(init_time, '%Y-%m-%dT%H:%i:%S'), cookie, client,
		                      gr_port, sound_port,
		                      DATE_FORMAT(last_time, '%Y-%m-%dT%H:%i:%S'), uname,
		                      MOD(UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(init_time), 86400),
		                      fs_port, tekictrl_port, tekidata_port
		                    from sessions
		                    where status!='F' and (session_id not like '%XSHAD%')
		                    order by status desc");
	} else {
		$sth=$dbh->prepare("select
		                      agent_pid, session_id, display, server, status,
		                      DATE_FORMAT(init_time, '%Y-%m-%dT%H:%i:%S'), cookie, client,
		                      gr_port, sound_port,
		                      DATE_FORMAT(last_time, '%Y-%m-%dT%H:%i:%S'), uname,
		                      MOD(UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(init_time), 86400),
		                      fs_port
		                    from sessions
		                    where status!='F' and (session_id not like '%XSHAD%')
		                    order by status desc");
	}
	$sth->execute();
	check_error($sth);
	@sessions = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @sessions;
}

sub db_listshadowsessions
{
	my $dbh = init_db();
	my $server = shift or die "argument \"server\" missing";
	my @sessions;
	my $sth=$dbh->prepare("select
	                         agent_pid, session_id, display, server, status,
	                         DATE_FORMAT(init_time, '%Y-%m-%dT%H:%i:%S'), cookie, client,
	                         gr_port, sound_port,
	                         DATE_FORMAT(last_time, '%Y-%m-%dT%H:%i:%S'), uname,
	                         MOD(UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(init_time), 86400),
	                         fs_port
	                       from sessions
	                       where status!='F' and server=? and (session_id like '%XSHAD%')
	                       order by status desc");
	$sth->execute($server);
	check_error($sth);
	@sessions = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @sessions;
}

sub db_listshadowsessions_all
{
	my $dbh = init_db();
	my @sessions;
	my $sth=$dbh->prepare("select
	                         agent_pid, session_id, display, server, status,
	                         DATE_FORMAT(init_time, '%Y-%m-%dT%H:%i:%S'), cookie, client,
	                         gr_port, sound_port,
	                         DATE_FORMAT(last_time, '%Y-%m-%dT%H:%i:%S'), uname,
	                         MOD(UNIX_TIMESTAMP(NOW()) - UNIX_TIMESTAMP(init_time), 86400),
	                         fs_port
	                       from sessions
	                       where status!='F' and (session_id is like '%XSHAD%')
	                       order by status desc");
	$sth->execute();
	check_error($sth);
	@sessions = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @sessions;
}

1;
