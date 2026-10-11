SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=45

MIRROR_BASE=https://eu.edge.kernel.org/fedora
MIRROR_ARCH=${MIRROR_BASE}/releases/test/45_Beta/Server/x86_64
MIRROR_URL=${MIRROR_ARCH}/os
MIRROR_ISO_URL=${MIRROR_ARCH}/iso/Fedora-Server-netinst-x86_64-45_Beta-1.3.iso

export PKR_VAR_iso_url=${MIRROR_ISO_URL}

help:
	@echo type one of:
	@echo 	make build-uefi-libvirt
	@echo 	make build-uefi-proxmox
	@echo 	make build-uefi-vsphere

build-uefi-libvirt: fedora-${VERSION}-uefi-amd64-libvirt.box
build-uefi-proxmox: fedora-${VERSION}-uefi-amd64-proxmox.box
build-uefi-vsphere: fedora-${VERSION}-uefi-amd64-vsphere.box

fedora-${VERSION}-uefi-amd64-libvirt.box: tmp/ks-libvirt.cfg upgrade.sh provision.sh fedora.pkr.hcl Vagrantfile.template
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
	PKR_VAR_ks=tmp/ks-libvirt.cfg \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.fedora-uefi-amd64 -on-error=abort -timestamp-ui fedora.pkr.hcl
	@./box-metadata.sh libvirt fedora-${VERSION}-uefi-amd64 $@

tmp/ks-libvirt.cfg: ks.cfg
	mkdir -p tmp
	sed -E \
		's,@@MIRROR_URL@@,${MIRROR_URL},g' \
		ks.cfg >$@

fedora-${VERSION}-uefi-amd64-proxmox.box: tmp/ks-proxmox.cfg upgrade.sh provision.sh fedora.pkr.hcl Vagrantfile.template
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
	PKR_VAR_ks=tmp/ks-proxmox.cfg \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=proxmox-iso.fedora-uefi-amd64 -on-error=abort -timestamp-ui fedora.pkr.hcl

# see https://packages.fedoraproject.org/pkgs/qemu/qemu-guest-agent/
tmp/ks-proxmox.cfg: ks.cfg
	mkdir -p tmp
	sed -E \
		's,@@MIRROR_URL@@,${MIRROR_URL},g' \
		's,(%packages .+),\1\nqemu-guest-agent,g' \
		ks.cfg >$@

fedora-${VERSION}-uefi-amd64-vsphere.box: tmp/ks-vsphere.cfg provision.sh fedora-vsphere.pkr.hcl Vagrantfile.template
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
		packer build -only=vsphere-iso.fedora-uefi-amd64 -timestamp-ui fedora-vsphere.pkr.hcl
	echo '{"provider":"vsphere"}' >metadata.json
	tar cvf $@ metadata.json
	rm metadata.json
	@./box-metadata.sh vsphere fedora-${VERSION}-uefi-amd64 $@

# see https://packages.fedoraproject.org/pkgs/open-vm-tools/open-vm-tools/
tmp/ks-vsphere.cfg: ks.cfg
	mkdir -p tmp
	sed -E \
		's,@@MIRROR_URL@@,${MIRROR_URL},g' \
		's,(%packages .+),\1\nopen-vm-tools,g' \
		ks.cfg >$@

.PHONY: \
	build-uefi-libvirt \
	build-uefi-proxmox \
	build-uefi-vsphere
