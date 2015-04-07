#!/bin/bash -e

shopt -s globstar

projectdir=$PWD
target=$projectdir/target

version_wildfly=8.1.0.Final
version_hibernate=4.2.15.Final
version_mojarra=2.1.28
version_mysql_connector=5.1.32
version_undertow=1.2.0.Beta10

build_mojarra=false
build_hibernate=true
build_wildfly=true
build_undertow=true

# rm -fr $target
rm -fr $target/*.zip $target/*.gz $target/*.cli \
  $target/mojarra21 $target/hibernate42 $target/undertow $target/standalone

mkdir -p $target $target/wildfly $target/wildfly-src \
  $target/mojarra21/modules $target/hibernate42/modules/org/hibernate/main \
  $target/undertow/modules/io/undertow/core/main \
  $target/standalone/deployments

mvn="mvn -q"
download_artifact=com.googlecode.maven-download-plugin:download-maven-plugin:1.2.0:artifact

echo 'Getting wildfly-dist'
$mvn $download_artifact -DgroupId=org.wildfly -DartifactId=wildfly-dist -Dversion=${version_wildfly} -Dtype=tar.gz -Dunpack -DoutputDirectory=$target/wildfly/

echo 'Getting wildfly-dist src'
$mvn $download_artifact -DgroupId=org.wildfly -DartifactId=wildfly-dist -Dversion=${version_wildfly} -Dclassifier=src -Dtype=tar.gz -Dunpack -DoutputDirectory=$target/wildfly-src/

echo 'Getting mysql-connector-java'
$mvn $download_artifact -DgroupId=mysql -DartifactId=mysql-connector-java -Dversion=${version_mysql_connector} -DoutputDirectory=$target/standalone/deployments/ -DoutputFileName=mysql-connector-java.jar

if $build_mojarra; then
    module_zip=$target/wildfly-${version_wildfly}-module-mojarra-${version_mojarra}.zip

    # Ref: https://community.jboss.org/wiki/StepsToAddAnyNewJSFImplementationOrVersionToWildFly

    cd $target/wildfly-src/wildfly-${version_wildfly}-src
    if $build_wildfly; then
        echo 'Building wildfly (this may take a while)'
        ./build.sh -q -Dmaven.test.skip
    fi

    cd ./jsf/multi-jsf-installer
    echo 'Building mojarra installer'
    $mvn -Djsf-version=${version_mojarra} -Pmojarra-2.x clean assembly:single
    /bin/cp ./target/install-mojarra-${version_mojarra}.zip $target/install-mojarra-${version_mojarra}.cli

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
    echo 'Building Mojarra module zip'
    zip -qr $module_zip modules/**/mojarra-${version_mojarra}

    cd $projectdir

    echo "The Mojarra module can be found here: $module_zip"
fi


if $build_hibernate; then
    module_src=$target/wildfly/wildfly-${version_wildfly}/modules/system/layers/base/org/hibernate/4.1
    module_target=$target/hibernate42/modules/org/hibernate/main
    module_zip=$target/wildfly-${version_wildfly}-module-hibernate-main-${version_hibernate}.zip

    /bin/cp $module_src/* $module_target/
    sed -i $module_target/module.xml \
        -e 's/ slot="4.1">/>/' \
        -e '/<resources>/a\
        <resource-root path="hibernate-core-'${version_hibernate}'.jar"/>\
        <resource-root path="hibernate-entitymanager-'${version_hibernate}'.jar"/>\
        <resource-root path="hibernate-infinispan-'${version_hibernate}'.jar"/>'

    echo 'Getting Hibernate jars'
    $mvn $download_artifact -DgroupId=org.hibernate -DartifactId=hibernate-core -Dversion=${version_hibernate} -DoutputDirectory=$module_target
    $mvn $download_artifact -DgroupId=org.hibernate -DartifactId=hibernate-entitymanager -Dversion=${version_hibernate} -DoutputDirectory=$module_target
    $mvn $download_artifact -DgroupId=org.hibernate -DartifactId=hibernate-infinispan -Dversion=${version_hibernate} -DoutputDirectory=$module_target


    echo 'Building Hibernate module zip'
    (cd $target/hibernate42 && zip -qr $module_zip .)

    echo "The Hibernate module can be found here: $module_zip"
fi

if $build_undertow; then
    module_src=$target/wildfly/wildfly-${version_wildfly}/modules/system/layers/base/io/undertow/core/main
    module_target=$target/undertow/modules/io/undertow/core/main
    module_zip=$target/wildfly-${version_wildfly}-module-undertow-${version_undertow}.zip

    if [[ -f $module_src/undertow-core-1.[01].*.jar ]]; then
        echo "Undertow 1.0 or 1.1 not found in specified version of WildFly. You might need to disable this module by setting build_undertow=false."
        exit 1
    fi
    /bin/cp $module_src/module.xml \
      $module_target/module.xml
    sed -i $module_target/module.xml \
      -e "s/undertow-core-\(1\.[01]\..*\)\.jar/undertow-core-${version_undertow}.jar/"

    echo 'Getting Undertow jar'
    $mvn $download_artifact -DgroupId=io.undertow -DartifactId=undertow-core -Dversion=${version_undertow} \
      -DoutputDirectory=$module_target

    echo 'Building Undertow module zip'
    (cd $target/undertow && zip -qr $module_zip .)

    echo "The Undertow module can be found here: $module_zip"
fi
