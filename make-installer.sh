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

VERSION=`grep '<version>' "$TOPDIR/opennms-build/pom.xml" | head -n 1 | sed -e 's,^.*<version>,,' -e 's,<.*$,,'`

pushd "$TOPDIR/opennms-build"
	[ -z "$SKIP_CLEAN" ] && ./build.sh clean
	[ -z "$SKIP_BUILD" ] && ./build.sh \
		-Dinstall.database.name='$izpackDatabaseName' \
		-Dinstall.database.url='jdbc:postgresql://$izpackDatabaseHost:5432/' \
		-Dopennms.home="$REPLACEMENT_TOKEN" \
		install assembly:directory-inline
popd

BINARY_DIRECTORY=`ls -d -1 "$TOPDIR/opennms-build/target/"opennms-*-SNAPSHOT`
TEMP_DIRECTORY="$TOPDIR/izpack-temp"

rsync -avr --progress --delete "$BINARY_DIRECTORY"/ "$TEMP_DIRECTORY"/
./handle-tokens.pl "$TEMP_DIRECTORY" "$REPLACEMENT_TOKEN" '$INSTALL_PATH' "$VERSION"

cp LICENSE userInputSpec.xml ProcessPanel.Spec.xml "$TEMP_DIRECTORY/"
cp discovery-configuration.xml "$TEMP_DIRECTORY/etc/"
cp jicmp.dll "$TEMP_DIRECTORY/lib/"

"$IZPACK_COMPILE" install.xml -b "$TEMP_DIRECTORY" -o opennms-installer.jar -k standard
