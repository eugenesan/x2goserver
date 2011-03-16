package x2godbwrapper;

use strict;
use Config::Simple;   
use DBI;   

use POSIX;

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

if($backend ne 'postgres' && $backend ne 'sqlite')
{
  die "unknown backend $backend";
}

if($backend eq 'postgres')
{
  $host=$Config->param("postgres.host");
  $port=$Config->param("postgres.port");
  if(!$host)
  {
    $host='localhost';
  }
  if(!$port)
  {
    $port='5432';
  }
  my $passfile;
  if($uname eq 'root')
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
  if(!$sslmode)
  {
         $sslmode="prefer";
  }
  open (FL,"< $passfile") or die "Can't read password file $passfile<br><b>Use x2godbadmin on server to configure database access for user $uname</b><br>";
  $dbpass=<FL>;
  close(FL);
  chomp($dbpass);
}

use base 'Exporter';

our @EXPORT=('db_listsessions','db_listsessions_all', 'db_getservers', 'db_getagent', 'db_resume', 'db_changestatus', 
	     'db_getdisplays', 'db_insertsession', 'db_getports', 'db_insertport', 'db_createsession', 'db_insertmount', 
	     'db_getmounts', 'db_deletemount', 'db_getdisplay', 'dbsys_getmounts', 'dbsys_listsessionsroot', 
	     'dbsys_listsessionsroot_all', 'dbsys_rmsessionsroot');

	     
	     
	     
 
sub dbsys_rmsessionsroot
{
       my $sid=shift or die "argument \"session_id\" missed";
       if($backend eq 'postgres')
       {
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", 
	       "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
	       
	       my $sth=$dbh->prepare("delete from sessions  where session_id='$sid'");
               $sth->execute()or die;
       }
       if($backend eq 'sqlite')
       {
	   `x2gosqlitewrapper rmsessionsroot $sid`;
       }
}

sub dbsys_listsessionsroot
{
       my $server=shift or die "argument \"server\" missed";
       if($backend eq 'postgres')
       {
       my @strings;
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", 
	       "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
	       
	       my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
				     to_char(init_time,'DD.MM.YY*HH24:MI:SS'),cookie,client,gr_port,
				     sound_port,to_char(last_time,'DD.MM.YY*HH24:MI:SS'),uname,
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
	   return split("\n",`x2gosqlitewrapper listsessionsroot $server`);
       }
}

sub dbsys_listsessionsroot_all
{
       if($backend eq 'postgres')
       {
       my @strings;
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
	       
	       my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
				     to_char(init_time,'DD.MM.YY*HH24:MI:SS'),cookie,client,gr_port,
				     sound_port,to_char(last_time,'DD.MM.YY*HH24:MI:SS'),uname,
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
       if($backend eq 'sqlite')
       {
	   return split("\n",`x2gosqlitewrapper listsessionsroot_all`);
       }
}

	     
sub dbsys_getmounts
{
       my $sid=shift or die "argument \"session_id\" missed";
       if($backend eq 'postgres')
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
       return @strings;
       }
       if($backend eq 'sqlite')
       {
	   return split("\n",`x2gosqlitewrapper getmounts $sid`);
       }

}

sub db_getmounts
{
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
       return @strings;
       }
       if($backend eq 'sqlite')
       {
	   return split("\n",`x2gosqlitewrapper getmounts $sid`);
       }
}
	     
sub db_deletemount
{
       my $sid=shift or die "argument \"session_id\" missed";
       my $path=shift or die "argument \"path\" missed";
       if($backend eq 'postgres')
       {
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;	       
	       my $sth=$dbh->prepare("delete from mounts_view where session_id='$sid' and path='$path'");
               $sth->execute();
               $sth->finish();
	       $dbh->disconnect();
       }
       if($backend eq 'sqlite')
       {
	   `x2gosqlitewrapper deletemount $sid \"$path\"`;
       }

}

sub db_insertmount
{
       my $sid=shift or die "argument \"session_id\" missed";
       my $path=shift or die "argument \"path\" missed";
       my $client=shift or die "argument \"client\" missed";
       my $res_ok=1;
       if($backend eq 'postgres')
       {
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;	       
	       my $sth=$dbh->prepare("insert into mounts (session_id,path,client) values  ('$sid','$path','$client')");
               $sth->execute();
	       if(!$sth->err())
	       {
		 $res_ok=1;
	       }
               $sth->finish();
	       $dbh->disconnect();
       }
       if($backend eq 'sqlite')
       {
	   if( `x2gosqlitewrapper insertmount $sid \"$path\" $client` eq "ok")
	   {
	     $res_ok=1;
	   }
       }
       return $res_ok;
}

	     
sub db_insertsession
{
	my $display=shift or die "argument \"display\" missed";
	my $server=shift or die "argument \"server\" missed";
        my $sid=shift or die "argument \"session_id\" missed";
       if($backend eq 'postgres')
       {
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;	       
	       my $sth=$dbh->prepare("insert into sessions (display,server,uname,session_id) values ('$display','$server','$uname','$sid')");
               $sth->execute()or die $_;
               $sth->finish();
	       $dbh->disconnect();
       }
       if($backend eq 'sqlite')
       {
	   my $err=`x2gosqlitewrapper insertsession $display $server $sid`;
	   if($err ne "ok")
	   {
	     die "$err: x2gosqlitewrapper insertsession $display $server $sid";
	   }
       }

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
       if($backend eq 'postgres')
       {
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;	       
	       my $sth=$dbh->prepare("update sessions_view set status='R',last_time=now(),
				     cookie='$cookie',agent_pid='$pid',client='$client',gr_port='$gr_port',
				     sound_port='$snd_port',fs_port='$fs_port' where session_id='$sid'");
               $sth->execute()or die;
	       $sth->finish();
	       $dbh->disconnect();
       }
       if($backend eq 'sqlite')
       {
	   my $err= `x2gosqlitewrapper createsession $cookie $pid $client $gr_port $snd_port $fs_port $sid`;
	   if($err ne "ok")
	   {
	     die $err;
	   }
       }

}

sub db_insertport
{
	my $server=shift or die "argument \"server\" missed";
	my $sid=shift or die "argument \"session_id\" missed";
	my $sshport=shift or die "argument \"port\" missed";
       if($backend eq 'postgres')
       {
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;	       
	       my $sth=$dbh->prepare("insert into used_ports (server,session_id,port) values  ('$server','$sid','$sshport')");
               $sth->execute()or die;
	       $sth->finish();
	       $dbh->disconnect();
       }
       if($backend eq 'sqlite')
       {
	   `x2gosqlitewrapper insertport $server $sid $sshport`;
       }

}

	     
sub db_resume
{
       my $client=shift or die "argument \"client\" missed";
       my $sid=shift or die "argument \"session_id\" missed";       
       if($backend eq 'postgres')
       {
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;	       
	       my $sth=$dbh->prepare("update sessions_view set last_time=now(),status='R',client='$client' where session_id = '$sid'");
               $sth->execute()or die;
	       $sth->finish();
	       $dbh->disconnect();
       }
       if($backend eq 'sqlite')
       {
	   `x2gosqlitewrapper resume $client $sid`;
       }

}

sub db_changestatus
{
       my $status=shift or die "argument \"status\" missed";
       my $sid=shift or die "argument \"session_id\" missed";       
       if($backend eq 'postgres')
       {
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;	       
	       my $sth=$dbh->prepare("update sessions_view set last_time=now(),status='$status' where session_id = '$sid'");
               $sth->execute()or die;
	       $sth->finish();
	       $dbh->disconnect();
       }
       if($backend eq 'sqlite')
       {
	   `x2gosqlitewrapper changestatus $status $sid`;
       }

}

sub db_getdisplays
{
       #ignore $server
       my $server=shift or die "argument \"server\" missed";         
       if($backend eq 'postgres')
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
       return @strings;
       }
       if($backend eq 'sqlite')
       {
	   return split("\n",`x2gosqlitewrapper getdisplays $server`);
       }

}

sub db_getports
{
       #ignore $server
       my $server=shift or die "argument \"server\" missed";         
       if($backend eq 'postgres')
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
       return @strings;
       }
       if($backend eq 'sqlite')
       {
	   return split("\n",`x2gosqlitewrapper getports $server`);
       }

}

sub db_getservers
{
       if($backend eq 'postgres')
       {
       my @strings;
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
	       
	       my $sth=$dbh->prepare("select server,count(*) from servers_view where status != 'F' group by server");
               $sth->execute()or die;
               my @data;
	       my $i=0;
               while (@data = $sth->fetchrow_array) 
               {
		   @strings[$i++]=@data[0];
               }
	       $sth->finish();
	       $dbh->disconnect();
       return @strings;
       }
              if($backend eq 'sqlite')
       {
	   return split("\n",`x2gosqlitewrapper getservers`);
       }

}

sub db_getagent
{
       my $sid=shift or die "argument \"session_id\" missed";
       my $agent;
       if($backend eq 'postgres')
       {
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
	       
	       my $sth=$dbh->prepare("select agent_pid from sessions_view
				      where session_id ='$sid'");
               $sth->execute()or die;
               my @data;
	       my $i=0;
               if(@data = $sth->fetchrow_array) 
               {
		   $agent=@data[0];
               }
               $sth->finish();
	       $dbh->disconnect();
       }
       if($backend eq 'sqlite')
       {
	   $agent=`x2gosqlitewrapper getagent $sid`;
       }
       return $agent;
}

sub db_getdisplay
{
       my $sid=shift or die "argument \"session_id\" missed";
       my $display;
       if($backend eq 'postgres')
       {
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
	       
	       my $sth=$dbh->prepare("select display from sessions_view
				      where session_id ='$sid'");
               $sth->execute()or die;
               my @data;
	       my $i=0;
               if(@data = $sth->fetchrow_array) 
               {
		   $display=@data[0];
               }
               $sth->finish();
	       $dbh->disconnect();
       }
       if($backend eq 'sqlite')
       {
	   $display=`x2gosqlitewrapper getdisplay $sid`;
       }
       return $display;
}
sub db_listsessions
{
       my $server=shift or die "argument \"server\" missed";
       if($backend eq 'postgres')
       {
	       my @strings;
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
	       
	       my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
				     to_char(init_time,'DD.MM.YY*HH24:MI:SS'), cookie, client, gr_port,
				     sound_port, to_char( last_time, 'DD.MM.YY*HH24:MI:SS'), uname,
				     to_char(now()- init_time,'SSSS'), fs_port from  sessions_view
				      where status !='F' and server='$server' and  
				      (  session_id not like '%XSHAD%') order by status desc");
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
	   return split("\n",`x2gosqlitewrapper listsessions $server`);
       }

}

sub db_listsessions_all
{
       if($backend eq 'postgres')
       {
	       my @strings;
	       my $dbh=DBI->connect("dbi:Pg:dbname=$db;host=$host;port=$port;sslmode=$sslmode", "$dbuser", "$dbpass",{AutoCommit => 1}) or die $_;
	       
	       my $sth=$dbh->prepare("select agent_pid, session_id, display, server, status,
				     to_char(init_time,'DD.MM.YY*HH24:MI:SS'), cookie, client, gr_port,
				     sound_port, to_char( last_time, 'DD.MM.YY*HH24:MI:SS'), uname,
				     to_char(now()- init_time,'SSSS'), fs_port from  sessions_view
				      where status !='F'  and  
				      (  session_id not like '%XSHAD%') order by status desc");
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
	   return split("\n",`x2gosqlitewrapper listsessions_all`);
       }

}
