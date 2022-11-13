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

variable "disk_size" {
  description = "Disk size (__ GB)"
  default     = 10
}

variable "dotfiles_uri" {
  description = <<-EOF
  Dotfiles repo URI (optional)

  see https://dotfiles.github.io
  EOF
  default = "git@github.com:sharkymark/dotfiles.git"
}

variable "extension" {
  description = "Rust VS Code extension"
  default     = "matklad.rust-analyzer"
  validation {
    condition = contains([
      "rust-lang.rust",
      "matklad.rust-analyzer"
    ], var.extension)
    error_message = "Invalid Rust VS Code extension!"  
}
}

variable "folder_path" {
  description = <<-EOF
 Folder to add to VS Code (optional)
e.g.,
/home/coder
/home/coder/rust-hw
/home/coder/rust-hw/rocket/hello-rocket
  EOF
  default = "/home/coder/"
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

# install rustup and dependencies

/coder/configure

# use coder CLI to clone and install dotfiles

coder dotfiles -y ${var.dotfiles_uri}

# Configure and run JetBrains IDEs

# Assumes you have CLion (/opt/clion)
# and pip3 installed in
# your image and the "coder" user has filesystem
# permissions for "/opt/*"

pip3 install projector-installer --user
/home/coder/.local/bin/projector --accept-license 

/home/coder/.local/bin/projector config add clion /opt/clion --force --use-separate-config --port 9001 --hostname localhost
/home/coder/.local/bin/projector run clion &

# install and start code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 &

# clone repo
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
git clone --progress git@github.com:mark-theshark/rust-hw.git

# install Rust and rust-analyzer VS Code extensions into code-server
SERVICE_URL=https://open-vsx.org/vscode/gallery ITEM_URL=https://open-vsx.org/vscode/item code-server --install-extension ${var.extension}

EOT
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
  slug          = "code-server"  
  display_name  = "VS Code"
  icon          = "/icon/code.svg"
  url           = "http://localhost:13337?folder=${var.folder_path}"
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 5
    threshold = 15
  }   
}

resource "coder_app" "jetbrains-clion" {
  agent_id      = coder_agent.coder.id
  slug          = "clion"  
  display_name  = "CLion"
  icon          = "/icon/clion.svg"
  url           = "http://localhost:9001/"
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:9001/healthz"
    interval  = 10
    threshold = 30
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
    # https://github.com/sharkymark/dockerfiles/tree/main/clion/latest
    container {
      name    = "clion"
      image   = "docker.io/marktmilligan/clion-rust:latest"
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
          cpu    = "500m"
          memory = "500Mi"
        }        
        limits = {
          cpu    = "4"
          memory = "4G"
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
