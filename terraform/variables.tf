variable "proxmox_api_url" {
  type        = string
  description = "The URL of the Proxmox API"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "The ID of the Proxmox API token"
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "The secret of the Proxmox API token"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "The name of the Proxmox node"
}

variable "vm_iso" {
  type        = string
  description = "The ISO file to use for the VM installation"
}

variable "ciuser" {
  description = "Cloud init user"
  type        = string
}

variable "cipassword" {
  description = "Cloud init user password"
  type        = string
  sensitive   = true
}

variable "ipconfig0" {
  description = "IP configuration for the VM"
  type        = string
  default     = "ip=dhcp"
}

variable "ssh_key" {
  description = "SSH public key for VM access"
  type        = string
}