#!/bin/bash

cd $(dirname $0)

source provision_common.sh

vagrant destroy $DESTROY_OPTS

echo "Getting VMs up"
DISABLE_PUPPET_SYNC=true vagrant up router maint puppet puppetback

echo "Puppet Server bootstrap"
vagrant ssh puppet -- sudo rm /etc/puppetlabs/code/ -rf
cat modules/cfpuppetserver/setup_puppetserver.sh | \
    vagrant ssh puppet -c 'cat >/tmp/setup_puppetserver.sh'
vagrant ssh puppet -- sudo \
        INSANE_PUPPET_AUTOSIGN=true dash \
        /tmp/setup_puppetserver.sh file:///vagrant puppet.example.com
vagrant reload puppet --provision-with=setup-network # with rsync enabled
vagrant rsync puppet

vagrant ssh puppet -- sudo bash /etc/puppetlabs/code/environments/production/modules/cfsystem/files/cf_wait_socket.sh 8081
vagrant ssh puppet -- sudo bash /etc/puppetlabs/code/environments/production/modules/cfsystem/files/cf_wait_socket.sh 8140

while ! puppet_deploy puppet; do
    vagrant ssh puppet -- sudo $PUPPET apply --catalog /opt/puppetlabs/puppet/cache/client_data/catalog/puppet.example.com.json
done

echo "Prepare maint"
puppet_init maint INIT_ONESHOT=1

vagrant ssh maint -- sudo $PUPPET resource host puppet.example.com ip=10.10.1.11
while ! puppet_deploy maint; do :; done
reload_vm maint

echo "Provision puppetback"
puppet_init puppetback INIT_ONESHOT=1
while ! puppet_deploy puppet || ! puppet_deploy puppetback; do :; done
vagrant ssh puppet -- sudo /bin/systemctl restart cfpuppetserver.service
vagrant reload puppetback
while ! puppet_deploy puppetback; do :; done
update_maint

echo "Provision router"
puppet_init router
puppet_deploy router
update_maint
reload_vm router

echo "Reloading puppet"
vagrant reload puppet
vagrant ssh puppet -- sudo /opt/codingfuture/bin/cf_wait_socket 8081
vagrant ssh puppet -- sudo /opt/codingfuture/bin/cf_wait_socket 8140
while ! puppet_deploy puppet; do :; done
