#!/bin/sh -e

rsync --exclude=.svn -avr src/main/java/ izpack/src/lib/
pushd "izpack/src"
	ant all
popd
