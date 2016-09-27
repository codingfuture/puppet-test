#!/bin/bash

vagrant rsync puppet
vagrant rsync puppetback

for h in web web2; do
        echo "Provisioning $h"
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
done
