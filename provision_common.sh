
set -ex

PS1="(provision) $PS1"

test ! -d modules && librarian-puppet install

PUPPET=/opt/puppetlabs/bin/puppet
PUPPET_DOMAIN=example.com
PUPPET_HOSTS="puppet puppetback"
DB_HOSTS="dbclust1 dbclust2 db"
WEB_HOSTS="web web2"
INFRA_HOSTS="maint router logmon $PUPPET_HOSTS"
ALL_HOSTS="$INFRA_HOSTS $DB_HOSTS $WEB_HOSTS"

DESTROY_OPTS=
if test "$1" = force; then
    DESTROY_OPTS=-f
fi

function puppet_deploy() {
    local vm=$1
    vagrant ssh $vm -- sudo $PUPPET agent --test --trace
    local res=$?
    [ $res -eq 0 ]
    #local last_res_var="last_puppet_res_${vm}"
    #local last_res=${!last_res_var}
    #declare last_puppet_res_${vm}=$res
    #[ $res -eq 0 ] || [ $res -eq 2 ]
}

function update_maint() {
    puppet_deploy maint || puppet_deploy maint
}

function set_nameserver() {
    local vm=$1
    local ns='10.10.1.10'
    
    if test $vm = 'maint';  then
        ns='8.8.8.8'
    fi

    vagrant ssh $vm -c "echo 'nameserver $ns' | sudo tee /etc/resolv.conf"
    vagrant ssh $vm -c "echo -e '[Resolve]\nDNS=$ns' | sudo tee /etc/systemd/resolved.conf"
}

function puppet_purge() {
    for vm in $@; do
        for p in $PUPPET_HOSTS; do
            vagrant ssh $p -- sudo $PUPPET node deactivate ${vm}.${PUPPET_DOMAIN} || true
            vagrant ssh $p -- sudo $PUPPET node clean ${vm}.${PUPPET_DOMAIN} || true
        done
    done
}


function puppet_init() {
    local vm=$1
    shift 1
    local env="$@"
    
    local http_proxy=
    
    if test "$vm" != maint; then
        http_proxy=http://maint.${PUPPET_DOMAIN}:3142
    fi
    
    set -e
    puppet_purge $vm
    vagrant ssh puppet -c "sudo /opt/codingfuture/bin/cf_gen_puppet_client_init ${vm}.${PUPPET_DOMAIN} 'somelocation' '' '$http_proxy' >/tmp/${vm}.init"
    # vagrant scp puppet:/tmp/${vm}.init $vm:/tmp/${vm}.init
    vagrant ssh puppet -- cat /tmp/${vm}.init | vagrant ssh $vm -- "cat >/tmp/${vm}.init"
    set_nameserver $vm
    vagrant ssh $vm -c "sudo $env dash /tmp/${vm}.init"
}

function reload_vm() {
    local vm=$1
    vagrant reload $@
    puppet_deploy $vm || puppet_deploy $vm
}

function vagrant_rsync() {
    local vm=$1
    vagrant rsync $vm
    vagrant ssh $vm -- sudo /opt/codingfuture/bin/cf_puppetserver_reload
}
