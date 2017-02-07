#!/bin/bash

cd $(dirname $0)
set +e

source provision_common.sh

vagrant_rsync puppet

for h in puppet puppetback; do
        echo "Provisioning $h"
        puppet_deploy $h
done
