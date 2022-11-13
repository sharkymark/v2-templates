terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
  }
}

variable "use_kubeconfig" {
  type        = bool
  sensitive   = true
  description = <<-EOF
  Use host kubeconfig? (true/false)

  Set this to false if the Coder host is itself running as a Pod on the same
  Kubernetes cluster as you are deploying workspaces to.

  Set this to true if the Coder host is running outside the Kubernetes cluster
  for workspaces.  A valid "~/.kube/config" must be present on the Coder host.
  EOF
}

variable "workspaces_namespace" {
  description = <<-EOF
  Kubernetes namespace to create the workspace pod (required)

  EOF
  default = ""
}

variable "dotfiles_uri" {
  description = <<-EOF
  Dotfiles repo URI (optional)

  see https://dotfiles.github.io
  EOF
  default = "git@github.com:sharkymark/dotfiles.git"
}

variable "cpu" {
  description = "CPU (__ cores)"
  default     = 1
  validation {
    condition = contains([
      "1",
      "2",
      "4",
      "6"
    ], var.cpu)
    error_message = "Invalid cpu!"   
}
}

variable "memory" {
  description = "Memory (__ GB)"
  default     = 2
  validation {
    condition = contains([
      "1",
      "2",
      "4",
      "8"
    ], var.memory)
    error_message = "Invalid memory!"  
}
}

variable "disk_size" {
  description = "Disk size (__ GB)"
  default     = 10
}

provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}

resource "coder_agent" "coder" {
  os   = "linux"
  arch = "amd64"
  dir = "/home/coder"
  startup_script = <<EOT
#!/bin/bash

export PATH=$PATH:$HOME/.local/bin

# add some Python libraries
pip3 install --user pandas numpy

# install code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 2>&1 &

# install and start airflow
pip3 install apache-airflow
/home/coder/.local/bin/airflow standalone

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${var.dotfiles_uri}

# clone repo
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git clone --progress git@github.com:sharkymark/airflow_wac.git

EOT
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
  slug          = "code-server"  
  display_name  = "VS Code"
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

# airflow
resource "coder_app" "airflow" {
  agent_id      = coder_agent.coder.id
  slug          = "airflow"  
  display_name  = "Airflow"
  icon          = "https://upload.wikimedia.org/wikipedia/commons/d/de/AirflowLogo.png"
  url           = "http://localhost:8080"
  subdomain = true
  share     = "owner"

  healthcheck {
    url       = "http://localhost:8080/healthz"
    interval  = 10
    threshold = 60
  } 
}

resource "kubernetes_pod" "main" {
  count = data.coder_workspace.me.start_count
  metadata {
    name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
    namespace = var.workspaces_namespace
  }
  spec {
    security_context {
      run_as_user = "1000"
      fs_group    = "1000"
    }     
    container {
      name    = "airflow"
      image   = "docker.io/codercom/enterprise-base:ubuntu"
      command = ["sh", "-c", coder_agent.coder.init_script]
      image_pull_policy = "Always"
      security_context {
        run_as_user = "1000"
      }
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.coder.token
      }
      resources {
        requests = {
          cpu    = "250m"
          memory = "250Mi"
        }        
        limits = {
          cpu    = "${var.cpu}"
          memory = "${var.memory}G"
        }
      }                       
      volume_mount {
        mount_path = "/home/coder"
        name       = "home-directory"
      }        
    }
    volume {
      name = "home-directory"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.home-directory.metadata.0.name
      }
    }         
  }
}

resource "kubernetes_persistent_volume_claim" "home-directory" {
  metadata {
    name      = "home-coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
    namespace = var.workspaces_namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${var.disk_size}Gi"
      }
    }
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
  item {
    key   = "CPU"
    value = "${kubernetes_pod.main[0].spec[0].container[0].resources[0].limits.cpu} cores"
  }
  item {
    key   = "memory"
    value = "${var.memory}GB"
  }  
  item {
    key   = "image"
    value = "codercom/enterprise-base:ubuntu"
  } 
  item {
    key   = "disk"
    value = "${var.disk_size}GiB"
  }
  item {
    key   = "volume"
    value = kubernetes_pod.main[0].spec[0].container[0].volume_mount[0].mount_path
  }  
}
