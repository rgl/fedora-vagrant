#!/bin/bash
set -eux

# install the qemu-kvm Guest Additions.
dnf install -y qemu-guest-agent spice-vdagent

# reboot.
nohup bash -c "ps -eo pid,comm | awk '/sshd/{print \$1}' | xargs kill; sync; reboot"
