
Vagrant.require_version ">= 1.8.0"

puppet_init = <<EOINIT
bash <<EOT
#!/bin/bash

if nc -z 10.10.1.10 3142; then
    http_proxy='http://10.10.1.10:3142'
else
    http_proxy=
fi

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

echo -n somelocation >/etc/cflocation

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
    use_ubuntu = false
    if ENV['USE_UBUNTU'] == 'y' or File.exists? 'USE_UBUNTU'
        use_ubuntu = true
    end

    config.vm.provider "virtualbox" do |v|
        v.linked_clone = true
        v.memory = 256
        v.cpus = 1
        #v.gui = 1
        
        v.customize [
            "storagectl", :id,
            "--name", "SATA Controller",
            "--hostiocache", "on"
        ]
    end
    
    if use_ubuntu
        # not working box
        #config.vm.box = "ubuntu/xenial64"
        config.vm.box = "geerlingguy/ubuntu1604"
        # Ubuntu virtio gets initialized before intel driver because
        # official Ubuntu cloud images do not tie vagrant nat to eth0
        nic_type = '82540EM'
    else
        config.vm.box = "debian/jessie64"
        nic_type = 'virtio'
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
    
    network_prefix = '192.168.88'

    config.vm.define 'router' do |node|
        node.vm.network(
            'public_network',
            adapter: 2,
            ip: "#{network_prefix}.30",
            netmask: "24",
            nic_type: nic_type,
            bridge: ['wlan0', 'eth0'],
            auto_config: false
        )
        node.vm.network(
            "private_network",
            adapter: 3,
            ip: "10.10.1.254",
            netmask: "24",
            nic_type: nic_type,
            virtualbox__intnet: "infradmz",
            auto_config: false
        )
        node.vm.network(
            "private_network",
            adapter: 4,
            ip: "10.10.2.254",
            netmask: "24",
            nic_type: nic_type,
            virtualbox__intnet: "dbdmz",
            auto_config: false
        )
        node.vm.network(
            "private_network",
            adapter: 5,
            ip: "10.10.3.254",
            netmask: "24",
            nic_type: nic_type,
            virtualbox__intnet: "webdmz",
            auto_config: false
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: "\
            hostname router.example.com; \
            ifconfig eth1 up; \
            ip addr add #{network_prefix}.30/24 dev eth1; \
            ifconfig eth2 up; \
            ip addr add 10.10.1.254/24 dev eth2; \
            ifconfig eth3 up; \
            ip addr add 10.10.2.254/24 dev eth3; \
            ifconfig eth4 up; \
            ip addr add 10.10.3.254/24 dev eth4; \
            ip route change default via #{network_prefix}.1 dev eth1; \
            sysctl -w net.ipv4.ip_forward=1; \
            echo 'Acquire::ForceIPv4 \"true\";' | tee /etc/apt/apt.conf.d/99force-ipv4; \
            ",
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
        node.vm.network(
            "private_network",
            adapter: 2,
            ip: "10.10.1.10",
            netmask: "24",
            nic_type: nic_type,
            virtualbox__intnet: "infradmz",
            auto_config: false
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: '\
            hostname maint.example.com; \
            ifconfig eth1 up; \
            ip addr add 10.10.1.10/24 dev eth1; \
            ip route change default via 10.10.1.254 dev eth1; \
            echo \'Acquire::ForceIPv4 "true";\' | tee /etc/apt/apt.conf.d/99force-ipv4;',
            run: 'always'
        # global config runs before node's one => place here
        node.vm.provision 'puppet_init', type: 'shell',
            inline: puppet_init
    end
    config.vm.define 'puppet' do |node|
        node.vm.provider "virtualbox" do |v|
            v.memory = 1280
        end
        node.vm.network(
            "private_network",
            adapter: 2,
            ip: "10.10.1.11",
            netmask: "24",
            nic_type: nic_type,
            virtualbox__intnet: "infradmz",
            auto_config: false
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: '\
            hostname puppet.example.com; \
            ifconfig eth1 up; \
            ip addr add 10.10.1.11/24 dev eth1; \
            ip route change default via 10.10.1.254 dev eth1; \
            echo \'Acquire::ForceIPv4 "true";\' | tee /etc/apt/apt.conf.d/99force-ipv4;',
            run: 'always'
        # global config runs before node's one => place here
        node.vm.provision 'puppet_init', type: 'shell',
            inline: puppet_init
        node.vm.provision 'setup_puppetserver', type: 'shell',
            path: 'modules/cfpuppetserver/setup_puppetserver.sh',
            args: ['file:///vagrant'],
            env: {
                'INSANE_PUPPET_AUTOSIGN': 'true',
            }
        node.vm.synced_folder ".", "/etc/puppetlabs/code/environments/production/",
            type: 'rsync', owner: 'puppet', group: 'puppet'
    end
    config.vm.define 'puppetback' do |node|
        node.vm.provider "virtualbox" do |v|
            v.memory = 1536
        end
        node.vm.network(
            "private_network",
            adapter: 2,
            ip: "10.10.1.12",
            netmask: "24",
            nic_type: nic_type,
            virtualbox__intnet: "infradmz",
            auto_config: false
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: '\
            hostname puppetback.example.com;\
            ifconfig eth1 up; \
            ip addr add 10.10.1.12/24 dev eth1; \
            ip route change default via 10.10.1.254 dev eth1; \
            echo \'Acquire::ForceIPv4 "true";\' | tee /etc/apt/apt.conf.d/99force-ipv4;',
            run: 'always'
        # global config runs before node's one => place here
        node.vm.provision 'puppet_init', type: 'shell',
            inline: puppet_init
        node.vm.synced_folder ".", "/etc/puppetlabs/code/environments/production/",
            type: 'rsync', owner: 'puppet', group: 'puppet'
    end
    config.vm.define 'db' do |node|
        node.vm.provider "virtualbox" do |v|
            v.memory = 1024
        end
        node.vm.network(
            "private_network",
            adapter: 2,
            ip: "10.10.2.10",
            netmask: "24",
            nic_type: nic_type,
            virtualbox__intnet: "dbdmz",
            auto_config: false
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: '\
            hostname db.example.com; \
            ifconfig eth1 up; \
            ip addr add 10.10.2.10/24 dev eth1; \
            ip route change default via 10.10.2.254 dev eth1; \
            echo \'Acquire::ForceIPv4 "true";\' | tee /etc/apt/apt.conf.d/99force-ipv4;',
            run: 'always'
        # global config runs before node's one => place here
        node.vm.provision 'puppet_init', type: 'shell',
            inline: puppet_init
    end
    config.vm.define 'web' do |node|
        node.vm.provider "virtualbox" do |v|
            v.memory = 512
        end
        node.vm.network(
            "private_network",
            adapter: 2,
            ip: "10.10.3.10",
            netmask: "24",
            nic_type: nic_type,
            virtualbox__intnet: "webdmz",
            auto_config: false
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: '\
            hostname web.example.com;\
            ifconfig eth1 up; \
            ip addr add 10.10.3.10/24 dev eth1; \
            ip route change default via 10.10.3.254 dev eth1; \
            echo \'Acquire::ForceIPv4 "true";\' | tee /etc/apt/apt.conf.d/99force-ipv4;',
            run: 'always'
        # global config runs before node's one => place here
        node.vm.provision 'puppet_init', type: 'shell',
            inline: puppet_init
    end
    config.vm.define 'dbclust1' do |node|
        node.vm.provider "virtualbox" do |v|
            v.memory = 1024
        end
        node.vm.network(
            "private_network",
            adapter: 2,
            ip: "10.10.2.20",
            netmask: "24",
            nic_type: nic_type,
            virtualbox__intnet: "dbdmz",
            auto_config: false
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: '\
            hostname dbclust1.example.com; \
            ifconfig eth1 up; \
            ip addr add 10.10.2.20/24 dev eth1; \
            ip route change default via 10.10.2.254 dev eth1; \
            echo \'Acquire::ForceIPv4 "true";\' | tee /etc/apt/apt.conf.d/99force-ipv4;',
            run: 'always'
        # global config runs before node's one => place here
        node.vm.provision 'puppet_init', type: 'shell',
            inline: puppet_init
    end
    config.vm.define 'dbclust2' do |node|
        node.vm.provider "virtualbox" do |v|
            v.memory = 1024
        end
        node.vm.network(
            "private_network",
            adapter: 2,
            ip: "10.10.2.21",
            netmask: "24",
            nic_type: nic_type,
            virtualbox__intnet: "dbdmz",
            auto_config: false
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: '\
            hostname dbclust2.example.com; \
            ifconfig eth1 up; \
            ip addr add 10.10.2.21/24 dev eth1; \
            ip route change default via 10.10.2.254 dev eth1; \
            echo \'Acquire::ForceIPv4 "true";\' | tee /etc/apt/apt.conf.d/99force-ipv4;',
            run: 'always'
        # global config runs before node's one => place here
        node.vm.provision 'puppet_init', type: 'shell',
            inline: puppet_init
    end
    config.vm.define 'web2' do |node|
        node.vm.provider "virtualbox" do |v|
            v.memory = 512
        end
        node.vm.network(
            "private_network",
            adapter: 2,
            ip: "10.10.3.11",
            netmask: "24",
            nic_type: nic_type,
            virtualbox__intnet: "webdmz",
            auto_config: false
        )
        node.vm.provision 'add-default-route', type: 'shell',
            inline: '\
            hostname web2.example.com;\
            ifconfig eth1 up; \
            ip addr add 10.10.3.11/24 dev eth1; \
            ip route change default via 10.10.3.254 dev eth1; \
            echo \'Acquire::ForceIPv4 "true";\' | tee /etc/apt/apt.conf.d/99force-ipv4;',
            run: 'always'
        # global config runs before node's one => place here
        node.vm.provision 'puppet_init', type: 'shell',
            inline: puppet_init
    end
end
