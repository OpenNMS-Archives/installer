"$JDKPath\bin\java"^
    -Xmx1024m -XX:MaxMetaspaceSize=256m^
    -XX:+HeapDumpOnOutOfMemoryError^
    -DisThreadContextMapInheritable=true^
    -Dopennms.home="$UNIFIED_INSTALL_PATH"^
    -Djava.endorsed.dirs="$UNIFIED_INSTALL_PATH/lib/endorsed"^
    -Djava.io.tmpdir="$UNIFIED_INSTALL_PATH/data/tmp"^
    -Dcom.sun.management.jmxremote.port=18980^
    -Dcom.sun.management.jmxremote.ssl=false^
    -Dcom.sun.management.jmxremote.authenticate=false^
    -jar "$UNIFIED_INSTALL_PATH/lib/opennms_bootstrap.jar" start
