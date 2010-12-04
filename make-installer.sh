#!/bin/sh -e

TOPDIR=`pwd -P`
if [ -z "$IZPACK_HOME" ]; then
	IZPACK_HOME="$TOPDIR/izpack"
fi
IZPACK_COMPILE="$IZPACK_HOME/bin/compile"
REPLACEMENT_TOKEN="XXX_TOKENIZE_ME_XXX"

INSTALL_XML="install-1.6.xml"

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
	if [ -z "$SKIP_PULL" ]; then
		pushd "$TOPDIR/opennms-build"
			git pull
		popd
	fi

	pushd "$TOPDIR/opennms-build"
		[ -z "$SKIP_CLEAN" ] && ./compile.pl $SETTINGS_XML clean
		[ -z "$SKIP_CLEAN" ] && ./assemble.pl $SETTINGS_XML clean
		./assemble.pl $SETTINGS_XML -Dbuild=all -PbuildDocs \
			-Dinstall.database.name='$izpackDatabaseName' \
			-Dinstall.database.url='jdbc:postgresql://$izpackDatabaseHost:5432/' \
			-Dinstall.database.admin.user='$izpackDatabaseAdminUser' \
			-Dinstall.database.admin.password='$izpackDatabaseAdminPass' \
			-Dopennms.home="$REPLACEMENT_TOKEN" \
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
TEMP_DIRECTORY="$TOPDIR/izpack-temp"

rsync -avr --progress --delete "$BINARY_DIRECTORY"/ "$TEMP_DIRECTORY"/
./handle-tokens.pl "$TEMP_DIRECTORY" "($REPLACEMENT_TOKEN|$BINARY_DIRECTORY)" '$UNIFIED_INSTALL_PATH' "$VERSION"

if [ -d "$TOPDIR/opennms-build/integrations/opennms-map-provisioning-adapter" ]; then
	INSTALL_XML="install.xml"
	cp $TOPDIR/opennms-build/integrations/opennms-dns-provisioning-adapter/target/*.jar  "$TEMP_DIRECTORY/lib/"
	cp $TOPDIR/opennms-build/integrations/opennms-link-provisioning-adapter/target/*.jar "$TEMP_DIRECTORY/lib/"
	cp $TOPDIR/opennms-build/integrations/opennms-map-provisioning-adapter/target/*.jar  "$TEMP_DIRECTORY/lib/"
	cp $TOPDIR/opennms-build/integrations/opennms-rancid/target/*.jar                    "$TEMP_DIRECTORY/lib/"
	rm -rf "$TEMP_DIRECTORY/"lib/*-sources.jar
	rm -rf "$TEMP_DIRECTORY/"lib/*-tests.jar
	rm -rf "$TEMP_DIRECTORY/"lib/*-xsds.jar
	cp $TOPDIR/opennms-build/integrations/opennms-link-provisioning-adapter/src/main/resources/link-adapter-configuration.xml "$TEMP_DIRECTORY/etc/"
	cp $TOPDIR/opennms-build/integrations/opennms-link-provisioning-adapter/src/main/resources/endpoint-configuration.xml "$TEMP_DIRECTORY/etc/"
	cp $TOPDIR/opennms-build/integrations/opennms-map-provisioning-adapter/src/main/resources/mapsadapter-configuration.xml   "$TEMP_DIRECTORY/etc/"
fi

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
if [ -z "$SKIP_ZIP" ]; then
	pushd "$TOPDIR" >/dev/null 2>&1
		zip -9 "$INSTALLER_NAME.zip" -r "$ZIP_DIRECTORY"
	popd >/dev/null 2>&1
fi
