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
  repo = "https://github.com/gmhafiz/go8.git"
  golang-image = "docker.io/codercom/enterprise-golang:ubuntu"
  postgres-image = "docker.io/marktmilligan/postgres:13"  
  dbeaver-image = "docker.io/dbeaver/cloudbeaver:latest"    
  pgadmin-image = "docker.io/dpage/pgadmin4:latest"    
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

variable "dotfiles_uri" {
  description = <<-EOF
  Dotfiles repo URI (optional)

  see https://dotfiles.github.io
  EOF
  default = "git@github.com:sharkymark/dotfiles.git"
}


variable "disk_size" {
  description = "Disk size (__ GB)"
  default     = 10
}

resource "coder_agent" "golang" {
  os   = "linux"
  arch = "amd64"
  dir = "/home/coder"
  startup_script = <<EOT
#!/bin/bash

# install and start code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 &

# add psql
sudo apt-get install -y postgresql-client 

# clone repo
git clone ${local.repo} 

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${var.dotfiles_uri} 

  EOT  
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.golang.id
  slug          = "code-server"  
  display_name  = "VS Code Web"
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

# dbeaver
resource "coder_app" "dbeaver" {
  agent_id      = coder_agent.golang.id
  slug          = "dbeaver"  
  display_name  = "DBeaver"
  icon          = "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/DBeaver_logo.svg/1024px-DBeaver_logo.svg.png"
  url           = "http://localhost:8978"
  subdomain = true
  share     = "owner"

  healthcheck {
    url       = "http://localhost:8978/healthz"
    interval  = 3
    threshold = 10
  }  
}

# dbadmin
resource "coder_app" "pgadmin" {
  agent_id      = coder_agent.golang.id
  slug          = "pgadmin"  
  display_name  = "pgAdmin"
  icon          = "https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Postgresql_elephant.svg/1200px-Postgresql_elephant.svg.png"
  url           = "http://localhost:80"
  subdomain = true
  share     = "owner"

  healthcheck {
    url       = "http://localhost:80/healthz"
    interval  = 3
    threshold = 10
  }  
}

resource "coder_agent" "postgres" {
  os   = "linux"
  arch = "amd64" 
  dir = "/home/postgres"
}

resource "kubernetes_config_map" "postgres-configmap" {
  metadata {
    name = "postgres-env-vars"
    namespace = var.workspaces_namespace
  }
  data = {
    DB_DRIVER = "postgres"
    DB_HOST   = "localhost"
    DB_PORT   = "5432"
    DB_USER   = "postgres"
    DB_PASS   = "postgres"
    DB_NAME   = "go8_db" 
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
      name    = "golang-container"
      image   = local.golang-image
      image_pull_policy = "Always"
      command = ["sh", "-c", coder_agent.golang.init_script]
      security_context {
        run_as_user = "1000"
      }     
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.golang.token
      }  
      env_from {
        config_map_ref {
          name = kubernetes_config_map.postgres-configmap.metadata.0.name
        }
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
      name    = "postgres-container"
      image   = local.postgres-image
      image_pull_policy = "Always" 
      security_context {
        run_as_user = "999"
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
    }  
    container {
      name    = "dbeaver-container"
      image   = local.dbeaver-image
      image_pull_policy = "Always" 
      security_context {
        run_as_user = "0"
      }
      env {
        name     = "XDG_DATA_HOME"
        value    = "/home/coder"
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
      name    = "pgadmin-container"
      image   = local.pgadmin-image
      image_pull_policy = "Always" 
      security_context {
        run_as_user = "5050"
      }
      env {
        name    = "PGADMIN_DEFAULT_EMAIL"
        value   = "pgadmin@pgadmin.org"
      }  
      env {
        name    = "PGADMIN_DEFAULT_PASSWORD"
        value   = "pgadmin"
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
        mount_path = "/var/lib/pgadmin"
        name       = "pgadmin-directory"
      }                                             
    }            
    volume {
      name = "home-directory"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.home-directory.metadata.0.name
      }
    }  
    volume {
      name = "pgadmin-directory"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.pgadmin-directory.metadata.0.name
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

resource "kubernetes_persistent_volume_claim" "pgadmin-directory" {
  metadata {
    name      = "pgadmin-coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
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
    key   = "golang-container-image"
    value = "${local.golang-image}"
  }
  item {
    key   = "postgres-container-image"
    value = "${local.postgres-image}"
  }  
  item {
    key   = "dbeaver-container-image"
    value = "${local.dbeaver-image}"
  }
  item {
    key   = "pgadmin-container-image"
    value = "${local.pgadmin-image}"
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