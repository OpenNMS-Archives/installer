#!/bin/sh -e

cp "src/main/java/com/izforge/izpack/panels/OpenNMSJDKPathPanel.java" "izpack/src/lib/com/izforge/izpack/panels/"
pushd "izpack/src"
	ant all
popd
