#!/bin/bash

for i in $(ls  /build/stages | sort -V | grep -v '^bosh_audit' | xargs echo)
do
  echo "Stage: $i"
  bash +e /build/stages/"$i"/apply.sh
done


rm -rf /build

