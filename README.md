This builds an up-to-date Vagrant Fedora Base Box.

Currently this targets [Fedora](https://fedoraproject.org/) 44.


# Usage

Install [Packer](https://www.packer.io/) and [Vagrant](https://www.vagrantup.com/).

If your host has multiple IP addresses, you might need to set the
`PACKER_HTTP_BIND_ADDRESS` environment variable, e.g.:

```bash
export PACKER_HTTP_BIND_ADDRESS='192.168.8.11'
```

Depending on your hypervisor, follow its instructions:

* [QEMU-KVM usage](#qemu-kvm-usage)
* [Proxmox VE usage](#proxmox-ve-usage)
* [VMware vSphere usage](#vmware-vsphere-usage)


## qemu-kvm usage

Install qemu-kvm:

```bash
apt-get install -y qemu-kvm
apt-get install -y sysfsutils
systool -m kvm_intel -v
```

Type `make build-uefi-libvirt` and follow the instructions.

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


## Proxmox VE usage

Install [Proxmox VE](https://www.proxmox.com/en/proxmox-ve).

**NB** This assumes proxmox was installed alike [rgl/proxmox-ve](https://github.com/rgl/proxmox-ve).

Set your proxmox details:

```bash
cat >secrets-proxmox.sh <<EOF
#export PACKER_HTTP_BIND_ADDRESS='192.168.8.11'
export PROXMOX_URL='https://192.168.1.21:8006/api2/json'
export PROXMOX_USERNAME='root@pam'
export PROXMOX_PASSWORD='vagrant'
export PROXMOX_NODE='pve'
EOF
source secrets-proxmox.sh
```

Create the template:

```bash
make build-uefi-proxmox
```

**NB** There is no way to use the created template with vagrant (the [vagrant-proxmox plugin](https://github.com/telcat/vagrant-proxmox) is no longer compatible with recent vagrant versions). Instead, use packer (e.g. see this repository) or terraform (e.g. see [rgl/terraform-proxmox-fedora-example](https://github.com/rgl/terraform-proxmox-fedora-example)).


### VMware vSphere usage

Download [govc](https://github.com/vmware/govmomi/releases/latest) and place it inside your `/usr/local/bin` directory.

Set your vSphere details, and test the connection to vSphere:

```bash
sudo apt-get install build-essential patch ruby-dev zlib1g-dev liblzma-dev
vagrant plugin install vagrant-vsphere
cat >secrets-vsphere.sh <<EOF
#export PACKER_HTTP_BIND_ADDRESS='192.168.8.11'
export GOVC_INSECURE='1'
export GOVC_HOST='vsphere.local'
export GOVC_URL="https://$GOVC_HOST/sdk"
export GOVC_USERNAME='administrator@vsphere.local'
export GOVC_PASSWORD='password'
export GOVC_DATACENTER='Datacenter'
export GOVC_CLUSTER='Cluster'
export GOVC_DATASTORE='Datastore'
export VSPHERE_OS_ISO="[$GOVC_DATASTORE] iso/Fedora-Server-netinst-x86_64-44-1.7.iso"
export VSPHERE_ESXI_HOST='esxi.local'
export VSPHERE_TEMPLATE_FOLDER='test/templates'
export VSPHERE_TEMPLATE_NAME="$VSPHERE_TEMPLATE_FOLDER/fedora-44-uefi-amd64"
export VSPHERE_VM_FOLDER='test'
export VSPHERE_VM_NAME='fedora-44-vagrant-example'
export VSPHERE_VLAN='packer'
# set the credentials that the guest will use
# to connect to this host smb share.
# NB you should create a new local user named _vagrant_share
#    and use that one here instead of your user credentials.
# NB it would be nice for this user to have its credentials
#    automatically rotated, if you implement that feature,
#    let me known!
export VAGRANT_SMB_USERNAME='_vagrant_share'
export VAGRANT_SMB_PASSWORD=''
EOF
source secrets-vsphere.sh
# see https://github.com/vmware/govmomi/blob/master/govc/USAGE.md
govc version
govc about
govc datacenter.info # list datacenters
govc find # find all managed objects
```

Download the Fedora ISO (you can find the full iso URL in the [fedora.pkr.hcl](fedora.pkr.hcl) file) and place it inside the datastore as defined by the `vsphere_iso_url` user variable that is inside the [packer template](fedora-vsphere.pkr.hcl).

See the [example Vagrantfile](example/Vagrantfile) to see how you could use a cloud-init configuration to configure the VM.

Create the base image:

```bash
source secrets-vsphere.sh
make build-uefi-vsphere
```

Try the example guest:

```bash
cd example
vagrant up --provider=vsphere --no-destroy-on-error
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
