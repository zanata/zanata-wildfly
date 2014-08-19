#!/bin/bash -e

shopt -s globstar

projectdir=$PWD
target=$projectdir/target

version_wildfly=8.1.0.Final
version_hibernate=4.2.15.Final
version_mojarra=2.1.28
version_weld_jsf=2.1.2.Final
version_mysql_connector=5.1.32

rm -fr $target
# rm -fr $target/*.zip $target/*.gz

mkdir -p $target $target/wildfly $target/wildfly-src $target/mojarra21/modules $target/hibernate42/modules $target/standalone/deployments

/bin/cp -r modules/mojarra21/modules/* $target/mojarra21/modules/
/bin/cp -r modules/hibernate42/modules/* $target/hibernate42/modules/

mvn="mvn -q"
download_artifact=com.googlecode.maven-download-plugin:download-maven-plugin:1.2.0:artifact

echo Getting wildfly-dist
$mvn $download_artifact -DgroupId=org.wildfly -DartifactId=wildfly-dist -Dversion=${version_wildfly} -Dtype=tar.gz -Dunpack -DoutputDirectory=$target/wildfly/

echo Getting wildfly-dist src
$mvn $download_artifact -DgroupId=org.wildfly -DartifactId=wildfly-dist -Dversion=${version_wildfly} -Dclassifier=src -Dtype=tar.gz -Dunpack -DoutputDirectory=$target/wildfly-src/

echo Getting mysql-connector-java
$mvn $download_artifact -DgroupId=mysql -DartifactId=mysql-connector-java -Dversion=${version_mysql_connector} -DoutputDirectory=$target/standalone/deployments/ -DoutputFileName=mysql-connector-java.jar


# echo Building mojarra installer:

# cd $target/wildfly-src/wildfly-${version_wildfly}-src
# # ./build.sh -DskipTests
# cd ./jsf/multi-jsf-installer
# $mvn -Djsf-version=${version_mojarra} -Pmojarra-2.x clean assembly:single
# cp ./target/install-mojarra-${version_mojarra}.zip $target/install-mojarra-${version_mojarra}.cli

# rm -fr $target/wildfly/wildfly-8.1.0.Final/modules/**/mojarra-${version_mojarra}

# echo Starting wildfly
# $target/wildfly/wildfly-8.1.0.Final/bin/standalone.sh &

# echo Installing mojarra module
# $target/wildfly/wildfly-8.1.0.Final/bin/jboss-cli.sh --connect --command="deploy $target/install-mojarra-${version_mojarra}.cli"

# echo Stopping wildfly
# $target/wildfly/wildfly-8.1.0.Final/bin/jboss-cli.sh --connect command=:shutdown

# # cd $JBOSS_HOME/modules
# cd $target/wildfly/wildfly-8.1.0.Final/
# echo Building Mojarra module zip
# zip -qr $target/wildfly-${version_wildfly}-module-mojarra-${version_mojarra}.zip modules/**/mojarra-${version_mojarra}

# Ref: https://community.jboss.org/wiki/StepsToAddAnyNewJSFImplementationOrVersionToWildFly

cd $projectdir

echo Getting Mojarra
$mvn $download_artifact -DgroupId=com.sun.faces -DartifactId=jsf-api -Dversion=${version_mojarra} -DoutputDirectory=$target/mojarra21/modules/javax/faces/api/mojarra-${version_mojarra}/
$mvn $download_artifact -DgroupId=com.sun.faces -DartifactId=jsf-impl -Dversion=${version_mojarra} -DoutputDirectory=$target/mojarra21/modules/com/sun/jsf-impl/mojarra-${version_mojarra}/

$mvn $download_artifact -DgroupId=org.jboss.weld -DartifactId=weld-core-jsf -Dversion=${version_weld_jsf} -DoutputDirectory=$target/mojarra21/modules/org/jboss/as/jsf-injection/mojarra-${version_mojarra}/
$mvn $download_artifact -DgroupId=org.wildfly -DartifactId=wildfly-jsf-injection -Dversion=${version_wildfly} -DoutputDirectory=$target/mojarra21/modules/org/jboss/as/jsf-injection/mojarra-${version_mojarra}/

echo Building Mojarra module zip
(cd target/mojarra21 && zip -qr $target/wildfly-${version_wildfly}-module-mojarra-${version_mojarra}.zip .)

echo Getting Hibernate 4.1
$mvn $download_artifact -DgroupId=org.hibernate -DartifactId=hibernate-core -Dversion=${version_hibernate} -DoutputDirectory=$target/hibernate42/modules/system/layers/base/org/hibernate/main/
$mvn $download_artifact -DgroupId=org.hibernate -DartifactId=hibernate-entitymanager -Dversion=${version_hibernate} -DoutputDirectory=$target/hibernate42/modules/system/layers/base/org/hibernate/main/
$mvn $download_artifact -DgroupId=org.hibernate -DartifactId=hibernate-infinispan -Dversion=${version_hibernate} -DoutputDirectory=$target/hibernate42/modules/system/layers/base/org/hibernate/main/
echo copying jipajapa from WildFly dist
/bin/cp target/wildfly/wildfly-*/modules/system/layers/base/org/hibernate/4.1/jipijapa-hibernate4-1*.jar $target/hibernate42/modules/system/layers/base/org/hibernate/main/

# This could replace the above /bin/cp and wildfly-dist download, but
# it needs a real pom to enable the jboss repo (jipijapa is not in Central):
# $mvn -Djboss.devel.repo.off com.googlecode.maven-download-plugin:download-maven-plugin:1.2.0:artifact -DgroupId=org.jipijapa -DartifactId=jipijapa-hibernate4-1 -Dversion=1.0.1.Final -DoutputDirectory=$target/hibernate42/modules/system/layers/base/org/hibernate/main/ -Dproject.remoteArtifactRepositories=https://repository.jboss.org/nexus/content/groups/public/

echo Building Hibernate module zip
(cd $target/hibernate42 && zip -qr $target/wildfly-${version_wildfly}-module-hibernate-main-${version_hibernate}.zip .)
