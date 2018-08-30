Vagrant.configure(2) do |config|
  config.vm.box = 'bento/ubuntu-16.04'

  config.vm.hostname = 'vault'

  config.vm.provider 'virtualbox' do |vb|
    vb.linked_clone = true
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.provision 'shell', path: 'provision.sh'
  config.vm.provision 'shell', path: 'provision-vault.sh'
end
