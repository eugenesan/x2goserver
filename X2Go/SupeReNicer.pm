#!/usr/bin/perl

# Copyright (C) 2013 X2Go Project - http://wiki.x2go.org
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
# Copyright (C) 2013 Guangzhou Nianguan Electronics Technology Co.Ltd. <opensource@gznianguan.com>
# Copyright (C) 2013 Mike Gabriel <mike.gabriel@das-netzwerkteam.de>

package X2Go::SuperRenicer;

=head1 NAME

X2Go::SuperRenicer- X2Go SuperRenicer package for Perl

=head1 DESCRIPTION

X2Go::SuperRenicer Perl package.

=cut

use strict;
use Sys::Syslog qw( :standard :macros );
use X2Go::Utils qw( sanitizer clups );

use base 'Exporter';

our @EXPORT=('superenice');


sub checkPID {
	my $pid = sanitizer("num",$_[0]);
	open(PS,"/bin/ps --no-headers -o %u,%p,%n,%c -p $pid|");
	my ($pidInf,undef) = <PS>;
	close(PS);
	my ($user,$pid,$nice,$cmd)  = split(/\,/,clups($pidInf));
	$pid =~ s/\D//g;
	return ($pid,$user,$nice,$cmd)
}


sub sanitizeNL {
	my $NL = shift;
	my $fallbackNL = shift;
	if ($NL =~ m/^(-|\+|)\d+$/) {
		$NL = int $NL;
		if ($NL > 19) { $NL = 19; }
		elsif ($NL < -19) { $NL = -19; }
	} else {
	    $NL = $fallbackNL;
	}
	return $NL;
}


sub superrenice {
	# Normal: Nice LEVEL?
	my $normalNL = shift; $normalNL = 0 unless defined $normalNL;
	$normalNL = sanitizeNL($normalNL, 0);
	# Idle: Nice LEVEL?
	my $idleNL = shift; $idleNL = 19 unless defined $idleNL;
	$idleNL = sanitizeNL($idleNL, 19);
	# Ignore these users (comma separated list as string)
	my $ignore_users = shift; $ignore_users = "" unless defined $ignore_users;
	# if set to "1" we will force renicing of entire user, even on systems with "/proc"
	my $forceUSERrenice = shift; $forceUSERrenice = 0 unless defined $forceUSERrenice;
	#Path to the "x2golistsessions_root" perl script...

	my $x2golsrpath = `x2gopath base` . "/sbin/x2golistsessions_root";

	###########################################################################################
	# Load list of users to "ignore". These users will never be reniced...
	my %ignore;
	while (split(",", $ignore_users)) {my $iu = clups($_);if (length($iu) > 0) {$ignore{$iu} = 1;}}
	# Load list of users to "ignore". These users will never be reniced...
	###########################################################################################

	if ((-f "/proc/$$/environ") and ($forceUSERrenice ne 1)) {
		###########################################################################################
		# Great! We're on a system with "/proc" so we're able to do this on individual sessions!
		# Basicaly we're checking the users /proc/<$PID>/environ files for the "X2GO_SESSION" env...
		my @x2goSessions;
		# Read the current list of X2Go sessions and their running state
		open(XGOLS,"$x2golsrpath|");
		while (<XGOLS>) {
			my $line = clups($_);
			my ($agentPid,$x2gosid,undef,undef,$x2goState,undef,undef,undef,undef,undef,undef,$userID,undef,undef) = split(/\|/,$line);
			#syslog('debug', "$agentPid,$x2gosid,$x2goState,$userID");
			unless ($ignore{$userID} eq 1) {
				push @x2goSessions, "$x2goState:$agentPid:$x2gosid:$userID";
			}
		}
		close(XGOLS);

		foreach my $x2goSInf (@x2goSessions) {
			my ($x2goState,$agentPid,$x2gosid,$userID,undef) = split(/\:/,$x2goSInf);
			$agentPid = sanitizer("num",$agentPid);

			# We're only working with "portable" unix usernames.
			$userID = sanitizer("anumazcsdaus",$userID);

			# So if the sanitizer returns something we'll do this....
			if ($userID) {

				# Using the NICE value of the agent to figgure out the current nice state...
				my ($psP,$psU,$psN,$psC) = checkPID($agentPid);

				if ($x2goState eq "R") {

					# State is R (Running?)...
					if ($psN ne $normalNL) {
						# If nice level is not normal, renice to normal...
						syslog('notice', "ReNicing \"$userID\" to level $normalNL for session \"$x2gosid\"");
						# For the sake of getting a user back to normal ASAP...  We'll renice the entire user not just individual sessions...
						system("renice -n $normalNL -u $userID 1>/dev/null 2>/dev/null");
					}

				} elsif ($x2goState eq "S") {

					# State is S (suspended)
					if ($psN ne $idleNL) {

						# Did we renice this?
						open(AUPS,"/bin/ps --no-headers -o %u,%p,%n,%c -u $userID|"); # use PS to fetch a list of the users current processes
						while (<AUPS>) {
							my ($user,$pid,$nice,$cmd)  = split(/\,/,clups($_));
							$pid  = sanitizer("num",$pid);

							if (-f "/proc/$pid/environ") {
								open(ENVIRON,"/proc/$pid/environ");my ($Environ,undef) = <ENVIRON>;close(ENVIRON);
								if ($Environ =~ m/X2GO_SESSION=$x2gosid/) {       # If the x2go Session ID is in environ... renice the pid...
									#syslog('debug', "$pid: X2GO_SESSION=$x2gosid");
									system("renice -n $idleNL -p $pid 1>/dev/null 2>/dev/null");
								}
							}

						}
						close(AUPS);

						# Renice the AGENT so that we'll know that this one is already reniced.
						system("renice -n $idleNL -p $agentPid 1>/dev/null 2>/dev/null");
						syslog('notice', "ReNicing \"$userID\" to level $idleNL for session \"$x2gosid\"");

					}
				}
			}
		}

		# Great! We're on a system with "/proc" so we're able to do this on individual sessions!
		############################################################################################

	} else {

		###########################################################################################
		# Oh no.... No "/proc"?  Lets do this on a per user basis instead then...  
		# If a user have more than one session, both need to be suspended before we renice....
		# Resuming any of that users sessions would return them all to normal priority.

		my %niceUsers;
		# Read the current list of X2Go sessions and their running state
		open(XGOLS,"$x2golsrpath|");
		while (<XGOLS>) {
			my $line = clups($_);
			my ($agentPid,$x2gosid,undef,undef,$x2goState,undef,undef,undef,undef,undef,undef,$userID,undef,undef) = split(/\|/,$line);
			syslog('debug', "$agentPid,$x2gosid,,$x2goState,$userID");

			# If user is in ignore list... we're not going a damn thing..
			unless ($ignore{$userID} eq 1) {
				unless ($niceUsers{$userID} =~ /^R:/) {   # Basically if we got an R we're sticking with it...
					$niceUsers{$userID} = "$x2goState:$agentPid";
				}
			}
		}
		close(XGOLS);

		foreach my $nUser (keys %niceUsers) {
			$nUser = sanitizer("anumazcsdaus",$nUser);

			# We're only working with "portable" unix usernames..  
			if ($nUser) {

				# So if the sanitizer return something we'll do this....
				my ($x2goState,$agentPid) = split(/\:/, $niceUsers{$nUser});

				# Using the NICE value of the agent to figgure out the current nice state...
				my ($psP,$psU,$psN,$psC) = checkPID($agentPid);
				syslog('debug', "$nUser:$x2goState,$agentPid:$psP,$psU,$psN,$psC");
				# State is R (Running?)...
				if ($x2goState eq "R") {

					# If nice level is not normal, renice to normal...
					if ($psN ne $normalNL) {
						syslog('debug', "ReNicing \"$nUser\" to level $normalNL");
						system("renice -n $normalNL -u $nUser 1>/dev/null 2>/dev/null");
					}

				# State is S (suspended)
				} elsif ($x2goState eq "S") {

					# Did we renice this?
					if ($psN ne $idleNL) {
						syslog('debug', "ReNicing \"$nUser\" to level $idleNL");
						system("renice -n $idleNL -u $nUser 1>/dev/null 2>/dev/null");
					}
				}
			}
		}
		# Oh no.... No "/proc"?  Lets do this on a per user basis instead then...  
		###########################################################################################
	}
}

1;
