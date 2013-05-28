"$JDKPath\bin\java" -Xmx512m -XX:MaxPermSize=256m -Dopennms.home="$UNIFIED_INSTALL_PATH" -Djava.endorsed.dirs="$OPENNMS_HOME/lib/endorsed" -jar "$UNIFIED_INSTALL_PATH/lib/opennms_bootstrap.jar" %*
