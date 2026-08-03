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
  default     = 4096
}

variable "disk_size" {
  description = "GB de disco"
  type        = number
  default     = 32
}

variable "datastore_id" {
  type    = string
  default = "local-lvm"
}

variable "ip_address" {
  description = "IP con mascara CIDR, ej: 192.168.1.30/24"
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

variable "cloud_image_url" {
  description = "URL de la imagen cloud-init a importar como disco"
  type        = string
  default     = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}
