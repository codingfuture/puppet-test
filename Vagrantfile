
Vagrant.require_version ">= 1.8.0"

Vagrant.configure(2) do |config|
    config.vm.provider "virtualbox" do |v|
        v.linked_clone = true
        v.memory = 256
        v.cpus = 1
    end
    
    config.ssh.username = 'adminuser'
    config.ssh.password = 'testpass'
    config.ssh.private_key_path = 'data/id_rsa_test'
    config.ssh.forward_x11 = false
    config.ssh.forward_agent = false

    config.vm.define 'router' do |node|
        node.vm.box = "debian/jessie64"
        node.vm.network(
            'public_network',
            ip: "192.168.0.30",
            netmask: "24",
            nic_type: "virtio",
            bridge: ['wlan0', 'eth0']
        )
        node.vm.network(
            "private_network",
            ip: "10.10.1.1",
            netmask: "24",
            nic_type: "virtio",
            virtualbox__intnet: "infradmz"
        )
        node.vm.network(
            "private_network",
            ip: "10.10.2.1",
            netmask: "24",
            nic_type: "virtio",
            virtualbox__intnet: "dbdmz"
        )
        node.vm.network(
            "private_network",
            ip: "10.10.3.1",
            netmask: "24",
            nic_type: "virtio",
            virtualbox__intnet: "webdmz"
        )
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
    end
    config.vm.define 'puppet' do |node|
        node.vm.box = "debian/jessie64"
        node.vm.network(
            "private_network",
            ip: "10.10.1.11",
            netmask: "24",
            nic_type: "virtio",
            virtualbox__intnet: "infradmz"
        )
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
    end
    config.vm.define 'web' do |node|
        node.vm.box = "ubuntu/wily64"
        node.vm.network(
            "private_network",
            ip: "10.10.3.10",
            netmask: "24",
            nic_type: "virtio",
            virtualbox__intnet: "webdmz"
        )
    end
end
