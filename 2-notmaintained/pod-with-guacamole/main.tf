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

  cpu-limit = "1"
  memory-limit = "1G"
  cpu-request = "250m"
  memory-request = "500m" 
  home-volume = "10Gi"
  guac-server-image = "docker.io/guacamole/guacd:1.5.0"
  guac-client-image = "docker.io/marktmilligan/guacamole:1.5.0" 
  base-image = "docker.io/marktmilligan/tigervnc:latest"     
  disk-size = 10
}

provider "coder" {

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
  default = true
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
  name        = "Dotfiles URL (optional)"
  description = "Personalize your workspace e.g., https://github.com/sharkymark/dotfiles.git"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  order       = 1
}

resource "coder_agent" "base" {
  os   = "linux"
  arch = "amd64"
  dir = "/home/coder"

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

  startup_script = <<EOT
#!/bin/bash

# run configure script to start tigervnc
/coder/configure

# install and start code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 >/dev/null 2>&1 &

# use coder CLI to clone and install dotfiles
if [ "${data.coder_parameter.dotfiles_url.value}" != "" ]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value} &
fi

# remove xfce screen locker, since keyboard commands cannot unlock it
sudo apt purge light-locker -y >/dev/null 2>&1 &

  EOT  
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.base.id
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

# guacamole client
resource "coder_app" "guac" {
  agent_id      = coder_agent.base.id
  slug          = "guac"  
  display_name  = "Guacamole Client"
  icon          = "https://www.dove.io/static/media/guac.4b7f0930426ff89e75ab.png"
  url           = "http://localhost:8080/guacamole"
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:8080/guacamole/healthz"
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
      name    = "base-container"
      image   = local.base-image
      image_pull_policy = "Always"
      command = ["sh", "-c", coder_agent.base.init_script]
      security_context {
        run_as_user = "1000"
      }     
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.base.token
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
    container {
      name    = "guac-server-container"
      image   = local.guac-server-image
      image_pull_policy = "Always"
      security_context {
        run_as_user = "1000"
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
        mount_path = "/home/guacamole"
        name       = "home-directory"
      }                                     
    }
    container {
      name    = "guac-client-container"
      image   = local.guac-client-image
      image_pull_policy = "Always" 
      security_context {
        run_as_user = "1001"
        run_as_group = "1001"
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
      env {
        name     = "GUACD_HOSTNAME"
        value    = "localhost"
      }
      env {
        name     = "GUACD_PORT"
        value    = "4822"
      }                      
      volume_mount {
        mount_path = "/home/guacamole"
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
        storage = "${local.disk-size}Gi"
      }
    }
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
  item {
    key   = "CPU (per container)"
    value = "${local.cpu-limit} cores"
  }
  item {
    key   = "memory (per container)"
    value = "${local.memory-limit}"
  }  
  item {
    key   = "guac-client-container-image"
    value = "${local.guac-client-image}"
  }
  item {
    key   = "guac-server-container-image"
    value = "${local.guac-server-image}"
  }    
  item {
    key   = "base-container-image"
    value = "${local.base-image}"
  }      
  item {
    key   = "disk"
    value = "${local.disk-size}GiB"
  }
  item {
    key   = "volume"
    value = kubernetes_pod.main[0].spec[0].container[0].volume_mount[0].mount_path
  }  
}