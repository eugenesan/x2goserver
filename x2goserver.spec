Name:           x2goserver
Version:        4.1.0.0
Release:        0.0x2go1%{?dist}
Summary:        X2Go Server

Group:          Applications/Communications
License:        GPLv2+
URL:            http://www.x2go.org
Source0:        http://code.x2go.org/releases/source/%{name}/%{name}-%{version}.tar.gz
# git clone git://code.x2go.org/x2goserver
# cd x2goserver
# git archive --prefix=x2goserver-4.1.0.0-20140722git65169c9/ 65169c9d65b117802e50631be0bbd719163d969e | gzip > ../x2goserver-4.1.0.0-20140722git65169c9.tar.gz
#Source0:        %{name}/%{name}-%{version}-%{checkout}.tar.gz
Source1:        x2goserver.service
Source2:        x2goserver.init
%if 0%{?el5}
# For compatibility with EPEL5
BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
%endif

BuildRequires:  desktop-file-utils
BuildRequires:  perl(ExtUtils::MakeMaker)
%if 0%{?fedora} || 0%{?rhel} >= 7
BuildRequires:  man2html-core
BuildRequires:  systemd
%else
BuildRequires:  man
%endif
# So XSESSIONDIR gets linked
%if 0%{suse_version}
BuildRequires:  xinit
%else
BuildRequires:  xorg-x11-xinit
%endif
# For x2goruncommand - for now
Requires:       bc
# For x2goshowblocks
Requires:       lsof
# For netstat in x2goresume-session
Requires:       net-tools
Requires:       openssh-server
%if 0%{suse_version}
Requires:       perl
%else
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
%endif
Requires:       perl(Try::Tiny)
# We need a database
# For killall in x2gosuspend-session
Requires:       psmisc
# For x2godbadmin
Requires:       pwgen
# For printing, file-sharing
Requires:       sshfs
# For /etc/sudoers.d
Requires:       sudo
Requires:       x2goagent >= 3.5.0.25
Requires:       xorg-x11-fonts-misc
Requires:       xorg-x11-xauth
Requires:       perl(File::Which)
Requires(pre):  shadow-utils
Requires(post): grep
Requires(post): perl(DBD::SQLite)
%if 0%{?fedora} || 0%{?rhel} >= 7
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd
%endif
Requires:       x2goserver-extensions
Requires:       x2goserver-xsession
#Recommands:       x2goserver-fmbindings
#Recommends:       x2goserver-printing

%{?perl_default_filter}

%description
X2Go is a server based computing environment with
    - session resuming
    - low bandwidth support
    - session brokerage support
    - client side mass storage mounting support
    - audio support
    - authentication by smartcard and USB stick

This package contains the main daemon and tools for X2Go server-side session
administrations.


%package common
Summary:        X2Go Server (common files)
%if 0%{suse_version}
Requires:       perl
%else
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
%endif
Group:          Applications/Communications

%description common
X2Go is a server based computing environment with
    - session resuming
    - low bandwidth support
    - session brokerage support
    - client side mass storage mounting support
    - audio support
    - authentication by smartcard and USB stick

This package contains common files needed by the X2Go Server
and the X2Go::Server Perl API.


%package -n perl-X2Go-Server
Summary:        Perl X2Go::Server package
Requires:       x2goserver-common = %{version}-%{release}
Requires:       perl-X2Go-Log = %{version}-%{release}
Requires:       perl-X2Go-Server-DB = %{version}-%{release}
%if 0%{suse_version}
Requires:       perl
%else
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
%endif
Group:          Development/Libraries

%description -n perl-X2Go-Server
X2Go is a server based computing environment with
    - session resuming
    - low bandwidth support
    - session brokerage support
    - client side mass storage mounting support
    - audio support
    - authentication by smartcard and USB stick

This package contains the X2Go::Server Perl package.


%package -n perl-X2Go-Server-DB
Summary:        Perl X2Go::Server::DB package
Requires:       x2goserver-common = %{version}-%{release}
Requires:       perl-X2Go-Log = %{version}-%{release}
Requires:       perl(DBD::SQLite)
Requires:       perl(DBD::Pg)
%if 0%{suse_version}
Requires:       perl
%else
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
%endif
Group:          Development/Libraries

%description -n perl-X2Go-Server-DB
X2Go is a server based computing environment with
    - session resuming
    - low bandwidth support
    - session brokerage support
    - client side mass storage mounting support
    - audio support
    - authentication by smartcard and USB stick

This package contains the X2Go::Server::DB Perl package.


%package -n perl-X2Go-Log
Summary:        Perl X2Go::Log package
Requires:       x2goserver-common = %{version}-%{release}
%if 0%{suse_version}
Requires:       perl
%else
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
%endif
Group:          Development/Libraries

%description -n perl-X2Go-Log
X2Go is a server based computing environment with
    - session resuming
    - low bandwidth support
    - session brokerage support
    - client side mass storage mounting support
    - audio support
    - authentication by smartcard and USB stick

This package contains the X2Go::Log Perl package.


%package printing
Summary:        X2Go Server (printing support)
Requires:       %{name} = %{version}-%{release}
%if 0%{suse_version}
Requires:       perl
%else
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
%endif
Group:          Applications/Communications

%description printing
X2Go is a server based computing environment with
    - session resuming
    - low bandwidth support
    - session brokerage support
    - client side mass storage mounting support
    - audio support
    - authentication by smartcard and USB stick

The X2Go Server printing package provides client-side printing support for
X2Go.

This package has to be installed on X2Go servers that shall be able to pass
X2Go print jobs on to the X2Go client.

This package co-operates with the cups-x2go CUPS backend. If CUPS server and
X2Go server are hosted on different machines, then make sure you install
this package on the X2Go server(s) (and the cups-x2go package on the CUPS
server).


%package extensions
Summary:        X2Go Server (extension support)
Requires:       %{name} = %{version}-%{release}
Group:          Applications/Communications

%description extensions
X2Go is a server based computing environment with
    - session resuming
    - low bandwidth support
    - session brokerage support
    - client side mass storage mounting support
    - audio support
    - authentication by smartcard and USB stick

The X2Go Server extension namespace offers contributors
to add script functionality to X2Go.

Make sure you have this package installed on your server
if you want X2Go clients to be able to access your server
without lack of features.


%package xsession
Summary:        X2Go Server (Xsession runner)
Requires:       %{name} = %{version}-%{release}
# For /etc/X11/Xresources
Requires:       xorg-x11-xinit
Group:          Applications/Communications

%description xsession
 X2Go is a server based computing environment with
    - session resuming
    - low bandwidth support
    - session brokerage support
    - client side mass storage mounting support
    - audio support
    - authentication by smartcard and USB stick
 .
 This X2Go Server add-on enables Xsession script handling
 when starting desktop sessions with X2Go.
 .
 Amongst others the parsing of Xsession scripts will
 enable desktop-profiles, ssh-agent startups, gpgagent
 startups and many more Xsession related features on
 X2Go session login automagically.

%package fmbindings
Summary:        X2Go Server (file manager bindings)
Requires:       %{name} = %{version}-%{release}
Requires:       xdg-utils
Requires:       desktop-file-utils
Requires(post):   desktop-file-utils
Requires(postun): desktop-file-utils
Group:          Applications/Communications

%description fmbindings
X2Go is a server based computing environment with
    - session resuming
    - low bandwidth support
    - session brokerage support
    - client side mass storage mounting support
    - audio support
    - authentication by smartcard and USB stick

This package contains generic MIME type information
for X2Go's local folder sharing. It can be used with all
freedesktop.org compliant desktop shells.

However, this package can be superseded by other, more specific
destkop binding components, if installed and being used with the
corresponding desktop shell:
    - under LXDE by x2golxdebindings
    - under GNOMEv2 by x2gognomebindings
    - under KDE4 by plasma-widget-x2go
    - under MATE by x2gomatebindings


%prep
%setup -q

# Set path
#find -type f | xargs sed -i -r -e '/^((LIBDIR|X2GO_LIB_PATH)=|use lib|my \$x2go_lib_path)/s,/lib/,/%{_lib}/,'
find -type f | xargs sed -i -r -e '/^LIBDIR=/s,/lib/,/%{_lib}/,'
sed -i -e 's,/lib/,/%{_lib}/,' x2goserver/bin/x2gopath
# Don't try to be root
sed -i -e 's/-o root -g root//' */Makefile

%build
export PATH=%{_qt4_bindir}:$PATH
make CFLAGS="%{optflags} -fPIC" %{?_smp_mflags} PERL_INSTALLDIRS=vendor PREFIX=%{_prefix}


%install
make install DESTDIR=%{buildroot} PREFIX=%{_prefix}

# Make sure the .packlist file is removed from %{perl_vendorarch}...
rm -f %{buildroot}%{perl_vendorarch}/auto/x2goserver/.packlist

# Remove placeholder files (in a way that works on EPEL-5, as well)
find %{buildroot}%{_libdir}/x2go/extensions/ -type f -name ".placeholder" | while read file; do rm -f "$file"; done

# x2gouser homedir, state dir
mkdir -p %{buildroot}%{_sharedstatedir}/x2go
# Create empty session file for %%ghost
touch %{buildroot}%{_sharedstatedir}/x2go/x2go_sessions

# Printing spool dir
mkdir -p %{buildroot}%{_localstatedir}/spool/x2goprint

%if 0%{?fedora} || 0%{?rhel} >= 7
# System.d session cleanup script
mkdir -p %{buildroot}%{_unitdir}
install -pm0644 %SOURCE1 %{buildroot}%{_unitdir}
%else
# SysV session cleanup script
%if 0%{?el5}
mkdir -p %{buildroot}%{_initrddir}
install -pm0755 %SOURCE2 %{buildroot}%{_initrddir}/x2goserver
%else
mkdir -p %{buildroot}%{_initddir}
install -pm0755 %SOURCE2 %{buildroot}%{_initddir}/x2goserver
%endif
%endif

%if 0%{?el5}
echo "Encoding=UTF-8" >> %{buildroot}%{_datadir}/applications/x2gofm.desktop
%endif
desktop-file-validate %{buildroot}%{_datadir}/applications/x2gofm.desktop


%pre common
getent group x2gouser >/dev/null || groupadd -r x2gouser
getent passwd x2gouser >/dev/null || \
    useradd -r -g x2gouser -d /var/lib/x2go -s /sbin/nologin \
    -c "x2go" x2gouser
exit 0


%post
# Initialize the session database
[ ! -s %{_sharedstatedir}/x2go/x2go_sessions ] &&
  [ -d %{_datadir}/doc/packages/perl-X2Go-Server-DB ] &&
  egrep "^backend=sqlite.*" /etc/x2go/x2gosql/sql >/dev/null 2>&1 &&
  %{_sbindir}/x2godbadmin --createdb >/dev/null 2>&1 || :

egrep "^backend=sqlite.*" /etc/x2go/x2gosql/sql 1>/dev/null 2>/dev/null && { [ ! -s %{_sharedstatedir}/x2go/x2go_sessions ] && %{_sbindir}/x2godbadmin --createdb 1>/dev/null 2>/dev/null || %{_sbindir}/x2godbadmin --updatedb 1>/dev/null 2>/dev/null; }

%if 0%{?fedora} || 0%{?rhel} >= 7
%systemd_post x2goserver.service

%preun
%systemd_preun x2goserver.service

%postun
%systemd_postun x2goserver.service
%else
/sbin/chkconfig --add x2goserver
/sbin/service x2goserver condrestart >/dev/null 2>&1 || :

%postun
if [ "$1" -ge "1" ] ; then
    /sbin/service x2goserver condrestart >/dev/null 2>&1 || :
fi

%preun
if [ "$1" = 0 ]; then
        /sbin/service x2goserver stop >/dev/null 2>&1
        /sbin/chkconfig --del x2goserver
fi
%endif


%post -n perl-X2Go-Server-DB
# Initialize the session database
[ ! -s %{_sharedstatedir}/x2go/x2go_sessions ] &&
  [ -x %{_sbindir}/x2godbadmin ] &&
  egrep "^backend=sqlite.*" /etc/x2go/x2gosql/sql >/dev/null 2>&1 &&
  %{_sbindir}/x2godbadmin --createdb >/dev/null 2>&1 ||

%post fmbindings
/usr/bin/update-mime-database /usr/share/mime &>/dev/null || :
/usr/bin/update-desktop-database &>/dev/null || :

%postun fmbindings
if [ $1 -eq 0 ] ; then
        /usr/bin/update-mime-database /usr/share/mime &>/dev/null || :
        /usr/bin/update-desktop-database &>/dev/null || :
fi

%pre printing
getent group x2goprint >/dev/null || groupadd -r x2goprint
getent passwd x2goprint >/dev/null || \
    useradd -r -g x2goprint -d /var/spool/x2goprint -s /sbin/nologin \
    -c "x2go" x2goprint
exit 0

%files
%doc debian/copyright
%doc debian/changelog
%config(noreplace) %{_sysconfdir}/logcheck/ignore.d.server/x2goserver
%config(noreplace) %{_sysconfdir}/sudoers.d/x2goserver
%dir %{_sysconfdir}/x2go/
%config(noreplace) %{_sysconfdir}/x2go/x2go*
%{_bindir}/x2go*
%exclude %{_bindir}/x2goserver-run-extensions
%exclude %{_bindir}/x2gofm
%exclude %{_bindir}/x2goprint
%dir %{_libdir}/x2go
%{_libdir}/x2go/x2gochangestatus
%{_libdir}/x2go/x2gocreatesession
%{_libdir}/x2go/x2gocreateshadowsession
%{_libdir}/x2go/x2gogetagent
%{_libdir}/x2go/x2gogetdisplays
%{_libdir}/x2go/x2gogetports
%{_libdir}/x2go/x2gogetstatus
%{_libdir}/x2go/x2goinsertport
%{_libdir}/x2go/x2goinsertsession
%{_libdir}/x2go/x2goinsertshadowsession
%{_libdir}/x2go/x2golistsessions_sql
%{_libdir}/x2go/x2gologlevel
%{_libdir}/x2go/x2goresume
%{_libdir}/x2go/x2gormforward
%{_libdir}/x2go/x2gormport
%{_libdir}/x2go/x2gosuspend-agent
%{_libdir}/x2go/x2gogetagentstate
%{_libdir}/x2go/x2gosyslog
%{_sbindir}/x2go*
%{_mandir}/man8/x2go*.8*
%exclude %{_mandir}/man8/x2goserver-run-extensions.8*
%exclude %{_mandir}/man8/x2gofm.8*
%exclude %{_mandir}/man8/x2goprint.8*
%dir %{_datadir}/x2go/x2gofeature.d/
%{_datadir}/x2go/x2gofeature.d/x2goserver.features
%{_datadir}/x2go/versions/VERSION.x2goserver
%attr(0775,root,x2gouser) %dir %{_sharedstatedir}/x2go/
%ghost %attr(0660,root,x2gouser) %{_sharedstatedir}/x2go/x2go_sessions
%if 0%{?fedora} || 0%{?rhel} >= 7
%{_unitdir}/x2goserver.service
%else
%if 0%{?el5}
%{_initrddir}/x2goserver
%else
%{_initddir}/x2goserver
%endif
%endif


%files -n perl-X2Go-Log
%{perl_vendorlib}/X2Go/Log.pm
%{_mandir}/man3/X2Go::Log.*


%files -n perl-X2Go-Server
%{perl_vendorlib}/X2Go/Config.pm
%{perl_vendorlib}/X2Go/Server.pm
%{perl_vendorlib}/X2Go/SupeReNicer.pm
%{perl_vendorlib}/X2Go/Utils.pm
%{perl_vendorlib}/X2Go/Server/Agent*
%{_mandir}/man3/X2Go::Config.*
%{_mandir}/man3/X2Go::Server.*
%{_mandir}/man3/X2Go::SupeReNicer.*
%{_mandir}/man3/X2Go::Utils.*
%{_mandir}/man3/X2Go::Server::Agent.*
%{_mandir}/man3/X2Go::Server::Agent::*


%files -n perl-X2Go-Server-DB
%dir %{_libdir}/x2go
%{perl_vendorlib}/X2Go/Server/DB*
%attr(2775,root,x2gouser) %{_libdir}/x2go/libx2go-server-db-sqlite3-wrapper
%{_libdir}/x2go/libx2go-server-db-sqlite3-wrapper.pl
%{_mandir}/man3/X2Go::Server::DB.*
%{_mandir}/man3/X2Go::Server::DB::*


%files common
%dir %{_sysconfdir}/x2go/
%dir %{_sysconfdir}/x2go/x2gosql
%config(noreplace) %{_sysconfdir}/x2go/x2go*
%{_mandir}/man5/x2goserver.conf.5.gz
%dir %{_datadir}/x2go/versions
%{_datadir}/x2go/versions/VERSION.x2goserver-common


%files extensions
%{_libdir}/x2go/extensions
%{_bindir}/x2goserver-run-extensions
%{_datadir}/x2go/x2gofeature.d/x2goserver-extensions.features
%{_datadir}/x2go/versions/VERSION.x2goserver-extensions
%{_mandir}/man8/x2goserver-run-extensions.8*


%files fmbindings
%{_bindir}/x2gofm
%{_datadir}/applications/x2gofm.desktop
%{_datadir}/mime/packages/sshfs-x2go.xml
%{_datadir}/x2go/versions/VERSION.x2goserver-fmbindings
%{_datadir}/x2go/x2gofeature.d/x2goserver-fmbindings.features
%{_mandir}/man8/x2gofm.8*


%files printing
%{_bindir}/x2goprint
%{_datadir}/x2go/versions/VERSION.x2goserver-printing
%{_datadir}/x2go/x2gofeature.d/x2goserver-printing.features
%attr(0700,x2goprint,x2goprint) %{_localstatedir}/spool/x2goprint
%{_mandir}/man8/x2goprint.8*


%files xsession
%{_sysconfdir}/x2go/xinitrc.d
%if 0%{?fedora} || 0%{?rhel}
%{_sysconfdir}/x2go/Xclients.d
%endif
%{_sysconfdir}/x2go/Xresources
%config(noreplace) %{_sysconfdir}/x2go/Xsession
%{_datadir}/x2go/x2gofeature.d/x2goserver-xsession.features
%{_datadir}/x2go/versions/VERSION.x2goserver-xsession


%changelog
