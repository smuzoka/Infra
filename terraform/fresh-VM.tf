resource "proxmox_vm_qemu" "fresh_vm" {
  target_node = var.proxmox_node
  vmid        = "100"
  name        = "Fresh_VM"
  desc        = "First Ubuntu VM from terraform"

  cpu    = "host"
  cores  = 1
  memory = 2048
  scsihw = "virtio-scsi-pci"

  disk {
    size    = "32G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  iso     = var.vm_iso
  boot    = "cdn"
  os_type = "Linux"
  agent   = 1
  onboot  = true
}
