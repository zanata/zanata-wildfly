#!/bin/bash -e

shopt -s globstar

projectdir=$PWD
target=$projectdir/target

version_wildfly=8.1.0.Final
version_hibernate=4.2.15.Final
version_mojarra=2.1.28
version_weld_jsf=2.1.2.Final
version_mysql_connector=5.1.32

# rm -fr $target
rm -fr $target/*.zip $target/*.gz

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


# Ref: https://community.jboss.org/wiki/StepsToAddAnyNewJSFImplementationOrVersionToWildFly

cd $target/wildfly-src/wildfly-${version_wildfly}-src
echo Building wildfly (this may take a while)
./build.sh -q -DskipTests

cd ./jsf/multi-jsf-installer
echo Building mojarra installer
$mvn -Djsf-version=${version_mojarra} -Pmojarra-2.x clean assembly:single
cp ./target/install-mojarra-${version_mojarra}.zip $target/install-mojarra-${version_mojarra}.cli

rm -fr $target/wildfly/wildfly-${version_wildfly}/modules/**/mojarra-*

echo -e '\nStarting WildFly\n'
$target/wildfly/wildfly-${version_wildfly}/bin/standalone.sh &
jboss_pid=$!
sleep 3 # wait for wildfly to start before connecting jboss-cli

echo -e '\nInstalling Mojarra modules\n'
$target/wildfly/wildfly-${version_wildfly}/bin/jboss-cli.sh -c "deploy $target/install-mojarra-${version_mojarra}.cli" ; \
echo -e '\nStopping WildFly\n'; \
$target/wildfly/wildfly-${version_wildfly}/bin/jboss-cli.sh -c :shutdown

cd $target/wildfly/wildfly-${version_wildfly}/
echo Building Mojarra module zip
zip -qr $target/wildfly-${version_wildfly}-module-mojarra-${version_mojarra}.zip modules/**/mojarra-${version_mojarra}

cd $projectdir

echo Getting Hibernate jars
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
