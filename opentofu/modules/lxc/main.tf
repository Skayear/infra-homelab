# Modulo generico para levantar un contenedor LXC Debian sin privilegios.
#
# NOTA: igual que en modules/vm, revisar la version del provider bpg/proxmox
# fijada en providers.tf si `tofu plan` reporta atributos desconocidos.

resource "proxmox_virtual_environment_download_file" "template" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = var.node_name
  url          = var.template_url
  overwrite    = false
}

resource "proxmox_virtual_environment_container" "this" {
  node_name    = var.node_name
  vm_id        = var.vmid
  unprivileged = true
  tags         = var.tags
  started      = true

  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.template.id
    type             = "debian"
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
  }

  network_interface {
    name   = "eth0"
    bridge = var.bridge
  }

  initialization {
    hostname = var.name

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      keys = [var.ssh_public_key]
    }
  }
}
