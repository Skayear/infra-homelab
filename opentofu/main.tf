# Los tags son clave: el inventario dinamico de Ansible (ansible/inventory/proxmox.yml)
# agrupa las VMs/LXC segun estos tags (tag "databases" -> grupo tag_databases, etc).
# Si cambias un tag aca, actualiza el playbook correspondiente en ansible/playbooks/.

module "databases" {
  source = "./modules/lxc"

  name           = "databases"
  vmid           = 200
  node_name      = var.proxmox_node
  cores          = 2
  memory         = 2048
  disk_size      = 20
  ip_address     = "192.168.1.40/24"
  gateway        = var.network_gateway
  bridge         = var.network_bridge
  ssh_public_key = var.ssh_public_key
  tags           = ["databases"]
}

module "model_server" {
  source = "./modules/vm"

  # TODO: cores/memory puestos como ejemplo (6 vCPU / 16GB). Ajustar a lo que
  # realmente tenga la notebook, dejando margen para el propio Proxmox y el
  # LXC de databases (no asignar el 100% de los recursos del host).
  name           = "model-server"
  vmid           = 201
  node_name      = var.proxmox_node
  cores          = 6
  memory         = 16384
  disk_size      = 80
  ip_address     = "192.168.1.30/24"
  gateway        = var.network_gateway
  bridge         = var.network_bridge
  ssh_public_key = var.ssh_public_key
  tags           = ["model_server"]
}
