#!/bin/sh -e

TOPDIR=`pwd -P`
IZPACK_HOME="$TOPDIR/izpack"
IZPACK_COMPILE="$IZPACK_HOME/bin/compile"
REPLACEMENT_TOKEN="XXX_TOKENIZE_ME_XXX"

export IZPACK_HOME

# build OpenNMS
if [ -d "$TOPDIR/opennms-build" ]; then
	svn up "$TOPDIR/opennms-build"
else
	svn co http://opennms.svn.sourceforge.net/svnroot/opennms/opennms/trunk "$TOPDIR/opennms-build"
fi

pushd "$TOPDIR/opennms-build"
	[ -z "$SKIP_CLEAN" ] && ./build.sh clean
	./build.sh -Droot.dir="$REPLACEMENT_TOKEN" install assembly:directory-inline
popd

BINARY_DIRECTORY="$TOPDIR/opennms-build/target/"opennms-*-SNAPSHOT
TEMP_DIRECTORY="$TOPDIR/izpack-temp"

rsync -avr --delete "$BINARY_DIRECTORY"/ "$TEMP_DIRECTORY"/
./handle-tokens.pl "$TEMP_DIRECTORY" "$REPLACEMENT_TOKEN" '$INSTALL_PATH'

cp LICENSE UserInputSpec.xml "$TEMP_DIRECTORY/"
cp discovery-configuration.xml "$TEMP_DIRECTORY/etc/"

"$IZPACK_COMPILE" install.xml -b "$TEMP_DIRECTORY" -o opennms-installer.jar -k standard
