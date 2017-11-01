#!/bin/bash

cd $(dirname $0)

source provision_common.sh
set +e

vagrant_rsync puppet
vagrant_rsync puppetback

if [ -n "$1" ]; then
    for h in $@; do
            echo "Provisioning $h"
            puppet_deploy $h
    done
fi
