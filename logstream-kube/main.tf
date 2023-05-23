terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
  }
}

provider "coder" {
  feature_use_managed_variables = "true"
}

data "coder_workspace" "me" {}

variable "ca" {
  sensitive   = true
  description = <<-EOF
  Kubernetes cluster namespace's CA certificate

  EOF
  default = ""
}

variable "token" {
  sensitive   = true
  description = <<-EOF
  Kubernetes cluster namespace's service account token

  EOF
  default = ""
}

variable "host" {
  sensitive   = true
  description = <<-EOF
  Kubernetes cluster host

  EOF
  default = ""
}

variable "workspaces_namespace" {
  description = <<-EOF
  Kubernetes namespace to deploy the workspace into

  EOF
  default = ""
}

provider "kubernetes" {
  host                   = var.host
  cluster_ca_certificate = base64decode(var.ca)
  token                  = base64decode(var.token)
}

data "coder_parameter" "disk_size" {
  name        = "PVC storage size"
  type        = "number"
  description = "Number of GB of storage"
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min       = 1
    max       = 20
    monotonic = "increasing"
  }
  mutable     = true
  default     = 10
}

data "coder_parameter" "cpu" {
  name        = "CPU cores"
  type        = "number"
  description = "CPU cores - be sure the cluster nodes have the capacity"
  icon        = "https://png.pngtree.com/png-clipart/20191122/original/pngtree-processor-icon-png-image_5165793.jpg"
  validation {
    min       = 1
    max       = 4
  }
  mutable     = true
  default     = 1
}

data "coder_parameter" "memory" {
  name        = "Memory (__ GB)"
  type        = "number"
  description = "Be sure the cluster nodes have the capacity"
  icon        = "https://www.vhv.rs/dpng/d/33-338595_random-access-memory-logo-hd-png-download.png"
  validation {
    min       = 1
    max       = 8
  }
  mutable     = true
  default     = 2
}

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL"
  description = "Personalize your workspace"
  type        = "string"
  default     = "git@github.com:sharkymark/dotfiles.git"
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"

  metadata {
    key          = "disk"
    display_name = "Home Volume Disk Usage"
    interval     = 600 # every 10 minutes
    timeout      = 30  # df can take a while on large filesystems
    script       = <<-EOT
      #!/bin/bash
      set -e
      df /home/coder | awk NR==2'{print $5}'
    EOT
  }

  metadata {
    display_name = "@CoderHQ Weather"
    key  = "weather"
    # for more info: https://github.com/chubin/wttr.in
    script = <<EOT
        curl -s 'wttr.in/{Austin}?format=3&u' 2>&1 | awk '{print}'
    EOT
    interval = 600
    timeout = 10
  }

  dir = "/home/coder"
  login_before_ready = false
  startup_script_timeout = 300  
  startup_script = <<EOT
#!/bin/sh

# install code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 >/dev/null 2>&1 &

# use coder CLI to clone and install dotfiles
if [[ ! -z "${data.coder_parameter.dotfiles_url.value}" ]]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
fi

  EOT  
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.main.id
  slug          = "code-server"  
  display_name  = "code-server"
  icon          = "/icon/code.svg"
  url           = "http://localhost:13337?folder=/home/coder"
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }  
}

resource "kubernetes_deployment" "main" {
  wait_for_rollout = false
  metadata {
    name = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
    namespace = var.workspaces_namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "hello-world"
      }
    }

    template {
      metadata {
        labels = {
          app = "hello-world"
          "banana.coder.example" = "true"
        }
      }

      spec {
        container {
          image = "codercom/enterprise-base:ubuntu"
          name  = "hello-world"
          command           = ["sh", "-c", coder_agent.main.init_script]

          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.main.token
          }
          resources {
            requests = {
              cpu    = "250m"
              memory = "500Mi"
            }        
            limits = {
              cpu    = data.coder_parameter.cpu.value
              memory = "${data.coder_parameter.memory.value}G"
            }
          }           
        }
        
      }
    }
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_deployment.main.id
  item {
    key   = "CPU"
    value = "${data.coder_parameter.cpu.value} cores"
  }
  item {
    key   = "memory"
    value = "${data.coder_parameter.memory.value}GB"
  }  
  item {
    key   = "CPU requests"
    value = "${kubernetes_deployment.main.spec[0].template[0].spec[0].container[0].resources[0].requests.cpu}"
  }
  item {
    key   = "memory requests"
    value = "${kubernetes_deployment.main.spec[0].template[0].spec[0].container[0].resources[0].requests.memory}"
  }   
  item {
    key   = "disk"
    value = "${data.coder_parameter.disk_size.value}GiB"
  } 
}
