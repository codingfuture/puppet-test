#!/bin/bash

cd $(dirname $0)

source provision_common.sh

vagrant destroy $DESTROY_OPTS $WEB_HOSTS
puppet_purge $WEB_HOSTS
update_maint

echo "Bootstrapping Web VMs"
for h in $WEB_HOSTS; do
    vagrant up $h
    puppet_init $h INIT_ONESHOT=1
done

update_maint

echo "Provisioning Web VMs"
for i in $(seq 1 2); do
    for h in $WEB_HOSTS; do
        puppet_deploy $h || test $1 = 1
    done
done

update_maint


echo "Testing CFDB restart pending after web"
for h in $DB_HOSTS; do
    puppet_deploy $h
    vagrant ssh $h -- sudo /opt/codingfuture/bin/cfdb_restart_pending
done

echo "Reloading Web VMs"
for h in $WEB_HOSTS; do
    reload_vm $h
done
