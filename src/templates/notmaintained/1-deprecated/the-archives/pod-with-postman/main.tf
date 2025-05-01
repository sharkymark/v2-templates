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

variable "dotfiles_uri" {
  description = <<-EOF
  Dotfiles repo URI (optional)
  see https://dotfiles.github.io
  EOF
  default     = "git@github.com:sharkymark/dotfiles.git"
}

variable "cpu" {
  description = "CPU (__ cores)"
  default     = 1
  validation {
    condition = contains([
      "1",
      "2",
      "4",
      "6"
    ], var.cpu)
    error_message = "Invalid cpu!"
  }
}

variable "memory" {
  description = "Memory (__ GB)"
  default     = 2
  validation {
    condition = contains([
      "1",
      "2",
      "4",
      "8"
    ], var.memory)
    error_message = "Invalid memory!"
  }
}

variable "disk_size" {
  description = "Disk size (__ GB)"
  default     = 10
}


variable "workspaces_namespace" {
  description = <<-EOF
  Kubernetes namespace to deploy the workspace into
  EOF
  default     = ""

}

provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}

resource "coder_agent" "coder" {
  os             = "linux"
  arch           = "amd64"
  dir            = "/home/coder"
  startup_script = <<EOT
#!/bin/bash
# start VNC
echo "Creating desktop..."
mkdir -p "$XFCE_DEST_DIR"
cp -rT "$XFCE_BASE_DIR" "$XFCE_DEST_DIR"
# Skip default shell config prompt.
cp /etc/zsh/newuser.zshrc.recommended $HOME/.zshrc
echo "Initializing Supervisor..."
nohup supervisord
# eclipse
DISPLAY=:90 /opt/eclipse/eclipse -data /home/coder sh &
# postman
DISPLAY=:90 /./usr/bin/Postman/Postman&
# install code-server
curl -fsSL https://code-server.dev/install.sh | sh 
code-server --auth none --port 13337 &
EOT
}

# code-server
resource "coder_app" "code-server" {
  agent_id     = coder_agent.coder.id
  slug         = "code-server"
  display_name = "VS Code"
  icon         = "/icon/code.svg"
  url          = "http://localhost:13337"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }

}

resource "coder_app" "eclipse" {
  agent_id     = coder_agent.coder.id
  slug         = "eclipse"
  display_name = "Eclipse"
  icon         = "https://upload.wikimedia.org/wikipedia/commons/c/cf/Eclipse-SVG.svg"
  url          = "http://localhost:6081"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:6081/healthz"
    interval  = 6
    threshold = 20
  }
}

resource "coder_app" "postman" {
  agent_id     = coder_agent.coder.id
  slug         = "postman"
  display_name = "Postman"
  icon         = "https://user-images.githubusercontent.com/7853266/44114706-9c72dd08-9fd1-11e8-8d9d-6d9d651c75ad.png"
  url          = "http://localhost:6081"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:6081/healthz"
    interval  = 6
    threshold = 20
  }
}

resource "kubernetes_pod" "main" {
  count = data.coder_workspace.me.start_count
  metadata {
    name      = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
    namespace = var.workspaces_namespace
  }
  spec {
    security_context {
      run_as_user = "1000"
      fs_group    = "1000"
    }
    container {
      name              = "eclipse"
      image             = "docker.io/ericpaulsen/eclipse-postman-vnc:latest"
      command           = ["sh", "-c", coder_agent.coder.init_script]
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
          cpu    = "250m"
          memory = "250Mi"
        }
        limits = {
          cpu    = "${var.cpu}"
          memory = "${var.memory}G"
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
    name      = "home-coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
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

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
  item {
    key   = "CPU"
    value = "${kubernetes_pod.main[0].spec[0].container[0].resources[0].limits.cpu} cores"
  }
  item {
    key   = "memory"
    value = "${var.memory}GB"
  }
  item {
    key   = "image"
    value = "docker.io/marktmilligan/eclipse-vnc:latest"
  }
  item {
    key   = "disk"
    value = "${var.disk_size}GiB"
  }
  item {
    key   = "volume"
    value = kubernetes_pod.main[0].spec[0].container[0].volume_mount[0].mount_path
  }
}