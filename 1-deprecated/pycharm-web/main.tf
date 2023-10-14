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
  #base-image = "docker.io/marktmilligan/pp-chown:2021.3.3"   
  #base-image = "docker.io/marktmilligan/pp-chown:2022.1.4" 
  base-image = "docker.io/marktmilligan/pp-chown:2023.2.3"     
  #base-image = "docker.io/marktmilligan/pp-chown:latest"
  image_nametag = try(element(split("/", local.base-image), length(split("/", local.base-image)) - 1), "")       
}

provider "coder" {

}

variable "use_kubeconfig" {
  type        = bool
  default     = "false"
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
  default     = ""
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
  name        = "Dotfiles URL (optional)"
  description = "Personalize your workspace e.g., git@github.com:sharkymark/dotfiles.git"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  order       = 1
}

resource "coder_agent" "dev" {

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

  os             = "linux"
  arch           = "amd64"
  dir            = "/home/coder"
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
    
    # install and code-server, VS Code in a browser 
    curl -fsSL https://code-server.dev/install.sh | sh
    code-server --auth none --port 13337 >/dev/null 2>&1 &

    # Configure and run JetBrains IDEs in a web browser
    # https://www.jetbrains.com/pycharm/download/other.html
    # Using JetBrains projector; please migrate to Gateway
    # https://lp.jetbrains.com/projector/
    # https://coder.com/docs/v2/latest/ides/gateway

    # Assumes you have JetBrains IDE installed in /opt
    # and pip3 installed in
    # your image and the "coder" user has filesystem
    # permissions for "/opt/*"
   
    pip3 install projector-installer --user
    /home/coder/.local/bin/projector --accept-license 
    
    /home/coder/.local/bin/projector config add pycharm1 /opt/pycharm --force --use-separate-config --port 9001 --hostname localhost
    /home/coder/.local/bin/projector run pycharm1 >/dev/null 2>&1 &

    # create symbolic link for JetBrains Gateway
    /opt/pycharm/bin/remote-dev-server.sh registerBackendLocationForGateway >/dev/null 2>&1 &

  EOF
}

# code-server
resource "coder_app" "code-server" {
  agent_id = coder_agent.dev.id
  slug          = "code-server"  
  display_name  = "code-server"  
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

resource "coder_app" "pycharm1" {
  agent_id = coder_agent.dev.id
  slug          = "pp"  
  display_name  = "PyCharm Pro"  
  icon          = "/icon/pycharm.svg"
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
    key   = "image"
    value = local.image_nametag
  }      
}
