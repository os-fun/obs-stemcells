# Building the fissile Stemcells on OBS(IBS)


We experimented a partial port of <link> inside OBS to explore the possibility to build fissile stemcells inside OBS and deprecate our current set of pipelines.

As a result, we managed to build an image based off from sle15 both as form of kiwi and dockerfiles, which is applying a patchset ported from <link>
during the build process.

Both processes seems to be viable solutions, but with some limitations.


To create a custom image which is installing packages from within OBS during the process few things are needed to take in consideration when creating the project:

1) If you are installing packages, you have to Link the repositories where are coming from in the Project Meta, otherwise OBS won't schedule a build as it tries to resolve the deptree beforehand
2) After that, in the kiwifile it's possible to import the same set of repositories that are linked in the Project Meta, so no need to duplicate any logic - On the other hand to provide
a complete Dockerfile, it's best to also add explictly the repositories (even if not needed) and the dependencies downloaded there.
1) In the project Config, it's necessary to specify the target repos of the build (e.g. kiwi, or dockerfile type, see [Project Config section](#Project-config)

## Configure an OBS project for Docker & KIWI

In this example we will create two repositories, one used to build the image using a kiwi file, and the other using a dockerfile. Both methods are equivalent, but they are using different technology stacks.

**Project config:**

In the Project config, we need to define which type of building method we want to enable:


```
%if "%_repository" == "dockerimages"
Type: docker
Repotype: none
Patterntype: none
%endif


%if "%_repository" == "images"
Type: kiwi
Repotype: staticlinks
Patterntype: none
%endif
```

## Linking repositories

During the build process it might be necessary to download packages from internal repositories to provide additional software.

In our case, to provide the dependencies required by the fissile stemcell we forked our repo [SUSE-Stemcell](https://build.opensuse.org/project/show/Cloud:Platform:SUSE-Stemcell) in OBS which contains the stemcells dependencies in https://build.suse.de/project/show/Devel:Cloud:Platform:SUSE-Stemcell ,

To link them, reference them in the Project Meta (**Note:** Crossreferencing projects between our two obs instances does not work, so in future we might want to run both parts on either IBS or OBS):

**Project meta:**
```xml
<project name="Devel:Cloud:Platform:Containers">
  <title/>
  <description/>
  <person userid="crichter" role="maintainer"/>
  <repository name="images">
    <path project="Devel:Cloud:Platform:SUSE-Stemcell" repository="SLE_15"/>
    <path project="SUSE:Templates:Images:SLE-15" repository="images"/>
    <path project="SUSE:SLE-15:Update" repository="standard"/>
    <arch>x86_64</arch>
  </repository>
  <repository name="dockerimages">
    <path project="Devel:Cloud:Platform:SUSE-Stemcell" repository="SLE_15"/>
    <path project="SUSE:Templates:Images:SLE-15" repository="images"/>
    <arch>x86_64</arch>
  </repository>
</project>
```

This will allow OBS to resolve the dependencies that we reference in our specfiles, otherwise OBS won't able to resolve the dependency tree and would mark the repository as *unresolvable*.

**Note:** Dependending on the build strategy, it is needed to add the repositories with zypper (or as tags in case of kiwi) to be able to consume those repositories during the build process.


### Example Dockerfile

```Dockerfile
#!BuildTag: my-container
#!UseOBSRepositories
FROM suse/sle15:15.0

# NOTE: Importing the same repositories we already defined in the meta:
RUN zypper ar -f -G "http://download.suse.de/ibs/SUSE:/SLE-15:/GA/standard/" "SLE15"
RUN zypper ar -f -G "http://download.suse.de/ibs/SUSE:/SLE-15:/Update/standard/" "SLE15_Updates"
RUN zypper ar -f -G "http://download.suse.de/ibs/Devel:/Cloud:/Platform:/SUSE-Stemcell/SLE_15/" stemcells

RUN zypper ref
RUN zypper in -y kernel-default filesystem tar gcc flex bison make check-devel chrony cronie cronie-anacron sudo rsyslog bind-utils iproute2 iputils net-tools wget glibc-devel-static vim glibc-locale less audit shadow runit zlib-devel netcat-openbsd libopenssl-devel cmake gcc-c++ patch libcap-devel libbz2-devel libgcrypt-devel libcurl-devel bison libgnutls-devel libxslt-devel binutils posix_cc krb5-devel libxml2-devel libuuid-devel curl timezone kernel-syms rsyslog-module-relp parted e2fsprogs ca-certificates ca-certificates-mozilla ntp unzip iptables libcap-progs quota apparmor-abstractions apparmor-utils apparmor-parser curl zip gptfdisk xen-kmp-default xen-libs xen-tools-domU rsync lsof libnfs8 gettext-tools sysstat tack


ENV stemcell_operating_system=sles
ENV chroot=/
ENV os_type=sles
ENV work=/build/work

# Add bosh-stemcell-builder assets
ADD stages /build/stages
ADD etc /build/etc
ADD lib /build/lib
ADD build.sh /build/build.sh

# Running bosh-stemcell-builder steps:
RUN mkdir /build/work
RUN bash /build/build.sh

# Remove the repos again
RUN zypper rr 3 && zypper rr 2 && zypper rr 1
```

### Example Kiwifile

```xml
<?xml version="1.0" encoding="utf-8"?>

<image schemaversion="6.8" name="sle15-fissile-base">
  <description type="system">
    <author>Tim Hardeck</author>
    <contact>thardeck@suse.de</contact>
    <specification>CloudFoundry root filesystem based on SUSE Linux Enterprise</specification>
  </description>
  <preferences>
    <type image="docker">
      <containerconfig
        name="sle15"
        tag="latest"
        maintainer="Tim Hardeck &lt;thardeck@suse.de&gt;"/>
    </type>
    <version>1.0.0</version>
    <packagemanager>zypper</packagemanager>
    <!--<rpm-check-signatures>false</rpm-check-signatures>-->
    <rpm-excludedocs>true</rpm-excludedocs>
  </preferences>
  <repository>
    <!-- NOTE: This automatically imports the repositories linked in the Project meta -->
    <source path="obsrepositories:/"/>
  </repository>
  <packages type="image">
    <!-- packages required to build the base image -->
    <package name="kernel-default"/>
    <package name="filesystem"/>
    <package name="tar"/>
    <package name="gcc"/>
    <package name="flex"/>
    <package name="bison"/>
    <package name="make"/>
    <package name="check-devel"/>
    <package name="chrony"/>
    <package name="cronie"/>
    <package name="cronie-anacron"/>
    <package name="sudo"/>
    <package name="rsyslog"/>
    <package name="bind-utils"/>
    <package name="iproute2"/>
    <package name="iputils"/>
    <package name="net-tools"/>
    <package name="wget"/>
    <package name="glibc-devel-static"/>
    <package name="vim"/>
    <package name="glibc-locale"/>
    <package name="less"/>
    <package name="audit"/>
    <package name="shadow"/>
    <package name="runit"/>
    <!-- packages required to build the stemcell -->
    <package name="zlib-devel"/>
    <package name="netcat-openbsd"/>
    <package name="libopenssl-devel"/>
    <package name="readline-devel"/>
    <package name="cmake"/>
    <package name="gcc-c++"/>
    <package name="patch"/>
    <package name="libcap-devel"/>
    <package name="libbz2-devel"/>
    <package name="libgcrypt-devel"/>
    <package name="libcurl-devel"/>
    <package name="bison"/>
    <package name="libgnutls-devel"/>
    <package name="libxslt-devel"/>
    <package name="binutils"/>
    <package name="posix_cc"/>
    <package name="krb5-devel"/>
    <package name="libxml2-devel"/>
    <package name="libuuid-devel"/>
    <package name="curl"/>
    <package name="timezone"/>
    <package name="kernel-syms"/>
    <package name="rsyslog-module-relp"/>
    <package name="parted"/>
    <package name="e2fsprogs"/>
    <package name="ca-certificates"/>
    <package name="ca-certificates-mozilla"/>
    <package name="ntp"/>
    <package name="unzip"/>
    <package name="iptables"/>
    <package name="libcap-progs"/>
    <package name="quota"/>
    <package name="apparmor-abstractions"/>
    <package name="apparmor-utils"/>
    <package name="apparmor-parser"/>
    <package name="curl"/>
    <package name="zip"/>
    <package name="gptfdisk"/>
    <package name="xen-kmp-default"/>
    <package name="xen-libs"/>
    <package name="xen-tools-domU"/>
    <package name="rsync"/>
    <package name="lsof"/>
    <package name="libnfs8"/>
    <package name="gettext-tools"/>
    <package name="sysstat11.0"/>
    <package name="openldap2-client"/>
    <package name="uuidd"/>
    <package name="automake"/>
    <package name="libtool"/>
    <package name="gdbm-devel"/>
    <package name="libffi-devel"/>
    <package name="sqlite3-devel"/>
    <package name="jq"/>
    <package name="tack"/>
  </packages>
  <packages type="bootstrap">
    <package name="aaa_base"/>
    <package name="cracklib-dict-small"/>
    <package name="filesystem"/>
    <package name="sles-release"/>
    <package name="shadow"/>
  </packages>
</image>
```

**Note** We extracted the stages in [bosh-linux-stemcell-builder](https://github.com/SUSE/bosh-linux-stemcell-builder) for SLE and we didn't adapted them fully, they are executed at the end of the process and are available in the OBS project.


