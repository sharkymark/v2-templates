terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.3"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.42.0"
    }
  }
}

variable "project_id" {
  description = "Which Google Compute Project should your workspace live in?"
}

variable "zone" {
  description = "What region should your workspace live in?"
  default     = "us-central1-a"
  validation {
    condition     = contains(["northamerica-northeast1-a", "us-central1-a", "us-west2-c", "europe-west4-b", "southamerica-east1-a"], var.zone)
    error_message = "Invalid zone!"
  }
}

variable "machine-type" {
  description = "What machine type should your workspace be?"
  default     = "e2-medium"
  validation {
    condition     = contains(["e2-standard-4","e2-standard-2","e2-medium","e2-micro", "e2-small"], var.machine-type)
    error_message = "Invalid machine type!"
  }
}

variable "os" {
  description = "What release of Microsoft Windows Server?"
  default     = "windows-server-2022-dc-v20221109"
  validation {
    condition     = contains(["windows-server-2022-dc-v20221109","windows-server-2019-dc-v20221109"], var.os)
    error_message = "Invalid Microsoft Windows release!"
  }
}

variable "vs" {
  description = "What release of Microsoft Visual Studio?"
  default     = "visualstudio2022community"
  validation {
    condition     = contains(["visualstudio2022community","visualstudio2019community"], var.vs)
    error_message = "Invalid Visual Studio release!"
  }
}

provider "google" {
  zone    = var.zone
  project = var.project_id
}

data "google_compute_default_service_account" "default" {
}

data "coder_workspace" "me" {
}

resource "google_compute_disk" "root" {
  name  = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}-root"
  type  = "pd-ssd"
  zone  = var.zone
  image = "projects/windows-cloud/global/images/${var.os}"    
  #image = "projects/windows-cloud/global/images/windows-server-2022-dc-v20221109"  
  #image = "projects/windows-cloud/global/images/windows-server-2019-dc-v20221014"
  lifecycle {
    ignore_changes = [image]
  }
}

resource "coder_agent" "main" {
  auth = "google-instance-identity"
  arch = "amd64"
  os   = "windows"
  startup_script = <<EOF

# Set admin password and enable admin user (must be in this order)
Get-LocalUser -Name "Administrator" | Set-LocalUser -Password (ConvertTo-SecureString -AsPlainText "${local.admin_password}" -Force)
Get-LocalUser -Name "Administrator" | Enable-LocalUser

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0

# Enable RDP through Windows Firewall
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

choco feature enable -n=allowGlobalConfirmation

# install microsoft visual studio community edition
choco install ${var.vs} --package-parameters "--add=Microsoft.VisualStudio.Workload.ManagedDesktop;includeRecommended --passive --locale en-US"

EOF
}

locals {
  # Password to log in via RDP
  #
  # Must meet Windows password complexity requirements:
  # https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements#reference
  admin_password = "coderRDP!"

}

resource "google_compute_instance" "dev" {
  zone         = var.zone
  count        = data.coder_workspace.me.start_count
  name         = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
  machine_type = "${var.machine-type}"
  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }
  boot_disk {
    auto_delete = false
    source      = google_compute_disk.root.name
  }
  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  metadata = {

    windows-startup-script-ps1 = <<EOF

    # Install Chocolatey package manager before
    # the agent starts to use via startup_script
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    # Reload path so sessions include "choco" and "refreshenv"
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    # Install Git and reload path
    choco install -y git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # start Coder agent init script (see startup_script above)
    ${coder_agent.main.init_script}

    EOF

  }

}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = google_compute_instance.dev[0].id
  item {
    key       = "Administrator password"
    value     = local.admin_password
    sensitive = true
  }  
  item {
    key   = "zone"
    value = "${var.zone}"
  }
  item {
    key   = "machine-type"
    value = "${var.machine-type}"
  }    
  item {
    key   = "windows os"
    value = "${var.os}"
  }  
  item {
    key   = "visual studio"
    value = "${var.vs}"
  }   
}

