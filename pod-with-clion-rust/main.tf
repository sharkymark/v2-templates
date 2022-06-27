terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.4.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11"
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
  default = ""
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
  type        = string
  sensitive   = true
  description = "The namespace to create workspaces in (must exist prior to creating workspaces)"
  default     = "oss"
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

/coder/configure 2>&1 > ~/configure.log

# use coder CLI to clone and install dotfiles

coder dotfiles -y ${var.dotfiles_uri} 2>&1 > ~/dotfiles.log

PROJECTOR_BINARY=/home/coder/.local/bin/projector

# install projector into /home/coder
if [ -f $PROJECTOR_BINARY ]; then
    echo 'projector has already been installed - check for update'
    /home/coder/.local/bin/projector self-update
else
    echo 'installing projector'
    pip3 install projector-installer --user
fi

echo 'access projector license terms'
/home/coder/.local/bin/projector --accept-license

PROJECTOR_CONFIG_PATH=/home/coder/.projector/configs/CLion

if [ -d $PROJECTOR_CONFIG_PATH ]; then
    echo 'projector has already been configured and the JetBrains IDE downloaded - skip step'
else
    echo 'autoinstalling IDE and creating projector config folder'
    /home/coder/.local/bin/projector ide autoinstall --config-name CLion --ide-name "CLion 2022.1.3" --hostname=localhost --port 8997 --use-separate-config --password coder

    # delete the config directory because it has password tokens
    rm -rf /home/coder/.projector/configs

    # create the config
    /home/coder/.local/bin/projector config add CLion /home/coder/.projector/apps/clion-2022.1.3 --port 8997 --hostname=localhost --use-separate-config

fi

# start JetBrains projector-based IDE
#/home/coder/.projector/configs/CLion/run.sh &

/home/coder/.local/bin/projector run CLion &

# install and start code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 &

EOT
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
  name          = "code-server"
  icon          = "https://cdn.icon-icons.com/icons2/2107/PNG/512/file_type_vscode_icon_130084.png"
  url           = "http://localhost:13337?folder=/home/coder"
  relative_path = true  
}

resource "coder_app" "jetbrains-clion" {
  agent_id      = coder_agent.coder.id
  name          = "jetbrains-clion"
  icon          = "https://upload.wikimedia.org/wikipedia/commons/6/62/Clion.svg"
  url           = "http://localhost:8997/"
  relative_path = true
}

resource "kubernetes_pod" "main" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim.home-directory
  ]    
  metadata {
    name = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = "oss"
  }
  spec {
    security_context {
      run_as_user = "1000"
      fs_group    = "1000"
    }     
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
