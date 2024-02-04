terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
    google = {
      source  = "hashicorp/google"
    }
  }
}

provider "coder" {

}

variable "project_id" {
  description = "Which Google Compute Project should your workspace live in?"
  default     = ""
}

data "coder_parameter" "zone" {
  display_name  = "GCP Zone"
  name          = "zone"
  type          = "string"
  description   = "What GCP zone should your workspace live in?"
  mutable       = false
  default       = "us-central1-a"
  icon          = "/emojis/1f30e.png"
  order         = 1

  option {
    name = "northamerica-northeast1-a"
    value = "northamerica-northeast1-a"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name = "us-central1-a"
    value = "us-central1-a"
    icon  = "/emojis/1f1fa-1f1f8.png"
  } 
  option {
    name = "us-west2-c"
    value = "us-west2-c"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name = "europe-west4-b"
    value = "europe-west4-b"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name = "southamerica-east1-a"
    value = "southamerica-east1-a"
    icon  = "/emojis/1f1e7-1f1f7.png"
  }       

}

data "coder_parameter" "machine-type" {
  display_name  = "GCP machine type"
  name          = "machine-type"  
  type          = "string"
  description   = "GCP machine type"
  mutable       = false
  default       = "e2-standard-4"
  order         = 2 
  option {
    name = "e2-standard-8"
    value = "e2-standard-8"
  }
  option {
    name = "e2-standard-4"
    value = "e2-standard-4"
  }
  option {
    name = "e2-standard-2"
    value = "e2-standard-2"
  } 
  option {
    name = "e2-medium"
    value = "e2-medium"
  }
  option {
    name = "e2-micro"
    value = "e2-micro"
  }
  option {
    name = "e2-small"
    value = "e2-small"
  }       
}

data "coder_parameter" "os" {
  name                = "os"
  display_name        = "Windows OS"
  type                = "string"
  description         = "What release of Microsoft Windows Server?"
  mutable             = false
  default             = "windows-server-2022-dc-v20221109"
  order               = 3
  option {
    name = "2022"
    value = "windows-server-2022-dc-v20221109"
  }
  option {
    name = "2019"
    value = "windows-server-2019-dc-v20221109"
  }
}

data "coder_parameter" "vs" {
  name                = "vs"  
  display_name        = "Visual Studio"
  type                = "string"
  description         = "What release of Microsoft Visual Studio Community?"
  mutable             = false
  default             = "visualstudio2022community"
  order               = 4
  option {
    name = "2022"
    value = "visualstudio2022community"
  }
  option {
    name = "2019"
    value = "visualstudio2019community"
  }
}

provider "google" {
  zone    = data.coder_parameter.zone.value
  project = var.project_id
}

data "google_compute_default_service_account" "default" {

}

data "coder_workspace" "me" {
}

resource "google_compute_disk" "root" {
  name  = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}-root"
  type  = "pd-ssd"
  zone  = data.coder_parameter.zone.value
  image = "projects/windows-cloud/global/images/${data.coder_parameter.os.value}"    
  #image = "projects/windows-cloud/global/images/windows-server-2022-dc-v20221109"  
  #image = "projects/windows-cloud/global/images/windows-server-2019-dc-v20221014"
  lifecycle {
    ignore_changes = [name,image]
  }
}

resource "coder_agent" "main" {
  auth                   = "google-instance-identity"
  arch                   = "amd64"
  os                     = "windows"

  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.
  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "sshd stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "sshd stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Disk"
    key          = "3_disk"
    script       = "sshd stat disk"
    interval     = 60
    timeout      = 1
  }


  display_apps {
    vscode                  = true
    vscode_insiders         = false
    web_terminal            = true
    ssh_helper              = false
    port_forwarding_helper  = false
  }
 
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
choco install ${data.coder_parameter.vs.value} --package-parameters "--add=Microsoft.VisualStudio.Workload.ManagedDesktop;includeRecommended --passive --locale en-US"

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
  zone         = data.coder_parameter.zone.value
  count        = data.coder_workspace.me.start_count
  name         = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
  machine_type = "${data.coder_parameter.machine-type.value}"
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
    value = "${data.coder_parameter.zone.value}"
  }
  item {
    key   = "machine-type"
    value = "${data.coder_parameter.machine-type.value}"
  }    
  item {
    key   = "windows os"
    value = "${data.coder_parameter.os.value}"
  }  
  item {
    key   = "visual studio"
    value = "${data.coder_parameter.vs.value}"
  }   
}

