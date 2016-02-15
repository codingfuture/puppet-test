
Vagrant.require_version ">= 1.8.0"

puppet_init = <<EOINIT
bash <<EOT
#!/bin/bash

http_proxy=

if test "\\\$(id -un)" != 'root'; then
    echo 'This script must run as root'
    exit 1
fi

if test ! -z "\\\$http_proxy"; then
    export http_proxy
    export https_proxy="\\\$http_proxy"
    export HTTP_PROXY="\\\$http_proxy"
    export HTTPS_PROXY="\\\$http_proxy"
fi

hostname=\\\$(hostname)

if ! which lsb-release | read; then
    apt-get install lsb-release
fi

codename=\\\$(lsb_release -cs)

if test -z "\\\$codename"; then
    echo "Failed to detect correct codename"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

wget -q https://apt.puppetlabs.com/puppetlabs-release-pc1-\\\${codename}.deb
dpkg -i puppetlabs-release-pc1-\\\${codename}.deb

mkdir -p /etc/puppetlabs/puppet

cat > /etc/puppetlabs/puppet/puppet.conf <<EOF
[main]
certname = \\\$hostname
server = puppet.example.com
environment = production
EOF

apt-get update && \
    apt-get install \
        -f -y \
        -o Dpkg::Options::="--force-confold" \
        puppet-agent

grep \\\$hostname /etc/hosts | read || \
   /opt/puppetlabs/bin/puppet resource host \\\$hostname ip=\\\$(/opt/puppetlabs/bin/facter networking.ip)

grep puppet.example.com /etc/hosts | read || \
   /opt/puppetlabs/bin/puppet resource host puppet.example.com ip=10.10.1.11
   
true
EOT
EOINIT


Vagrant.configure(2) do |config|
    config.vm.provider "virtualbox" do |v|
        v.linked_clone = true
        v.memory = 256
        v.cpus = 1
    end

    config.ssh.username = 'vagrant'
    #config.ssh.password = 'vagrant'
    config.ssh.private_key_path = [
        '~/.vagrant.d/insecure_private_key',
        'data/id_rsa_test'
    ]
    config.ssh.insert_key = false
    config.ssh.forward_x11 = false
    config.ssh.forward_agent = false
    config.ssh.pty = false

    config.vm.define 'router' do |node|
        node.vm.box = "debian/jessie64"
        node.vm.network(
            'public_network',
            ip: "192.168.1.30",
            netmask: "24",
            nic_type: "virtio",
            bridge: ['wlan0', 'eth0']
        )
        node.vm.network(
            "private_network",
            ip: "10.10.1.254",
            netmask: "24",
            nic_type: "virtio",
            virtualbox__intnet: "infradmz"
        )
        node.vm.network(
            "private_network",
            ip: "10.10.2.254",
            netmask: "24",
            nic_type: "virtio",
            virtualbox__intnet: "dbdmz"
        )
        node.vm.network(
            "private_network",
            ip: "10.10.3.254",
            netmask: "24",
            nic_type: "virtio",
            virtualbox__intnet: "webdmz"
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: '\
            hostname router.example.com; \
            ip route change default via 192.168.1.1 dev eth1; \
            sysctl -w net.ipv4.ip_forward=1 \
            ',
            run: 'always'
        node.vm.provision 'add-default-nat', type: 'shell',
            inline: '\
            iptables -t raw -A PREROUTING -i eth1 -d 10/8 -j DROP; \
            iptables -t nat -A POSTROUTING -o eth1 -s 10/8 -j MASQUERADE; \
            iptables -t nat -A POSTROUTING -o eth1 -s 10/8 -j MASQUERADE'
        # global config runs before node's one => place here
        node.vm.provision 'puppet_init', type: 'shell',
            inline: puppet_init
    end
    config.vm.define 'maint' do |node|
        node.vm.box = "debian/jessie64"
        node.vm.network(
            "private_network",
            ip: "10.10.1.10",
            netmask: "24",
            nic_type: "virtio",
            virtualbox__intnet: "infradmz"
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: '\
            hostname maint.example.com; \
            ip route change default via 10.10.1.254 dev eth1',
            run: 'always'
        # global config runs before node's one => place here
        node.vm.provision 'puppet_init', type: 'shell',
            inline: puppet_init
    end
    config.vm.define 'puppet' do |node|
        config.vm.provider "virtualbox" do |v|
            v.memory = 1024
        end
        node.vm.box = "debian/jessie64"
        node.vm.network(
            "private_network",
            ip: "10.10.1.11",
            netmask: "24",
            nic_type: "virtio",
            virtualbox__intnet: "infradmz"
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: '\
            hostname puppet.example.com; \
            ip route change default via 10.10.1.254 dev eth1',
            run: 'always'
        # global config runs before node's one => place here
        node.vm.provision 'puppet_init', type: 'shell',
            inline: puppet_init
        node.vm.provision 'setup_puppetserver', type: 'shell',
            path: 'setup_puppetserver.sh'
        node.vm.synced_folder ".", "/etc/puppetlabs/code/environments/production/",
            type: 'rsync', owner: 'puppet', group: 'puppet'
    end
    config.vm.define 'db' do |node|
        node.vm.box = "debian/jessie64"
        node.vm.network(
            "private_network",
            ip: "10.10.2.10",
            netmask: "24",
            nic_type: "virtio",
            virtualbox__intnet: "dbdmz"
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: '\
            hostname db.example.com; \
            ip route change default via 10.10.2.254 dev eth1',
            run: 'always'
        # global config runs before node's one => place here
        node.vm.provision 'puppet_init', type: 'shell',
            inline: puppet_init
    end
    config.vm.define 'web' do |node|
        #node.vm.box = "ubuntu/wily64"
        node.vm.box = "debian/jessie64"
        node.vm.network(
            "private_network",
            ip: "10.10.3.10",
            netmask: "24",
            nic_type: "virtio",
            virtualbox__intnet: "webdmz"
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: '\
            hostname web.example.com;\
            ip route change default via 10.10.3.254 dev eth1',
            run: 'always'
        # global config runs before node's one => place here
        node.vm.provision 'puppet_init', type: 'shell',
            inline: puppet_init
    end
end
