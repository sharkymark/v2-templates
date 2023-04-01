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

locals {
  cpu-limit = "4"
  memory-limit = "8G"
  cpu-request = "500m"
  memory-request = "1" 
  home-volume = "10Gi"
  #repo = "iluwatar/java-design-patterns.git"
  repo = "sharkymark/java_helloworld.git"  
  repo-owner = "docker.io/marktmilligan"
  #image = "intellij-idea-ultimate:2022.3.2"
  #image = "intellij-idea-ultimate:2022.1.4"
  image = "intellij-idea-ultimate:2023.1"    
}

provider "coder" {
  feature_use_managed_variables = "true"
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
  default = false
}

variable "workspaces_namespace" {
  sensitive   = true
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

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL"
  description = "Personalize your workspace"
  type        = "string"
  default     = "git@github.com:sharkymark/dotfiles.git"
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
}

data "coder_provisioner" "me" {
}

resource "coder_agent" "coder" {
  os                      = "linux"
  arch                    = data.coder_provisioner.me.arch
  dir                     = "/home/coder"
  env                     = { "DOTFILES_URI" = data.coder_parameter.dotfiles_url.value != "" ? data.coder_parameter.dotfiles_url.value : null }    
  startup_script = <<EOT
#!/bin/bash

# use coder CLI to clone and install dotfiles
if [ -n "$DOTFILES_URI" ]; then
  echo "Installing dotfiles from $DOTFILES_URI"
  coder dotfiles -y "$DOTFILES_URI"
fi

# clone java repo
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git clone git@github.com:${local.repo}

# script to symlink JetBrains Gateway IDE directory to image-installed IDE directory
# More info: https://www.jetbrains.com/help/idea/remote-development-troubleshooting.html#setup
cd /opt/idea/bin
./remote-dev-server.sh registerBackendLocationForGateway

  EOT  
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
      image   = "${local.repo-owner}/${local.image}"
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
          cpu    = local.cpu-request
          memory = local.memory-request
        }        
        limits = {
          cpu    = local.cpu-limit
          memory = local.memory-limit
        }
      }                       
      volume_mount {
        mount_path = "/home/coder"
        name       = "home-directory"
        read_only  = false
      }      
    }
    volume {
      name = "home-directory"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.home-directory.metadata.0.name
        read_only  = false
      }
    }        
  }
}



resource "kubernetes_persistent_volume_claim" "home-directory" {
  metadata {
    name      = "home-coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = local.home-volume
      }
    }
  }
}

resource "coder_metadata" "home-directory" {
    resource_id = kubernetes_persistent_volume_claim.home-directory.id
    daily_cost  = 10
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
  daily_cost  = 20
  item {
    key   = "CPU"
    value = "${local.cpu-limit} cores"
  }
  item {
    key   = "memory"
    value = "${local.memory-limit} GiB"
  }  
  item {
    key   = "disk"
    value = "${local.home-volume}"
  }
  item {
    key   = "image"
    value = local.image
  }    
}

