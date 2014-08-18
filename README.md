zanata-wildfly contains files which help Zanata (3.5 or later) to run on WildFly.

Author: Sean Flanigan <sflaniga@redhat.com>


The modules contain repackaged copies of Mojarra 2.1 and Hibernate 4.2.  The zip files are meant to be extracted into a WildFly installation, which will add some Mojarra 2.1 modules and replace the 'main' Hibernate module with Hibernate 4.2.

The 'main' Hibernate module is used by default, but the Mojarra modules need to be activated by a line like this in `standalone.xml`:

    <subsystem xmlns="urn:jboss:domain:jsf:1.0" default-jsf-impl-slot="mojarra-2.1.28"/>

(NB: The slot name needs to match the version of Mojarra.)

The `standalone` directory (in the source tree) contains configuration for WildFly which might help you to run Zanata.  Note: these files may or may not be kept up to date, and might be removed in future.


The build scripts are licensed under LGPL 2.1, but Mojarra and Hibernate retain their original licences.

The source code for zanata-wildfly lives here: https://github.com/zanata/zanata-wildfly

Hibernate: http://hibernate.org/
Mojarra: https://javaserverfaces.java.net/
WildFly: http://wildfly.org/
Zanata: http://zanata.org/
