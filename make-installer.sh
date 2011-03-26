#!/bin/sh -e

TOPDIR=`pwd -P`
if [ -z "$IZPACK_HOME" ]; then
	IZPACK_HOME="$TOPDIR/izpack"
fi
IZPACK_COMPILE="$IZPACK_HOME/bin/compile"
REPLACEMENT_TOKEN="XXX_TOKENIZE_ME_XXX"

INSTALL_XML="install.xml"

if [ -z "$JAVA_HOME" ]; then
	JAVA_HOME=`ls -d /usr/java/jdk1* | sort -r -u | head -n 1`
fi
PATH="$JAVA_HOME/bin:$PATH"

if [ -e "settings.xml" ]; then
	SETTINGS_XML="-s $TOPDIR/settings.xml"
fi

export IZPACK_HOME PATH JAVA_HOME

if [ "$OPENNMS_SKIP_PULL" != 1 ]; then
	pushd "$TOPDIR/opennms-build"
		git pull
	popd
fi

if [ "$OPENNMS_SKIP_CLEAN" != 1 ]; then
	pushd "$TOPDIR/opennms-build"
		./compile.pl $SETTINGS_XML clean
		./assemble.pl $SETTINGS_XML clean
	popd
fi

if [ "$OPENNMS_SKIP_COMPILE" != 1 ]; then
	pushd "$TOPDIR/opennms-build"
		./compile.pl $SETTINGS_XML -Dbuild=all \
			-Dinstall.database.name='$izpackDatabaseName' \
			-Dinstall.database.url='jdbc:postgresql://$izpackDatabaseHost:5432/' \
			-Dinstall.database.admin.user='$izpackDatabaseAdminUser' \
			-Dinstall.database.admin.password='$izpackDatabaseAdminPass' \
			-Dopennms.home="$REPLACEMENT_TOKEN" \
			-Dbuild.profile=fulldir \
			install
	popd
fi

if [ "$OPENNMS_SKIP_ASSEMBLE" != 1 ]; then
	pushd "$TOPDIR/opennms-build"
		./assemble.pl $SETTINGS_XML -Dbuild=all \
			-Dinstall.database.name='$izpackDatabaseName' \
			-Dinstall.database.url='jdbc:postgresql://$izpackDatabaseHost:5432/' \
			-Dinstall.database.admin.user='$izpackDatabaseAdminUser' \
			-Dinstall.database.admin.password='$izpackDatabaseAdminPass' \
			-Dopennms.home="$REPLACEMENT_TOKEN" \
			-Dbuild.profile=fulldir \
			install
	popd
fi

DATESTAMP=`date '+%Y%m%d'`
VERSION=`grep '<version>' "$TOPDIR/opennms-build/pom.xml" | head -n 1 | sed -e 's,^.*<version>,,' -e 's,<.*$,,'`
VERSION=`echo $VERSION | sed -e "s,-SNAPSHOT,-${DATESTAMP},g"`
if [ -n "$1" ]; then
	VERSION="$1"; shift
fi
BINARY_DIRECTORY=`ls -d -1 "$TOPDIR/opennms-build/target/"opennms-* | grep -v -E 'tar.gz$' | sort -u | tail -1`
if [ -z "$BINARY_DIRECTORY" ]; then
	echo "build failed!"
	exit 1
fi
TEMP_DIRECTORY="$TOPDIR/izpack-temp"

rsync -avr --progress --delete "$BINARY_DIRECTORY"/ "$TEMP_DIRECTORY"/
./handle-tokens.pl "$TEMP_DIRECTORY" "($REPLACEMENT_TOKEN|$BINARY_DIRECTORY)" '$UNIFIED_INSTALL_PATH' "$VERSION"

cp LICENSE README.html logo.png ProcessPanel.Spec.xml userInput*.xml* "$TEMP_DIRECTORY/"
cp *.bat "$TEMP_DIRECTORY/bin/"
cp discovery-configuration.xml java.conf.* opennms-datasources.xml "$TEMP_DIRECTORY/etc/"
cp native/* "$TEMP_DIRECTORY/lib/"

INSTALLER_NAME="standalone-opennms-installer-$VERSION"
ZIP_DIRECTORY="opennms-installer"
rm -rf "$TOPDIR/$ZIP_DIRECTORY"
mkdir -p "$TOPDIR/$ZIP_DIRECTORY"
"$IZPACK_COMPILE" $INSTALL_XML -b "$TEMP_DIRECTORY" -o "$TOPDIR/$ZIP_DIRECTORY/$INSTALLER_NAME.jar" -k standard
cp INSTALL.txt launcher.ini setup??.exe "$TOPDIR/$ZIP_DIRECTORY/"
if [ "$OPENNMS_SKIP_ZIP" != 1 ]; then
	pushd "$TOPDIR" >/dev/null 2>&1
		zip -9 "$INSTALLER_NAME.zip" -r "$ZIP_DIRECTORY"
	popd >/dev/null 2>&1
fi
