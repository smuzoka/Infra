resource "proxmox_vm_qemu" "clone_vm" {
  target_node = var.proxmox_node
  vmid        = "101"
  name        = "Ubuntu-TF"
  desc        = "Ubuntu VM from terraform"

  clone = "Fresh_VM"

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

  iso    = var.vm_iso
  agent  = 1
  onboot = true

  os_type    = "cloud-init"
  ciuser     = var.ciuser
  cipassword = var.cipassword
  ipconfig0  = var.ipconfig0
  sshkeys    = <<EOF
  ${var.ssh_key}
  EOF

}
