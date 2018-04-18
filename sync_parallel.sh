#!/bin/bash

cd $(dirname $0)

source provision_common.sh
set +e

vagrant_rsync puppet
vagrant_rsync puppetback

if [ -n "$1" ]; then
    for h in $@; do
            echo "Provisioning $h"
            puppet_deploy $h &
    done

    wait
else
    #---
    for h in $INFRA_HOSTS; do
            echo "Provisioning $h"
            puppet_deploy $h &
    done

    wait

    #---
    for h in $DB_HOSTS; do
            echo "Provisioning $h"
            puppet_deploy $h &
    done

    wait

    #---
    for h in $WEB_HOSTS; do
            echo "Provisioning $h"
            puppet_deploy $h &
    done

    wait
fi
