#!/bin/bash

test ! -d modules && librarian-puppet install

vagrant up router maint puppet

skip_dns=${skip_dns:-0}

if test "$skip_dns" != 1; then
    vagrant ssh maint -- sudo /opt/puppetlabs/bin/puppet resource host maint.example.com ip=10.10.1.10
    vagrant ssh maint -- sudo /opt/puppetlabs/bin/puppet resource host puppet.example.com ip=10.10.1.11
    vagrant ssh maint -- sudo /opt/puppetlabs/bin/puppet resource host puppetback.example.com ip=10.10.1.12
fi

for h in maint puppet; do
        echo "Provisioning $h"
        
        if test "$skip_dns" != 1; then
            if test $h = 'maint';  then
                vagrant ssh $h -c "echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf"
            else
                vagrant ssh $h -c "echo 'nameserver 10.10.1.10' | sudo tee /etc/resolv.conf"
            fi
        fi
        
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
        
        if test $h = 'puppet'; then
            vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet apply \
                --catalog /opt/puppetlabs/puppet/cache/client_data/catalog/puppet.example.com.json
            vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
        fi
        
        vagrant ssh maint -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
        vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
        
        if test $h = 'puppetback';  then
            vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
            vagrant ssh puppet -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
            vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
            vagrant ssh $h -- sudo /opt/puppetlabs/bin/puppet agent --test --trace
        fi
done
