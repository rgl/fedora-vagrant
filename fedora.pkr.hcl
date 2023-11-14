packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-qemu
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "1.0.10"
    }
    # see https://github.com/hashicorp/packer-plugin-vagrant
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "1.1.1"
    }
  }
}

variable "version" {
  type = string
}

variable "vagrant_box" {
  type = string
}

variable "disk_size" {
  type    = string
  default = 8 * 1024
}

variable "iso_url" {
  type    = string
  default = "https://download.fedoraproject.org/pub/fedora/linux/releases/39/Server/x86_64/iso/Fedora-Server-netinst-x86_64-39-1.5.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:61576ae7170e35210f03aae3102048f0a9e0df7868ac726908669b4ef9cc22e9"
}

variable "ks" {
  type    = string
  default = "ks.cfg"
}

source "qemu" "fedora-amd64" {
  accelerator = "kvm"
  cpus        = 2
  memory      = 2 * 1024
  qemuargs = [
    ["-cpu", "host"]
  ]
  headless         = true
  net_device       = "virtio-net"
  http_directory   = "."
  format           = "qcow2"
  disk_size        = var.disk_size
  disk_interface   = "virtio-scsi"
  disk_cache       = "unsafe"
  disk_discard     = "unmap"
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  ssh_wait_timeout = "60m"
  boot_wait        = "5s"
  boot_command = [
    "<home>e<down><down><end>",
    " ip=dhcp",
    " inst.cmdline",
    " inst.ksstrict",
    " inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/${var.ks}",
    " systemd.mask=brltty.service",
    "<f10>",
  ]
  shutdown_command = "echo vagrant | sudo -S poweroff"
}

build {
  sources = [
    "source.qemu.fedora-amd64",
  ]

  provisioner "shell" {
    expect_disconnect = true
    execute_command   = "echo vagrant | sudo -S {{ .Vars }} bash {{ .Path }}"
    scripts = [
      "upgrade.sh",
      "provision-guest-additions.sh",
      "provision.sh"
    ]
  }

  post-processor "vagrant" {
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }
}
