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
  Kubernetes namespace to deploy the workspace into

  EOF
  default = ""
}

provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}

variable "dotfiles_uri" {
  description = <<-EOF
  Dotfiles repo URI (optional)

  see https://dotfiles.github.io
  EOF
  default = "git@github.com:sharkymark/dotfiles.git"
}

variable "cpu" {
  description = "CPU (__ cores)"
  default     = 2
  validation {
    condition = contains([
      "2",
      "4",
      "6"
    ], var.cpu)
    error_message = "Invalid cpu!"   
}
}

variable "memory" {
  description = "Memory (__ GB)"
  default     = 4
  validation {
    condition = contains([
      "4",
      "6",
      "8"
    ], var.memory)
    error_message = "Invalid memory!"  
}
}

locals {
  repo = {
    "Java" = "sharkymark/java_helloworld.git" 
    "Python" = "sharkymark/python-commissions.git" 
    "Go" = "coder/coder.git"
  }  
  image = {
    "Java" = "codercom/enterprise-java:ubuntu" 
    "Python" = "codercom/enterprise-base:ubuntu" 
    "Go" = "codercom/enterprise-golang:ubuntu"
  }  
}

variable "lang" {
  description = "Programming language"
  default     = "Go"
  validation {
    condition = contains([
      "Go",
      "Python",      
      "Java"
    ], var.lang)
    error_message = "Invalid language!"   
}
}

variable "disk_size" {
  description = "Disk size (__ GB)"
  default     = 10
}

resource "coder_agent" "dev" {
  os   = "linux"
  arch = "amd64"
  dir = "/home/coder"
  startup_script = <<EOT
#!/bin/bash

# clone repo
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git clone --progress git@github.com:${lookup(local.repo, var.lang)}

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${var.dotfiles_uri}

# install and start code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 &

  EOT  
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.dev.id
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

resource "kubernetes_pod" "main" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim.home-directory
  ]  
  metadata {
    name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
  spec {
    security_context {
      run_as_user = "1000"
      fs_group    = "1000"
    }    
    container {
      name    = "coder-container"
      image   = "docker.io/${lookup(local.image, var.lang)}"
      image_pull_policy = "Always"
      command = ["sh", "-c", coder_agent.dev.init_script]
      security_context {
        run_as_user = "1000"
      }      
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.dev.token
      }  
      resources {
        requests = {
          cpu    = "500m"
          memory = "500Mi"
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
    name      = "home-coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
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
    value = "${var.cpu} cores"
  }
  item {
    key   = "memory"
    value = "${var.memory}GB"
  }  
  item {
    key   = "image"
    value = "docker.io/${lookup(local.image, var.lang)}"
  }
  item {
    key   = "repo cloned"
    value = "docker.io/${lookup(local.repo, var.lang)}"
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