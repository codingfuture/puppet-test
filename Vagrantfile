
Vagrant.require_version ">= 1.9.1"

Vagrant.configure(2) do |config|
    use_os = 'stretch'
    
    if ENV['USE_OS']
        use_os = ENV['USE_OS']
    elsif File.exists? 'USE_OS'
        use_os = File.read('USE_OS').strip
    end
    
    nic_type = 'virtio'
    disk_controller = 'SATA Controller'
    storagectl_opts = []
    eth0='enp0s3'
    eth1='enp0s8'
    eth2='enp0s9'
    eth3='enp0s10'
    eth4='enp0s16'

    if ['wily', 'xenial', 'jakkety', 'zesty'].include? use_os
        if false
            disk_controller = 'SCSI'
            storagectl_opts = [
                '--controller', 'BusLogic',
            ]
            config.vm.box = "ubuntu/#{use_os}64"
        else
            config.vm.box = case use_os
                when 'wily' then 'bento/ubuntu-15.10'
                when 'xenial' then 'bento/ubuntu-16.04'
                when 'jakkety' then 'bento/ubuntu-16.10'
                when 'zesty' then 'bento/ubuntu-17.04'
                else
                    fail("Unknown OS image #{use_os}")
                end
        end
    elsif [ 'jessie', 'stretch' ].include? use_os
        config.vm.box = "debian/#{use_os}64"
        eth0='eth0'
        eth1='eth1'
        eth2='eth2'
        eth3='eth3'
        eth4='eth4'
    else
        fail("Unknown OS image #{use_os}")
    end


    config.vm.provider "virtualbox" do |v|
        v.linked_clone = true
        v.memory = 256
        v.cpus = 1
        if ENV['VAGRANT_GUI']
            v.gui = 1
        end
        
        if disk_controller
            v.customize [
                "storagectl", :id,
                "--name", disk_controller,
                "--hostiocache", "on"
            ] + storagectl_opts
        end
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
    
    network_prefix = '172.31.99'
    
    config.vm.synced_folder ".", "/vagrant", disabled: true
    
    disable_puppet_sync = ENV['DISABLE_PUPPET_SYNC'] == 'true'

    #----
    # Router
    #----
    config.vm.define 'router' do |node|
        node.vm.network(
            "private_network",
            adapter: 2,
            ip: "#{network_prefix}.30",
            netmask: "24",
            nic_type: nic_type,
            name: 'vboxnet0',
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
        node.vm.provision 'setup-network', type: 'shell',
            inline: "\
            ip link set dev #{eth1} up; \
            ip addr add #{network_prefix}.30/24 dev #{eth1}; \
            ip link set dev #{eth2} up; \
            ip addr add 10.10.1.254/24 dev #{eth2}; \
            ip link set dev #{eth3} up; \
            ip addr add 10.10.2.254/24 dev #{eth3}; \
            ip link set dev #{eth4} up; \
            ip addr add 10.10.3.254/24 dev #{eth4}; \
            ip route change default via #{network_prefix}.1 dev #{eth1}; \
            sysctl -w net.ipv4.ip_forward=1; \
            echo 'Acquire::ForceIPv4 \"true\";' | tee /etc/apt/apt.conf.d/99force-ipv4;"
        node.vm.provision 'add-default-nat', type: 'shell',
            inline: "\
            iptables -t raw -A PREROUTING -i #{eth1} -d 10/8 -j DROP; \
            iptables -t nat -A POSTROUTING -o #{eth1} -s 10/8 -j MASQUERADE"
        
        node.vm.network :forwarded_port, guest: 22, host: 17022
    end
    #----
    # Infra
    #----
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
        node.vm.provision 'setup-network', type: 'shell',
            inline: "\
            ip link set dev #{eth1} up; \
            ip addr add 10.10.1.10/24 dev #{eth1}; \
            ip route change default via 10.10.1.254 dev #{eth1}; \
            echo 'Acquire::ForceIPv4 \"true\";' | tee /etc/apt/apt.conf.d/99force-ipv4;"
        
        node.vm.network :forwarded_port, guest: 22, host: 17023
    end
    #----
    # Pupppet cluster
    #----
    config.vm.define 'puppet' do |node|
        node.vm.provider "virtualbox" do |v|
            v.memory = 1536
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
        node.vm.provision('setup-network', type: 'shell',
            inline: "\
            ip link set dev #{eth1} up; \
            ip addr add 10.10.1.11/24 dev #{eth1}; \
            ip route change default via 10.10.1.254 dev #{eth1}; \
            echo 'Acquire::ForceIPv4 \"true\";' | tee /etc/apt/apt.conf.d/99force-ipv4;"
        )
        node.vm.synced_folder(".", "/etc/puppetlabs/code/environments/production/",
            type: 'rsync', owner: 'puppet', group: 'puppet', disabled: disable_puppet_sync
        )
        
        node.vm.network :forwarded_port, guest: 22, host: 17024
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
        node.vm.provision('setup-network', type: 'shell',
            inline: "\
            ip link set dev #{eth1} up; \
            ip addr add 10.10.1.12/24 dev #{eth1}; \
            ip route change default via 10.10.1.254 dev #{eth1}; \
            echo 'Acquire::ForceIPv4 \"true\";' | tee /etc/apt/apt.conf.d/99force-ipv4;"
        )
        node.vm.synced_folder(".", "/etc/puppetlabs/code/environments/production/",
            type: 'rsync', owner: 'puppet', group: 'puppet', disabled: disable_puppet_sync
        )
        
        node.vm.network :forwarded_port, guest: 22, host: 17025
    end
    #----
    # DB cluster
    #----
    config.vm.define 'dbclust1' do |node|
        node.vm.provider "virtualbox" do |v|
            v.memory = 1536
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
        node.vm.network(
            "private_network",
            adapter: 3,
            ip: "10.11.0.20",
            netmask: "24",
            nic_type: nic_type,
            virtualbox__intnet: "dbcomms",
            auto_config: false
        )
        node.vm.provision('setup-network', type: 'shell',
            inline: "\
            ip link set dev #{eth1} up; \
            ip addr add 10.10.2.20/24 dev #{eth1}; \
            ip route change default via 10.10.2.254 dev #{eth1}; \
            ip link set dev #{eth2} up; \
            ip addr add 10.11.0.20/27 dev #{eth2}; \
            echo 'Acquire::ForceIPv4 \"true\";' | tee /etc/apt/apt.conf.d/99force-ipv4;"
        )

        node.vm.provision('guest-additions', type: 'shell',
            inline: "\
            sed -i /etc/apt/sources.list -e 's/main/main contrib non-free/g';\
            apt-get update;\
            apt-get install lsb-release;\
            echo \"deb http://deb.debian.org/debian $(lsb_release -cs)-backports main contrib non-free\" >> /etc/apt/sources.list;\
            apt-get update;\
            apt-get install -y linux-headers-amd64 virtualbox-guest-dkms" )
        node.vm.provision('setup-esearch', type: 'shell',
            inline: "useradd -U elasticsearch_esearch" )
        node.vm.synced_folder("backup_share/elasticsearch_esearch", "/mnt/backup/elasticsearch_esearch",
            type: 'virtualbox',
            owner: 'elasticsearch_esearch', group: 'elasticsearch_esearch',
            create: true,
            disabled: disable_puppet_sync
        )
        
        node.vm.network :forwarded_port, guest: 22, host: 17026
    end
    config.vm.define 'dbclust2' do |node|
        node.vm.provider "virtualbox" do |v|
            v.memory = 1536
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
        node.vm.network(
            "private_network",
            adapter: 3,
            ip: "10.11.0.21",
            netmask: "27",
            nic_type: nic_type,
            virtualbox__intnet: "dbcomms",
            auto_config: false
        )
        node.vm.provision('setup-network', type: 'shell',
            inline: "\
            ip link set dev #{eth1} up; \
            ip addr add 10.10.2.21/24 dev #{eth1}; \
            ip route change default via 10.10.2.254 dev #{eth1}; \
            ip link set dev #{eth2} up; \
            ip addr add 10.11.0.21/27 dev #{eth2}; \
            echo 'Acquire::ForceIPv4 \"true\";' | tee /etc/apt/apt.conf.d/99force-ipv4;"
        )

        node.vm.provision('guest-additions', type: 'shell',
            inline: "\
            sed -i /etc/apt/sources.list -e 's/main/main contrib non-free/g';\
            apt-get update;\
            apt-get install lsb-release;\
            echo \"deb http://deb.debian.org/debian $(lsb_release -cs)-backports main contrib non-free\" >> /etc/apt/sources.list;\
            apt-get update;\
            apt-get install -y linux-headers-amd64 virtualbox-guest-dkms" )
        node.vm.provision('setup-esearch', type: 'shell',
            inline: "useradd -U elasticsearch_esearch" )
        node.vm.synced_folder("backup_share/elasticsearch_esearch", "/mnt/backup/elasticsearch_esearch",
            type: 'virtualbox',
            owner: 'elasticsearch_esearch', group: 'elasticsearch_esearch',
            create: true,
            disabled: disable_puppet_sync
        )
        
        node.vm.network :forwarded_port, guest: 22, host: 17027
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
        node.vm.network(
            "private_network",
            adapter: 3,
            ip: "10.11.0.10",
            netmask: "27",
            nic_type: nic_type,
            virtualbox__intnet: "dbcomms",
            auto_config: false
        )
        node.vm.provision('setup-network', type: 'shell',
            inline: "\
            ip link set dev #{eth1} up; \
            ip addr add 10.10.2.10/24 dev #{eth1}; \
            ip route change default via 10.10.2.254 dev #{eth1}; \
            ip link set dev #{eth2} up; \
            ip addr add 10.11.0.10/27 dev #{eth2}; \
            echo 'Acquire::ForceIPv4 \"true\";' | tee /etc/apt/apt.conf.d/99force-ipv4;"
        )
        
        node.vm.network :forwarded_port, guest: 22, host: 17028
    end
    #----
    # Web
    #----
    config.vm.define 'web' do |node|
        node.vm.provider "virtualbox" do |v|
            v.memory = 1600
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
        node.vm.provision('setup-network', type: 'shell',
            inline: "\
            ip link set dev #{eth1} up; \
            ip addr add 10.10.3.10/24 dev #{eth1}; \
            ip route change default via 10.10.3.254 dev #{eth1}; \
            echo 'Acquire::ForceIPv4 \"true\";' | tee /etc/apt/apt.conf.d/99force-ipv4;"
        )
        
        node.vm.network :forwarded_port, guest: 22, host: 17029
    end
    config.vm.define 'web2' do |node|
        node.vm.provider "virtualbox" do |v|
            v.memory = 1024
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
        node.vm.provision('setup-network', type: 'shell',
            inline: "\
            ip link set dev #{eth1} up; \
            ip addr add 10.10.3.11/24 dev #{eth1}; \
            ip route change default via 10.10.3.254 dev #{eth1}; \
            echo 'Acquire::ForceIPv4 \"true\";' | tee /etc/apt/apt.conf.d/99force-ipv4;"
        )
        
        node.vm.network :forwarded_port, guest: 22, host: 17030
    end
    config.vm.define 'logmon' do |node|
        node.vm.provider "virtualbox" do |v|
            v.memory = 1024
        end
        node.vm.network(
            "private_network",
            adapter: 2,
            ip: "10.10.1.21",
            netmask: "24",
            nic_type: nic_type,
            virtualbox__intnet: "infradmz",
            auto_config: false
        )
        node.vm.provision('setup-network', type: 'shell',
            inline: "\
            ip link set dev #{eth1} up; \
            ip addr add 10.10.1.21/24 dev #{eth1}; \
            ip route change default via 10.10.1.254 dev #{eth1}; \
            echo 'Acquire::ForceIPv4 \"true\";' | tee /etc/apt/apt.conf.d/99force-ipv4;"
        )
        
        node.vm.network :forwarded_port, guest: 22, host: 17031
    end
end
