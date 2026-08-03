variable "proxmox_api_url" {
  description = "URL de la API de Proxmox, ej: https://192.168.1.10:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Token de API en formato 'user@realm!tokenid=uuid'. Crear con pveum, ver docs/proxmox-setup.md"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "true si el certificado TLS de Proxmox es self-signed (caso tipico en homelab)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Nombre del nodo Proxmox donde se crean las VMs/LXC (ej: pve-notebook)"
  type        = string
}

variable "network_bridge" {
  description = "Bridge de red de Proxmox a usar"
  type        = string
  default     = "vmbr0"
}

variable "network_gateway" {
  description = "Gateway de la red local"
  type        = string
}

variable "ssh_public_key" {
  description = "Clave publica SSH que se inyecta via cloud-init en las VMs/LXC (la misma que usa Ansible)"
  type        = string
}
