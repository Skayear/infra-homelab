output "ip_address" {
  value = split("/", var.ip_address)[0]
}

output "vmid" {
  value = proxmox_virtual_environment_vm.this.vm_id
}
