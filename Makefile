SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=40

help:
	@echo type make build-libvirt

build-libvirt: fedora-${VERSION}-amd64-libvirt.box

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

.PHONY: buid-libvirt
