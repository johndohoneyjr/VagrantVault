
Vagrant.configure("2") do |config|
  config.vm.define "vault" do |vault|

    vault.vm.box = "bento/ubuntu-16.04"
    vault.vm.hostname = 'vault'
    vault.vm.box_url = "bento/ubuntu-16.04"

    vault.vm.network :private_network, ip: '192.168.56.101'

    vault.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 1024]
      v.customize ["modifyvm", :id, "--name", "vault"]
    end
    vault.vm.provision 'shell', path: 'provision.sh'
    vault.vm.provision 'shell', path: 'provision-vault.sh'
  end

  config.vm.define "db" do |db|
    db.vm.box = "centos/7"
    db.vm.hostname = 'db'
    db.vm.box_url = "centos/7"
    db.vm.network :private_network, ip: '192.168.56.102'

    db.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 1024]
      v.customize ["modifyvm", :id, "--name", "db"]
    end
    db.vm.provision 'shell', path: 'bootstrap.sh'
  end
end
