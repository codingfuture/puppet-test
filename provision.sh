#!/bin/bash

vagrant up
for h in puppet maint db web router; do
	vagrant ssh $h -- /opt/puppetlabs/bin/puppet agent --test --waitforcert 0
done
