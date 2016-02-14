#!/bin/bash

vagrant up
for h in maint router puppet db web; do
	vagrant ssh $h -- /opt/puppetlabs/bin/puppet agent --test
done
