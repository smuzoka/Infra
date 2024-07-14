# Deploying VMs on Proxmox using Terraform

This guide will walk you through the process of setting up Terraform to deploy virtual machines on Proxmox.

## Table of Contents

1. [Setting up Proxmox API key](#setting-up-proxmox-api-key)
2. [Installing Terraform on Windows](#installing-terraform-on-windows)
3. [Using Visual Studio Code with Terraform](#using-visual-studio-code-with-terraform)
4. [Setting up Terraform init project folder](#setting-up-terraform-init-project-folder)
5. [Generating SSH key on Windows](#generating-ssh-key-on-windows)
6. [Setting up VMs](#setting-up-vms)
7. [Using Terraform commands](#using-terraform-commands)
8. [Helpful Links](#helpful-links)

## Setting up Proxmox API key

1. Log in to your Proxmox web interface.
2. Navigate to Datacenter -> Permissions -> API Tokens.
3. Click "Add" to create a new API token.
4. Select a user, give the token a name, and decide whether to restrict the token's privileges.
5. Save the token ID and secret. You'll need these for Terraform. If these are misplaced you will have to create a new one.

## Installing Terraform on Windows

1. Download the Terraform ZIP file for Windows from the [official website](https://www.terraform.io/downloads.html).
2. Extract the ZIP file to a directory, e.g., `C:\terraform`.
3. Add the directory to your system's PATH:
   - Right-click on 'This PC' and go to Properties -> Advanced system settings -> Environment Variables.
   - Under System variables, find PATH, click Edit, then Add, and enter the path to your Terraform directory.
4. Open a new Command Prompt and test the installation:

   ```PowerShell
   terraform version
   ```

   This should display the installed Terraform version.

## Using Visual Studio Code with Terraform

Visual Studio Code (VS Code) is an excellent editor for working with Terraform configurations. To enhance your Terraform development experience in VS Code, install the following extensions:

1. HashiCorp Terraform (hashicorp.terraform)
   - Provides syntax highlighting, IntelliSense, and other language features for Terraform files.
   - Offers commands for Terraform operations directly from VS Code.

2. HashiCorp HCL (hashicorp.hcl)
   - Adds language support for HashiCorp Configuration Language (HCL).
   - Improves syntax highlighting and formatting for .tf and .tfvars files.

3. Checkov (bridgecrew.checkov)
   - Scans cloud infrastructure configurations to find misconfigurations.
   - Helps identify security and compliance issues in your Terraform code.

## Setting up Terraform init project folder

1. Create a new directory `Infra` for your Terraform project using VSCode.
2. Create a file named `providers.tf` in this directory.
3. Initialize the Terraform working directory:

   ```PowerShell
   terraform init
   ```

A `.terraform.lock.hcl` file is generated.

## Generating SSH key on Windows

1. Open PowerShell.
2. Generate a new SSH key pair:

   ```PowerShell
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   ```

3. Save the key in the default location or specify a custom path.
4. Set a passphrase (optional but recommended).

## Setting up VMs

Edit your `providers.tf` file to include the following sections:

### Provider

```hcl
terraform {

  required_version = ">= 0.13.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">= 2.9.14"
    }
  }
}

provider "proxmox" {

  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret

  # (Optional) Skip TLS Verification
  pm_tls_insecure = true

}

```

### Variables

Create a new file in your project folder `variables.tf` which will store all variables to be used in setup. The number of variables depend on the complexity of the implementation.

```hcl
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
```

### Secrets

It's recommended to use environment variables or a `secrets.auto.tfvars` file for sensitive information. Here's an example `secrets.auto.tfvars`:

```hcl
proxmox_api_url          = "https://[PROXMOX_IP_ADDRESS]:8006/api2/json" # Your Proxmox IP Address
proxmox_api_token_id     = "[YOUR_API_TOKEN_ID]"                         # API Token ID
proxmox_api_token_secret = "[YOUR_API_TOKEN_SECRET]"                     # API Token Secret
proxmox_node             = "[YOUR_PROXMOX_NODE_NAME]"                    # Name of your Proxmox node
vm_iso                   = "[STORAGE_NAME]:iso/[YOUR_ISO_FILE_NAME]"     # Path to your VM ISO file
ciuser                   = "[YOUR_CLOUD_INIT_USERNAME]"                  # Cloud-init username
cipassword               = "[YOUR_CLOUD_INIT_PASSWORD]"                  # Cloud-init password
ipconfig0                = "ip=dhcp"                                     # IP configuration (DHCP in this case)
ssh_key                  = "[YOUR_SSH_PUBLIC_KEY]"                       # Your SSH public key
```

### Fresh install

Then, create a new file in your project folder `fresh-VM.tf` this will run and setup a new VM from an iso file located in `var.vm_iso`. You would need to complete the setup manually.

```hcl
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

```

### Cloned install

This will set up a VM using cloud init based on an existing VM.

```hcl
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

```

### Outputs

Add this to your `outputs.tf` to output the IP address of your created VM:

```hcl
output "fresh_vm_ip" {
  value       = proxmox_vm_qemu.fresh_vm.default_ipv4_address
  description = "The IP address of the created VM"
}

output "clone_vm_ip" {
  value       = proxmox_vm_qemu.clone_vm.default_ipv4_address
  description = "The IP address of the created VM"
}
```

## Using Terraform commands

- To check your configuration and see planned changes:

  ```PowerShell
  terraform plan
  ```

- To apply your configuration and create resources:

  ```PowerShell
  terraform apply
  ```

- To destroy all resources created by your Terraform configuration:

  ```PowerShell
  terraform destroy
  ```

- Other useful commands:
  - `terraform show`: Display the current state
  - `terraform validate`: Check if your configuration is valid
  - `terraform fmt`: Format your configuration files

## Helpful Links

Here are some helpful resources:

- [Christian Lempa:Proxmox virtual machine *automation* in Terraform](https://www.youtube.com/watch?v=dvyeoDBUtsU)
- [Telmate Proxmox Provider Documentation](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
