# Modulo generico para levantar una VM Debian via cloud-init, importando la
# imagen cloud oficial (sin necesidad de armar una plantilla a mano primero).
#
# NOTA: la API del provider bpg/proxmox cambia con cierta frecuencia entre
# versiones. Si `tofu plan` falla por atributos desconocidos, revisar la
# version fijada en providers.tf contra la doc actual del provider.

resource "proxmox_virtual_environment_download_file" "cloud_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.node_name
  url          = var.cloud_image_url
  file_name    = "${var.name}-cloud-image.img"
  overwrite    = false
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.node_name
  vm_id     = var.vmid
  tags      = var.tags

  agent {
    enabled = true
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore_id
    import_from  = proxmox_virtual_environment_download_file.cloud_image.id
    interface    = "scsi0"
    size         = var.disk_size
  }

  network_device {
    bridge = var.bridge
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }
    user_account {
      username = "debian"
      keys     = [var.ssh_public_key]
    }
  }
}
