#!/bin/bash
# Will create RPM packages inside docker images, the latters will be
# deleted and packages can be retrieved in $WORK_DIR/packages

WORK_DIR=/tmp/jasmin-packager-rpm
COMMONS_DIR=./commons

if [ $# -ne 2 ]; then
    echo "Usage: $0 pypi-version redhat-version"
    echo "Example:"
    echo "$0 0.6b19 0.6.19"
    echo
    echo "Tips:"
    echo " - changelog have to be updated manually."
    echo
    exit 1
fi

PYPI_JASMIN_URL="https://pypi.python.org/packages/source/j/jasmin/jasmin-$1.tar.gz"
PYPI_TXAMQP_URL="https://pypi.python.org/packages/source/t/txAMQP/txAMQP-0.6.2.tar.gz"
PYPI_PYPARS_URL="https://pypi.python.org/packages/source/p/pyparsing/pyparsing-2.0.3.tar.gz"
TWISTED_URL="https://pypi.python.org/packages/source/T/Twisted/Twisted-15.4.0.tar.bz2"
ZOPE_IFACE_URL="https://pypi.python.org/packages/source/z/zope.interface/zope.interface-4.1.3.tar.gz"

[ -d $COMMONS_DIR ] || exit 10

# Reset work folder
[ -d $WORK_DIR ] && rm -rf $WORK_DIR
mkdir -p $WORK_DIR/packages $WORK_DIR/images/centos7

# Update package version

# Init Centos7 Dockerfile:
DOCKER_FILE=$WORK_DIR/images/centos7/Dockerfile
cp $COMMONS_DIR/REDHAT/python-jasmin.spec $WORK_DIR/images/centos7/
sed -i "s/%pypiversion%/$1/" $WORK_DIR/images/centos7/python-jasmin.spec
sed -i "s/%rhversion%/$2/" $WORK_DIR/images/centos7/python-jasmin.spec
echo "FROM centos:7" > $DOCKER_FILE
echo "VOLUME $WORK_DIR/packages" >> $DOCKER_FILE
echo "MAINTAINER Jookies LTD <jasmin@jookies.net>" >> $DOCKER_FILE
echo "RUN mkdir -p ~/rpmbuild/{RPMS,SRPMS,BUILD,SOURCES,SPECS}" >> $DOCKER_FILE
echo "ADD ./python-jasmin.spec /rpmbuild/SPECS/python-jasmin.spec" >> $DOCKER_FILE
echo "RUN yum -y install rpm-build tar python-setuptools gcc bzip2 python-devel" >> $DOCKER_FILE
echo "RUN curl 'https://bootstrap.pypa.io/get-pip.py'|python" >> $DOCKER_FILE
echo "RUN curl '$PYPI_JASMIN_URL' -o ~/rpmbuild/SOURCES/jasmin-$1.tar.gz" >> $DOCKER_FILE
echo "RUN curl '$PYPI_TXAMQP_URL' -o ~/rpmbuild/SOURCES/txAMQP-0.6.2.tar.gz" >> $DOCKER_FILE
echo "RUN curl '$PYPI_PYPARS_URL' -o ~/rpmbuild/SOURCES/pyparsing-2.0.3.tar.gz" >> $DOCKER_FILE
echo "RUN curl '$TWISTED_URL' -o ~/rpmbuild/SOURCES/Twisted-15.4.0.tar.bz2" >> $DOCKER_FILE
echo "RUN curl '$ZOPE_IFACE_URL' -o ~/rpmbuild/SOURCES/zope.interface-4.1.3.tar.gz" >> $DOCKER_FILE
echo "RUN rpmbuild -ba ~/rpmbuild/SPECS/python-jasmin.spec" >> $DOCKER_FILE

# Create rpm inside a centos 7 container
docker build --rm=true -t jasmin-centos7-rpm $WORK_DIR/images/centos7
docker run --rm -v $WORK_DIR/packages:/tmp/packages -it jasmin-centos7-rpm /bin/sh -c 'cp /rpmbuild/RPMS/x86_64/*.rpm /tmp/packages'
docker rmi -f jasmin-centos7-rpm

# Get packages
mv $WORK_DIR/packages/*.rpm packages/
