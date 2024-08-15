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
  cpu-limit = "2"
  memory-limit = "4G"
  cpu-request = "500m"
  memory-request = "1" 
  home-volume = "10Gi"
  image = "marktmilligan/kasm:latest"
  user = "kasm-user"
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
  default = false
}

variable "namespace" {
  description = <<-EOF
  Kubernetes namespace to deploy the workspace into

  EOF
  default = ""
}

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL (optional)"
  description = "Personalize your workspace e.g., https://github.com/sharkymark/dotfiles.git"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  order       = 1
}

provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}

data "coder_workspace_owner" "me" {}

resource "coder_agent" "coder" {
  os                      = "linux"
  arch                    = "amd64"
  dir                     = "/home/${local.user}"

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
    vscode = true
    vscode_insiders = false
    ssh_helper = false
    port_forwarding_helper = false
    web_terminal = true
  }

  env = { 
  
    }

  startup_script_behavior = "blocking"

  startup_script = <<EOT

#!/bin/bash

# install and start the latest code-server
curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server
/tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

# use coder CLI to clone and install dotfiles
if [[ ! -z "${data.coder_parameter.dotfiles_url.value}" ]]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
fi

# start Kasm
/dockerstartup/kasm_default_profile.sh
/dockerstartup/vnc_startup.sh >/dev/null 2>&1 &

# start Insomnia 
insomnia >/dev/null 2>&1 &

# change shell
sudo chsh -s $(which bash) $(whoami) >/dev/null 2>&1 &

  EOT  
}

resource "coder_app" "kasm" {
  agent_id      = coder_agent.coder.id
  slug          = "kasm"  
  display_name  = "KasmVNC"
  icon          = "https://avatars.githubusercontent.com/u/44181855?s=280&v=4"
  url           = "http://localhost:6901"
  subdomain = true
  share     = "owner"

  healthcheck {
    url       = "http://localhost:6901/healthz"
    interval  = 5
    threshold = 15
  } 
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
  slug          = "code-server"  
  display_name  = "code-server"
  icon          = "/icon/code.svg"
  url           = "http://localhost:13337?folder=/home/${local.user}"
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
    name = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
    namespace = var.namespace
  }
  spec {
    security_context {
      run_as_user = "1000"
      fs_group    = "1000"
    }    
    container {
      name    = "coder-container"
      image   = local.image
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
          cpu    = local.cpu-request
          memory = local.memory-request
        }        
        limits = {
          cpu    = local.cpu-limit
          memory = local.memory-limit
        }
      }                       
      volume_mount {
        mount_path = "/home/${local.user}"
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
    name      = "home-coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
    namespace = var.namespace
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
}
