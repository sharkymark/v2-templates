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
  repo = "git@github.com:sharkymark/java_helloworld.git"
  repo-name = "java_helloworld" 
  image = "intellij-idea-community-vnc"

}

variable "use_kubeconfig" {
  type        = bool
  sensitive   = false
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
  sensitive   = false
  description = <<-EOF
  Kubernetes namespace to deploy the workspace into

  EOF
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
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
}

data "coder_parameter" "intellij-idea-version" {
  name        = "IntelliJ IDEA Community Edition Version"
  type        = "string"
  description = "What version of IntelliJ IDEA Community Edition do you want?"
  mutable     = true
  default     = "2023.2.2"
  icon        = "https://resources.jetbrains.com/storage/products/company/brand/logos/IntelliJ_IDEA_icon.svg"

  option {
    name = "2023.2.2"
    value = "2023.2.2"
  }
  option {
    name = "2023.2.1"
    value = "2023.2.1"
  }
  option {
    name = "2022.3.2"
    value = "2022.3.2"
  }  
}

resource "coder_agent" "coder" {
  os   = "linux"
  arch = "amd64"

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

  display_apps {
    vscode = false
    vscode_insiders = false
    ssh_helper = false
    port_forwarding_helper = false
    web_terminal = true
  }

  dir                     = "/home/coder"
  startup_script_behavior = "blocking"
  startup_script_timeout = 200 

  startup_script = <<EOT
#!/bin/bash

# start VNC
# based on custom container images:
# https://hub.docker.com/r/marktmilligan/intellij-idea-community-vnc
#
# Dockerfile:
# https://github.com/sharkymark/dockerfiles/blob/main/intellij-idea/vnc/Dockerfile
#
# parent container image is noVNC and TurboVNC
# https://hub.docker.com/r/marktmilligan/vnc
# tags:
# coder-v2
#
# Dockerfile:
# https://github.com/sharkymark/dockerfiles/tree/main/vnc
/coder/start_vnc >/dev/null 2>&1 

# use coder CLI to clone and install dotfiles
if [ -n "$DOTFILES_URL" ]; then
  echo "Installing dotfiles from $DOTFILES_URL"
  coder dotfiles -y "$DOTFILES_URL" >/dev/null 2>&1 &
fi

# clone repo
if [ ! -d "${local.repo-name}" ]; then
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git clone ${local.repo} >/dev/null 2>&1 &
fi

# start intellij idea community in vnc window
# https://www.jetbrains.com/help/idea/run-for-the-first-time.html#linux
# delay starting intellij in case vnc is not finished setting up
sleep 5
DISPLAY=:90 /opt/idea/bin/idea.sh >/dev/null 2>&1 &

  EOT  
}

resource "coder_app" "novnc" {
  agent_id      = coder_agent.coder.id
  slug          = "vnc"  
  display_name  = "IntelliJ in noVNC"
  icon          = "/icon/intellij.svg"
  url           = "http://localhost:6081"
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:6081/healthz"
    interval  = 10
    threshold = 15
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
      image   = "docker.io/marktmilligan/${local.image}:${data.coder_parameter.intellij-idea-version.value}"
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

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
  item {
    key   = "image"
    value = local.image
  }    
  item {
    key   = "repo"
    value = local.repo-name
  } 
  item {
    key   = "IntelliJ Community Version"
    value = data.coder_parameter.intellij-idea-version.value
  }     
}