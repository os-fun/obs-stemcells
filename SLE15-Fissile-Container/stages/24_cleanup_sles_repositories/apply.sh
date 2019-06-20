#!/usr/bin/env bash

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/etc/settings.bash

cd $chroot/etc/zypp/repos.d
grep internal * | cut -d ":" -f1 | xargs rm
