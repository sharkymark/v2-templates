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

data "coder_parameter" "disk_size" {
  name        = "PVC storage size"
  type        = "number"
  description = "Number of GB of storage"
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min       = 50
    max       = 100
    monotonic = "increasing"
  }
  mutable     = true
  default     = 50
}

data "coder_parameter" "cpu" {
  name        = "CPU cores"
  type        = "number"
  description = "CPU cores - be sure the cluster nodes have the capacity"
  icon        = "https://png.pngtree.com/png-clipart/20191122/original/pngtree-processor-icon-png-image_5165793.jpg"
  validation {
    min       = 1
    max       = 4
  }
  mutable     = true
  default     = 1
}

data "coder_parameter" "memory" {
  name        = "Memory (__ GB)"
  type        = "number"
  description = "Be sure the cluster nodes have the capacity"
  icon        = "https://www.vhv.rs/dpng/d/33-338595_random-access-memory-logo-hd-png-download.png"
  validation {
    min       = 1
    max       = 8
  }
  mutable     = true
  default     = 2
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
      df /home/coder | awk NR==2'{print $5}'
    EOT
  }

  metadata {
    key          = "mem-used"
    display_name = "Memory Usage"
    interval     = 1
    timeout      = 1
    script       = <<-EOT
      #!/bin/bash
      set -e
      awk '(NR == 1){tm=$1} (NR == 2){mu=$1} END{printf("%.0f%%",mu/tm * 100.0)}' /sys/fs/cgroup/memory/memory.limit_in_bytes /sys/fs/cgroup/memory/memory.usage_in_bytes
    EOT
  } 


    metadata {
    key          = "cpu-used"
    display_name = "CPU Usage"
    interval     = 3
    timeout      = 3
    script       = <<-EOT
      #!/bin/bash
      set -e

      tstart=$(date +%s%N)
      cstart=$(cat /sys/fs/cgroup/cpu/cpuacct.usage)

      sleep 1

      tstop=$(date +%s%N)
      cstop=$(cat /sys/fs/cgroup/cpu/cpuacct.usage)

      echo "($cstop - $cstart) / ($tstop - $tstart) * 100" | /usr/bin/bc -l | awk '{printf("%.0f%%",$1)}'      

    EOT
  }


  metadata {
    display_name = "Load Average"
    key  = "load"
    script = <<EOT
        awk '{print $1,$2,$3,$4}' /proc/loadavg
    EOT
    interval = 1
    timeout = 1
  }

  dir = "/home/coder"
  startup_script = <<EOT
#!/bin/bash

# install bench/basic calculator
sudo apt install bc 

# clone coder/coder repo
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git clone --progress git@github.com:coder/coder.git

# use coder CLI to clone and install dotfiles
coder dotfiles -y ${data.coder_parameter.dotfiles_url.value}

# install and start code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 &

  EOT  
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.coder.id
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
      fs_group    = "1000"
    }      
    # Run a privileged dind (Docker in Docker) container
    container {
      name  = "docker-sidecar"
      image = "docker:dind"
      security_context {
        privileged = true
      }
      command = ["dockerd", "-H", "tcp://127.0.0.1:2375"]
    }         
    container {
      name    = "go-container"
      image   = "docker.io/codercom/enterprise-golang:ubuntu"
      image_pull_policy = "Always"
      command = ["sh", "-c", coder_agent.coder.init_script]
      security_context {
        run_as_user = "1000"
      }      
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.coder.token
      }  
      # Use the Docker daemon in the "docker-sidecar" container
      env {
        name  = "DOCKER_HOST"
        value = "localhost:2375" 
      }     
      resources {
        requests = {
          cpu    = "500m"
          memory = "500Mi"
        }        
        limits = {
          cpu    = "${data.coder_parameter.cpu.value}"
          memory = "${data.coder_parameter.memory.value}G"
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

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
  item {
    key   = "CPU"
    value = "${data.coder_parameter.cpu.value} cores"
  }
  item {
    key   = "memory"
    value = "${data.coder_parameter.memory.value}GB"
  }  
  item {
    key   = "disk"
    value = "${data.coder_parameter.disk_size.value}GiB"
  }   
  item {
    key   = "container-1"
    value = "${kubernetes_pod.main[0].spec[0].container[0].name}"
  }  
  item {
    key   = "container-2"
    value = "${kubernetes_pod.main[0].spec[0].container[1].name}"
  }    
  item {
    key   = "image"
    value = "docker.io/codercom/enterprise-golang:ubuntu"
  }
  item {
    key   = "repo cloned"
    value = "docker.io/coder/coder.git"
  }     
}