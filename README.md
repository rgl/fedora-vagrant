This builds an up-to-date Vagrant Fedora Base Box.

Currently this targets [Fedora](https://fedoraproject.org/) 31.


# Usage

Install [Packer](https://www.packer.io/), [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/).

## qemu-kvm usage

Install qemu-kvm:

```bash
apt-get install -y qemu-kvm
apt-get install -y sysfsutils
systool -m kvm_intel -v
```

Type `make build-libvirt` and follow the instructions.

Try the example guest:

```bash
cd example
apt-get install -y virt-manager libvirt-dev
vagrant plugin install vagrant-libvirt
vagrant up --provider=libvirt
vagrant ssh
exit
vagrant destroy -f
```

## VirtualBox usage

Install [VirtuaBox](https://www.virtualbox.org/).

Type `make build-virtualbox` and follow the instructions.

Try the example guest:

```bash
cd example
vagrant up --provider=virtualbox
vagrant ssh
exit
vagrant destroy -f
```


# Kickstart

The Fedora installation iso uses the Anaconda installer to install Fedora.
During the installation it will ask you some questions and it will also
store your anwsers in the `/root/anaconda-ks.cfg` (aka kickstart) file.
This file is later used to fully automate a new installation by specifying
its location in the `inst.ks` kernel command line argument.


# Reference

* [Anaconda boot options](https://docs.fedoraproject.org/en-US/fedora/f31/install-guide/advanced/Boot_Options/)
* [Kickstart manual](http://pykickstart.readthedocs.io/en/latest/kickstart-docs.html)
* [Kickstart Syntax Reference](https://docs.fedoraproject.org/en-US/fedora/f31/install-guide/appendixes/Kickstart_Syntax_Reference/#appe-kickstart-syntax-reference)
* [Automating the Installation with Kickstart](https://docs.fedoraproject.org/en-US/fedora/f31/install-guide/advanced/Kickstart_Installations/)
* [Mirror list](https://admin.fedoraproject.org/mirrormanager/)
