packer {
    required_plugins {
      hyperv = {
        version = ">= 1.0.0"
        source  = "github.com/hashicorp/hyperv"
      }
    }
  }
  
  variable "hyperv_switch" {
    type    = string
    default = "Default Switch"
  }
  
  variable "timestamp" {
  type    = string
  default = formatdate("2024-05-025-150405", timestamp())
}
  
  source "hyperv-iso" "windows_server_2022" {
    iso_url            = "file:///caminho_da_sua_iso_de_instalação"
    iso_checksum       = "sha256:your_iso_checksum"
    communicator       = "winrm"
    winrm_username     = "Administrator"
    winrm_password     = "password"
    winrm_timeout      = "6h"
    switch_name        = var.hyperv_switch
    disk_size          = 153600
    vm_name            = "win2022-${var.timestamp}"
    shutdown_command   = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
    shutdown_timeout   = "45m"
    output_directory   = "output-hyperv"
    boot_wait          = "5s"
    boot_command       = ["<tab><wait> autounattend=<enter>"]
  }
  
  build {
    sources = ["source.hyperv-iso.windows_server_2022"]
  
    provisioner "powershell" {
      inline = [
        "Set-ExecutionPolicy Bypass -Scope Process -Force",
        "Install-WindowsFeature -Name PowerShell-ISE"
      ]
    }
  }