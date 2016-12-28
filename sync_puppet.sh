#!/bin/bash

vagrant rsync puppet

for h in puppet puppetback; do
        echo "Provisioning $h"
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
done
