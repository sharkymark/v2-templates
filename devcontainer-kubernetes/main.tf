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
  memory-request = "4" 
  image = "ghcr.io/coder/envbuilder:latest"
}

data "coder_provisioner" "me" {
}

provider "coder" {
}

variable "use_kubeconfig" {
  type        = bool
  description = <<-EOF
  Use host kubeconfig? (true/false)

  Set this to false if the Coder host is itself running as a Pod on the same
  Kubernetes cluster as you are deploying workspaces to.

  Set this to true if the Coder host is running outside the Kubernetes cluster
  for workspaces.  A valid "~/.kube/config" must be present on the Coder host.
  EOF
  default     = false
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace to create workspaces in (must exist prior to creating workspaces)"
  default = ""  
}

variable "docker_config" {
  sensitive   = true
  description = <<-EOF
  envbuilder uses Kaniko to build containers. Enter your base64 Docker authentication configuration.

  EOF
  default = ""
}

variable "cache_repo" {
  sensitive   = true
  description = <<-EOF
  Enter your repository to cache image layers.

  EOF
  default = ""
}

data "coder_parameter" "cpu" {
  name        = "CPU cores"
  type        = "number"
  description = "CPU cores for your workspace"
  order        = 1
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
  description = "Memory (__ GB) for your workspace"
  order        = 2
  icon        = "https://www.vhv.rs/dpng/d/33-338595_random-access-memory-logo-hd-png-download.png"
  validation {
    min       = 1
    max       = 8
  }
  mutable     = true
  default     = 4
}

data "coder_parameter" "disk_size" {
  name        = "PVC (your $HOME directory) storage size"
  type        = "number"
  description = "Number of GB of storage"
  order        = 3
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min       = 1
    max       = 200
    monotonic = "increasing"
  }
  mutable     = true
  default     = 100
}

data "coder_parameter" "repo" {
  name         = "repo"
  display_name = "Repository (auto)"
  order        = 4
  description  = "Select a repository to automatically clone and start working with a devcontainer."
  mutable      = true
  option {
    name        = "sharkymark/envbuilder-starter-devcontainer"
    description = "An example repository for getting started with devcontainer.json and envbuilder."
    value       = "https://github.com/sharkymark/envbuilder-starter-devcontainer"
    icon        = "https://avatars.githubusercontent.com/u/95932066?s=200&v=4"
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
    name        = "Custom"
    icon        = "/emojis/1f5c3.png"
    description = "Specify a custom repo URL below"
    value       = "custom"
  }
}

data "coder_parameter" "custom_repo_url" {
  name         = "custom_repo"
  display_name = "Repository URL (custom)"
  order        = 5
  default      = ""
  description  = "Optionally enter a custom repository URL, see [awesome-devcontainers](https://github.com/manekinekko/awesome-devcontainers)."
  mutable      = true
}

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL (optional)"
  description = "Personalize your workspace e.g., https://github.com/sharkymark/dotfiles.git"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  order       = 6
}

provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}


data "coder_workspace" "me" {}

data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  arch                   = data.coder_provisioner.me.arch
  os                     = "linux"

  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.
  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  startup_script_behavior = "non-blocking"

  startup_script         = <<-EOT
  
  set -e

  # install and start the latest code-server
  curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server
  /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

  # use coder CLI to clone and install dotfiles
  if [ -n "$DOTFILES_URI" ]; then
    echo "Installing dotfiles from $DOTFILES_URI"
    coder dotfiles -y "$DOTFILES_URI"
  fi

  EOT
  
  dir                    = "/workspaces"

  # These environment variables allow you to make Git commits right away after creating a
  # workspace. Note that they take precedence over configuration defined in ~/.gitconfig!
  # You can remove this block if you'd prefer to configure Git manually or using
  # dotfiles. (see docs/dotfiles.md)
  env = {
    "DOTFILES_URI" = data.coder_parameter.dotfiles_url.value != "" ? data.coder_parameter.dotfiles_url.value : null
    GIT_AUTHOR_NAME     = "${data.coder_workspace_owner.me.name}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace_owner.me.name}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace_owner.me.email}"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace_owner.me.email}"
  }

}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  url          = "http://localhost:13337/?folder=/workspaces"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 5
    threshold = 6
  }
}

resource "kubernetes_persistent_volume_claim" "workspaces" {
  metadata {
    name      = "coder-${data.coder_workspace.me.id}"
    namespace = var.namespace
    labels = {
      "coder.owner"                      = data.coder_workspace_owner.me.name
      "coder.owner_id"                   = data.coder_workspace_owner.me.id
      "coder.workspace_id"               = data.coder_workspace.me.id
      "coder.workspace_name_at_creation" = data.coder_workspace.me.name
    }
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi" // adjust as needed
      }
    }
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "kubernetes_deployment" "workspace" {
  count = data.coder_workspace.me.start_count  
  metadata {
    name      = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
    namespace = var.namespace
    labels = {
      "coder.owner"          = data.coder_workspace_owner.me.name
      "coder.owner_id"       = data.coder_workspace_owner.me.id
      "coder.workspace_id"   = data.coder_workspace.me.id
      "coder.workspace_name" = data.coder_workspace.me.name
    }
  }
  spec {
    replicas = data.coder_workspace.me.start_count
    selector {
      match_labels = {
        "coder.workspace_id" = data.coder_workspace.me.id
      }
    }
    template {
      metadata {
        labels = {
          "coder.workspace_id" = data.coder_workspace.me.id
        }
      }
      spec {
        automount_service_account_token = false  
        container {
          name  = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
          image = local.image
          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.main.token
          }
          env {
            name  = "CODER_AGENT_URL"
            value = replace(data.coder_workspace.me.access_url, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")
          }
          env {
            name  = "GIT_URL"
            value = data.coder_parameter.repo.value == "custom" ? data.coder_parameter.custom_repo_url.value : data.coder_parameter.repo.value
          }          
          env {
            name  = "INIT_SCRIPT"
            value = replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")
          }
          env {
            name  = "FALLBACK_IMAGE"
            value = "codercom/enterprise-base:ubuntu"
          }
          env {
            name = "DOCKER_CONFIG_BASE64"
            value = var.docker_config
          } 
          env {
            name = "CACHE_REPO"
            value = var.cache_repo
          }          
          volume_mount {
            name       = "workspaces"
            mount_path = "/workspaces"
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
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_deployment.workspace[0].id
  item {
    key   = "image"
    value = local.image
  }  
  item {
    key   = "devcontainer"
    value = data.coder_parameter.repo.value
  }  
}
