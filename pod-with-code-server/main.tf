terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.4.9"
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
  default = "oss"
  validation {
    condition = contains([
      "oss",
      "coder-oss",
      "coder-workspaces"
    ], var.workspaces_namespace)
    error_message = "Invalid namespace!"   
}  
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
  default = ""
}

variable "image" {
  description = <<-EOF
  Container images from coder-com

  EOF
  default = "codercom/enterprise-node:ubuntu"
  validation {
    condition = contains([
      "codercom/enterprise-node:ubuntu",
      "codercom/enterprise-golang:ubuntu",
      "codercom/enterprise-java:ubuntu",
      "codercom/enterprise-base:ubuntu"
    ], var.image)
    error_message = "Invalid image!"   
}  
}

variable "repo" {
  description = <<-EOF
  Code repository to clone

  EOF
  default = "mark-theshark/coder-react.git"
  validation {
    condition = contains([
      "mark-theshark/coder-react.git",
      "coder/coder.git",
      "coder/code-server.git",      
      "mark-theshark/commissions.git",
      "mark-theshark/java_helloworld.git",
      "mark-theshark/python-commissions.git"
    ], var.repo)
    error_message = "Invalid repo!"   
}  
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

locals {
  code-server-releases = {
    "latest" = "" 
    "4.6.1 | Code 1.70.2" = "4.6.1" 
    "4.6.0 | Code 1.70.1" = "4.6.0"    
    "4.5.1 | Code 1.68.1" = "4.5.1"
    "4.5.0 | Code 1.68.1" = "4.5.0"
    "4.4.0 | Code 1.66.2" = "4.4.0"
    "4.3.0 | Code 1.65.2" = "4.3.0"
    "4.2.0 | Code 1.64.2" = "4.2.0"
  }
}

variable "code-server" {
  description = "code-server release"
  default     = "latest"
  validation {
    condition = contains([
      "latest",
      "4.6.1 | Code 1.70.2",      
      "4.6.0 | Code 1.70.1",
      "4.5.1 | Code 1.68.1",      
      "4.5.0 | Code 1.68.1",
      "4.4.0 | Code 1.66.2",
      "4.3.0 | Code 1.65.2",
      "4.2.0 | Code 1.64.2"
    ], var.code-server)
    error_message = "Invalid code-server!"   
}
}

variable "disk_size" {
  description = "Disk size (__ GB)"
  default     = 10
}

resource "coder_agent" "coder" {
  os   = "linux"
  arch = "amd64"
  dir = "/home/coder"
  startup_script = <<EOT
#!/bin/bash

# install code-server
echo "CS_REL value: " ${var.code-server}

if [[ "${var.code-server}" != "latest" ]]; then
  CS_REL=" -s -- --version=${lookup(local.code-server-releases, var.code-server)}"
fi

curl -fsSL https://code-server.dev/install.sh | sh $CS_REL
code-server --auth none --port 13337 &

# clone repo
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git clone --progress git@github.com:${var.repo}

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${var.dotfiles_uri}

  EOT  
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
  name          = "code-server ${var.code-server}"
  icon          = "/icon/code.svg"
  url           = "http://localhost:13337?folder=/home/coder"
  relative_path = true  
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
      image   = "docker.io/${var.image}"
      image_pull_policy = "Always"
      command = ["sh", "-c", coder_agent.coder.init_script]
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
    value = "docker.io/${var.image}"
  }
  item {
    key   = "repo cloned"
    value = "docker.io/${var.repo}"
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