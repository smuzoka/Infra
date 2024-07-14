output "fresh_vm_ip" {
  value       = proxmox_vm_qemu.fresh_vm.default_ipv4_address
  description = "The IP address of the created VM"
}

output "clone_vm_ip" {
  value       = proxmox_vm_qemu.clone_vm.default_ipv4_address
  description = "The IP address of the created VM"
}
