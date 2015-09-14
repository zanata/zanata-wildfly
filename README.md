zanata-wildfly contains files which help Zanata (3.5 or later) to run on WildFly.

Author: Sean Flanigan <sflaniga@redhat.com>


The modules contain repackaged copies of Mojarra 2.1, Hibernate 4.2 and Undertow 1.2.x.  The zip files are meant to be extracted into a WildFly 8.1/8.2/9 installation, which will add some Mojarra 2.1 modules, replace the 'main' Hibernate module with Hibernate 4.2, and upgrade Undertow to fix https://bugzilla.redhat.com/show_bug.cgi?id=1197955 (Undertow module not recommended: just use WildFly 9).

The 'main' Hibernate module is used by default, but the Mojarra modules *previously* had to be activated by a line like this in `standalone.xml`:

    <subsystem xmlns="urn:jboss:domain:jsf:1.0" default-jsf-impl-slot="mojarra-2.1.28"/>

(NB: The slot name needs to match the version of Mojarra.)

Update: as of 2.1.29-04, the Mojarra module uses the 'main' slot (like Hibernate), so you don't need to override default-jsf-impl-slot.

If upgrading from an earlier version, you need to remove the default-jsf-impl-slot attribute from the jsf subsystem.


The `standalone` directory (in the source tree) contains configuration for WildFly which might help you to run Zanata.  Note: these files may or may not be kept up to date, and might be removed in future.


The build scripts are licensed under LGPL 2.1, but Mojarra, Hibernate and Undertow retain their original licences.

The source code for zanata-wildfly lives here: https://github.com/zanata/zanata-wildfly

 * Module binaries: https://sourceforge.net/projects/zanata/files/wildfly/
 * Hibernate: http://hibernate.org/
 * Mojarra: https://javaserverfaces.java.net/
 * Undertow: http://undertow.io/
 * WildFly: http://wildfly.org/
 * Zanata: http://zanata.org/
