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
  cpu-request = "500m"
  memory-request = "2" 
  image = "ghcr.io/coder/envbuilder"
}

provider "coder" {
  feature_use_managed_variables = "true"
}

data "coder_provisioner" "me" {
}

variable "use_kubeconfig" {
  type        = bool
  #sensitive   = true
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
  #sensitive   = true
  description = <<-EOF
  Kubernetes namespace to deploy the workspace into

  EOF
  default = ""
}

variable "docker_config" {
  sensitive   = true
  description = <<-EOF
  envbuilder uses Kaniko to build containers. Enter your base64 Docker authentication configuration.

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

data "coder_parameter" "disk_size" {
  name        = "PVC (your $HOME directory) storage size"
  type        = "number"
  description = "Number of GB of storage"
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min       = 1
    max       = 100
    monotonic = "increasing"
  }
  mutable     = true
  default     = 25
}

data "coder_parameter" "cpu" {
  name        = "CPU cores"
  type        = "number"
  description = "Be sure the cluster nodes have the capacity"
  icon        = "https://png.pngtree.com/png-clipart/20191122/original/pngtree-processor-icon-png-image_5165793.jpg"
  validation {
    min       = 1
    max       = 4
  }
  mutable     = true
  default     = 2
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
  default     = 4
}

data "coder_parameter" "devcontainer-repo" {
  name         = "devcontainer-repo"
  display_name = "Repository"
  description  = "Select a repository to automatically clone and start working with a devcontainer and Dockerfile."
  mutable      = true
  option {
    name        = "sharkymark/envbuilder-starter-devcontainer"
    description = "An example repository for getting started with devcontainer.json and envbuilder."
    value       = "https://github.com/sharkymark/envbuilder-starter-devcontainer"
    icon        = "https://avatars.githubusercontent.com/u/95932066?s=200&v=4"
  }  
  option {
    name        = "vercel/next.js"
    description = "The React Framework"
    value       = "https://github.com/vercel/next.js"
    icon        = "https://www.datocms-assets.com/75941/1657707878-nextjs_logo.png"
  }
  option {
    name        = "denoland/deno"
    description = "A modern runtime for JavaScript and TypeScript."
    value       = "https://github.com/denoland/deno"
    icon        = "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Deno_2021.svg/2048px-Deno_2021.svg.png"
  }
  option {
    name        = "microsoft/vscode-remote-try-go"
    description = "Golang"
    value       = "https://github.com/microsoft/vscode-remote-try-go"
    icon        = "https://cdn.worldvectorlogo.com/logos/golang-gopher.svg"
  }
  option {
    name        = "microsoft/vscode-remote-try-node"
    description = "Node.js"
    value       = "https://github.com/microsoft/vscode-remote-try-node"
    icon        = "https://cdn.freebiesupply.com/logos/large/2x/nodejs-icon-logo-png-transparent.png"
  } 
  option {
    name        = "microsoft/vscode-remote-try-java"
    description = "Java"
    value       = "https://github.com/microsoft/vscode-remote-try-java"
    icon        = "https://assets.stickpng.com/images/58480979cef1014c0b5e4901.png"
  }
  option {
    name        = "microsoft/vscode-remote-try-rust"
    description = "Rust"
    value       = "https://github.com/microsoft/vscode-remote-try-rust"
    icon        = "https://rustacean.net/assets/cuddlyferris.svg"
  }  
  option {
    name        = "microsoft/vscode-remote-try-cpp"
    description = "C++"
    icon        = "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Visual_Studio_Icon_2022.svg/1200px-Visual_Studio_Icon_2022.svg.png"
    value       = "https://github.com/microsoft/vscode-remote-try-cpp"
  }
  option {
    name        = "microsoft/vscode-remote-try-php"
    description = "PHP"
    icon        = "https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/Webysther_20160423_-_Elephpant.svg/2560px-Webysther_20160423_-_Elephpant.svg.png"
    value       = "https://github.com/microsoft/vscode-remote-try-php"
  } 
  option {
    name        = "microsoft/vscode-remote-try-dotnet"
    description = "PHP"
    icon        = "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ee/.NET_Core_Logo.svg/768px-.NET_Core_Logo.svg.png"
    value       = "https://github.com/microsoft/vscode-remote-try-dotnet"
  }      
}

data "coder_git_auth" "github" {
  # Matches the ID of the git auth provider in Coder.
  id = "primary-github"
}

resource "coder_agent" "coder" {
  os                      = "linux"
  arch                    = data.coder_provisioner.me.arch
  dir                     = "/workspaces/${basename(data.coder_parameter.devcontainer-repo.value)}"
  env                     = {
    "DOTFILES_URI" = data.coder_parameter.dotfiles_url.value != "" ? data.coder_parameter.dotfiles_url.value : null
    }    
  startup_script = <<EOT
#!/bin/bash

# install code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 >/dev/null 2>&1 &

# use coder CLI to clone and install dotfiles
if [ -n "$DOTFILES_URI" ]; then
  echo "Installing dotfiles from $DOTFILES_URI"
  coder dotfiles -y "$DOTFILES_URI"
fi

  EOT  
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
  slug          = "code-server"  
  display_name  = "code-server"
  icon          = "/icon/code.svg"
  url           = "http://localhost:13337?folder=/workspaces/${basename(data.coder_parameter.devcontainer-repo.value)}"
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
    kubernetes_persistent_volume_claim.workspaces
  ]  
  metadata {
    name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
  spec {

    automount_service_account_token = false  
    container {
      name    = "coder-container"
      image   = local.image
      image_pull_policy = "Always"     
      security_context {
        run_as_user = "0"
      }   
      env {
        name  = "CODER_AGENT_URL"
        value = data.coder_workspace.me.access_url
      }         
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.coder.token
      }  
      env {
        name  = "INIT_SCRIPT"
        value = coder_agent.coder.init_script
      }
      env {
        name = "GIT_URL"
        value = data.coder_parameter.devcontainer-repo.value
      }  
      env {
        name = "GITHUB_TOKEN"
        value = data.coder_git_auth.github.access_token
      }        
      env {
        name = "DOCKER_CONFIG_BASE64"
        value = var.docker_config
      } 
      env {
        name = "CACHE_REPO"
        value = "docker.io/marktmilligan/kaniko-cache"
      }       
      resources {
        requests = {
          cpu    = local.cpu-request
          memory = local.memory-request
        }        
        limits = {
          cpu    = data.coder_parameter.cpu.value
          memory = "${data.coder_parameter.cpu.value}G"
        }
      }                       
      volume_mount {
        mount_path = "/workspaces"
        name       = "workspaces"
      }      
    }
    volume {
      name = "workspaces"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.workspaces.metadata.0.name
      }
    }        
  }
}

resource "kubernetes_persistent_volume_claim" "workspaces" {
  metadata {
    name      = "workspaces-coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.coder_parameter.disk_size.value}Gi"
      }
    }
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
  item {
    key   = "CPU"
    value = "${data.coder_parameter.cpu.value} cores"
  }
  item {
    key   = "memory"
    value = "${data.coder_parameter.memory.value}G"
  }  
  item {
    key   = "disk"
    value = "${data.coder_parameter.disk_size.value}GiB"
  }
  item {
    key   = "image"
    value = local.image
  }  
  item {
    key   = "devcontainer"
    value = data.coder_parameter.devcontainer-repo.value
  }  
}