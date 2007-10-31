#!/bin/sh -e

rsync --exclude=.svn -avr src/main/java/ izpack/src/lib/
pushd "izpack/src"
	ant -Dcompat.source=1.5 -Dcompat.target=1.5 all
popd
