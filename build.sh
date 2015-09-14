#!/bin/bash -e

shopt -s globstar

projectdir=$PWD
target=$projectdir/target

version_wildfly=9.0.1.Final
version_hibernate=4.2.20.Final
version_mojarra=2.1.29-04

build_mojarra=true
build_hibernate=true
build_wildfly=true

# rm -fr $target
rm -fr $target/*.zip $target/*.gz $target/*.cli \
  $target/mojarra21 $target/hibernate42 $target/standalone

mkdir -p $target $target/wildfly $target/wildfly-src \
  $target/mojarra21/modules $target/hibernate42/modules/org/hibernate/main \
  $target/standalone/deployments

mvn="mvn -q"
download_artifact=com.googlecode.maven-download-plugin:download-maven-plugin:1.2.0:artifact

echo 'Getting wildfly-dist'
$mvn $download_artifact -DgroupId=org.wildfly -DartifactId=wildfly-dist -Dversion=${version_wildfly} -Dtype=tar.gz -Dunpack -DoutputDirectory=$target/wildfly/

echo 'Getting wildfly-dist src'
$mvn $download_artifact -DgroupId=org.wildfly -DartifactId=wildfly-dist -Dversion=${version_wildfly} -Dclassifier=src -Dtype=tar.gz -Dunpack -DoutputDirectory=$target/wildfly-src/

if $build_mojarra; then
    module_zip=$target/wildfly-module-mojarra-${version_mojarra}.zip

    # Ref: https://community.jboss.org/wiki/StepsToAddAnyNewJSFImplementationOrVersionToWildFly

    cd $target/wildfly-src/wildfly-${version_wildfly}-src
    if $build_wildfly; then
        echo 'Building wildfly (this may take a while)'
        ./build.sh -q -DskipTests
    fi

    cd ./jsf/multi-jsf-installer
    echo 'Building mojarra installer'

    sed -i 's/slot="${jsf-impl-name}-${jsf-version}"/slot="main"/g' \
      src/main/resources/mojarra-*-module.xml

    sed -i 's/--slot=mojarra-${jsf-version}/--slot=main/g' \
      src/main/resources/mojarra-*deploy.scr

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
    zip -qr $module_zip \
      modules/com/sun/jsf-impl/main \
      modules/javax/faces/api/main \
      modules/org/jboss/as/jsf-injection/main

    cd $projectdir

    echo "The Mojarra module can be found here: $module_zip"
fi


if $build_hibernate; then
    module_src=$target/wildfly/wildfly-${version_wildfly}/modules/system/layers/base/org/hibernate/4.1
    module_target=$target/hibernate42/modules/org/hibernate/main
    module_zip=$target/wildfly-module-hibernate-main-${version_hibernate}.zip

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
