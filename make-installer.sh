#!/bin/sh

IZPACK_COMPILE="/Users/ranger/Local Applications/IzPack/bin/compile"
BINARY_DIRECTORY="/Users/ranger/source.build/opennms-trunk/target/opennms-1.3.8-SNAPSHOT"
TEMP_DIRECTORY="/tmp/izpack-temp"

rsync -avr --delete "$BINARY_DIRECTORY"/ "$TEMP_DIRECTORY"/
./handle-tokens.pl "$TEMP_DIRECTORY" "$BINARY_DIRECTORY" '$INSTALL_PATH'

cp LICENSE UserInputSpec.xml "$TEMP_DIRECTORY/"
cp discovery-configuration.xml "$TEMP_DIRECTORY/etc/"

"$IZPACK_COMPILE" install.xml -b "$TEMP_DIRECTORY" -o opennms-install.jar -k standard
