Name:           x2goserver
Version:        4.0.1.9
Release:        0x2go1%{?dist}
Summary:        X2Go Server

Group:          Applications/Communications
License:        GPLv2+
URL:            http://www.x2go.org
Source0:        http://code.x2go.org/releases/source/%{name}/%{name}-%{version}.tar.gz
# git clone git://code.x2go.org/x2goserver
# cd x2goserver
# git archive --prefix=x2goserver-4.1.0.0-20130722git65169c9/ 65169c9d65b117802e50631be0bbd719163d969e | gzip > ../x2goserver-4.1.0.0-20130722git65169c9.tar.gz
#Source0:        %{name}/%{name}-%{version}-%{checkout}.tar.gz
Source1:        x2gocleansessions.service
Source2:        x2gocleansessions.init

BuildRequires:  perl(ExtUtils::MakeMaker)
%if 0%{?fedora}
BuildRequires:  man2html-core
BuildRequires:  systemd
%else
BuildRequires:  man
%endif
# So XSESSIONDIR gets linked
BuildRequires:  xorg-x11-xinit
# For x2goruncommand - for now
Requires:       bc
# For netstat in x2goresume-session
Requires:       net-tools
Requires:       openssh-server
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
# We need a database
Requires:       perl(DBD::SQLite)
# For killall in x2gosuspend-session
Requires:       psmisc
Requires:       pwgen
# For printing, file-sharing
Requires:       sshfs
# For /etc/sudoers.d
Requires:       sudo
Requires:       x2goagent
# For /etc/X11/Xresources
Requires:       xorg-x11-xinit
Requires:       xorg-x11-fonts-misc
Requires(pre):  shadow-utils

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


%package printing
Summary:        X2Go server printing support
Requires:       %{name} = %{version}-%{release}

%description printing
The X2Go server printing package provides client-side printing support for
X2Go.

This package has to be installed on X2Go servers that shall be able to pass
X2Go print jobs on to the X2Go client.

This package co-operates with the cups-x2go CUPS backend. If CUPS server and
X2Go server are hosted on different machines, then make sure you install
this package on the X2Go server(s) (and the cups-x2go package on the CUPS
server).


%prep
%setup -q

# Set path
#find -type f | xargs sed -i -r -e '/^((LIBDIR|X2GO_LIB_PATH)=|use lib|my \$x2go_lib_path)/s,/lib/,/%{_lib}/,'
find -type f | xargs sed -i -r -e '/^LIBDIR=/s,/lib/,/%{_lib}/,'
sed -i -e 's,/lib/,/%{_lib}/,' x2goserver/bin/x2gopath
# Don't try to be root
sed -i -e 's/-o root -g root//' */Makefile
# Perl pure_install
sed -i -e 's/perl install/perl pure_install/' Makefile


%build
export PATH=%{_qt4_bindir}:$PATH
make CFLAGS="%{optflags} -fPIC" %{?_smp_mflags} PERL_INSTALLDIRS=vendor PREFIX=%{_prefix}


%install
make install DESTDIR=%{buildroot} PREFIX=%{_prefix} XSESSIONDIR=/etc/X11/xinit/Xclients.d

# Make symbolic link relative
rm %{buildroot}%{_sysconfdir}/x2go/Xresources
ln -s ../X11/Xresources %{buildroot}%{_sysconfdir}/x2go/

# Remove placeholder files
rm %{buildroot}%{_libdir}/x2go/extensions/*.d/.placeholder

# x2gouser homedir, state dir
mkdir -p %{buildroot}%{_sharedstatedir}/x2go
# Create empty session file for %%ghost
touch %{buildroot}%{_sharedstatedir}/x2go/x2go_sessions

# Printing spool dir
mkdir -p %{buildroot}%{_localstatedir}/spool/x2goprint

%if 0%{?fedora}
# System.d session cleanup script
mkdir -p %{buildroot}%{_unitdir}
install -pm0644 %SOURCE1 %{buildroot}%{_unitdir}
%else
# SysV session cleanup script
mkdir -p %{buildroot}%{_initddir}
install -pm0755 %SOURCE2 %{buildroot}%{_initddir}/x2gocleansessions
%endif

%pre
getent group x2gouser >/dev/null || groupadd -r x2gouser
getent passwd x2gouser >/dev/null || \
    useradd -r -g x2gouser -d /var/lib/x2go -s /sbin/nologin \
    -c "x2go" x2gouser
exit 0

%post
# Initialize the session database
[ ! -f %{_sharedstatedir}/x2go/x2go_sessions ] &&
  %{_sbindir}/x2godbadmin --createdb || :

%if 0%{?fedora}
%systemd_post x2gocleansessions.service

%preun
%systemd_preun x2gocleansessions.service

%postun
%systemd_postun x2gocleansessions.service
%else
/sbin/chkconfig --add x2gocleansessions

%postun
if [ "$1" -ge "1" ] ; then
    /sbin/service x2gocleansessions condrestart >/dev/null 2>&1 || :
fi

%preun
if [ "$1" = 0 ]; then
        /sbin/service x2gocleansessions stop >/dev/null 2>&1
        /sbin/chkconfig --del x2gocleansessions
fi
%endif

%pre printing
getent group x2goprint >/dev/null || groupadd -r x2goprint
getent passwd x2goprint >/dev/null || \
    useradd -r -g x2goprint -d /var/spool/x2goprint -s /sbin/nologin \
    -c "x2go" x2goprint
exit 0


%files
%doc debian/copyright
%doc debian/changelog
%config(noreplace) %{_sysconfdir}/sudoers.d/x2goserver
%dir %{_sysconfdir}/x2go/
%config(noreplace) %{_sysconfdir}/x2go/x*
%config(noreplace) %{_sysconfdir}/x2go/Xsession.options
%{_sysconfdir}/x2go/Xresources
%{_sysconfdir}/x2go/Xsession
%{_sysconfdir}/x2go/Xsession.d
%{_bindir}/x2go*
%exclude %{_bindir}/x2goprint
%dir %{_libdir}/x2go
%{_libdir}/x2go/extensions
%{_libdir}/x2go/x2gosqlitewrapper.pl
%attr(02755,root,x2gouser) %{_libdir}/x2go/x2gosqlitewrapper
%{_libdir}/x2go/x2gochangestatus
%{_libdir}/x2go/x2gocreatesession
%{_libdir}/x2go/x2godbwrapper.pm
%{_libdir}/x2go/x2gogetagent
%{_libdir}/x2go/x2gogetdisplays
%{_libdir}/x2go/x2gogetports
%{_libdir}/x2go/x2gogetstatus
%{_libdir}/x2go/x2goinsertport
%{_libdir}/x2go/x2goinsertsession
%{_libdir}/x2go/x2golistsessions_sql
%{_libdir}/x2go/x2gologlevel
%{_libdir}/x2go/x2gologlevel.pm
%{_libdir}/x2go/x2goresume
%{_libdir}/x2go/x2gormport
%{_libdir}/x2go/x2gosuspend-agent
%{_libdir}/x2go/x2gosyslog
%{_sbindir}/x2go*
%{_mandir}/man8/x2go*.8.gz
%exclude %{_mandir}/man8/x2goprint.8.gz
%{_datadir}/x2go/
%exclude %{_datadir}/x2go/versions/VERSION.x2goserver-printing
%exclude %{_datadir}/x2go/x2gofeature.d/x2goserver-printing.features
%attr(0775,root,x2gouser) %dir %{_sharedstatedir}/x2go/
%ghost %attr(0660,root,x2gouser) %{_sharedstatedir}/x2go/x2go_sessions
%if 0%{?fedora}
%{_unitdir}/x2gocleansessions.service
%else
%{_initddir}/x2gocleansessions
%endif

%files printing
%{_bindir}/x2goprint
%{_mandir}/man8/x2goprint.8.gz
%{_datadir}/x2go/versions/VERSION.x2goserver-printing
%{_datadir}/x2go/x2gofeature.d/x2goserver-printing.features
%attr(0700,x2goprint,x2goprint) %{_localstatedir}/spool/x2goprint

%changelog
* Wed Nov 27 2013 Orion Poplawski <orion@cora.nwra.com> - 4.0.1.8-2
- Use mktemp instead of tempfile
- BR xorg-x11-xinit for Xsession.d link creation
- Add patch to fix keyboard setting (bug #1033876)

* Sat Nov 23 2013 Orion Poplawski <orion@cora.nwra.com> - 4.0.1.8-1
- Update to 4.0.1.8
- Fix x2gocleansessions init script for EL6 (bug #1031150)

* Tue Oct 22 2013 Orion Poplawski <orion@cora.nwra.com> - 4.0.1.6-6
- Fix bug in x2gocleansessions init script, enable by default

* Wed Sep 11 2013 Orion Poplawski <orion@cora.nwra.com> - 4.0.1.6-5
- Add some needed requires

* Sun Aug 04 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 4.0.1.6-4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_20_Mass_Rebuild

* Tue Jul 30 2013 Orion Poplawski <orion@cora.nwra.com> - 4.0.1.6-3
- Mark /var/lib/x2go as a directory
- Add patch to make the following changes:
- Remove Xsession.options
- Make /etc/x2go/Xsession.d point to /etc/X11/xinit/Xclients.d
- Make /etc/x2go/Xsession executable

* Mon Jul 29 2013 Orion Poplawski <orion@cora.nwra.com> - 4.0.1.6-2
- Add SysV init script for EL6

* Mon Jul 29 2013 Orion Poplawski <orion@cora.nwra.com> - 4.0.1.6-1
- Use 4.0.1.6 release
- Drop patches applied upstream

* Mon Jul 22 2013 Rok Mandeljc <rok.mandeljc@gmail.com> - 4.1.0.0-0.4.20130722git65169c9
- Update to latest git
- Use PREFIX=%{_prefix} when building, not just when installing.
- Use pwgen instead of makepasswd, which is not available on Fedora.
- Fixed a missing function import in x2golistsessions.
- Added dependencies for xorg-x11-fonts-misc
- Added system.d script for session cleanup on start.
- Fixed x2goruncommand for TERMINAL -> gnome-terminal; the latter seems to return immediately in Fedora 19.

* Thu May 30 2013 Orion Poplawski <orion@cora.nwra.com> - 4.1.0.0-0.3.20130520gitbd2cfe4
- Update to latest git
- Split out printing sub-package

* Wed Jan 23 2013 Orion Poplawski <orion@cora.nwra.com> - 4.1.0.0-0.2.20130122git
- Add post script to create session database if needed

* Tue Jan 22 2013 Orion Poplawski <orion@cora.nwra.com> - 4.1.0.0-0.1.20130122git
- Update to 4.1.0.0 git

* Fri Jan 18 2013 Orion Poplawski <orion@cora.nwra.com> - 4.0.0.0-1
- Update to 4.0.0.0

* Tue Dec 11 2012 Orion Poplawski <orion@cora.nwra.com> - 3.1.1.9-1
- Initial Fedora package
