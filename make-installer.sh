#!/bin/sh -e

TOPDIR=`pwd -P`
IZPACK_HOME="$TOPDIR/izpack"
IZPACK_COMPILE="$IZPACK_HOME/bin/compile"
REPLACEMENT_TOKEN="XXX_TOKENIZE_ME_XXX"

if [ -z "$JAVA_HOME" ]; then
	JAVA_HOME=`ls -d /usr/java/jdk1* | sort -r -u | head -n 1`
fi
PATH="$JAVA_HOME/bin:$PATH"

if [ -e "settings.xml" ]; then
	SETTINGS_XML="-s $TOPDIR/settings.xml"
fi

export IZPACK_HOME PATH JAVA_HOME

# build OpenNMS
if [ -z "$SKIP_BUILD" ]; then
	if [ -d "$TOPDIR/opennms-build" ]; then
		svn up "$TOPDIR/opennms-build"
	else
		svn co http://opennms.svn.sourceforge.net/svnroot/opennms/opennms/trunk "$TOPDIR/opennms-build"
	fi

	pushd "$TOPDIR/opennms-build"
		[ -z "$SKIP_CLEAN" ] && ./build.sh $SETTINGS_XML clean
		./build.sh $SETTINGS_XML -Dbuild=all \
			-Dinstall.database.name='$izpackDatabaseName' \
			-Dinstall.database.url='jdbc:postgresql://$izpackDatabaseHost:5432/' \
			-Dopennms.home="$REPLACEMENT_TOKEN" \
			install assembly:directory-inline
	popd
fi

VERSION=`grep '<version>' "$TOPDIR/opennms-build/pom.xml" | head -n 1 | sed -e 's,^.*<version>,,' -e 's,<.*$,,'`
BINARY_DIRECTORY=`ls -d -1 "$TOPDIR/opennms-build/target/"opennms-*`
TEMP_DIRECTORY="$TOPDIR/izpack-temp"

rsync -avr --progress --delete "$BINARY_DIRECTORY"/ "$TEMP_DIRECTORY"/
./handle-tokens.pl "$TEMP_DIRECTORY" "($REPLACEMENT_TOKEN|$BINARY_DIRECTORY)" '$UNIFIED_INSTALL_PATH' "$VERSION"

cp LICENSE ProcessPanel.Spec.xml userInputSpec.xml "$TEMP_DIRECTORY/"
cp *.bat "$TEMP_DIRECTORY/bin/"
cp discovery-configuration.xml java.conf.* opennms-datasources.xml "$TEMP_DIRECTORY/etc/"
cp native/* "$TEMP_DIRECTORY/lib/"

"$IZPACK_COMPILE" install.xml -b "$TEMP_DIRECTORY" -o standalone-opennms-installer-$VERSION.jar -k standard
