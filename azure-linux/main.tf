terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.28.0"
    }
  }
}

variable "location" {
  description = "What location should your workspace live in?"
  default     = "eastus"
  validation {
    condition = contains([
      "eastus",
      "centralus",
      "southcentralus",
      "westus2",
      "australiaeast",
      "southeastasia",
      "northeurope",
      "westeurope",
      "centralindia",
      "eastasia",
      "japaneast",
      "brazilsouth",
      "asia",
      "asiapacific",
      "australia",
      "brazil",
      "india",
      "japan",
      "southafrica",
      "switzerland",
      "uae",
    ], var.location)
    error_message = "Invalid location!"
  }
}

variable "instance_type" {
  description = "What instance type should your workspace use?"
  default     = "Standard_B4ms"
  validation {
    condition = contains([
      "Standard_B1ms",
      "Standard_B2ms",
      "Standard_B4ms",
      "Standard_B8ms",
      "Standard_B12ms",
      "Standard_B16ms",
      "Standard_D2as_v5",
      "Standard_D4as_v5",
      "Standard_D8as_v5",
      "Standard_D16as_v5",
      "Standard_D32as_v5",
    ], var.instance_type)
    error_message = "Invalid instance type!"
  }
}

variable "home_size" {
  type        = number
  description = "How large would you like your home volume to be (in GB)?"
  default     = 20
  validation {
    condition     = var.home_size >= 1
    error_message = "Value must be greater than or equal to 1."
  }
}

provider "azurerm" {
  features {}
}

variable "dotfiles_uri" {
  description = <<-EOF
  Dotfiles repo URI (optional)

  see https://dotfiles.github.io
  EOF
  default = "git@github.com:sharkymark/dotfiles.git"
}


data "coder_workspace" "me" {
}

resource "coder_agent" "main" {
  arch = "amd64"
  os   = "linux"
  auth = "azure-instance-identity"

  startup_script = <<EOT
  #!/bin/bash

  # install code-server
  curl -fsSL https://code-server.dev/install.sh | sh
  code-server --auth none --port 13337 &

  # use coder CLI to clone and install dotfiles
  coder dotfiles -y ${var.dotfiles_uri}

    EOT 

}

resource "coder_app" "code-server" {
  agent_id = coder_agent.main.id
  slug          = "code-server"  
  display_name  = "VS Code"
  url      = "http://localhost:13337/?folder=/home/${lower(substr(data.coder_workspace.me.owner, 0, 32))}"
  icon     = "/icon/code.svg"
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 6
    threshold = 20
  } 
}


locals {
  prefix = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"

  userdata = templatefile("cloud-config.yaml.tftpl", {
    username          = lower(substr(data.coder_workspace.me.owner, 0, 32))
#    username          = "ubuntu"   
    init_script       = base64encode(coder_agent.main.init_script)
    hostname          = lower(data.coder_workspace.me.name)
  })
}

resource "azurerm_resource_group" "main" {
  name     = "${local.prefix}-resources"
  location = var.location

  tags = {
    Coder_Provisioned = "true"
  }
}

// Uncomment here and in the azurerm_network_interface resource to obtain a public IP
resource "azurerm_public_ip" "main" {
  name                = "publicip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = {
    Coder_Provisioned = "true"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "network"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Coder_Provisioned = "true"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/29"]
}

resource "azurerm_network_interface" "main" {
  name                = "nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    // Uncomment for public IP address as well as azurerm_public_ip resource above
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = {
    Coder_Provisioned = "true"
  }
}

resource "azurerm_managed_disk" "home" {
  create_option        = "Empty"
  location             = azurerm_resource_group.main.location
  name                 = "home"
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "StandardSSD_LRS"
  disk_size_gb         = var.home_size
}

// azurerm requires an SSH key (or password) for an admin user or it won't start a VM.  However,
// cloud-init overwrites this anyway, so we'll just use a dummy SSH key.
resource "tls_private_key" "dummy" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "main" {
  count               = data.coder_workspace.me.transition == "start" ? 1 : 0
  name                = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.instance_type
  // cloud-init overwrites this, so the value here doesn't matter
  admin_username = "adminuser"
  admin_ssh_key {
    public_key = tls_private_key.dummy.public_key_openssh
    username   = "adminuser"
  }

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]
  computer_name = lower(data.coder_workspace.me.name)
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  user_data = base64encode(local.userdata)

  tags = {
    Coder_Provisioned = "true"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "home" {
  count              = data.coder_workspace.me.transition == "start" ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.home.id
  virtual_machine_id = azurerm_linux_virtual_machine.main[0].id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = azurerm_linux_virtual_machine.main[0].id
  icon = "/icon/memory.svg"
  item {
    key   = "instance type"
    value = azurerm_linux_virtual_machine.main[0].size
  }
  item {
    key   = "location"
    value = var.location
  }  
  item {
    key   = "image"
    value = azurerm_linux_virtual_machine.main[0].source_image_reference[0].offer
  }  
  item {
    key   = "ip address"
    value = azurerm_public_ip.main.ip_address
  }    
}

resource "coder_metadata" "home_info" {
  resource_id = azurerm_managed_disk.home.id
  icon = "/icon/database.svg"
  item {
    key   = "size"
    value = "${var.home_size} GiB"
  }

}


resource "coder_metadata" "hide_azurerm_resource_group" {
  count = data.coder_workspace.me.start_count
  resource_id = azurerm_resource_group.main.id
  hide = true
  item {
    key = "name"
    value = azurerm_resource_group.main.name
  }  
}


resource "coder_metadata" "hide_azurerm_public_ip" {
  count = data.coder_workspace.me.start_count
  resource_id = azurerm_public_ip.main.id
  hide = true
  item {
    key = "name"
    value = azurerm_public_ip.main.name
  }  
}

resource "coder_metadata" "hide_azurerm_virtual_network" {
  count = data.coder_workspace.me.start_count
  resource_id = azurerm_virtual_network.main.id
  hide = true
  item {
    key = "name"
    value = azurerm_virtual_network.main.name
  }  
}

resource "coder_metadata" "hide_azurerm_subnet" {
  count = data.coder_workspace.me.start_count
  resource_id = azurerm_subnet.internal.id
  hide = true
  item {
    key = "name"
    value = azurerm_subnet.internal.name
  }  
}

resource "coder_metadata" "hide_azurerm_network_interface" {
  count = data.coder_workspace.me.start_count
  resource_id = azurerm_network_interface.main.id
  hide = true
  item {
    key = "name"
    value = azurerm_network_interface.main.name
  }  
}

resource "coder_metadata" "hide_tls_private_key" {
  count = data.coder_workspace.me.start_count
  resource_id = tls_private_key.dummy.id
  hide = true
  item {
    key = "name"
    value = tls_private_key.dummy.algorithm
  }  
}

resource "coder_metadata" "hide_azurerm_virtual_machine_data_disk_attachment" {
  count = data.coder_workspace.me.start_count
  resource_id = azurerm_virtual_machine_data_disk_attachment.home[0].id
  hide = true
  item {
    key = "name"
    value = azurerm_virtual_machine_data_disk_attachment.home[0].managed_disk_id
  }  
}