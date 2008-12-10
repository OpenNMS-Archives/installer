SET OPENNMS_HOME=$UNIFIED_INSTALL_PATH
SET DBNAME=$izpackDatabaseName
SET DBURL=jdbc:postgresql://$izpackDatabaseHost:5432/
SET ETCDIR=%OPENNMS_HOME%/etc
SET SERVLETDIR=%OPENNMS_HOME%/webapps/opennms
SET ARGS=--admin-username $izpackDatabaseAdminUser --admin-password $izpackDatabaseAdminPass

"$JDKPath\bin\java" -Xmx256m -Dopennms.home=%OPENNMS_HOME% -Dinstall.dir=%OPENNMS_HOME% -Dinstall.database.name=%DBNAME% -Dinstall.database.url=%DBURL% -Dinstall.etc.dir=%ETCDIR% -Dinstall.servlet.dir=%SERVLETDIR% -jar %OPENNMS_HOME%/lib/opennms_install.jar %ARGS% %1 %2 %3 %4 %5 %6 %7 %8 %9
