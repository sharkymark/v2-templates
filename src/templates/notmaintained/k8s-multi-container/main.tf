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
  folder_name = try(element(split("/", local.repo), length(split("/", local.repo)) - 1), "")  
  repo_owner_name = try(element(split("/", local.repo), length(split("/", local.repo)) - 2), "")      
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

variable "workspaces_namespace" {
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

data "coder_parameter" "disk_size" {
  name        = "PVC storage size"
  type        = "number"
  description = "Number of GB of storage to mount on each container"
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min       = 1
    max       = 10
    monotonic = "increasing"
  }
  mutable     = true
  default     = 2
  order       = 1
}

data "coder_parameter" "cpu" {
  name        = "CPU cores"
  type        = "number"
  description = "CPUs per container"
  icon        = "https://png.pngtree.com/png-clipart/20191122/original/pngtree-processor-icon-png-image_5165793.jpg"
  validation {
    min       = 1
    max       = 2
  }
  mutable     = true
  default     = 1
  order       = 2
}

data "coder_parameter" "memory" {
  name        = "Memory (__ GB)"
  type        = "number"
  description = "Memory per container"
  icon        = "https://www.vhv.rs/dpng/d/33-338595_random-access-memory-logo-hd-png-download.png"
  validation {
    min       = 1
    max       = 2
  }
  mutable     = true
  default     = 1
  order       = 3
}

data "coder_parameter" "dotfiles_url" {
  name        = "Dotfiles URL (optional)"
  description = "Personalize your workspace e.g., https://github.com/sharkymark/dotfiles.git"
  type        = "string"
  default     = ""
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
  order       = 4
}

resource "coder_agent" "golang" {
  os   = "linux"

 # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.
  metadata {
    display_name = "Go CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Go RAM Usage"
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

  arch = "amd64"
  dir = "/home/coder"

  env = {  }  

  startup_script = <<EOT

# install and start code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 >/dev/null 2>&1 &

# add psql
sudo apt-get install -y postgresql-client 

# clone repo
if [ ! -d "${local.folder_name}" ] 
then
  echo "Cloning git repo..."
  git clone ${local.repo}
else
  echo "Repo ${local.repo} already exists. Will not reclone"
fi


# use coder CLI to clone and install dotfiles
if [[ ! -z "${data.coder_parameter.dotfiles_url.value}" ]]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}
fi

  EOT  
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.golang.id
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
      env {
        name  = "DB_DRIVER"
        value = "postgres"
      }  
      env {
        name  = "DB_PORT"
        value = "5432"
      }   
      env {
        name  = "DB_USER"
        value = "postgres"
      }  
      env {
        name  = "DB_PASS"
        value = "postgres"
      }  
      env {
        name  = "DB_HOST"
        value = "localhost"
      }  
      env {
        name  = "DB_NAME"
        value = "go8_db"
      }                              
      resources {
        requests = {
          cpu    = local.cpu-request
          memory = local.memory-request
        }        
        limits = {
          cpu    = data.coder_parameter.cpu.value
          memory = "${data.coder_parameter.memory.value}G"
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
          cpu    = data.coder_parameter.cpu.value
          memory = "${data.coder_parameter.memory.value}G"
        }
      }
      env {
          name    = "PGDATA"
          value   = "/var/lib/postgresql/data/k8s"        
      }
      volume_mount {
        mount_path = "/var/lib/postgresql/data"
        name       = "postgres-data-directory"
      }                                               
    }  
    container {
      name    = "dbeaver-container"
      image   = local.dbeaver-image
      image_pull_policy = "Always" 
      security_context {
        run_as_user = "0"
      }                                     
      resources {
        requests = {
          cpu    = local.cpu-request
          memory = local.memory-request
        }        
        limits = {
          cpu    = data.coder_parameter.cpu.value
          memory = "${data.coder_parameter.memory.value}G"
        }
      }      
      volume_mount {
        mount_path = "/opt/cloudbeaver/workspace"
        name       = "dbeaver-directory"
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
          cpu    = data.coder_parameter.cpu.value
          memory = "${data.coder_parameter.memory.value}G"
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
    volume {
      name = "postgres-data-directory"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.postgres-data-directory.metadata.0.name
      }
    } 
    volume {
      name = "dbeaver-directory"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.dbeaver-directory.metadata.0.name
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
        storage = "${data.coder_parameter.disk_size.value}Gi"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "pgadmin-directory" {
  metadata {
    name      = "pgadmin-coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.coder_parameter.disk_size.value}Gi"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "postgres-data-directory" {
  metadata {
    name      = "postgres-data-coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.coder_parameter.disk_size.value}Gi"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "dbeaver-directory" {
  metadata {
    name      = "dbeaver-coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = var.workspaces_namespace
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.coder_parameter.disk_size.value}Gi"
      }
    }
  }
}


resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
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
    key   = "repo cloned"
    value = "${local.repo_owner_name}/${local.folder_name}"
  }   
}