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
  cpu-request = "250m"
  memory-request = "250m" 
  home-volume = "10Gi"
  repo = "https://github.com/sharkymark/java_helloworld" 
  repo_name = "sharkymark/java_helloworld"  
  folder_name = try(element(split("/", local.repo), length(split("/", local.repo)) - 1), "")  
  repo_owner_name = try(element(split("/", local.repo), length(split("/", local.repo)) - 2), "")       
  image = "docker.io/marktmilligan/eclipse-kasm:2023-03"
  image_tag = try(element(split("/", local.image), length(split("/", local.image)) - 1), "")   
  user = "kasm-user"  
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
}

variable "workspaces_namespace" {
  sensitive   = true
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
  default     = "git@github.com:sharkymark/dotfiles.git"
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
}

resource "coder_agent" "coder" {
  os   = "linux"
  arch = "amd64"

  metadata {
    key          = "disk"
    display_name = "Home Volume Disk Usage"
    interval     = 600 # every 10 minutes
    timeout      = 30  # df can take a while on large filesystems
    script       = <<-EOT
      #!/bin/bash
      set -e
      df /home/${local.user} | awk NR==2'{print $5}'
    EOT
  }

  dir = "/home/${local.user}"
  login_before_ready = false
  startup_script_timeout = 200   
  env                     = { "DOTFILES_URL" = data.coder_parameter.dotfiles_url.value != "" ? data.coder_parameter.dotfiles_url.value : null }     
  startup_script = <<EOT
#!/bin/sh

set -e

echo "starting KasmVNC"
/dockerstartup/kasm_default_profile.sh
/dockerstartup/vnc_startup.sh >/dev/null 2>&1 &

# use coder CLI to clone and install dotfiles
if [ -n "$DOTFILES_URL" ]; then
  echo "Installing dotfiles from $DOTFILES_URL"
  coder dotfiles -y "$DOTFILES_URL"
fi

# clone repo
if [ ! -d "${local.folder_name}" ] 
then
  echo "Cloning git repo..."
  git clone ${local.repo}
else
  echo "Repo ${local.repo} already exists. Will not reclone"
fi

# Eclipse needs KasmVNC fully running to start, so sleep let it complete
sleep 5

echo "starting Eclipse IDE"
/opt/eclipse/eclipse >/dev/null 2>&1 &

# change shell
sudo chsh -s $(which bash) $(whoami)

  EOT  
}

resource "coder_app" "kasm" {
  agent_id      = coder_agent.coder.id
  slug          = "kasm"  
  display_name  = "Eclipse in KasmVNC"
  icon          = "https://cdn.freebiesupply.com/logos/large/2x/eclipse-11-logo-png-transparent.png"
  url           = "http://localhost:6901"
  subdomain = true
  share     = "owner"

  healthcheck {
    url       = "http://localhost:6901/healthz"
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
      image   = local.image
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
    name      = "home-coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
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
    key   = "CPU"
    value = "${local.cpu-limit} cores"
  }
  item {
    key   = "memory"
    value = "${local.memory-limit}"
  }  
  item {
    key   = "disk"
    value = "${local.home-volume}"
  }
  item {
    key   = "image"
    value = local.image_tag
  }     
  item {
    key   = "repo"
    value = local.repo_name
  }   
}