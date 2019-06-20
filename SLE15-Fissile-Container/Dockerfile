#!BuildTag: my-container
#!UseOBSRepositories
FROM suse/sle15:15.0
#FROM registry.suse.com/suse/sle15:15.0
#FROM registry.opensuse.org/cloud/platform/stack/rootfs/images/sle15

RUN zypper ar -f -G "http://download.suse.de/ibs/SUSE:/SLE-15:/GA/standard/" "SLE15"
RUN zypper ar -f -G "http://download.suse.de/ibs/SUSE:/SLE-15:/Update/standard/" "SLE15_Updates" 
RUN zypper ar -f -G "http://download.suse.de/ibs/Devel:/Cloud:/Platform:/SUSE-Stemcell/SLE_15/" stemcells
RUN zypper ref
RUN zypper in -y kernel-default filesystem tar gcc flex bison make check-devel chrony cronie cronie-anacron sudo rsyslog bind-utils iproute2 iputils net-tools wget glibc-devel-static vim glibc-locale less audit shadow runit zlib-devel netcat-openbsd libopenssl-devel cmake gcc-c++ patch libcap-devel libbz2-devel libgcrypt-devel libcurl-devel bison libgnutls-devel libxslt-devel binutils posix_cc krb5-devel libxml2-devel libuuid-devel curl timezone kernel-syms rsyslog-module-relp parted e2fsprogs ca-certificates ca-certificates-mozilla ntp unzip iptables libcap-progs quota apparmor-abstractions apparmor-utils apparmor-parser curl zip gptfdisk xen-kmp-default xen-libs xen-tools-domU rsync lsof libnfs8 gettext-tools sysstat tack readline-devel


ENV stemcell_operating_system=sles
ENV chroot=/
ENV os_type=sles
ENV work=/build/work
# Put additional files into container
ADD stages /build/stages
ADD etc /build/etc
ADD lib /build/lib
ADD build.sh /build/build.sh
#COPY MY.FILE /opt/my_space

# Install further packages using zypper
RUN mkdir /build/work 
RUN bash /build/build.sh

# Remove the repos again
RUN zypper rr 3 && zypper rr 2 && zypper rr 1