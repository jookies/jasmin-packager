Name:                 python-jasmin
Version:              %rhversion%
Release:              1%{?dist}
Summary:              SMS Gateway
Group:                System Environment/Daemons
License:              Apache2.0
URL:                  http://www.jasminsms.com

Source0:              https://pypi.python.org/packages/source/j/jasmin/jasmin-%pypiversion%.tar.gz
Source1:              https://pypi.python.org/packages/source/t/txAMQP/txAMQP-0.6.2.tar.gz
Source2:              https://pypi.python.org/packages/source/p/pyparsing/pyparsing-2.0.3.tar.gz
Source3:              https://pypi.python.org/packages/source/T/Twisted/Twisted-15.4.0.tar.bz2
Source4:              https://pypi.python.org/packages/source/z/zope.interface/zope.interface-4.1.3.tar.gz
BuildArch:            x86_64
BuildRoot:            %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildRequires:        python-setuptools
BuildRequires:        tar, gcc, bzip2
BuildRequires:        systemd
Requires(post):       systemd
Requires(preun):      systemd
Requires(postun):     systemd
Requires:             python >= 2.7.0, python-dateutil, python-lockfile, pyOpenSSL
Requires:             rabbitmq-server, redis
Requires(pre):        /usr/sbin/useradd, /usr/sbin/groupadd, /usr/bin/getent

%description
Jasmin is a very complete open source SMS Gateway with many enterprise-class
features such as:
.
 - SMPP Client / Server
 - HTTP Client / Server
 - Console-based configuration, no service restart required
 - Based on AMQP broker for store&forward mechanisms and other queuing systems
 - Using Redis for in-memory DLR tracking and billing
 - Advanced message routing/filtering
 - Web and console ui for management
 - Supports Unicode (UTF-8) for sending out multilingual SMS
 - Supports easy creation and sending of specialized/binary SMS
 - Supports concatenated SMS strings (long SMS)
.
Jasmin relies heavily on message queuing through message brokers
(Using AMQP), it is designed for performance, high traffic loads and full
in-memory execution.

%pre
/usr/bin/getent group jasmin > /dev/null || /usr/sbin/groupadd --system jasmin
/usr/bin/getent passwd jasmin > /dev/null || /usr/sbin/useradd \
  --system \
  --home-dir /usr/lib/jasmin \
  --no-create-home \
  --comment "Jasmin SMS Gateway" \
  --shell /sbin/nologin \
  --gid jasmin \
  jasmin

%prep
%setup -T -c -a 0
%setup -T -D -c -a 1
%setup -T -D -c -a 2
%setup -T -D -c -a 3
%setup -T -D -c -a 4

%build
cd jasmin-%pypiversion%
%{__python} setup.py build
cd ../pyparsing-2.0.3
%{__python} setup.py build
cd ../txAMQP-0.6.2
%{__python} setup.py build
cd ../Twisted-15.4.0
%{__python} setup.py build
cd ../zope.interface-4.1.3
%{__python} setup.py build

%install
rm -rf %{buildroot}
cd jasmin-%pypiversion%

# Install Jasmin
%{__python} setup.py install --skip-build --optimize=2 --root=%{buildroot}
mkdir -p %{buildroot}/etc/jasmin/store
mkdir -p %{buildroot}/etc/jasmin/resource
chmod +x %{buildroot}/usr/bin/jasmind.py
chmod +x %{buildroot}/usr/bin/interceptord.py
install -m0644 misc/config/jasmin.cfg %{buildroot}/etc/jasmin/jasmin.cfg
install -m0644 misc/config/interceptor.cfg %{buildroot}/etc/jasmin/interceptor.cfg
install -m0644 misc/config/resource/amqp0-9-1.xml %{buildroot}/etc/jasmin/resource/amqp0-9-1.xml
install -m0644 misc/config/resource/amqp0-8.stripped.rabbitmq.xml %{buildroot}/etc/jasmin/resource/amqp0-8.stripped.rabbitmq.xml

# Install systemd units for Jasmin
mkdir -p %{buildroot}/%{_unitdir}
install -m0644 misc/config/systemd/jasmind.service %{buildroot}/%{_unitdir}/jasmind.service
install -m0644 misc/config/systemd/interceptord.service %{buildroot}/%{_unitdir}/interceptord.service

# Install other requirements
cd ../pyparsing-2.0.3
%{__python} setup.py install --skip-build --optimize=2 --root=%{buildroot}
cd ../txAMQP-0.6.2
%{__python} setup.py install --skip-build --optimize=2 --root=%{buildroot}
cd ../Twisted-15.4.0
%{__python} setup.py install --skip-build --optimize=2 --root=%{buildroot}
cd ../zope.interface-4.1.3
%{__python} setup.py install --skip-build --optimize=2 --root=%{buildroot}

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%config(noreplace) /etc/jasmin
/usr/bin/jasmind.py
/usr/bin/interceptord.py
%{_unitdir}/jasmind.service
%{_unitdir}/interceptord.service
%{python_sitelib}/jasmin
%{python_sitelib}/txamqp
%{python_sitelib}/pyparsing.*
%{python_sitelib}/*.egg-info
%{python_sitearch}/zope
%{python_sitearch}/twisted
%{python_sitearch}/Twisted-15.4.0
/usr/bin/pyhtmlizer
/usr/bin/tap2deb
/usr/bin/ckeygen
/usr/bin/conch
/usr/bin/tkconch
/usr/bin/twistd
/usr/bin/cftp
/usr/bin/manhole
/usr/bin/tap2rpm
/usr/bin/trial
/usr/bin/mailmail

%post
mkdir /var/log/jasmin
chown jasmin:jasmin /etc/jasmin/store
chown jasmin:jasmin /var/log/jasmin
%systemd_post jasmind.service
%systemd_post interceptord.service

%preun
%systemd_preun jasmind.service
%systemd_preun interceptord.service

%postun
%systemd_postun_with_restart jasmind.service
%systemd_postun_with_restart interceptord.service

%changelog
* Sat Oct 31 2015 Jookies LTD <jasmin@jookies.net> - %rhversion%
- TODO: correct changelog for rpm packaging
