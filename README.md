# Freifunk Example Node

Instead of taking real communities we decided to take a subset of the DC Universe
for our examples here: https://github.com/ffnord/ffnord-example

## Experimental environment

### INSTALL

install the packages vagrant and virtualbox, for example on debian:

    sudo apt-get install vagrant virtualbox
    
Vagrant 1.5 or later is required, which is available on the [Vagrant download page](http://www.vagrantup.com/downloads.html)

Now start your virtualbox service.

To have an experimental environment for testing of new features and tools, you like to deploy in your real world community,
you can setup parts of or the whole virtual world, using `vagrant`.

Before you start to roll out the virtual machines you should proceed some setup steps:

You need about 1.2 GB for each virtual machine in your homefolder in `~/VirtualBox VMs/`.

Now we can rollout the machine with:

    vagrant up testnode
    # Get a cup of coffee, take a walk or do something interesting. This will take time...
    vagrant ssh testnode

Vagrant uses the configuration in `Vagrantfile` to create each machine. In our `Vagrantfile` there is defined that on each machine the shell script `bootstrap-testnode.sh` is executed on install, so if you like to change the way machines are deployed, you can manipulate the `bootstrap-testnode.sh`.

On each machine this folder is mounted in the path `/vagrant/`. This way the configurations from the ffnord-example can be transfered on each machine.

If you want to see the boot process on the VMs, you can enable the virtualbox gui in `Vagrantfile` by uncommenting the line

    vb.gui = true
