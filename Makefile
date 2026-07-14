SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=44

help:
	@echo type make build-libvirt, or make build-vsphere

build-libvirt: fedora-${VERSION}-amd64-libvirt.box
build-vsphere: fedora-${VERSION}-amd64-vsphere.box

fedora-${VERSION}-amd64-libvirt.box: ks.cfg upgrade.sh provision.sh fedora.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init fedora.pkr.hcl
	PACKER_KEY_INTERVAL=10ms \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.fedora-amd64 -on-error=abort -timestamp-ui fedora.pkr.hcl
	@./box-metadata.sh libvirt fedora-${VERSION}-amd64 $@

fedora-${VERSION}-amd64-vsphere.box: tmp/ks-vsphere.cfg provision.sh fedora-vsphere.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init fedora-vsphere.pkr.hcl
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_ks=tmp/ks-vsphere.cfg \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=vsphere-iso.fedora-amd64 -timestamp-ui fedora-vsphere.pkr.hcl
	echo '{"provider":"vsphere"}' >metadata.json
	tar cvf $@ metadata.json
	rm metadata.json
	@./box-metadata.sh vsphere fedora-${VERSION}-amd64 $@

# see https://packages.fedoraproject.org/pkgs/open-vm-tools/open-vm-tools/
tmp/ks-vsphere.cfg: ks.cfg
	mkdir -p tmp
	sed -E 's,(%packages .+),\1\nopen-vm-tools,g' ks.cfg >$@

.PHONY: build-libvirt build-vsphere
