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
  feature_use_managed_variables = true
}

variable "project_id" {
  description = "Which Google Compute Project should your workspace live in?"
}

data "coder_parameter" "zone" {
  name    = "What region should your workspace live in?"
  type    = "string"
  default = "us-central1-a"
  icon    = "/emojis/1f30e.png"
  mutable = false
  option {
    name  = "North America (Northeast)"
    value = "northamerica-northeast1-a"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "North America (Central)"
    value = "us-central1-a"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "North America (West)"
    value = "us-west2-c"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "Europe (West)"
    value = "europe-west4-b"
    icon  = "/emojis/1f1ea-1f1fa.png"
  }
  option {
    name  = "South America (East)"
    value = "southamerica-east1-a"
    icon  = "/emojis/1f1e7-1f1f7.png"
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

resource "coder_agent" "main" {
  auth = "google-instance-identity"
  arch = "amd64"

  metadata {
    display_name = "CPU Usage"
    key  = "cpu"
    # calculates CPU usage by summing the "us", "sy" and "id" columns of
    # vmstat.
    script = <<EOT
        top -bn1 | awk 'FNR==3 {printf "%2.0f%%", $2+$3+$4}'
        #vmstat | awk 'FNR==3 {printf "%2.0f%%", $13+$14+$16}'
    EOT
    interval = 1
    timeout = 1
  }

  metadata {
    display_name = "Disk Usage"
    key  = "disk"
    script = "df -h | awk '$6 ~ /^\\/$/ { print $5 }'"
    interval = 1
    timeout = 1
  }

  metadata {
    display_name = "Memory Used"
    key  = "mem3"
    script = <<EOT
    free | awk '/^Mem/ { printf("%.0f%%", $3/$2 * 100.0) }'
    EOT
    interval = 1
    timeout = 1
  }   
  
  metadata {
    display_name = "Node Load Average"
    key  = "load"
    script = <<EOT
        awk '{print $1,$2,$3,$4}' /proc/loadavg
    EOT
    interval = 1
    timeout = 1
  }


  os   = "linux"

  login_before_ready     = false
  startup_script_timeout = 180
  startup_script         = <<-EOT
    set -e

    # install and start code-server
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server
    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &
  EOT
}

# code-server
resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  icon         = "/icon/code.svg"
  url          = "http://localhost:13337?folder=/home/coder"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }
}

module "gce-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "3.0.0"

  container = {
    image   = "codercom/enterprise-base:ubuntu"
    command = ["sh"]
    args    = ["-c", coder_agent.main.init_script]
    securityContext = {
      privileged : true
    }
    resources = {
      limits = {
        cpu    = "1"
        memory = "1G"
      }
    }
  }
}

resource "google_compute_instance" "dev" {
  zone         = data.coder_parameter.zone.value
  count        = data.coder_workspace.me.start_count
  name         = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
  machine_type = "e2-medium"
  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }
  boot_disk {
    initialize_params {
      image = module.gce-container.source_image
    }
  }
  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }
  metadata = {
    "gce-container-declaration" = module.gce-container.metadata_value
  }
  labels = {
    container-vm = module.gce-container.vm_container_label
  }
}

resource "coder_agent_instance" "dev" {
  count       = data.coder_workspace.me.start_count
  agent_id    = coder_agent.main.id
  instance_id = google_compute_instance.dev[0].instance_id
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = google_compute_instance.dev[0].id

  item {
    key   = "image"
    value = module.gce-container.container.image
  }
}
