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
  memory-limit = "8G"
  cpu-request = "500m"
  memory-request = "4G" 
  home-volume = "5Gi"

  repo = {
    "Java"    = "sharkymark/java_helloworld.git" 
    "Python"  = "sharkymark/python_commissions.git" 
    "Golang"  = "coder/coder.git"
    "Node"    = "sharkymark/coder-react.git"
  }  
  image = {
    "Java"    = "codercom/enterprise-java:ubuntu" 
    "Python"  = "codercom/enterprise-base:ubuntu" 
    "Golang"  = "codercom/enterprise-golang:ubuntu"
    "Node"    = "codercom/enterprise-node:ubuntu"
  }  

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
  default = false
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
  name        = "Dotfiles URL"
  description = "Personalize your workspace"
  type        = "string"
  default     = "git@github.com:sharkymark/dotfiles.git"
  mutable     = true 
  icon        = "https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png"
}

data "coder_parameter" "lang" {
  name        = "Programming Language"
  type        = "string"
  description = "What container image and language do you want?"
  mutable     = true
  default     = "Java"
  icon        = "https://www.docker.com/wp-content/uploads/2022/03/vertical-logo-monochromatic.png"

  option {
    name = "Node"
    value = "Node"
    icon = "https://cdn.freebiesupply.com/logos/large/2x/nodejs-icon-logo-png-transparent.png"
  }
  option {
    name = "Golang"
    value = "Golang"
    icon = "https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Go_Logo_Blue.svg/1200px-Go_Logo_Blue.svg.png"
  } 
  option {
    name = "Java"
    value = "Java"
    icon = "https://assets.stickpng.com/images/58480979cef1014c0b5e4901.png"
  } 
  option {
    name = "Python"
    value = "Python"
    icon = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Python-logo-notext.svg/1869px-Python-logo-notext.svg.png"
  }      
}

resource "coder_agent" "dev" {
  os   = "linux"

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

  arch = "amd64"
  dir = "/home/coder"
  startup_script = <<EOT
#!/bin/bash

# install bench/basic calculator
sudo apt install bc 

# clone repo
mkdir -p ~/.ssh
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git clone --progress git@github.com:${lookup(local.repo, data.coder_parameter.lang.value)} >/dev/null 2>&1 &

# install and start code-server
curl -fsSL https://code-server.dev/install.sh | sh
code-server --auth none --port 13337 >/dev/null 2>&1 &

# use coder CLI to clone and install dotfiles
if [[ ! -z "${data.coder_parameter.dotfiles_url.value}" ]]; then
  coder dotfiles -y ${data.coder_parameter.dotfiles_url.value} >/dev/null 2>&1 &
fi

  EOT  
}

# code-server
resource "coder_app" "code-server" {
  agent_id      = coder_agent.dev.id
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
      run_as_user = "1000"
      fs_group    = "1000"
    }    
    container {
      name    = "coder-container"
      image   = "docker.io/${lookup(local.image, data.coder_parameter.lang.value)}"
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
          cpu    = "${local.cpu-request}"
          memory = "${local.memory-request}"
        }        
        limits = {
          cpu    = "${local.cpu-limit}"
          memory = "${local.memory-limit}"
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
        storage = "${local.home-volume}"
      }
    }
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
  item {
    key   = "CPU limits"
    value = "${local.cpu-limit} cores"
  }
  item {
    key   = "memory limits"
    value = "${local.memory-limit}"
  } 
  item {
    key   = "CPU requests"
    value = "${kubernetes_pod.main[0].spec[0].container[0].resources[0].requests.cpu}"
  }
  item {
    key   = "memory requests"
    value = "${kubernetes_pod.main[0].spec[0].container[0].resources[0].requests.memory}"
  }    
  item {
    key   = "image"
    value = "docker.io/${lookup(local.image, data.coder_parameter.lang.value)}"
  }
  item {
    key   = "repo cloned"
    value = "docker.io/${lookup(local.repo, data.coder_parameter.lang.value)}"
  }  
  item {
    key   = "disk"
    value = "${local.home-volume}GiB"
  }
  item {
    key   = "volume"
    value = kubernetes_pod.main[0].spec[0].container[0].volume_mount[0].mount_path
  }  
}