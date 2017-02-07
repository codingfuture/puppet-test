
set -ex

test ! -d modules && librarian-puppet install

PUPPET=/opt/puppetlabs/bin/puppet

function puppet_deploy() {
    local vm=$1
    vagrant ssh $vm -- sudo $PUPPET agent --test --trace
}

function update_maint() {
    puppet_deploy maint || puppet_deploy maint
}

function set_nameserver() {
    local vm=$1
    
    if test $vm = 'maint';  then
        vagrant ssh $vm -c "echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf"
    else
        vagrant ssh $vm -c "echo 'nameserver 10.10.1.10' | sudo tee /etc/resolv.conf"
    fi
}

function puppet_init() {
    local vm=$1
    shift 1
    local env="$@"
    
    local http_proxy=
    
    if test "$vm" != maint; then
        http_proxy=http://maint.example.com:3142
    fi
    
    set -e
    vagrant ssh puppet -- sudo $PUPPET ca destroy ${vm}.example.com
    vagrant ssh puppet -c "sudo /opt/codingfuture/bin/cf_gen_puppet_client_init ${vm}.example.com 'somelocation' '' '$http_proxy' >/tmp/${vm}.init"
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
