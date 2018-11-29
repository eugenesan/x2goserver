#!/usr/bin/perl

# Copyright (C) 2007-2018 X2Go Project - http://wiki.x2go.org
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

package X2Go::Server::DB::SQLite3;

=head1 NAME

X2Go::Server::DB::SQLite3 - X2Go Session Database package for Perl (SQLite3 backend)

=head1 DESCRIPTION

X2Go::Server::DB::SQLite3 Perl package for X2Go::Server.

=cut

use strict;
use DBI;
use POSIX;

#### NOTE: the default X2Go server setups runs the code in this package
####       via a setgid <group> wrapper (where <group> is group ,,x2gouser'').
####       It is intended that the code in this package cannot do system() calls.

use Sys::Syslog qw( :standard :macros );
use X2Go::Config qw( get_config );
use X2Go::Log qw( loglevel );
use X2Go::Utils qw( sanitizer is_true );

openlog($0,'cons,pid','user');
setlogmask( LOG_UPTO(loglevel()) );

my ($uname, $pass, $uid, $pgid, $quota, $comment, $gcos, $homedir, $shell, $expire) = getpwuid($<);
my $realuser=$uname;

use base 'Exporter';

our @EXPORT=('db_listsessions','db_listsessions_all', 'db_getservers', 'db_getagent', 'db_resume', 'db_changestatus', 'db_getstatus',
             'db_getdisplays', 'db_insertsession', 'db_insertshadowsession', 'db_getports', 'db_insertport', 'db_rmport', 'db_createsession', 'db_createshadowsession', 'db_insertmount',
             'db_getmounts', 'db_deletemount', 'db_getdisplay', 'dbsys_getmounts', 'dbsys_listsessionsroot',
             'dbsys_listsessionsroot_all', 'dbsys_rmsessionsroot', 'dbsys_deletemounts', 'db_listshadowsessions','db_listshadowsessions_all', );

sub init_db
{
	# retrieve home dir of x2gouser
	my $x2gouser='x2gouser';
	my ($uname, $pass, $uid, $pgid, $quota, $comment, $gcos, $homedir, $shell, $expire) = getpwnam($x2gouser);
	my $dbfile="$homedir/x2go_sessions";
	my $dbh=DBI->connect("dbi:SQLite:dbname=$dbfile","","",{sqlite_use_immediate_transaction => 1, AutoCommit => 1, }) or die $_;

	# on SLE 11.x the sqlite_busy_timeout function does not exist, trying to work around that...
	if ( $dbh->can('sqlite_busy_timeout') )
	{
		$dbh->sqlite_busy_timeout( 2000 );
	}
	return $dbh;
}

sub dbsys_rmsessionsroot
{
	my $dbh = init_db();
	check_root();
	my $sid=shift or die "argument \"session_id\" missed";
	my $sth=$dbh->prepare("delete from sessions  where session_id=?");
	$sth->execute($sid);
	if ($sth->err())
	{
		syslog('error', "rmsessionsroot (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die;
	}
	$sth->finish();
	undef $dbh;
	return 1;
}

sub dbsys_listsessionsroot
{
	my $dbh = init_db();
	check_root();
	my $server=shift or die "argument \"server\" missed";
	my @strings;
	my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
	                       strftime('%Y-%m-%dT%H:%M:%S',init_time),
	                       cookie,client,gr_port,sound_port,
	                       strftime('%Y-%m-%dT%H:%M:%S',last_time),
	                       uname,
	                       strftime('%s','now','localtime') - strftime('%s',init_time),fs_port,
	                       tekictrl_port, tekidata_port from sessions
	                       where server=?  order by status desc");
	$sth->execute($server);
	if ($sth->err()) {
		syslog('error', "listsessionsroot (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	my @sessions = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @sessions;
}

sub dbsys_listsessionsroot_all
{
	my $dbh = init_db();
	check_root();
	my @strings;
	my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
	                       strftime('%Y-%m-%dT%H:%M:%S',init_time),
	                       cookie,client,gr_port,sound_port,
	                       strftime('%Y-%m-%dT%H:%M:%S',last_time),
	                       uname,
	                       strftime('%s','now','localtime') - strftime('%s',init_time),fs_port,
	                       tekictrl_port, tekidata_port from sessions
	                       order by status desc");
	$sth->execute();
	if ($sth->err())
	{
		syslog('error', "listsessionsroot_all (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	my @sessions = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @sessions;
}

sub dbsys_deletemounts
{
	my $dbh = init_db();
	my $sid=shift or die "argument \"session_id\" missed";
	check_user($sid);
	my $sth=$dbh->prepare("delete from mounts where session_id=?");
	$sth->execute($sid);
	if ($sth->err())
	{
		syslog('error', "deletemounts (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_getmounts
{
	my $dbh = init_db();
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	check_user($sid);
	my @strings;
	my $sth=$dbh->prepare("select client, path from mounts where session_id=?");
	$sth->execute($sid);
	if ($sth->err())
	{
		syslog('error', "getmounts (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die;
	}
	my @mounts = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @mounts;
}

sub db_deletemount
{
	my $dbh = init_db();
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	my $path=shift or die "argument \"path\" missed";
	check_user($sid);
	my $sth=$dbh->prepare("delete from mounts where session_id=? and path=?");
	$sth->execute($sid, $path);
	if ($sth->err())
	{
		syslog('error', "deletemount (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_insertmount
{
	my $dbh = init_db();
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	my $path=shift or die "argument \"path\" missed";
	my $client=shift or die "argument \"client\" missed";
	check_user($sid);
	my $sth=$dbh->prepare("insert into mounts (session_id,path,client) values  (?, ?, ?)");
	$sth->execute($sid, $path, $client);
	my $success = 0;
	if(! $sth->err())
	{
		$success = 1;
	} else {
		syslog('debug', "insertmount (SQLite3 session db backend) failed with exitcode: $sth->err(), this issue will be interpreted as: SSHFS share already mounted");
	}
	$sth->finish();
	undef $dbh;
	return $success;
}

sub db_insertsession
{
	my $dbh = init_db();
	my $display=shift or die "argument \"display\" missed";
	$display = sanitizer('num', $display) or die "argument \"display\" malformed";
	my $server=shift or die "argument \"server\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	check_user($sid);
	my $sth=$dbh->prepare("insert into sessions (display,server,uname,session_id, init_time, last_time) values
	                       (?, ?, ?, ?, datetime('now','localtime'), datetime('now','localtime'))");
	$sth->execute($display, $server, $realuser, $sid) or die $_;
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_insertshadowsession
{
	my $dbh = init_db();
	my $display=shift or die "argument \"display\" missed";
	$display = sanitizer('num', $display) or die "argument \"display\" malformed";
	my $server=shift or die "argument \"server\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	my $shadreq_user = shift or die "argument \"shadreq_user\" missed";
	my $fake_sid = $sid;
	$fake_sid =~ s/$shadreq_user-/$realuser-/;
	check_user($fake_sid);
	my $sth=$dbh->prepare("insert into sessions (display,server,uname,session_id, init_time, last_time) values
	                       (?, ?, ?, ?, datetime('now','localtime'), datetime('now','localtime'))");
	$sth->execute($display, $server, $shadreq_user, $sid) or die $_;
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_createsession
{
	my $dbh = init_db();
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	my $cookie=shift or die"argument \"cookie\" missed";
	my $pid=shift or die"argument \"pid\" missed";
	$pid = sanitizer('num', $pid) or die "argument \"pid\" malformed";
	my $client=shift or die"argument \"client\" missed";
	my $gr_port=shift or die"argument \"gr_port\" missed";
	$gr_port = sanitizer('num', $gr_port) or die "argument \"gr_port\" malformed";
	my $snd_port=shift or die"argument \"snd_port\" missed";
	$snd_port = sanitizer('num', $snd_port) or die "argument \"snd_port\" malformed";
	my $fs_port=shift or die"argument \"fs_port\" missed";
	$fs_port = sanitizer('num', $fs_port) or die "argument \"fs_port\" malformed";
	my $tekictrl_port=shift or die "argument \"tekictrl_port\" missed";
	$tekictrl_port = sanitizer('pnnum', $tekictrl_port) or die "argument \"tekictrl_port\" malformed";
	my $tekidata_port=shift or die "argument \"tekidata_port\" missed";
	$tekidata_port = sanitizer('pnnum', $tekidata_port) or die "argument \"tekidata_port\" malformed";
	check_user($sid);
	my $sth=$dbh->prepare("update sessions set status='R',last_time=datetime('now','localtime'),cookie=?,agent_pid=?,
	                       client=?,gr_port=?,sound_port=?,fs_port=?,tekictrl_port=?,tekidata_port=? where session_id=? and uname=?");
	$sth->execute($cookie, $pid, $client, $gr_port, $snd_port, $fs_port, $tekictrl_port, $tekidata_port, $sid, $realuser);
	if ($sth->err())
	{
		syslog('error', "createsession (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_createshadowsession
{
	my $dbh = init_db();
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	my $cookie=shift or die"argument \"cookie\" missed";
	my $pid=shift or die"argument \"pid\" missed";
	$pid = sanitizer('num', $pid) or die "argument \"pid\" malformed";
	my $client=shift or die"argument \"client\" missed";
	my $gr_port=shift or die"argument \"gr_port\" missed";
	$gr_port = sanitizer('num', $gr_port) or die "argument \"gr_port\" malformed";
	my $snd_port=shift or die"argument \"snd_port\" missed";
	$snd_port = sanitizer('num', $snd_port) or die "argument \"snd_port\" malformed";
	my $fs_port=shift or die"argument \"fs_port\" missed";
	$fs_port = sanitizer('num', $fs_port) or die "argument \"fs_port\" malformed";
	my $shadreq_user = shift or die "argument \"shadreq_user\" missed";
	check_user($sid);
	my $sth=$dbh->prepare("update sessions set status='R',last_time=datetime('now','localtime'),cookie=?,agent_pid=?,
	                       client=?,gr_port=?,sound_port=?,fs_port=?,tekictrl_port=-1,tekidata_port=-1 where session_id=? and uname=?");
	$sth->execute($cookie, $pid, $client, $gr_port, $snd_port, $fs_port, $sid, $shadreq_user);
	if ($sth->err())
	{
		syslog('error', "createshadowsession (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_insertport
{
	my $dbh = init_db();
	my $server=shift or die "argument \"server\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	my $sshport=shift or die "argument \"port\" missed";
	my $sth=$dbh->prepare("insert into used_ports (server,session_id,port) values  (?, ?, ?)");
	check_user($sid);
	$sth->execute($server, $sid, $sshport);
	if ($sth->err())
	{
		syslog('error', "insertport (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_rmport
{
	my $dbh = init_db();
	my $server=shift or die "argument \"server\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	my $sshport=shift or die "argument \"port\" missed";
	my $sth=$dbh->prepare("delete from used_ports where server=? and session_id=? and port=?");
	check_user($sid);
	$sth->execute($server, $sid, $sshport);
	if ($sth->err()) {
		syslog('error', "rmport (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_resume
{
	my $dbh = init_db();
	my $client=shift or die "argument \"client\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	my $gr_port=shift or die "argument \"gr_port\" missed";
	$gr_port = sanitizer('num', $gr_port) or die "argument \"gr_port\" malformed";
	my $snd_port=shift or die "argument \"snd_port\" missed";
	$snd_port = sanitizer('num', $snd_port) or die "argument \"snd_port\" malformed";
	my $fs_port=shift or die "argument \"fs_port\" missed";
	$fs_port = sanitizer('num', $fs_port) or die "argument \"fs_port\" malformed";
	my $tekictrl_port=shift or die"argument \"tekictrl_port\" missed";
	$tekictrl_port = sanitizer('pnnum', $tekictrl_port) or die "argument \"tekictrl_port\" malformed";
	my $tekidata_port=shift or die"argument \"tekidata_port\" missed";
	$tekidata_port = sanitizer('pnnum', $tekidata_port) or die "argument \"tekidata_port\" malformed";
	check_user($sid);
	my $sth=$dbh->prepare("update sessions set last_time=datetime('now','localtime'),status='R',
	                       client=?,gr_port=?,sound_port=?,fs_port=?,tekictrl_port=?,tekidata_port=? where session_id = ? and uname=?");
	$sth->execute($client, $gr_port, $snd_port, $fs_port, $tekictrl_port, $tekidata_port, $sid, $realuser);
	if ($sth->err())
	{
		syslog('error', "resume (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_changestatus
{
	my $dbh = init_db();
	my $status=shift or die "argument \"status\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	check_user($sid);

	# we need to be able to change the state of normal sessions ($realuser == $effective_user)
	# _and_ desktop sharing session ($realuser != $effective_user). Thus, extracting the effective
	# username from the session ID...
	my $effective_user = $sid;
	$effective_user =~ s/\-[0-9]+\-[0-9]{10}_.*//;

	my $sth=$dbh->prepare("update sessions set last_time=datetime('now','localtime'),
	                       status=? where session_id = ? and uname=?");
	$sth->execute($status, $sid, $effective_user);
	if ($sth->err())
	{
		syslog('error', "changestatus (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	$sth->finish();
	undef $dbh;
	return 1;
}

sub db_getstatus
{
	my $dbh = init_db();
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	check_user($sid);
	my $sth=$dbh->prepare("select status from sessions where session_id = ?");
	$sth->execute($sid);
	if ($sth->err())
	{
		syslog('error', "changestatus (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	my @data;
	my $status;
	@data = $sth->fetchrow_array;
	{
		$status = $data[0];
	}
	$sth->finish();
	undef $dbh;
	return $status;
}

sub db_getdisplays
{
	my $dbh = init_db();
	#ignore $server
	my @strings;
	my $sth=$dbh->prepare("select display from sessions");
	$sth->execute();
	if ($sth->err())
	{
		syslog('error', "getdisplays (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	my @data;
	my $i=0;
	while (@data = $sth->fetchrow_array)
	{
		$strings[$i++]='|'.$data[0].'|';
	}
	$sth->finish();
	undef $dbh;
	return join("\n",@strings);
}

sub db_getports
{
	my $dbh = init_db();
	#ignore $server
	my $server=shift or die "argument \"server\" missed";
	my @strings;
	my $sth=$dbh->prepare("select port from used_ports");
	$sth->execute();
	if ($sth->err())
	{
		syslog('error', "getports (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	my @data;
	my $i=0;
	while (@data = $sth->fetchrow_array)
	{
		$strings[$i++]='|'.$data[0].'|';
	}
	$sth->finish();
	undef $dbh;
	return join("\n",@strings);
}

sub db_getservers
{
	my $dbh = init_db();
	my @strings;
	my $sth=$dbh->prepare("select server,count(*) from sessions where status != 'F' group by server");
	$sth->execute();
	if ($sth->err())
	{
		syslog('error', "getservers (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	my @data;
	my $i=0;
	while (@data = $sth->fetchrow_array)
	{
		$strings[$i++]=$data[0];
	}
	$sth->finish();
	undef $dbh;
	return join("\n",@strings);
}

sub db_getagent
{
	my $dbh = init_db();
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	my $agent;
	check_user($sid);
	my $sth=$dbh->prepare("select agent_pid from sessions
	                       where session_id=?");
	$sth->execute($sid);
	if ($sth->err())
	{
		syslog('error', "getagent (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	my @data;
	my $i=0;
	if(@data = $sth->fetchrow_array)
	{
		$agent=$data[0];
	}
	$sth->finish();
	undef $dbh;
	return $agent;
}

sub db_getdisplay
{
	my $dbh = init_db();
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	my $display;
	check_user($sid);
	my $sth=$dbh->prepare("select display from sessions
	                       where session_id =?");
	$sth->execute($sid);
	if ($sth->err())
	{
		syslog('error', "getdisplay (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	my @data;
	my $i=0;
	if(@data = $sth->fetchrow_array)
	{
		$display=$data[0];
	}
	$sth->finish();
	undef $dbh;
	return $display;
}

sub db_listsessions
{
	my $dbh = init_db();
	my $server=shift or die "argument \"server\" missed";
	my @strings;
	my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
	                       strftime('%Y-%m-%dT%H:%M:%S',init_time),
	                       cookie,client,gr_port,sound_port,
	                       strftime('%Y-%m-%dT%H:%M:%S',last_time),
	                       uname,
	                       strftime('%s','now','localtime') - strftime('%s',init_time),fs_port,
	                       tekictrl_port,tekidata_port from sessions
	                       where status !='F' and server=? and uname=?
	                       and  (  session_id not like '%XSHAD%')  order by status desc");
	$sth->execute($server, $realuser);
	if ($sth->err())
	{
		syslog('error', "listsessions (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	my @sessions = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @sessions;
}

sub db_listsessions_all
{
	my $dbh = init_db();
	my @strings;
	my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
	                       strftime('%Y-%m-%dT%H:%M:%S',init_time),
	                       cookie,client,gr_port,sound_port,
	                       strftime('%Y-%m-%dT%H:%M:%S',last_time),
	                       uname,
	                       strftime('%s','now','localtime') - strftime('%s',init_time),fs_port,
	                       tekictrl_port,tekidata_port from  sessions
	                       where status !='F' and uname=? and  (  session_id not like '%XSHAD%')  order by status desc");

	$sth->execute($realuser);
	if ($sth->err())
	{
		syslog('error', "listsessions_all (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	my @sessions = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @sessions;
}

sub db_listshadowsessions
{
	my $dbh = init_db();
	my $server=shift or die "argument \"server\" missed";
	my @strings;
	my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
	                       strftime('%Y-%m-%dT%H:%M:%S',init_time),
	                       cookie,client,gr_port,sound_port,
	                       strftime('%Y-%m-%dT%H:%M:%S',last_time),
	                       uname,
	                       strftime('%s','now','localtime') - strftime('%s',init_time),fs_port from  sessions
	                       where status !='F' and server=? and uname=?
	                       and  (  session_id like '%XSHAD%')  order by status desc");
	$sth->execute($server, $realuser);
	if ($sth->err())
	{
		syslog('error', "listshadowsessions (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	my @sessions = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @sessions;
}

sub db_listshadowsessions_all
{
	my $dbh = init_db();
	my @strings;
	my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
	                       strftime('%Y-%m-%dT%H:%M:%S',init_time),
	                       cookie,client,gr_port,sound_port,
	                       strftime('%Y-%m-%dT%H:%M:%S',last_time),
	                       uname,
	                       strftime('%s','now','localtime') - strftime('%s',init_time),fs_port from  sessions
	                       where status !='F' and uname=? and  (  session_id like '%XSHAD%')  order by status desc");

	$sth->execute($realuser);
	if ($sth->err())
	{
		syslog('error', "listshadowsessions_all (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	my @sessions = fetchrow_array_datasets($sth);
	$sth->finish();
	undef $dbh;
	return @sessions;
}

sub check_root
{
	if ($realuser ne "root")
	{
		die "$realuser, you can not do this job";
	}
}

sub check_user
{
	my $sid=shift or die "argument \"session_id\" missed";
	return if $realuser eq "root";

	# session id looks like someuser-51-1304005895_stDgnome-session_dp24
	# during DB insertsession it only looks like someuser-51-1304005895

	# derive the session's user from the session name/id
	my $user = "$sid";

	# handle ActiveDirectory Domain user accounts gracefully
	$realuser =~ s/\\//;

	# perform the user check
	$user =~ s/($realuser-[0-9]{2,}-[0-9]{10,}_st(D|R).*|.*-[0-9]{2,}-[0-9]{10,}_stS(0|1)XSHAD$realuser.*)/$realuser/;
	$user eq $realuser or die "$realuser is not authorized";
}

sub fetchrow_array_datasets
{
	my $sth = shift;
	my @lines;
	my @data;
	while (@data = $sth->fetchrow_array())
	{
		push @lines, join('|', @data);
	}
	return @lines;
}

1;
