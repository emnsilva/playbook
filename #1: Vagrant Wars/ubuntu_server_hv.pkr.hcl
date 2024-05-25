variable "hyperv_switch" {
  type    = string
  default = "Default Switch"
}

variable "timestamp" {
  type    = string
  default = formatdate("2006-01-02-150405", timestamp())
}

source "hyperv-iso" "ubuntu_server" {
  iso_url          = "file:///caminho_da_sua_iso_de_instalação"
  iso_checksum     = "sha256:your_iso_checksum"
  communicator     = "ssh"
  ssh_username     = "ubuntu"
  ssh_password     = "ubuntu"
  ssh_timeout      = "60m"
  switch_name      = var.hyperv_switch
  disk_size        = 153600
  vm_name          = "ubuntu-${var.timestamp}"
  shutdown_command = "sudo shutdown -P now"
  shutdown_timeout = "15m"
  boot_wait        = "5s"
  boot_command     = [
    "<esc><wait>",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/<enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]
  output_directory = "output-hyperv"
}

build {
  sources = ["source.hyperv-iso.ubuntu_server"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y curl vim"
    ]
  }

  provisioner "shell" {
    inline = [
      "vm_name=ubuntu-${var.timestamp}",
      "if [[ $(sudo virsh list --all | grep $vm_name) ]]; then",
      "  sudo virsh destroy $vm_name",
      "  sudo virsh undefine $vm_name --remove-all-storage",
      "fi"
    ]
  }
}