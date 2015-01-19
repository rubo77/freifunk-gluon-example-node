# setup instructions vor vagrant to install a local VM with debian sid that works as a Freifunk node
# This config file will enable to setup and run the vm testnode with:
# # vagrant up testnode

# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "loicfrering/debian-unstable"

  config.vm.provider "virtualbox" do |vb|
    # Don't boot with headless mode
    vb.gui = true

    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end

  # node machine
  config.vm.define "testnode" do |node|
    node.vm.hostname = "testnode"
    node.vm.network "private_network",ip: "172.19.0.100", netmask: "255.255.0.0"
    node.vm.provision :shell, path: "bootstrap-testnode.sh"
  end
end
