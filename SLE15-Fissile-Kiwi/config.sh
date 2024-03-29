#!/bin/bash

# Copyright (c) 2018 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

set -euo pipefail

echo "Configure image: [$kiwi_iname]..."

#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct

#======================================
# Import repositories' keys
#--------------------------------------
suseImportBuildKey


#======================================
# Disable recommends
#--------------------------------------
sed -i 's/.*solver.onlyRequires.*/solver.onlyRequires = true/g' /etc/zypp/zypp.conf

#======================================
# Exclude docs intallation
#--------------------------------------
sed -i 's/.*rpm.install.excludedocs.*/# rpm.install.excludedocs = yes/g' /etc/zypp/zypp.conf

#======================================
# Remove locale files
#--------------------------------------
find /usr/share/locale -name '*.mo' -delete

# Remove zypp uuid (bsc#1098535)
rm -f /var/lib/zypp/AnonymousUniqueId

#======================================
# Configure core dump directory
#--------------------------------------
mkdir -p /var/vcap/sys/cores
chmod ugo+rwx /var/vcap/sys/cores

#======================================
# create the vcap for garden and warden
#--------------------------------------
useradd -u 2000 -mU -s /bin/bash vcap
mkdir /home/vcap/app
chown vcap /home/vcap/app
ln -s /home/vcap/app /app

# Fix the shebang line of installed gems to use '/usr/bin/env ruby' instead of the versioned ruby
echo "custom_shebang: /usr/bin/env ruby" >> /etc/gemrc

# libuv1 is in the cflinuxfs3 stack
# but Aspnetcore seems to require libuv.so which is a symlink
# that we ship only in libuv-devel
# https://github.com/aspnet/libuv-build/blob/ecd5b95c3ad660856c9009ca4fe8bb420e86a92d/makefile.shade#L96
if [ ! -L "/usr/lib64/libuv.so" ]; then
  ln -s /usr/lib64/libuv.so.1.0.0 /usr/lib64/libuv.so
fi

/build.sh

exit 0
