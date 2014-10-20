SET OPENNMS_HOME=$UNIFIED_INSTALL_PATH
SET DBNAME=$izpackDatabaseName
SET DBURL=jdbc:postgresql://$izpackDatabaseHost:5432/
SET ETCDIR=%OPENNMS_HOME%/etc
SET SERVLETDIR=%OPENNMS_HOME%/webapps/opennms

"$JDKPath\bin\java" -Xmx512m "-Dopennms.home=%OPENNMS_HOME%" "-Dinstall.dir=%OPENNMS_HOME%" "-Dinstall.database.name=%DBNAME%" "-Dinstall.database.url=%DBURL%" "-Dinstall.etc.dir=%ETCDIR%" "-Dinstall.servlet.dir=%SERVLETDIR%" -classpath "%OPENNMS_HOME%/lib/opennms_bootstrap.jar" org.opennms.bootstrap.InstallerBootstrap %*
