#!/bin/bash

MYDIR=`dirname $0`
TOPDIR=`cd $MYDIR; pwd`
BRANCH=""
COMMIT=""

ASSEMBLY_ONLY=false

function exists() {
    which "$1" >/dev/null 2>&1
}

function run()
{
    if exists $1; then
        "$@"
    else
        die "Command not found: $1"
    fi
}    

function die()
{
    echo "$@" 1>&2
    exit 1
}

function tell()
{
    echo -e "$@" 1>&2
}

function calcMinor()
{
    if exists git; then
        pushd opennms-build >/dev/null 2>&1
            git log --pretty='format:%cd' --date=short -1 | head -n 1 | sed -e 's,^Date: *,,' -e 's,-,,g'
        popd >/dev/null 2>&1
    else
        date '+%Y%m%d'
    fi
}

function branch()
{
    if [ -n "${BRANCH}" ]; then
        echo "${BRANCH}"
    elif [ -n "${bamboo_planRepository_branch}" ]; then
        echo "${bamboo_planRepository_branch}"
    else
        pushd opennms-build >/dev/null 2>&1
            run git branch | grep -E '^\*' | awk '{ print $2 }'
        popd >/dev/null 2>&1
    fi
}

function commit()
{
    if [ -n "${COMMIT}" ]; then
        echo "${COMMIT}"
    elif [ -n "${bamboo_repository_revision_number}" ]; then
        echo "${bamboo_repository_revision_number}"
    else
        pushd opennms-build >/dev/null 2>&1
            run git log -1 | grep -E '^commit' | cut -d' ' -f2
        popd >/dev/null 2>&1
    fi
}

function version()
{
    grep '<version>' opennms-build/pom.xml | \
    sed -e 's,^[^>]*>,,' -e 's,<.*$,,' -e 's,-[^-]*-SNAPSHOT$,,' -e 's,-SNAPSHOT$,,' -e 's,-testing$,,' -e 's,-,.,g' | \
    head -n 1
}

function usage()
{
    tell "make-installer [-h] [-a] [-M <major>] [-m <minor>] [-u <micro>]"
    tell "\t-h : print this help"
    tell "\t-a : assembly only (skip the compile step)"
    tell "\t-r : no build (skip the compile and assembly steps)"
    tell "\t-z : don't create a zip file"
    tell "\t-b <branch> : the name of the branch"
    tell "\t-c <commit> : the commit revision hash from git"
    tell "\t-M <major>  : default 0 (0 means a snapshot release)"
    tell "\t-m <minor>  : default <datestamp> (ignored unless major is 0)"
    tell "\t-u <micro>  : default 1 (ignore unless major is 0)"
    exit 1
}

function setJavaHome()
{
    if [ -z "$JAVA_HOME" ]; then
        # hehe
        for dir in /usr/java/jdk1.{5,6,7,8,9}* /usr/lib/jvm/java-{1.5.0,6,7,8,9}-sun; do
            if [ -x "$dir/bin/java" ]; then
                export JAVA_HOME="$dir"
                break
            fi
        done
    fi

    if [ -z $JAVA_HOME ]; then
        die "*** JAVA_HOME must be set ***"
    fi
}

function skipCompile()
{
    if $ASSEMBLY_ONLY; then echo 1; else echo 0; fi
}

function main() {
    setJavaHome

    PATH="$JAVA_HOME/bin:$PATH"

    if [ -z "$IZPACK_HOME" ]; then
        IZPACK_HOME="$TOPDIR/izpack"
    fi
    IZPACK_COMPILE="$IZPACK_HOME/bin/compile"
    REPLACEMENT_TOKEN="XXX_TOKENIZE_ME_XXX"

    export PATH

    ASSEMBLY_ONLY=false
    BUILD=true
    ZIP=true

    RELEASE_MAJOR=0
    local RELEASE_MINOR="$(calcMinor)"
    local RELEASE_MICRO=1

    while builtin getopts ahrzM:m:u:b:c: OPT; do
        case $OPT in
            a)  ASSEMBLY_ONLY=true
                ;;
            r)  BUILD=false
                ;;
            M)  RELEASE_MAJOR="$OPTARG"
                ;;
            m)  RELEASE_MINOR="$OPTARG"
                ;;
            u)  RELEASE_MICRO="$OPTARG"
                ;;
            z)  ZIP=false
                ;;
            b)  BRANCH="$OPTARG"
                ;;
            c)  COMMIT="$OPTARG"
                ;;
            *)  usage
                ;;
        esac
    done

    RELEASE=$RELEASE_MAJOR
    if [ "$RELEASE_MAJOR" = 0 ] ; then
        RELEASE=${RELEASE_MAJOR}.${RELEASE_MINOR}.${RELEASE_MICRO}
    fi

    VERSION=$(version)
    #PARALLEL_OPTIONS="-Daether.connector.basic.threads=1 -Daether.connector.resumeDownloads=false -T1C"
    PARALLEL_OPTIONS="-Daether.connector.basic.threads=1 -Daether.connector.resumeDownloads=false"

    if $BUILD; then
        echo "==== Building OpenNMS ===="
        echo ""
        echo "Version: " $VERSION
        echo "Release: " $RELEASE

	pushd "$TOPDIR/opennms-build"
                git clean -fdx || die "failed to clean git directories"
	popd

        EXTRA_OPTIONS="-Dmaven.test.skip.exec=true -DskipITs=true"
        if $ASSEMBLY_ONLY; then
            EXTRA_OPTIONS="$EXTRA_OPTIONS -Denable.snapshots=true -DupdatePolicy=always"
        else
            EXTRA_OPTIONS="$EXTRA_OPTIONS -Denable.snapshots=false -DupdatePolicy=never"
            pushd "$TOPDIR/opennms-build"
                ./compile.pl $EXTRA_OPTIONS $PARALLEL_OPTIONS install || die "compile failed"
            popd
        fi

        pushd "$TOPDIR/opennms-build"
            ./assemble.pl \
                -Dinstall.database.name='$izpackDatabaseName' \
                -Dinstall.database.url='jdbc:postgresql://$izpackDatabaseHost:5432/' \
                -Dinstall.database.user='$izpackDatabaseUser' \
                -Dinstall.database.password='$izpackDatabasePass' \
                -Dinstall.database.admin.user='$izpackDatabaseAdminUser' \
                -Dinstall.database.admin.password='$izpackDatabaseAdminPass' \
                -Dopennms.home="$REPLACEMENT_TOKEN" \
                $EXTRA_OPTIONS \
                -p fulldir install || die "assemble failed"
        popd
    fi

    BINARY_DIRECTORY=`ls -d -1 "$TOPDIR/opennms-build/target/"opennms-* | grep -v -E 'tar.gz$' | sort -u | tail -1`
    [ -n "$BINARY_DIRECTORY" ] && [ -d "$BINARY_DIRECTORY" ] || die "binary directory in opennms-build/target not found"
    TEMP_DIRECTORY="$TOPDIR/izpack-temp"

    rsync -avr --progress --delete "$BINARY_DIRECTORY"/ "$TEMP_DIRECTORY"/ || die "unable to sync $BINARY_DIRECTORY to temporary directory"
    "${TOPDIR}"/handle-tokens.pl "$TEMP_DIRECTORY" "($REPLACEMENT_TOKEN|$BINARY_DIRECTORY)" '$UNIFIED_INSTALL_PATH' "${VERSION}-${RELEASE}" || die "unable to tokenize configuration files"
    
    cp LICENSE README.html logo.png ProcessPanel.Spec.xml userInput*.xml* "$TEMP_DIRECTORY/" || die "unable to copy files to temp directory"
    cp *.bat "$TEMP_DIRECTORY/bin/" || die "unable to copy batch files to temp directory"
    cp install "$TEMP_DIRECTORY/bin/" || die "unable to copy install files to temp directory"
    cp discovery-configuration.xml java.conf.* opennms-datasources.xml "$TEMP_DIRECTORY/etc/" || die "unable to copy etc files to temp directory"
    cp native/* "$TEMP_DIRECTORY/lib/" || die "unable to copy native files to temp directory"
    
    INSTALLER_NAME="standalone-opennms-installer-${VERSION}-${RELEASE}"
    ZIP_DIRECTORY="opennms-installer"
    rm -rf "$TOPDIR/$ZIP_DIRECTORY"
    mkdir -p "$TOPDIR/$ZIP_DIRECTORY"

    INSTALL_XML="install.xml"
    if [ -d "$TEMP_DIRECTORY/system" ]; then
        INSTALL_XML="install-with-karaf.xml"
    fi

    if [ ! -d "$TEMP_DIRECTORY/docs" ]; then
        INSTALL_XML="install-21.xml"
    fi

    "$IZPACK_COMPILE" "$INSTALL_XML" -b "$TEMP_DIRECTORY" -o "$TOPDIR/$ZIP_DIRECTORY/$INSTALLER_NAME.jar" -k standard || die "failed while creating installer jar"
    cp INSTALL.txt "$TOPDIR/$ZIP_DIRECTORY/" || die "unable to copy files to zip directory"

    if [ "$OPENNMS_SKIP_ZIP" != 1 ]; then
        pushd "$TOPDIR" >/dev/null 2>&1
            zip -9 "$INSTALLER_NAME.zip" -r "$ZIP_DIRECTORY" || die "zipping $INSTALLER_NAME.zip failed"
        popd >/dev/null 2>&1
    fi

    exit 0
}

main "$@"
