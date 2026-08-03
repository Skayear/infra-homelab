variable "name" {
  type = string
}

variable "vmid" {
  type = number
}

variable "node_name" {
  type = string
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  description = "MB de RAM"
  type        = number
  default     = 1024
}

variable "disk_size" {
  description = "GB de disco"
  type        = number
  default     = 16
}

variable "datastore_id" {
  type    = string
  default = "local-lvm"
}

variable "ip_address" {
  description = "IP con mascara CIDR, ej: 192.168.1.40/24"
  type        = string
}

variable "gateway" {
  type = string
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "ssh_public_key" {
  type = string
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "template_url" {
  description = "URL del template LXC (vztmpl) a descargar"
  type        = string
  default     = "http://download.proxmox.com/images/system/debian-12-standard_12.7-1_amd64.tar.zst"
}
