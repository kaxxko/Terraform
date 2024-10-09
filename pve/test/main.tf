terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc2"
    }
  }
}

provider "proxmox" {
  pm_api_url          = "https://192.168.128.1:8006/api2/json"
  pm_user             = var.pve_user
  pm_password         = var.pve_pass
  pm_api_token_id     = var.pve_api_id
  pm_api_token_secret = var.pve_api_secret
}

resource "proxmox_vm_qemu" "vm_creation" {
  #Proxmox_system
  target_node = var.host_node
  clone       = "Alma-9.4-mini"
  os_type     = "cloud-init"

  name   = var.vm_name
  vmid   = var.vm_id
  onboot = true

  # #vm_status
  #   #CUP
  #   sockets = 1
  #   cores   = 1
  #   cpu     = "host"
  #   #Memory
  #   memory = 2048
  #   #others
  #   scsihw = "virtio-scsi-single"

  #   #Disk
  #   disks {
  #     sata {
  #       sata0 {
  #         cloudinit {
  #           storage = "local-lvm"
  #         }
  #       }
  #       sata1 {
  #         disk {
  #           size    = "10G"
  #           storage = "local-lvm"
  #         }
  #       }
  #     }
  #   }

  #   #Network
  #   network {
  #     bridge   = var.vm_nic
  #     tag      = -1
  #     firewall = false
  #     model    = "e1000"
  #   }

  #cloud-init
  ipconfig0 = "ip=dhcp"
  ipconfig1 = "ip=dhcp"
  ciuser    = var.user
  ssh_user  = var.user
  sshkeys   = var.pub_key
}