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
  memory-limit = "4G"
  cpu-request = "250m"
  memory-request = "2" 
  disk-size = "10Gi"
  #base-image = "docker.io/marktmilligan/iu-chown:2021.3.3"   
  base-image = "docker.io/marktmilligan/iu-chown:2022.1.4"  
  #base-image = "docker.io/marktmilligan/iu-chown:latest"    
}

provider "coder" {
  feature_use_managed_variables = "true"
}

variable "use_kubeconfig" {
  type        = bool
  description = <<-EOF
  Use host kubeconfig? (true/false)

  Set this to false if the Coder host is itself running as a Pod on the same
  Kubernetes cluster as you are deploying workspaces to.

  Set this to true if the Coder host is running outside the Kubernetes cluster
  for workspaces.  A valid "~/.kube/config" must be present on the Coder host. This
  is likely not your local machine unless you are using `coder server --dev.`

  EOF
}

variable "workspaces_namespace" {
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

resource "coder_agent" "dev" {

  metadata {
    key          = "disk"
    display_name = "Home Volume Disk Usage"
    interval     = 600 # every 10 minutes
    timeout      = 30  # df can take a while on large filesystems
    script       = <<-EOT
      #!/bin/bash
      set -e
      df /home/coder | awk NR==2'{print $5}'
    EOT
  }

  os = "linux"
  arch = "amd64"
  dir = "/home/coder"
  env = {
    "DOTFILES_URL" = data.coder_parameter.dotfiles_url.value != "" ? data.coder_parameter.dotfiles_url.value : null
    }     
  startup_script = <<EOF
    #!/bin/sh

    # use coder CLI to clone and install dotfiles
    if [ -n "$DOTFILES_URL" ]; then
      echo "Installing dotfiles from $DOTFILES_URL"
      coder dotfiles -y "$DOTFILES_URL" &
    fi

    # create symbolic link for JetBrains Gateway
    /opt/idea/bin/remote-dev-server.sh registerBackendLocationForGateway &

    # Start code-server
    # note code-server is in the container image
    code-server --auth none --port 13337 &

    # Configure and run JetBrains IDEs in a web browser
    # https://www.jetbrains.com/idea/download/other.html
    # Using JetBrains projector; please migrate to Gateway
    # https://lp.jetbrains.com/projector/
    # https://coder.com/docs/v2/latest/ides/gateway

    # Assumes you have JetBrains IDE installed in /opt
    # and pip3 installed in
    # your image and the "coder" user has filesystem
    # permissions for "/opt/*"
   
    pip3 install projector-installer --user
    /home/coder/.local/bin/projector --accept-license 
    
    /home/coder/.local/bin/projector config add intellij1 /opt/idea --force --use-separate-config --port 9001 --hostname localhost
    /home/coder/.local/bin/projector run intellij1 &

  EOF
}

# code-server
resource "coder_app" "code-server" {
  agent_id = coder_agent.dev.id
  slug          = "code-server"  
  display_name  = "VS Code Web"  
  icon     = "/icon/code.svg"
  url      = "http://localhost:13337"
  subdomain = false
  share     = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }  

}

resource "coder_app" "intellij1" {
  agent_id = coder_agent.dev.id
  slug          = "iu"  
  display_name  = "IntelliJ Ultimate"  
  icon          = "/icon/intellij.svg"
  url           = "http://localhost:9001"
  subdomain     = false
  share         = "owner"

  healthcheck {
    url         = "http://localhost:9001/healthz"
    interval    = 6
    threshold   = 20
  }    
}

resource "kubernetes_pod" "main" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim.home-directory
  ]
  metadata {
    name      = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
  spec {
    security_context {
      run_as_user = 1000
      fs_group    = 1000
    }
    container {
      name    = "dev"
      image   = local.base-image
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
    name      = "coder-pvc-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
  wait_until_bound = false  
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = local.disk-size
      }
    }
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
  item {
    key   = "kubernetes namespace"
    value = "${var.workspaces_namespace}"
  }    
  item {
    key   = "CPU (limits, requests)"
    value = "${local.cpu-limit} cores"
  }
  item {
    key   = "memory (limits, requests)"
    value = local.memory-limit
  }    
  item {
    key   = "image"
    value = kubernetes_pod.main[0].spec[0].container[0].image
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
