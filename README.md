This builds an up-to-date Vagrant Fedora Base Box.

Currently this targets [Fedora](https://fedoraproject.org/) 44.


# Usage

Install [Packer](https://www.packer.io/) and [Vagrant](https://www.vagrantup.com/).

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


# Kickstart

The Fedora installation iso uses the Anaconda installer to install Fedora.
During the installation it will ask you some questions and it will also
store your answers in the `/root/anaconda-ks.cfg` (aka kickstart) file.
This file is later used to fully automate a new installation by specifying
its location in the `inst.ks` kernel command line argument.


# Reference

* [Anaconda boot options](https://anaconda-installer.readthedocs.io/en/latest/boot-options.html)
* [Kickstart manual](http://pykickstart.readthedocs.io/en/latest/kickstart-docs.html)
* [Kickstart Syntax Reference](https://anaconda-installer.readthedocs.io/en/latest/kickstart.html)
* [Mirror list](https://mirrormanager.fedoraproject.org/mirrors/Fedora)
  * [The fedora repository](https://docs.fedoraproject.org/en-US/quick-docs/fedora-repositories/)
    * [Near Fedora 44 mirrors](https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-44&arch=x86_64)
