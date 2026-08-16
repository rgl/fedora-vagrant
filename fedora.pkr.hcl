packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-qemu
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "1.1.6"
    }
    # see https://github.com/hashicorp/packer-plugin-proxmox
    proxmox = {
      version = "1.2.4"
      source  = "github.com/hashicorp/proxmox"
    }
    # see https://github.com/hashicorp/packer-plugin-vagrant
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "1.1.7"
    }
  }
}

variable "http_bind_address" {
  type    = string
  default = env("PACKER_HTTP_BIND_ADDRESS")
}

variable "version" {
  type = string
}

variable "vagrant_box" {
  type = string
}

variable "proxmox_node" {
  type    = string
  default = env("PROXMOX_NODE")
}

variable "disk_size" {
  type    = string
  default = 8 * 1024
}

variable "iso_url" {
  type    = string
  default = "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Server/x86_64/iso/Fedora-Server-netinst-x86_64-44-1.7.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:ae20c06bea746913cadea7d80463e13f4bf55bee4df2918111c921c674b70283"
}

variable "ks" {
  type    = string
  default = "ks.cfg"
}

source "qemu" "fedora-uefi-amd64" {
  accelerator       = "kvm"
  machine_type      = "q35"
  efi_boot          = true
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.fd"
  cpus              = 2
  memory            = 2 * 1024
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
    "<home>e",                       // edit the install boot entry.
    "<down><down>",                  // go to the linux line.
    "<end><bs><bs><bs><bs><bs><bs>", // delete the "quiet" word.
    " ip=dhcp",
    " net.ifnames=0",
    " inst.cmdline",
    " inst.ksstrict",
    " inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/${var.ks}",
    " systemd.mask=brltty.service",
    "<f10>" // boot.
  ]
  shutdown_command = "echo vagrant | sudo -S poweroff"
}

source "proxmox-iso" "fedora-uefi-amd64" {
  template_name            = "template-fedora-${var.version}-uefi"
  template_description     = <<-EOS
                              See https://github.com/rgl/fedora-vagrant

                              ```
                              Build At: ${timestamp()}
                              ```
                              EOS
  tags                     = "fedora-${var.version}-uefi;template"
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node
  machine                  = "q35"
  http_directory           = "."
  http_bind_address        = var.http_bind_address
  boot_command = [
    "<home>e",                       // edit the install boot entry.
    "<down><down>",                  // go to the linux line.
    "<end><bs><bs><bs><bs><bs><bs>", // delete the "quiet" word.
    " ip=dhcp",
    " net.ifnames=0",
    " inst.cmdline",
    " inst.ksstrict",
    " inst.ks=http://{{.HTTPIP}}:{{.HTTPPort}}/${var.ks}",
    " systemd.mask=brltty.service",
    "<f10>" // boot.
  ]
  boot_wait = "5s"
  bios      = "ovmf"
  efi_config {
    efi_storage_pool = "local-lvm"
  }
  cpu_type = "host"
  cores    = 2
  memory   = 2 * 1024
  vga {
    type   = "qxl"
    memory = 16
  }
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  scsi_controller = "virtio-scsi-single"
  disks {
    type         = "scsi"
    io_thread    = true
    ssd          = true
    discard      = true
    disk_size    = "${var.disk_size}M"
    storage_pool = "local-lvm"
    format       = "raw"
  }
  boot_iso {
    type             = "scsi"
    iso_storage_pool = "local"
    iso_url          = var.iso_url
    iso_checksum     = var.iso_checksum
    iso_download_pve = true
    unmount          = true
  }
  os           = "l26"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_timeout  = "60m"
}

build {
  sources = [
    "source.qemu.fedora-uefi-amd64",
    "source.proxmox-iso.fedora-uefi-amd64",
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
    only = [
      "qemu.fedora-uefi-amd64",
    ]
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }
}
