#!/usr/bin/perl

# Copyright (C) 2007-2015 X2Go Project - http://wiki.x2go.org
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
# Copyright (C) 2007-2015 Oleksandr Shneyder <oleksandr.shneyder@obviously-nice.de>
# Copyright (C) 2007-2015 Heinz-Markus Graesing <heinz-m.graesing@obviously-nice.de>

use strict;
use DBI;
use POSIX;

#### NOTE: this script is run setgid <group> and it cannot do system() calls.

####
#### One consequence of this is...
#### This first part of code that handles syslogging is duplicated from
#### x2gologlevel.pm. This is because we are not able to detect the
#### installation path automatically via the x2gobasepath in this
#### script.
####

use Config::Simple;
use Sys::Syslog qw( :standard :macros );
my $Config = new Config::Simple(syntax=>'ini');
$Config->read('/etc/x2go/x2goserver.conf' );
my $strloglevel = $Config->param("log.loglevel");
my $loglevel = LOG_NOTICE;
if    ( $strloglevel eq "emerg" )  { $loglevel = LOG_EMERG; }
elsif ( $strloglevel eq "alert" )  { $loglevel = LOG_ALERT; }
elsif ( $strloglevel eq "crit" )   { $loglevel = LOG_CRIT; }
elsif ( $strloglevel eq "err" )    { $loglevel = LOG_ERR; }
elsif ( $strloglevel eq "warning" )   { $loglevel = LOG_WARNING; }
elsif ( $strloglevel eq "notice" ) { $loglevel = LOG_NOTICE; }
elsif ( $strloglevel eq "info" )   { $loglevel = LOG_INFO; }
elsif ( $strloglevel eq "debug" )  { $loglevel = LOG_DEBUG; }
setlogmask( LOG_UPTO($loglevel) );

# same applies for the sanitizer code shipped in x2goutils.pm
sub sanitizer {
	my $type   = $_[0];
	my $string = $_[1];
	if ($type eq "num") {
		$string =~ s/\D//g;
		if ($string =~ /^([0-9]*)$/) {
			$string = $1;
			return $string;
		} else {return 0;}
	} elsif ($type eq "x2gosid") {
		$string =~ s/[^a-zA-Z0-9\_\-\$\.\@]//g;
		if ($string =~ /^([a-zA-Z0-9\_\-\$\.\@]*)$/) {
			$string = $1;
			if ($string =~ /^([a-zA-Z\_][a-zA-Z0-9\_\-\.\@]{0,47}[\$]?)\-([\d]{2,4})\-([\d]{9,12})\_[a-zA-Z0-9\_\-\.]*\_dp[\d]{1,2}$/) {
				if ((length($1) > 0) and (length($1) < 48)){
					return $string;
				} else {return 0;}
			} else {return 0;}
		} else {return 0;}
	} elsif ($type eq "SOMETHINGELSE") {
		return 0;
	} else {
		return 0;
	}
}

####
#### end of duplicated syslogging code
####

# retrieve home dir of x2gouser
my $x2gouser='x2gouser';
my ($uname, $pass, $uid, $pgid, $quota, $comment, $gcos, $homedir, $shell, $expire) = getpwnam($x2gouser);
my $dbfile="$homedir/x2go_sessions";

# retrieve account data of real user
my ($uname, $pass, $uid, $pgid, $quota, $comment, $gcos, $homedir, $shell, $expire) = getpwuid($<);
my $realuser=$uname;

my $dbh=DBI->connect("dbi:SQLite:dbname=$dbfile","","",{sqlite_use_immediate_transaction => 1, AutoCommit => 1, }) or die $_;

# on SLE 11.x the sqlite_busy_timeout function does not exist, trying to work around that...
if ( $dbh->can('sqlite_busy_timeout') )
{
	$dbh->sqlite_busy_timeout( 2000 );
}

my $cmd=shift or die "command not specified";
my $rc=0;

if($cmd eq  "rmsessionsroot")
{
	checkroot();
	my $sid=shift or die "argument \"session_id\" missed";
	my $sth=$dbh->prepare("delete from sessions  where session_id=?");
	$sth->execute($sid);
	if ($sth->err())
	{
		syslog('error', "rmsessionsroot (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die;
	}
	$sth->finish();
}

elsif($cmd eq  "listsessionsroot")
{
	checkroot();
	my $server=shift or die "argument \"server\" missed";
	my @strings;
	my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
	                       strftime('%Y-%m-%dT%H:%M:%S',init_time),
	                       cookie,client,gr_port,sound_port,
	                       strftime('%Y-%m-%dT%H:%M:%S',last_time),
	                       uname,
	                       strftime('%s','now','localtime') - strftime('%s',init_time),fs_port from  sessions
	                       where server=?  order by status desc");
	$sth->execute($server);
	if ($sth->err()) {
		syslog('error', "listsessionsroot (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	fetchrow_printall_array($sth);
}

elsif($cmd eq  "listsessionsroot_all")
{
	checkroot();
	my @strings;
	my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
	                       strftime('%Y-%m-%dT%H:%M:%S',init_time),
	                       cookie,client,gr_port,sound_port,
	                       strftime('%Y-%m-%dT%H:%M:%S',last_time),
	                       uname,
	                       strftime('%s','now','localtime') - strftime('%s',init_time),fs_port from  sessions
	                       order by status desc");
	$sth->execute();
	if ($sth->err())
	{
		syslog('error', "listsessionsroot_all (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	fetchrow_printall_array($sth);
}

elsif($cmd eq  "getmounts")
{
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
	fetchrow_printall_array($sth);
}

elsif($cmd eq  "deletemount")
{
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
}

elsif($cmd eq  "deletemounts")
{
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	check_user($sid);
	my $sth=$dbh->prepare("delete from mounts where session_id=?");
	$sth->execute($sid);
	if ($sth->err())
	{
		syslog('error', "deletemounts (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	$sth->finish();
}

elsif($cmd eq  "insertmount")
{
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	my $path=shift or die "argument \"path\" missed";
	my $client=shift or die "argument \"client\" missed";
	check_user($sid);
	my $sth=$dbh->prepare("insert into mounts (session_id,path,client) values  (?, ?, ?)");
	$sth->execute($sid, $path, $client);
	if(! $sth->err())
	{
		print "ok";
	} else {
		syslog('debug', "insertmount (SQLite3 session db backend) failed with exitcode: $sth->err(), this issue will be interpreted as: SSHFS share already mounted");
	}
	$sth->finish();
}

elsif($cmd eq  "insertsession")
{
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
	print "ok";
}

elsif($cmd eq  "createsession")
{
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
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	check_user($sid);
	my $sth=$dbh->prepare("update sessions set status='R',last_time=datetime('now','localtime'),cookie=?,agent_pid=?,
	                       client=?,gr_port=?,sound_port=?,fs_port=? where session_id=? and uname=?");
	$sth->execute($cookie, $pid, $client, $gr_port, $snd_port, $fs_port, $sid, $realuser);
	if ($sth->err())
	{
		syslog('error', "createsession (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	$sth->finish();
	print "ok";
}

elsif($cmd eq  "insertport")
{
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
}

elsif($cmd eq  "rmport")
{
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
}

elsif($cmd eq  "resume")
{
	my $client=shift or die "argument \"client\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	my $gr_port=shift or die "argument \"gr_port\" missed";
	$gr_port = sanitizer('num', $gr_port) or die "argument \"gr_port\" malformed";
	my $snd_port=shift or die "argument \"snd_port\" missed";
	$snd_port = sanitizer('num', $snd_port) or die "argument \"snd_port\" malformed";
	my $fs_port=shift or die "argument \"fs_port\" missed";
	$fs_port = sanitizer('num', $fs_port) or die "argument \"fs_port\" malformed";
	check_user($sid);
	my $sth=$dbh->prepare("update sessions set last_time=datetime('now','localtime'),status='R',
	                       client=?,gr_port=?,sound_port=?,fs_port=? where session_id = ? and uname=?");
	$sth->execute($client, $gr_port, $snd_port, $fs_port, $sid, $realuser);
	if ($sth->err())
	{
		syslog('error', "resume (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	$sth->finish();
}

elsif($cmd eq  "changestatus")
{
	my $status=shift or die "argument \"status\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	$sid = sanitizer('x2gosid', $sid) or die "argument \"session_id\" malformed";
	check_user($sid);
	my $sth=$dbh->prepare("update sessions set last_time=datetime('now','localtime'),
	                       status=? where session_id = ? and uname=?");
	$sth->execute($status, $sid, $realuser);
	if ($sth->err())
	{
		syslog('error', "changestatus (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	$sth->finish();
}

elsif($cmd eq  "getstatus")
{
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
		$status = @data[0];
	}
	$sth->finish();
	print $status;
}

elsif($cmd eq  "getdisplays")
{
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
		@strings[$i++]='|'.@data[0].'|';
	}
	$sth->finish();
	print join("\n",@strings);
}

elsif($cmd eq  "getports")
{

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
		@strings[$i++]='|'.@data[0].'|';
	}
	$sth->finish();
	print join("\n",@strings);
}

elsif($cmd eq  "getservers")
{
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
		@strings[$i++]=@data[0];
	}
	$sth->finish();
	print join("\n",@strings);
}

elsif($cmd eq  "getagent")
{
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
		$agent=@data[0];
	}
	$sth->finish();
	print $agent;
}

elsif($cmd eq  "getdisplay")
{
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
		$display=@data[0];
	}
	$sth->finish();
	print $display;
}

elsif($cmd eq  "listsessions")
{
	my $server=shift or die "argument \"server\" missed";
	my @strings;
	my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
	                       strftime('%Y-%m-%dT%H:%M:%S',init_time),
	                       cookie,client,gr_port,sound_port,
	                       strftime('%Y-%m-%dT%H:%M:%S',last_time),
	                       uname,
	                       strftime('%s','now','localtime') - strftime('%s',init_time),fs_port from  sessions
	                       where status !='F' and server=? and uname=?
	                       and  (  session_id not like '%XSHAD%')  order by status desc");
	$sth->execute($server, $realuser);
	if ($sth->err())
	{
		syslog('error', "listsessions (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	fetchrow_printall_array($sth);
}

elsif($cmd eq  "listsessions_all")
{
	my @strings;
	my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
	                       strftime('%Y-%m-%dT%H:%M:%S',init_time),
	                       cookie,client,gr_port,sound_port,
	                       strftime('%Y-%m-%dT%H:%M:%S',last_time),
	                       uname,
	                       strftime('%s','now','localtime') - strftime('%s',init_time),fs_port from  sessions 
	                       where status !='F' and uname=? and  (  session_id not like '%XSHAD%')  order by status desc");
	
	$sth->execute($realuser);
	if ($sth->err())
	{
		syslog('error', "listsessions_all (SQLite3 session db backend) failed with exitcode: $sth->err()");
		die();
	}
	fetchrow_printall_array($sth);
}
else
{
	print "unknown command $cmd\n";
}

undef $dbh;

sub checkroot
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

sub fetchrow_printall_array
{
	# print all arrays separated by the pipe symbol
	local $, = '|';

	my $sth = shift;
	my @data;
	while (@data = $sth->fetchrow_array())
	{
		print @data, "\n";
	}
	$sth->finish();
}
