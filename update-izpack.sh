#!/bin/sh -e

pushd "izpack/src"
	ant -Dcompat.source=1.5 -Dcompat.target=1.5 all
popd
