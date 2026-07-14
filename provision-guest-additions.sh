#!/bin/bash
set -eux

# install the Guest Additions.
if [ -n "$(lspci | grep 'Red Hat' | head -1)" ]; then
# install the qemu-kvm Guest Additions.
# see https://packages.fedoraproject.org/pkgs/qemu/qemu-guest-agent/
# see https://packages.fedoraproject.org/pkgs/spice-vdagent/spice-vdagent/
dnf install -y qemu-guest-agent spice-vdagent
elif [ -n "$(lspci | grep VMware | head -1)" ]; then
# install the VMware Guest Additions.
# see https://packages.fedoraproject.org/pkgs/open-vm-tools/open-vm-tools/
# no need to install the guest additions, as they are already installed from
# tmp/ks-vsphere.cfg.
exit 0
else
echo 'ERROR: Unknown VM host.' || exit 1
fi

# reboot.
nohup bash -c "ps -eo pid,comm | awk '/sshd/{print \$1}' | xargs kill; sync; reboot"
