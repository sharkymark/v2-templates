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
  image = "docker.io/codercom/enterprise-base:ubuntu"
  repo = "https://github.com/sharkymark" 
  repo-name = "airflow_wac"    
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
  for workspaces.  A valid "~/.kube/config" must be present on the Coder host.
  EOF
  default = false
}

variable "workspaces_namespace" {
  description = <<-EOF
  Kubernetes namespace to deploy the workspace into

  EOF
  default = ""
}

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL"
  description = "Personalize your workspace"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
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

  startup_script_behavior = "blocking"
  startup_script_timeout = 200    
  startup_script = <<EOT
#!/bin/bash

export PATH=$PATH:$HOME/.local/bin

# add some Python libraries
pip3 install --user pandas numpy &

# install code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 2>&1 >/dev/null 2>&1 &

# install and start airflow
pip3 install apache-airflow
/home/coder/.local/bin/airflow standalone >/dev/null 2>&1 &

# use coder CLI to clone and install dotfiles
if [[ ! -z "${data.coder_parameter.dotfiles_url.value}" ]]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
fi

# clone repo
if [ ! -d "${local.repo-name}" ] 
then
  echo "Cloning git repo..."
  git clone ${local.repo}/${local.repo-name}
else
  echo "Repo ${local.repo}/${local.repo-name} already exists. Will not reclone"
fi

EOT
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
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

# airflow
resource "coder_app" "airflow" {
  agent_id      = coder_agent.coder.id
  slug          = "airflow"  
  display_name  = "Airflow"
  icon          = "https://upload.wikimedia.org/wikipedia/commons/d/de/AirflowLogo.png"
  url           = "http://localhost:8080"
  subdomain = true
  share     = "owner"

  healthcheck {
    url       = "http://localhost:8080/healthz"
    interval  = 10
    threshold = 60
  } 
}

resource "kubernetes_pod" "main" {
  count = data.coder_workspace.me.start_count
  metadata {
    name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
    namespace = var.workspaces_namespace
  }
  spec {
    security_context {
      run_as_user = "1000"
      fs_group    = "1000"
    }     
    container {
      name    = "airflow"
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
    key   = "CPU"
    value = "${kubernetes_pod.main[0].spec[0].container[0].resources[0].limits.cpu} cores"
  }
  item {
    key   = "memory"
    value = "${local.memory-limit}"
  }  
  item {
    key   = "image"
    value = "codercom/enterprise-base:ubuntu"
  } 
  item {
    key   = "disk"
    value = local.home-volume
  }
  item {
    key   = "volume"
    value = kubernetes_pod.main[0].spec[0].container[0].volume_mount[0].mount_path
  }  
}
