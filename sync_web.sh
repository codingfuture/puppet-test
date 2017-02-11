#!/bin/bash

cd $(dirname $0)

source provision_common.sh
set +e

vagrant_rsync puppet
vagrant_rsync puppetback

for h in web web2 web3; do
        echo "Provisioning $h"
        puppet_deploy $h
done
