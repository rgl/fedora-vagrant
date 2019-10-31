VERSION=$(shell jq -r .variables.version fedora.json)

help:
	@echo type make build-libvirt or make build-virtualbox

build-libvirt: fedora-${VERSION}-amd64-libvirt.box

build-virtualbox: fedora-${VERSION}-amd64-virtualbox.box

fedora-${VERSION}-amd64-libvirt.box: ks.cfg upgrade.sh provision.sh fedora.json Vagrantfile.template
	rm -f fedora-${VERSION}-amd64-libvirt.box
	PACKER_KEY_INTERVAL=10ms CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=fedora-${VERSION}-amd64-libvirt -on-error=abort fedora.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f fedora-${VERSION}-amd64 fedora-${VERSION}-amd64-libvirt.box

fedora-${VERSION}-amd64-virtualbox.box: ks.cfg upgrade.sh provision.sh fedora.json
	rm -f fedora-${VERSION}-amd64-virtualbox.box
	 CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
		packer build -only=fedora-${VERSION}-amd64-virtualbox -on-error=abort fedora.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f fedora-${VERSION}-amd64 fedora-${VERSION}-amd64-virtualbox.box

.PHONY: buid-libvirt build-virtualbox
