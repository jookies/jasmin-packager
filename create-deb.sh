#!/bin/bash

WORK_DIR=/tmp/jasmin-packager
COMMONS_DIR=./commons
PYPI_BASEURL="https://pypi.python.org/packages/source/j/jasmin"

if [ $# -ne 2 ]; then
    echo "Usage: $0 pypi-version debian-version"
    echo "Example:"
    echo "$0 0.6b19 0.6.19-1"
    echo
    echo "Tips:"
    echo " - changelog have to be updated manually."
    echo
    exit 1
fi

[ -d $COMMONS_DIR ] || exit 10

# Reset work folder
[ -d $WORK_DIR ] && rm -rf $WORK_DIR
mkdir $WORK_DIR $WORK_DIR/package $WORK_DIR/jasmin

# Download and build jasmin
curl -o $WORK_DIR/jasmin.tgz "$PYPI_BASEURL/jasmin-$1.tar.gz" || exit 11
tar zxf $WORK_DIR/jasmin.tgz -C $WORK_DIR
cd $WORK_DIR/jasmin-$1
python setup.py bdist || exit 12
cd -

# Prepare work folder
cp -r $COMMONS_DIR/DEBIAN $WORK_DIR/package/

## Documentation
mkdir -p $WORK_DIR/package/usr/share/doc/python-jasmin
cp $COMMONS_DIR/changelog $COMMONS_DIR/copyright $WORK_DIR/package/usr/share/doc/python-jasmin
cp $WORK_DIR/package/usr/share/doc/python-jasmin/changelog $WORK_DIR/package/usr/share/doc/python-jasmin/changelog.Debian
cp $WORK_DIR/jasmin-$1/README.rst $WORK_DIR/package/usr/share/doc/python-jasmin/
gzip --best $WORK_DIR/package/usr/share/doc/python-jasmin/changelog
gzip --best $WORK_DIR/package/usr/share/doc/python-jasmin/changelog.Debian
gzip --best $WORK_DIR/package/usr/share/doc/python-jasmin/README.rst

# Update package version
sed -i "s/%debversion%/$2/" $WORK_DIR/package/DEBIAN/control

## /etc folder
mkdir -p $WORK_DIR/package/etc/init.d $WORK_DIR/package/etc/jasmin/resource $WORK_DIR/package/etc/jasmin/store
cp $WORK_DIR/jasmin-$1/misc/config/jasmin.cfg $WORK_DIR/package/etc/jasmin/
cp $WORK_DIR/jasmin-$1/misc/config/resource/* $WORK_DIR/package/etc/jasmin/resource/
cp $WORK_DIR/jasmin-$1/misc/config/init-script/jasmind-ubuntu $WORK_DIR/package/etc/init.d/jasmind

## /usr folder
mkdir -p $WORK_DIR/package/usr/bin $WORK_DIR/package/usr/lib/python2.7/dist-packages
cp -r $WORK_DIR/jasmin-$1/build/lib.*/jasmin $WORK_DIR/package/usr/lib/python2.7/dist-packages/jasmin
cp $WORK_DIR/package/usr/lib/python2.7/dist-packages/jasmin/bin/jasmind.py $WORK_DIR/package/usr/bin/jasmind

# Remove unneeded files
find $WORK_DIR/package -name ".gitignore" | xargs rm -f 

# Create md5sums
cd $WORK_DIR/package;find usr -type f -exec md5sum {} \; > md5sums;cd -;mv $WORK_DIR/package/md5sums $WORK_DIR/package/DEBIAN

# Fix file & folder permissions
find $WORK_DIR/package -type d | xargs chmod 755
find $WORK_DIR/package -type f | xargs chmod 644
chmod 755 $WORK_DIR/package/DEBIAN/preinst
chmod 755 $WORK_DIR/package/DEBIAN/postinst
chmod 755 $WORK_DIR/package/DEBIAN/prerm
chmod 755 $WORK_DIR/package/DEBIAN/postrm
chmod 755 $WORK_DIR/package/etc/init.d/jasmind
chmod 755 $WORK_DIR/package/usr/bin/jasmind

# Build package
fakeroot dpkg-deb --build $WORK_DIR/package
mv $WORK_DIR/package.deb packages/python-jasmin-$2_all.deb
lintian packages/python-jasmin-$2_all.deb