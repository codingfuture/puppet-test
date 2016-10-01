#!/bin/bash

vagrant rsync puppet
vagrant rsync puppetback

for h in dbclust1 dbclust2 db; do
        echo "Provisioning $h"
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
done
