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

package x2godbwrapper;

use strict;
use Config::Simple;
use DBI;
use POSIX;
use Sys::Syslog qw( :standard :macros );

my $x2go_lib_path=`echo -n \$(x2gobasepath)/lib/x2go`;
use lib `echo -n \$(x2gobasepath)/lib/x2go`;
use X2Go::Log qw(loglevel);

setlogmask( LOG_UPTO(loglevel()) );

my ($uname, $pass, $uid, $pgid, $quota, $comment, $gcos, $homedir, $shell, $expire) = getpwuid(getuid());

my $Config = new Config::Simple(syntax=>'ini');
$Config->read('/etc/x2go/x2gosql/sql' ) or die "Can't read config file /etc/x2go/x2gosql/sql";
my $backend=$Config->param("backend");

my $host;
my $port;
my $db="x2go_sessions";
my $dbpass;
my $dbuser;
my $sslmode;

if ($backend ne 'postgres' && $backend ne 'sqlite')
{
	die "unknown backend $backend";
}

if ($backend eq 'postgres')
{
	$host=$Config->param("postgres.host");
	$port=$Config->param("postgres.port");
	if (!$host)
	{
		$host='localhost';
	}
	if (!$port)
	{
		$port='5432';
	}
	my $passfile;
	if ($uname eq 'root')
	{
		$dbuser='x2godbuser';
		$passfile="/etc/x2go/x2gosql/passwords/x2goadmin";
	}
	else
	{
		$dbuser="x2gouser_$uname";
		$passfile="$homedir/.x2go/sqlpass";
	}
	$sslmode=$Config->param("postgres.ssl");
	if (!$sslmode)
	{
		$sslmode="prefer";
	}
	open (FL,"< $passfile") or die "Can't read password file $passfile<br><b>Use x2godbadmin on server to configure database access for user $uname</b><br>";
	$dbpass=<FL>;
	close(FL);
	chomp($dbpass);
}

use base 'Exporter';

our @EXPORT=('db_listsessions','db_listsessions_all', 'db_getservers', 'db_getagent', 'db_resume', 'db_changestatus', 'db_getstatus', 
             'db_getdisplays', 'db_insertsession', 'db_getports', 'db_insertport', 'db_rmport', 'db_createsession', 'db_insertmount', 
             'db_getmounts', 'db_deletemount', 'db_getdisplay', 'dbsys_getmounts', 'dbsys_listsessionsroot', 
             'dbsys_listsessionsroot_all', 'dbsys_rmsessionsroot', 'dbsys_deletemounts');

sub dbsys_rmsessionsroot
{
	my $sid=shift or die "argument \"session_id\" missed";
	dbsys_deletemounts($sid);
	if($backend eq 'postgres')
	{
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", 
		                     "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;

		my $sth=$dbh->prepare("delete from sessions  where session_id='$sid'");
		$sth->execute() or die;
		$sth=$dbh->prepare("delete from used_ports where session_id='$sid'");
		$sth->execute() or die;
	}
	if($backend eq 'sqlite')
	{
		`$x2go_lib_path/x2gosqlitewrapper rmsessionsroot $sid`;
	}
}

sub dbsys_deletemounts
{
        my $sid=shift or die "argument \"session_id\" missed";
        if ($backend eq 'postgres')
        {
                my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
                my $sth=$dbh->prepare("delete from mounts where session_id='$sid'");
                $sth->execute();
                $sth->finish();
                $dbh->disconnect();
        }
        if ($backend eq 'sqlite')
        {
                `$x2go_lib_path/x2gosqlitewrapper deletemounts $sid`;
        }
        syslog('debug', "dbsys_deletemounts called, session ID: $sid");
}

sub dbsys_listsessionsroot
{
	my $server=shift or die "argument \"server\" missed";
	if ($backend eq 'postgres')
	{
		my @strings;
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", 
		                     "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;

		my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
		                      to_char(init_time,'YYYY-MM-DDTHH24:MI:SS'),cookie,client,gr_port,
		                      sound_port,to_char(last_time,'YYYY-MM-DDTHH24:MI:SS'),uname,
		                      to_char(now()-init_time,'SSSS'),fs_port  from  sessions
		                      where server='$server'  order by status desc");
		$sth->execute()or die;
		my @data;
		my $i=0;
		while (@data = $sth->fetchrow_array) 
		{
			@strings[$i++]=join('|',@data);
		}
		$sth->finish();
		$dbh->disconnect();
		return @strings;
	}
	if($backend eq 'sqlite')
	{
		return split("\n",`$x2go_lib_path/x2gosqlitewrapper listsessionsroot $server`);
	}
}

sub dbsys_listsessionsroot_all
{
	if ($backend eq 'postgres')
	{
		my @strings;
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
		                      to_char(init_time,'YYYY-MM-DDTHH24:MI:SS'),cookie,client,gr_port,
		                      sound_port,to_char(last_time,'YYYY-MM-DDTHH24:MI:SS'),uname,
		                      to_char(now()-init_time,'SSSS'),fs_port  from  sessions
		                      order by status desc");
		$sth->execute()or die;
		my @data;
		my $i=0;
		while (@data = $sth->fetchrow_array) 
		{
			@strings[$i++]=join('|',@data);
		}
		$sth->finish();
		$dbh->disconnect();
		return @strings;
	}
	if ($backend eq 'sqlite')
	{
		return split("\n",`$x2go_lib_path/x2gosqlitewrapper listsessionsroot_all`);
	}
}

sub dbsys_getmounts
{
	my @mounts;
	my $sid=shift or die "argument \"session_id\" missed";
	if ($backend eq 'postgres')
	{
		my @strings;
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("select client, path from mounts where session_id='$sid'");
		$sth->execute()or die;
		my @data;
		my $i=0;
		while (@data = $sth->fetchrow_array) 
		{
			@strings[$i++]=join("|",@data);
		}
		$sth->finish();
		$dbh->disconnect();
		@mounts = @strings;
	}
	if ($backend eq 'sqlite')
	{
		@mounts = split("\n",`$x2go_lib_path/x2gosqlitewrapper getmounts $sid`);
	}
	my $log_retval = join(" ", @mounts);
	syslog('debug', "dbsys_getmounts called, session ID: $sid; return value: $log_retval");
	return @mounts;
}

sub db_getmounts
{
	my @mounts;
	my $sid=shift or die "argument \"session_id\" missed";
	if($backend eq 'postgres')
	{
		my @strings;
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("select client, path from mounts_view where session_id='$sid'");
		$sth->execute()or die;
		my @data;
		my $i=0;
		while (@data = $sth->fetchrow_array) 
		{
			@strings[$i++]=join("|",@data);
		}
		$sth->finish();
		$dbh->disconnect();
		@mounts = @strings;
	}
	if ($backend eq 'sqlite')
	{
		@mounts = split("\n",`$x2go_lib_path/x2gosqlitewrapper getmounts $sid`);
	}
	my $log_retval = join(" ", @mounts);
	syslog('debug', "db_getmounts called, session ID: $sid; return value: $log_retval");
	return @mounts;
}

sub db_deletemount
{
	my $sid=shift or die "argument \"session_id\" missed";
	my $path=shift or die "argument \"path\" missed";
	if ($backend eq 'postgres')
	{
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("delete from mounts_view where session_id='$sid' and path='$path'");
		$sth->execute();
		$sth->finish();
		$dbh->disconnect();
	}
	if ($backend eq 'sqlite')
	{
		`$x2go_lib_path/x2gosqlitewrapper deletemount $sid \"$path\"`;
	}
	syslog('debug', "db_deletemount called, session ID: $sid, path: $path");
}

sub db_insertmount
{
	my $sid=shift or die "argument \"session_id\" missed";
	my $path=shift or die "argument \"path\" missed";
	my $client=shift or die "argument \"client\" missed";
	my $res_ok=0;
	if ($backend eq 'postgres')
	{
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("insert into mounts (session_id,path,client) values  ('$sid','$path','$client')");
		$sth->execute();
		if (!$sth->err())
		{
			$res_ok=1;
		}
		$sth->finish();
		$dbh->disconnect();
	}
	if ($backend eq 'sqlite')
	{
		if( `$x2go_lib_path/x2gosqlitewrapper insertmount $sid \"$path\" $client` eq "ok")
		{
			$res_ok=1;
		}
	}
	syslog('debug', "db_insertmount called, session ID: $sid, path: $path, client: $client; return value: $res_ok");
	return $res_ok;
}

sub db_insertsession
{
	my $display=shift or die "argument \"display\" missed";
	my $server=shift or die "argument \"server\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	if ($backend eq 'postgres')
	{
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("insert into sessions (display,server,uname,session_id) values ('$display','$server','$uname','$sid')");
		$sth->execute()or die $_;
		$sth->finish();
		$dbh->disconnect();
	}
	if ($backend eq 'sqlite')
	{
		my $err=`$x2go_lib_path/x2gosqlitewrapper insertsession $display $server $sid`;
		if ($err ne "ok")
		{
			die "$err: $x2go_lib_path/x2gosqlitewrapper insertsession $display $server $sid";
		}
	}
	syslog('debug', "db_insertsession called, session ID: $sid, server: $server, session ID: $sid");
}

sub db_createsession
{
	my $cookie=shift or die"argument \"cookie\" missed";
	my $pid=shift or die"argument \"pid\" missed";
	my $client=shift or die"argument \"client\" missed";
	my $gr_port=shift or die"argument \"gr_port\" missed";
	my $snd_port=shift or die"argument \"snd_port\" missed";
	my $fs_port=shift or die"argument \"fs_port\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	if ($backend eq 'postgres')
	{
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("update sessions_view set status='R',last_time=now(),
		                      cookie='$cookie',agent_pid='$pid',client='$client',gr_port='$gr_port',
		                      sound_port='$snd_port',fs_port='$fs_port' where session_id='$sid'");
		$sth->execute()or die;
		$sth->finish();
		$dbh->disconnect();
	}
	if ($backend eq 'sqlite')
	{
		my $err= `$x2go_lib_path/x2gosqlitewrapper createsession $cookie $pid $client $gr_port $snd_port $fs_port $sid`;
		if ($err ne "ok")
		{
			die $err;
		}
	}
	syslog('debug', "db_createsession called, session ID: $sid, cookie: $cookie, client: $client, pid: $pid, graphics port: $gr_port, sound port: $snd_port, file sharing port: $fs_port");
}

sub db_insertport
{
	my $server=shift or die "argument \"server\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	my $sshport=shift or die "argument \"port\" missed";
	if ($backend eq 'postgres')
	{
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("insert into used_ports (server,session_id,port) values  ('$server','$sid','$sshport')");
		$sth->execute()or die;
		$sth->finish();
		$dbh->disconnect();
	}
	if ($backend eq 'sqlite')
	{
		`$x2go_lib_path/x2gosqlitewrapper insertport $server $sid $sshport`;
	}
	syslog('debug', "db_insertport called, session ID: $sid, server: $server, SSH port: $sshport");
}

sub db_rmport
{
	my $server=shift or die "argument \"server\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	my $sshport=shift or die "argument \"port\" missed";
	if ($backend eq 'postgres')
	{
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("delete from used_ports where server='$server' and session_id='$sid' and port='$sshport'");
		$sth->execute()or die;
		$sth->finish();
		$dbh->disconnect();
	}
	if ($backend eq 'sqlite')
	{
		`$x2go_lib_path/x2gosqlitewrapper rmport $server $sid $sshport`;
	}
	syslog('debug', "db_rmport called, session ID: $sid, server: $server, SSH port: $sshport");
}

sub db_resume
{
	my $client=shift or die "argument \"client\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	my $gr_port=shift or die "argument \"gr_port\" missed";
	my $sound_port=shift or die "argument \"sound_port\" missed";
	my $fs_port=shift or die "argument \"fs_port\" missed";
	if ($backend eq 'postgres')
	{
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("update sessions_view set last_time=now(),status='R',client='$client',gr_port='$gr_port',
			sound_port='$sound_port',fs_port='$fs_port' where session_id = '$sid'");
		$sth->execute()or die;
		$sth->finish();
		$dbh->disconnect();
	}
	if ($backend eq 'sqlite')
	{
		`$x2go_lib_path/x2gosqlitewrapper resume $client $sid $gr_port $sound_port $fs_port`;
	}
	syslog('debug', "db_resume called, session ID: $sid, client: $client, gr_port: $gr_port, sound_port: $sound_port, fs_port: $fs_port");
}

sub db_changestatus
{
	my $status=shift or die "argument \"status\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	if ($backend eq 'postgres')
	{
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("update sessions_view set last_time=now(),status='$status' where session_id = '$sid'");
		$sth->execute()or die;
		$sth->finish();
		$dbh->disconnect();
	}
	if ($backend eq 'sqlite')
	{
		`$x2go_lib_path/x2gosqlitewrapper changestatus $status $sid`;
	}
	syslog('debug', "db_changestatus called, session ID: $sid, new status: $status");
}

sub db_getstatus
{
	my $sid=shift or die "argument \"session_id\" missed";
	my $status='';
	if ($backend eq 'postgres')
	{
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("select status from sessions_view where session_id = '$sid'");
		$sth->execute($sid) or die;
		my @data;
		if (@data = $sth->fetchrow_array) 
		{
			$status=@data[0];
		}
		$sth->finish();
		$dbh->disconnect();
	}
	if ($backend eq 'sqlite')
	{
		$status=`$x2go_lib_path/x2gosqlitewrapper getstatus $sid`;
	}
	syslog('debug', "db_getstatus called, session ID: $sid, return value: $status");
	return $status;
}

sub db_getdisplays
{
	my @displays;
	#ignore $server
	my $server=shift or die "argument \"server\" missed";
	if ($backend eq 'postgres')
	{
		my @strings;
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("select display from servers_view");
		$sth->execute()or die;
		my @data;
		my $i=0;
		while (@data = $sth->fetchrow_array) 
		{
			@strings[$i++]='|'.@data[0].'|';
		}
		$sth->finish();
		$dbh->disconnect();
		@displays = @strings;
	}
	if ($backend eq 'sqlite')
	{
		@displays = split("\n",`$x2go_lib_path/x2gosqlitewrapper getdisplays $server`);
	}
	my $log_retval = join(" ", @displays);
	syslog('debug', "db_getdisplays called, server: $server; return value: $log_retval");
	return @displays;
}

sub db_getports
{
	my @ports;
	#ignore $server
	my $server=shift or die "argument \"server\" missed";
	if ($backend eq 'postgres')
	{
		my @strings;
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("select port from ports_view");
		$sth->execute()or die;
		my @data;
		my $i=0;
		while (@data = $sth->fetchrow_array) 
		{
			@strings[$i++]='|'.@data[0].'|';
		}
		$sth->finish();
		$dbh->disconnect();
		@ports = @strings;
	}
	if ($backend eq 'sqlite')
	{
		@ports = split("\n",`$x2go_lib_path/x2gosqlitewrapper getports $server`);
	}
	my $log_retval = join(" ", @ports);
	syslog('debug', "db_getports called, server: $server; return value: $log_retval");
	return @ports;
}

sub db_getservers
{
	my @servers;
	if ($backend eq 'postgres')
	{
		my @strings;
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("select server,count(*) from servers_view where status != 'F' group by server");
		$sth->execute()or die;
		my @data;
		my $i=0;
		while (@data = $sth->fetchrow_array) 
		{
			@strings[$i++]=@data[0]." ".@data[1];
		}
		$sth->finish();
		$dbh->disconnect();
		@servers = @strings;
	}
	if ($backend eq 'sqlite')
	{
		@servers = split("\n",`$x2go_lib_path/x2gosqlitewrapper getservers`);
	}
	my $log_retval = join(" ", @servers);
	syslog('debug', "db_getservers called, return value: $log_retval");
	return @servers;
}

sub db_getagent
{
	my $agent;
	my $sid=shift or die "argument \"session_id\" missed";
	if ($backend eq 'postgres')
	{
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("select agent_pid from sessions_view
		                      where session_id ='$sid'");
		$sth->execute()or die;
		my @data;
		my $i=0;
		if (@data = $sth->fetchrow_array) 
		{
			$agent=@data[0];
		}
		$sth->finish();
		$dbh->disconnect();
	}
	if($backend eq 'sqlite')
	{
		$agent=`$x2go_lib_path/x2gosqlitewrapper getagent $sid`;
	}
	syslog('debug', "db_getagent called, session ID: $sid; return value: $agent");
	return $agent;
}

sub db_getdisplay
{
	my $display;
	my $sid=shift or die "argument \"session_id\" missed";
	if ($backend eq 'postgres')
	{
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("select display from sessions_view
		                      where session_id ='$sid'");
		$sth->execute() or die;
		my @data;
		my $i=0;
		if (@data = $sth->fetchrow_array) 
		{
			$display=@data[0];
		}
		$sth->finish();
		$dbh->disconnect();
	}
	if ($backend eq 'sqlite')
	{
		$display=`$x2go_lib_path/x2gosqlitewrapper getdisplay $sid`;
	}
	syslog('debug', "db_getdisplay called, session ID: $sid; return value: $display");
	return $display;
}

sub db_listsessions
{
	my $server=shift or die "argument \"server\" missed";
	if ($backend eq 'postgres')
	{
		my @strings;
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
		                      to_char(init_time,'YYYY-MM-DDTHH24:MI:SS'), cookie, client, gr_port,
		                      sound_port, to_char( last_time, 'YYYY-MM-DDTHH24:MI:SS'), uname,
		                      to_char(now()- init_time,'SSSS'), fs_port from  sessions_view
		                      where status !='F' and server='$server' and  
		                      (session_id not like '%XSHAD%') order by status desc");
		$sth->execute() or die;
		my @data;
		my $i=0;
		while (@data = $sth->fetchrow_array) 
		{
			@strings[$i++]=join('|',@data);
		}
		$sth->finish();
		$dbh->disconnect();
		return @strings;
	}
	if ($backend eq 'sqlite')
	{
		return split("\n",`$x2go_lib_path/x2gosqlitewrapper listsessions $server`);
	}
}

sub db_listsessions_all
{
	if($backend eq 'postgres')
	{
		my @strings;
		my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
		my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
		                      to_char(init_time,'YYYY-MM-DDTHH24:MI:SS'), cookie, client, gr_port,
		                      sound_port, to_char( last_time, 'YYYY-MM-DDTHH24:MI:SS'), uname,
		                      to_char(now()- init_time,'SSSS'), fs_port from  sessions_view
		                      where status !='F'  and  
		                      (session_id not like '%XSHAD%') order by status desc");
		$sth->execute()or die;
		my @data;
		my $i=0;
		while (@data = $sth->fetchrow_array) 
		{
			@strings[$i++]=join('|',@data);
		}
		$sth->finish();
		$dbh->disconnect();
		return @strings;
	}
	if ($backend eq 'sqlite')
	{
		return split("\n",`$x2go_lib_path/x2gosqlitewrapper listsessions_all`);
	}
}
